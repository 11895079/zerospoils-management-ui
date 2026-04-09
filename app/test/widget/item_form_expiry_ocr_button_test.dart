import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/feature_flags/feature_flag_key.dart';
import 'package:zerospoils/core/feature_flags/feature_flags_provider.dart';
import 'package:zerospoils/core/ocr/expiry_date_ocr_service.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/user_category.dart';
import 'package:zerospoils/domain/utils/expiry_date_parser.dart';
import 'package:zerospoils/presentation/barcode/barcode_capture_launcher.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart'
    show TelemetryClient, telemetryClientProvider;
import 'package:zerospoils/presentation/ocr/expiry_ocr_capture_launcher.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';

class FakeExpiryOcrCaptureLauncher {
  FakeExpiryOcrCaptureLauncher(this.result);

  final ExpiryDateOcrScanResult result;
  int callCount = 0;
  String? lastPreferredDateFormat;

  Future<ExpiryDateOcrScanResult> call({
    required BuildContext context,
    required String preferredDateFormat,
  }) async {
    callCount++;
    lastPreferredDateFormat = preferredDateFormat;
    return result;
  }
}

class FakeBarcodeCaptureLauncher {
  FakeBarcodeCaptureLauncher(this.result);

  final BarcodeCaptureResult result;
  int callCount = 0;

  Future<BarcodeCaptureResult> call({required BuildContext context}) async {
    callCount++;
    return result;
  }
}

class FakeItemRepository extends HiveItemRepository {
  FakeItemRepository([Iterable<Item> items = const []]) {
    for (final item in items) {
      _items[item.id] = item;
    }
  }

  final Map<String, Item> _items = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<Item>> getAllItems() async => _items.values.toList();

  @override
  Future<Item?> getItem(String id) async => _items[id];

