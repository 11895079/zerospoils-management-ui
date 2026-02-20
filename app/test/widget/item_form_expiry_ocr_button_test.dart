import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/domain/models/user_category.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/item_form_screen.dart';

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

  testWidgets('expiry OCR button hidden for non-Pro', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ItemFormScreen())),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expiry_date_scan_button')), findsNothing);
  });

  testWidgets('expiry OCR button shows for Pro with feature flag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proEntitlementProvider.overrideWith((ref) => true),
          expiryDateOcrFeatureProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(home: ItemFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expiry_date_scan_button')), findsOneWidget);
  });
}
