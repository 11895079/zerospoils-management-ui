# Play Integrity API Setup Guide

## Overview

Play Integrity API is Google's solution for verifying that requests come from your genuine, unmodified app running on a real Android device. It replaces the deprecated SafetyNet Attestation API.

**Purpose**: Protect backend endpoints (OCR, export, Pro features) from abuse by verifying:
- App authenticity (signed with your signing key)
- Device integrity (not rooted/modified)
- App license status (from Google Play)

## When to Implement

**Recommended timeline**: Before **public Play Store launch** (M6 milestone).

**Current status (M4/370 Step 5)**: Secure token storage implemented. Play Integrity integration deferred to closed-testing validation phase.

**Why defer**:
- Requires Google Play Console setup (app must be uploaded to Play Console first)
- Requires backend endpoint to verify integrity tokens (server-side work)
- Not critical for closed alpha/beta testing with trusted users
- Can be added incrementally without breaking existing auth flow

## Prerequisites

1. **App uploaded to Play Console** (any track: internal/closed/open testing)
2. **Play Integrity API enabled** in Google Cloud Console
3. **Backend endpoint** to verify integrity tokens (server-side validation required)
4. **Signing key** used for release builds registered in Play Console

## Implementation Checklist

### Client-Side (Flutter App)

- [ ] Add `play_integrity` package to `pubspec.yaml` (or use platform channels for native integration)
- [ ] Create `IntegrityService` to request integrity tokens:
  ```dart
  class IntegrityService {
    Future<String?> getIntegrityToken() async {
      // Request Play Integrity token
      // Returns base64-encoded token or null on failure
    }
  }
  ```
- [ ] Update gated endpoints (OCR, export) to include integrity token in request headers
- [ ] Handle integrity check failures gracefully (show user-friendly error)

### Backend (Server-Side Validation)

**CRITICAL**: Integrity tokens MUST be verified server-side. Client-side checks can be bypassed.

- [ ] Set up Google Play Integrity API credentials in backend
- [ ] Create middleware to verify integrity tokens on Pro endpoints:
  1. Decode token from request header
  2. Call Google Play Integrity API to verify token
  3. Check `appIntegrity`, `deviceIntegrity`, `accountDetails` fields
  4. Return 403 Forbidden if verification fails
- [ ] Log integrity failures for monitoring (potential abuse patterns)

### Google Play Console Setup

1. **Enable Play Integrity API**:
   - Go to Google Cloud Console
   - Enable "Play Integrity API" for your project
   - Link your Play Console account

2. **Configure allowed package name**:
   - Play Console → App integrity → Play Integrity API
   - Verify package name: `com.zerospoils.zerospoils`

3. **Register signing key**:
   - Upload app bundle to Play Console (any track)
   - Google Play App Signing will register your key automatically

4. **Test with internal testing track**:
   - Upload signed release build to internal testing
   - Install app from Play Store (not sideload)
   - Verify integrity checks pass

## Integrity Check Flow

```
User triggers Pro feature (e.g., OCR)
  ↓
App checks entitlements (Firebase custom claims)
  ↓ [Pro tier = true]
App requests Play Integrity token
  ↓
Google Play verifies app authenticity + device integrity
  ↓
App receives integrity token (JWT)
  ↓
App calls backend endpoint with:
  - Firebase ID token (authentication)
  - Play Integrity token (verification)
  ↓
Backend verifies both tokens
  ↓ [Valid]
Backend processes request
```

## Testing Requirements

### Pre-Implementation (M4 Closed Testing)

- ✅ Firebase Auth + custom claims (Steps 3-4)
- ✅ Secure token storage (Step 5)
- ⏳ Backend endpoint gating (custom claims check only)

**Testing approach**: Trust closed-test users (no integrity checks yet). Firebase custom claims control Pro access.

### Post-Implementation (M6 Public Launch)

- ✅ Play Integrity API enabled
- ✅ Server-side integrity verification
- ✅ Graceful fallback for integrity failures

**Testing approach**:
1. Install app from Play Store (internal/closed track)
2. Trigger Pro feature → verify integrity token sent
3. Check backend logs for verification success
4. Test on rooted device → verify 403 Forbidden response
5. Test with modified APK → verify rejection

## Error Handling

### Client-Side

```dart
try {
  final integrityToken = await integrityService.getIntegrityToken();
  if (integrityToken == null) {
    // Device doesn't support Play Integrity or check failed
    showErrorDialog('This feature requires a verified device');
    return;
  }
  
  // Include token in request headers
  final response = await http.post(
    endpoint,
    headers: {
      'Authorization': 'Bearer $firebaseIdToken',
      'X-Integrity-Token': integrityToken,
    },
  );
} catch (e) {
  // Integrity check failed (network, attestation failure, etc.)
  logError('Integrity check failed: $e');
  showErrorDialog('Unable to verify device integrity');
}
```

### Server-Side

```python
def verify_integrity(token: str) -> bool:
    try:
        response = requests.post(
            'https://playintegrity.googleapis.com/v1/...:decodeIntegrityToken',
            json={'integrity_token': token},
            headers={'Authorization': f'Bearer {service_account_token}'}
        )
        
        if response.status_code != 200:
            return False
        
        result = response.json()
        
        # Check app integrity (genuine app, not modified)
        app_integrity = result.get('tokenPayloadExternal', {}).get('appIntegrity')
        if app_integrity != 'PLAY_RECOGNIZED':
            return False
        
        # Check device integrity (not rooted/unlocked)
        device_integrity = result.get('tokenPayloadExternal', {}).get('deviceIntegrity', [])
        if 'MEETS_DEVICE_INTEGRITY' not in device_integrity:
            return False
        
        return True
    except Exception as e:
        logger.error(f'Integrity verification failed: {e}')
        return False
```

## Fallback Strategy

**If Play Integrity unavailable** (e.g., device too old, Play Services disabled):

1. **Graceful degradation**: Allow feature access with Firebase Auth only (entitlements check)
2. **Rate limiting**: Enforce stricter rate limits for non-verified requests
3. **Monitoring**: Flag high-volume usage from non-verified devices

**Configuration**:
```dart
// Remote Config flag for integrity enforcement
final enforceIntegrity = RemoteConfig.instance.getBool('enforce_play_integrity');

if (enforceIntegrity && integrityToken == null) {
  showErrorDialog('This feature requires device verification');
  return;
}
```

## Cost Considerations

**Play Integrity API pricing** (as of 2024):
- Free tier: 10,000 calls/day
- Above free tier: $0.01 per call

**Optimization strategies**:
1. **Cache integrity tokens** (valid for ~1 hour)
2. **Only check on critical endpoints** (OCR, export, not every API call)
3. **Batch operations** (e.g., verify once per photo batch, not per photo)

Expected usage (100 DAU, 5 Pro features/day): ~500 calls/day = **free tier sufficient**.

## References

- [Play Integrity API Documentation](https://developer.android.com/google/play/integrity)
- [Migration from SafetyNet](https://developer.android.com/google/play/integrity/migrate)
- [Server-Side Verification Guide](https://developer.android.com/google/play/integrity/verdict)

## Next Steps (M6 Timeline)

1. Enable Play Integrity API in Google Cloud Console
2. Implement `IntegrityService` client wrapper
3. Add server-side verification endpoint
4. Update gated endpoints to require integrity token
5. Test with internal testing track
6. Monitor integrity failure rates in production