  @override
  Future<void> saveItem(Item item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.remove(id);
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('item_form_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(UserCategoryAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('expiry OCR button hides when feature flag is disabled', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) async => false),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expiry_date_scan_button')), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'expiry OCR button shows when feature flag resolves true on mobile',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isFlagEnabledProvider(
                FeatureFlagKey.expiryDateOcr,
              ).overrideWith((ref) async => true),
            ],
            child: const MaterialApp(home: ItemFormScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('expiry_date_scan_button')),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('expiry OCR button stays hidden while flag is loading', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final completer = Completer<bool>();

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('expiry_date_scan_button')), findsNothing);

      completer.complete(true);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expiry_date_scan_button')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'camera-assisted panel shows on supported mobile when OCR is enabled',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isFlagEnabledProvider(
                FeatureFlagKey.expiryDateOcr,
              ).overrideWith((ref) async => true),
            ],
            child: const MaterialApp(home: ItemFormScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('camera_assisted_add_panel')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('camera_assisted_status_barcode_ready')),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('barcode stage prefills name and locks panel after capture', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final fakeBarcodeLauncher = FakeBarcodeCaptureLauncher(
      const BarcodeCaptureResult.success(
        rawValue: '0678000012345',
        suggestedName: 'Greek Yogurt',
        suggestedCategory: ItemCategory.dairy,
        source: 'seed_catalog',
      ),
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) async => true),
            barcodeCaptureLauncherProvider.overrideWithValue(
              fakeBarcodeLauncher.call,
            ),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('camera_assisted_scan_barcode_button')),
      );
      await tester.pumpAndSettle();

      expect(fakeBarcodeLauncher.callCount, 1);
      expect(
        find.byKey(const Key('camera_assisted_status_barcode_locked')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('camera_assisted_detected_name')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('camera_assisted_detected_barcode')),
        findsOneWidget,
      );
      expect(find.text('0678000012345'), findsOneWidget);

      final nameField = tester.widget<TextFormField>(
        find.byKey(const Key('item_form_name_field')),
      );
      expect(nameField.controller?.text, 'Greek Yogurt');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('barcode capture reuses previous category and location', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final fakeBarcodeLauncher = FakeBarcodeCaptureLauncher(
      const BarcodeCaptureResult.success(
        rawValue: '0678000012345',
        suggestedName: 'Greek Yogurt',
        suggestedCategory: ItemCategory.dairy,
        source: 'seed_catalog',
      ),
    );
    final fakeRepository = FakeItemRepository([
      Item(
        id: 'existing-1',
        name: 'Greek Yogurt',
        category: ItemCategory.pantry,
        location: StorageLocation.freezer,
        quantity: 1,
        status: ItemStatus.available,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(fakeRepository),
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) async => true),
            barcodeCaptureLauncherProvider.overrideWithValue(
              fakeBarcodeLauncher.call,
            ),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('camera_assisted_scan_barcode_button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_form_save_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final items = await fakeRepository.getAllItems();
      final saved = items.firstWhere((item) => item.id != 'existing-1');
      expect(saved.category, ItemCategory.pantry);
      expect(saved.location, StorageLocation.freezer);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('barcode stage keeps form untouched when scan is cancelled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final fakeBarcodeLauncher = FakeBarcodeCaptureLauncher(
      const BarcodeCaptureResult.failure(BarcodeCaptureFailure.cancelled),
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) async => true),
            barcodeCaptureLauncherProvider.overrideWithValue(
              fakeBarcodeLauncher.call,
            ),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('camera_assisted_scan_barcode_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('camera_assisted_status_barcode_ready')),
        findsOneWidget,
      );
      final nameField = tester.widget<TextFormField>(
        find.byKey(const Key('item_form_name_field')),
      );
      expect(nameField.controller?.text, isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'camera-assisted expiry handoff locks expiry after barcode scan',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final fakeBarcodeLauncher = FakeBarcodeCaptureLauncher(
        const BarcodeCaptureResult.success(
          rawValue: '0678000012345',
          suggestedName: 'Greek Yogurt',
          suggestedCategory: ItemCategory.dairy,
          source: 'seed_catalog',
        ),
      );
      final fakeExpiryLauncher = FakeExpiryOcrCaptureLauncher(
        ExpiryDateOcrScanResult.success(
          ExpiryDateParseResult(
            date: DateTime(2026, 2, 10),
            format: 'MM/DD/YYYY',
          ),
        ),
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isFlagEnabledProvider(
                FeatureFlagKey.expiryDateOcr,
              ).overrideWith((ref) async => true),
              dateFormatPreferenceProvider.overrideWith(
                (ref) async => 'MM/DD/YYYY',
              ),
              barcodeCaptureLauncherProvider.overrideWithValue(
                fakeBarcodeLauncher.call,
              ),
              expiryOcrCaptureLauncherProvider.overrideWithValue(
                fakeExpiryLauncher.call,
              ),
            ],
            child: const MaterialApp(home: ItemFormScreen()),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('camera_assisted_scan_barcode_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('camera_assisted_scan_expiry_button')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('camera_assisted_scan_expiry_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('expiry_ocr_guidance_continue')));
        await tester.pumpAndSettle();

        expect(fakeExpiryLauncher.callCount, 1);
        expect(
          find.byKey(const Key('camera_assisted_status_expiry_locked')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('camera_assisted_detected_expiry')),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'camera-assisted save telemetry marks accepted barcode and expiry',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final telemetry = TelemetryClient(consentEnabled: true);
      final fakeBarcodeLauncher = FakeBarcodeCaptureLauncher(
        const BarcodeCaptureResult.success(
          rawValue: '0678000012345',
          suggestedName: 'Greek Yogurt',
          suggestedCategory: ItemCategory.dairy,
          source: 'seed_catalog',
        ),
      );
      final fakeExpiryLauncher = FakeExpiryOcrCaptureLauncher(
        ExpiryDateOcrScanResult.success(
          ExpiryDateParseResult(
            date: DateTime(2026, 2, 10),
            format: 'MM/DD/YYYY',
          ),
        ),
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              telemetryClientProvider.overrideWithValue(telemetry),
              isFlagEnabledProvider(
                FeatureFlagKey.expiryDateOcr,
              ).overrideWith((ref) async => true),
              dateFormatPreferenceProvider.overrideWith(
                (ref) async => 'MM/DD/YYYY',
              ),
              barcodeCaptureLauncherProvider.overrideWithValue(
                fakeBarcodeLauncher.call,
              ),
              expiryOcrCaptureLauncherProvider.overrideWithValue(
                fakeExpiryLauncher.call,
              ),
            ],
            child: const MaterialApp(home: ItemFormScreen()),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('camera_assisted_scan_barcode_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('camera_assisted_scan_expiry_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('expiry_ocr_guidance_continue')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('item_form_save_button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        final itemAddedEvent = telemetry.events.lastWhere(
          (event) => event['name'] == 'item_added',
        );
        final properties = itemAddedEvent['properties'] as Map<String, dynamic>;

        expect(properties['entry_method'], 'camera_barcode_and_expiry');
        expect(properties['source'], 'camera_barcode_and_expiry');
        expect(properties['camera_used'], true);
        expect(properties['camera_barcode_accepted'], true);
        expect(properties['camera_expiry_accepted'], true);
        expect(properties['camera_barcode_source'], 'seed_catalog');
        expect(properties['camera_expiry_format'], 'MM/DD/YYYY');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('guidance dialog opens and OCR result pre-fills expiry date', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeLauncher = FakeExpiryOcrCaptureLauncher(
      ExpiryDateOcrScanResult.success(
        ExpiryDateParseResult(
          date: DateTime(2026, 1, 15),
          format: 'MM/DD/YYYY',
        ),
      ),
    );

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) async => true),
            dateFormatPreferenceProvider.overrideWith(
              (ref) async => 'DD/MM/YYYY',
            ),
            expiryOcrCaptureLauncherProvider.overrideWithValue(
              fakeLauncher.call,
            ),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expiry_date_scan_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('expiry_ocr_guidance_dialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('expiry_ocr_guidance_continue')));
      await tester.pumpAndSettle();

      expect(fakeLauncher.callCount, 1);
      expect(fakeLauncher.lastPreferredDateFormat, 'DD/MM/YYYY');
      final expiryText = tester.widget<Text>(
        find.byKey(const Key('item_form_expiry_date_value')),
      );
      expect(expiryText.data, 'Expires: 2026-01-15');
      expect(find.byType(SnackBar), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
