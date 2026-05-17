# Security Baseline Checklist

## Purpose
Establish security posture for MVP and Pro tier features. Ensures compliance with privacy regulations (GDPR, CCPA) and prevents common vulnerabilities.

## How to Fill
Create checklist with verification steps for each security domain:

### 1. Data Storage Security
- [ ] Local database encrypted at rest (sqlcipher or Hive encryption)
- [ ] Sensitive data (e.g., Pro user tokens) stored in secure keychain (iOS Keychain, Android KeyStore)
- [ ] No plaintext PII in local storage
- [ ] Database files excluded from device backups (iOS iCloud, Android Auto Backup)
- [ ] Secure file permissions (readable only by app process)

### 2. Network Security
- [ ] All API calls use TLS 1.3 minimum
- [ ] Certificate pinning for critical endpoints (auth, payment)
- [ ] API keys not hardcoded in source (environment variables or secure config)
- [ ] Rate limiting implemented to prevent abuse
- [ ] No sensitive data in URL query parameters (use POST body)

### 3. Authentication & Authorization
- [ ] OAuth2/OpenID Connect for third-party auth (Google, Apple)
- [ ] JWT tokens with short expiry (15 min access, 7 day refresh)
- [ ] Refresh token rotation on use
- [ ] Biometric authentication option (FaceID, TouchID, fingerprint)
- [ ] Account lockout after 5 failed login attempts

### 4. Privacy & Compliance
- [ ] Privacy policy published and linked in app (issue 340)
- [ ] User consent flow for telemetry (opt-in/opt-out)
- [ ] Camera permission requested only on first OCR use (not at app launch)
- [ ] Camera permission rationale clearly stated ("Scan expiry dates to save time")
- [ ] Captured images processed on-device only (ML Kit); never uploaded
- [ ] Data export functionality (GDPR Article 15 - Right to access)
- [ ] Data deletion functionality (GDPR Article 17 - Right to erasure)
- [ ] No PII in telemetry events by default
- [ ] Receipt images deleted after OCR processing (30-day retention max, Pro tier only)

### 5. Code Security
- [ ] Dependency vulnerability scanning (Dependabot, Snyk)
- [ ] No secrets in source code (API keys, tokens)
- [ ] Code obfuscation for release builds (ProGuard/R8 for Android, Flutter obfuscation)
- [ ] Secure random number generation for cryptographic operations
- [ ] Input validation and sanitization (prevent injection attacks)

### 6. API Security (Pro Tier)
- [ ] Row-level security (RLS) enforced in database (Supabase)
- [ ] User can only access their own data (enforce user_id filter)
- [ ] API authentication required for all endpoints
- [ ] CORS policy configured (allow only mobile app origins)
- [ ] Webhook signature verification (HMAC) for IoT integrations

### 7. Third-Party Integrations
- [ ] OCR provider (Google Vision API): Use service accounts with least privilege
- [ ] Analytics provider: Anonymized data only; no PII
- [ ] Payment provider (IAP): Receipt verification on server-side
- [ ] Crash reporting: Scrub PII from stack traces

### 8. Incident Response
- [ ] Security contact email published (security@zerospoils.app)
- [ ] Vulnerability disclosure policy documented
- [ ] Incident response runbook created (issue 400)
- [ ] Breach notification plan (72-hour GDPR requirement)

### 9. Testing & Validation
- [ ] Penetration testing before launch (M4)
- [ ] OWASP Mobile Top 10 checklist review
- [ ] Static analysis security testing (SAST) in CI/CD
- [ ] Dynamic analysis security testing (DAST) for API endpoints
- [ ] Security audit by external firm (optional for Pro tier)

### 10. Monitoring & Alerts
- [ ] Anomaly detection for unusual API patterns
- [ ] Failed authentication attempt monitoring
- [ ] Alerts for high-privilege operations (data export, account deletion)
- [ ] Regular security log review (weekly)

## How It Will Be Used
- **M2 implementation:** Validate security posture for MVP features (140-250)
- **Pre-launch review (M4):** Complete checklist before public release
- **Pro tier (M5/M6):** Additional validation for backend services
- **Compliance audits:** Evidence for GDPR/CCPA compliance
- **Incident response:** Baseline security controls when investigating breaches
- **AI coding agents:** Security requirements reference; prevents insecure implementations

## Source Material
- OWASP Mobile Application Security Verification Standard (MASVS)
- GDPR Articles 15, 17, 32, 33, 34 (privacy rights, security measures, breach notification)
- PRD Section 8.6 (Security & Privacy)
- Issues: 245-encryption, 340-privacy-policy, 400-incident-response

## Status
🚧 **IN PROGRESS (M3/M4)** — Updated 2026-05-15 with current project state:

### Implemented
- [x] TLS 1.3 enforcement via Firebase
- [x] App Check attestation on Cloud Functions (`submitFeedbackIngest`)
- [x] Anonymous Firebase auth with secure token caching
- [x] Rate limiting (feedback: 10-min window per device fingerprint)
- [x] Input validation on Firestore rules (no plaintext PII in events)
- [x] Telemetry PII filter (disallows email, phone, device_id, ip_address in events)
- [x] Camera permission gating (only on OCR feature flag enabled)
- [x] No hardcoded API keys (environment variables via `--dart-define`)
- [x] Dependency management active (pubspec.lock)
- [x] Unit/widget tests for feedback service
- [x] Firestore rules enforce non-anonymous auth for feedback

### In Progress / Planned
- [ ] Local database encryption (Hive currently unencrypted; Pro tier blocker)
- [ ] Certificate pinning for critical endpoints (M4, before launch)
- [ ] JWT token rotation (M4, after auth refactor)
- [ ] Biometric authentication option (M5, Pro tier)
- [ ] Account lockout mechanism (M4, requires auth service enhancement)
- [ ] Data export/import (GDPR Article 15; M5)
- [ ] Data deletion workflow (GDPR Article 17; M4)
- [ ] Dependency scanning in CI (Dependabot/Snyk; M2)
- [ ] Code obfuscation (ProGuard/R8 for release Android builds; M4)
- [ ] Security contact/vulnerability disclosure (M4)
- [ ] Incident response runbook (issue 400, M4)
- [ ] Penetration testing (M4, before public launch)
- [ ] External security audit (M5, optional for Pro tier)
- [ ] Anomaly detection & monitoring (M5)

### Open Gaps
- Receipt image lifecycle/retention policy (30-day max for Pro tier, currently undefined)
- Webhook signature verification (deferred to M5 when IoT integrations planned)
- CORS/API auth for Pro-tier backend (M5+)
- Server-side receipt verification for IAP (M4, payment subsystem)
- Static/dynamic security testing in CI (M4)
