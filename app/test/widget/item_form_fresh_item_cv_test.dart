import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerospoils/core/feature_flags/feature_flag_key.dart';
import 'package:zerospoils/core/feature_flags/feature_flags_provider.dart';
import 'package:zerospoils/core/vision/fresh_item_cv_service.dart';
import 'package:zerospoils/data/repositories/user_category_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/domain/models/user_category.dart';
import 'package:zerospoils/presentation/fresh_item/fresh_item_capture_launcher.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';

class FakeFreshItemCaptureLauncher {
  FakeFreshItemCaptureLauncher(this.result);

  final FreshItemCaptureResult result;
  int callCount = 0;

  Future<FreshItemCaptureResult> call({required BuildContext context}) async {
    callCount++;
    return result;
  }
}

class FakeUserCategoryRepository extends UserCategoryRepository {
  @override
  Future<List<UserCategory>> getAll() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('camera-assisted panel shows for fresh item CV alone', (
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
            isFlagEnabledProvider(
              FeatureFlagKey.freshItemCv,
            ).overrideWith((ref) async => true),
            userCategoryRepositoryProvider.overrideWithValue(
              FakeUserCategoryRepository(),
            ),
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
        find.byKey(const Key('camera_assisted_scan_fresh_item_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('camera_assisted_scan_expiry_button')),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('fresh item CV suggestion prefills the form after selection', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final launcher = FakeFreshItemCaptureLauncher(
      FreshItemCaptureResult.success(
        primarySuggestion: const FreshItemCvSuggestion(
          name: 'Banana',
          category: ItemCategory.produce,
          location: StorageLocation.fridge,
          itemType: ItemType.raw,
          confidence: 0.94,
          source: 'test',
        ),
        suggestions: const [
          FreshItemCvSuggestion(
            name: 'Banana',
            category: ItemCategory.produce,
            location: StorageLocation.fridge,
            itemType: ItemType.raw,
            confidence: 0.94,
            source: 'test',
          ),
          FreshItemCvSuggestion(
            name: 'Fresh produce',
            category: ItemCategory.produce,
            location: StorageLocation.fridge,
            itemType: ItemType.raw,
            confidence: 0.61,
            source: 'test',
          ),
        ],
        labels: const [FreshItemCvLabel(label: 'banana', confidence: 0.94)],
      ),
    );

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFlagEnabledProvider(
              FeatureFlagKey.expiryDateOcr,
            ).overrideWith((ref) async => false),
            isFlagEnabledProvider(
              FeatureFlagKey.freshItemCv,
            ).overrideWith((ref) async => true),
            userCategoryRepositoryProvider.overrideWithValue(
              FakeUserCategoryRepository(),
            ),
            freshItemCaptureLauncherProvider.overrideWithValue(launcher.call),
          ],
          child: const MaterialApp(home: ItemFormScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('camera_assisted_scan_fresh_item_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('fresh_item_cv_suggestion_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(launcher.callCount, 1);
      expect(
        find.byKey(const Key('camera_assisted_detected_fresh_item')),
        findsOneWidget,
      );

      final nameField = tester.widget<TextFormField>(
        find.byKey(const Key('item_form_name_field')),
      );
      expect(nameField.controller?.text, 'Banana');
      expect(
        find.byKey(const Key('camera_assisted_status_fresh_item_detected')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
