/// Feature flag definitions with metadata
///
/// Flags control rollout of upcoming Pro/IoT/backend features.
/// Values are resolved in order: local_override > remote_override (optional) > default
abstract class FeatureFlagKey {
  final String key;
  final String description;
  final bool defaultValue;
  final String targetMilestone;
  final String? costNotes;

  const FeatureFlagKey({
    required this.key,
    required this.description,
    required this.defaultValue,
    required this.targetMilestone,
    this.costNotes,
  });

  @override
  String toString() => key;

  /// Cloud sync: household inventory shared across devices
  static const FeatureFlagKey cloudSync = _CloudSync();

  /// Cloud analytics export: send event data to backend
  static const FeatureFlagKey cloudAnalyticsExport = _CloudAnalyticsExport();

  /// Shopping batch capture: store trip metadata and optional receipt photo.
  static const FeatureFlagKey receiptBatchCapture = _ReceiptBatchCapture();

  /// Receipt OCR: extract items from receipt photos
  static const FeatureFlagKey receiptOcr = _ReceiptOcr();

  /// Batch photo capture: scan multiple receipts in one session
  static const FeatureFlagKey batchPhotoCapture = _BatchPhotoCapture();

  /// Fresh item CV: identify loose produce, meat, and prepared foods
  static const FeatureFlagKey freshItemCv = _FreshItemCv();

  /// Household sync: collaborate with household members
  static const FeatureFlagKey householdSync = _HouseholdSync();

  /// IoT hooks: integration with smart kitchen devices
  static const FeatureFlagKey iotHooks = _IotHooks();

  /// Expiry date OCR: extract expiry dates from receipt text
  static const FeatureFlagKey expiryDateOcr = _ExpiryDateOcr();

  /// Return all known flags for enumeration
  static List<FeatureFlagKey> get all => [
    cloudSync,
    cloudAnalyticsExport,
    receiptBatchCapture,
    receiptOcr,
    batchPhotoCapture,
    freshItemCv,
    householdSync,
    iotHooks,
    expiryDateOcr,
  ];
}

class _CloudSync extends FeatureFlagKey {
  const _CloudSync()
    : super(
        key: 'cloud_sync',
        description: 'Household inventory shared across devices',
        defaultValue: false,
        targetMilestone: 'M6',
        costNotes: 'Cloud storage read/write (Supabase)',
      );
}

class _CloudAnalyticsExport extends FeatureFlagKey {
  const _CloudAnalyticsExport()
    : super(
        key: 'cloud_analytics_export',
        description: 'Send event data to backend',
        defaultValue: false,
        targetMilestone: 'M4+',
        costNotes: 'Network bandwidth for telemetry',
      );
}

class _ReceiptBatchCapture extends FeatureFlagKey {
  const _ReceiptBatchCapture()
    : super(
        key: 'receipt_batch_capture',
        description:
            'Save shopping batches with metadata and optional receipt photos',
        defaultValue: true,
        targetMilestone: 'M3',
        costNotes: 'Local-only storage; no network cost for MVP',
      );
}

class _ReceiptOcr extends FeatureFlagKey {
  const _ReceiptOcr()
    : super(
        key: 'receipt_ocr',
        description: 'Extract items from receipt photos',
        defaultValue: false,
        targetMilestone: 'M5+',
        costNotes: 'ML API calls (Google Vision API)',
      );
}

class _BatchPhotoCapture extends FeatureFlagKey {
  const _BatchPhotoCapture()
    : super(
        key: 'batch_photo_capture',
        description: 'Scan multiple receipts in one session',
        defaultValue: false,
        targetMilestone: 'M5+',
        costNotes: 'Depends on receipt_ocr; scales with volume',
      );
}

class _FreshItemCv extends FeatureFlagKey {
  const _FreshItemCv()
    : super(
        key: 'fresh_item_cv',
        description:
            'Identify loose produce, meat, and prepared foods with on-device CV',
        defaultValue: true,
        targetMilestone: 'M4',
        costNotes: 'On-device ML Kit image labeling; no network cost',
      );
}

class _HouseholdSync extends FeatureFlagKey {
  const _HouseholdSync()
    : super(
        key: 'household_sync',
        description: 'Collaborate with household members',
        defaultValue: false,
        targetMilestone: 'M6',
        costNotes: 'Cloud database + sync logic',
      );
}

class _IotHooks extends FeatureFlagKey {
  const _IotHooks()
    : super(
        key: 'iot_hooks',
        description: 'Integration with smart kitchen devices',
        defaultValue: false,
        targetMilestone: 'M7+',
        costNotes: 'Device APIs and cloud messaging',
      );
}

class _ExpiryDateOcr extends FeatureFlagKey {
  const _ExpiryDateOcr()
    : super(
        key: 'expiry_date_ocr',
        description:
            'Extract expiry dates from product labels using on-device OCR',
        defaultValue: true,
        targetMilestone: 'M2',
        costNotes: 'On-device ML Kit OCR; no network cost',
      );
}
