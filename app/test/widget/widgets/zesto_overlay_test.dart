import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/domain/models/zesto_model.dart';
import 'package:zerospoils/domain/repositories/zesto_service.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/widgets/zesto_overlay.dart';

class MockAssetBundle extends AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/data/storage_tips.json') {
      return '{"produce": "Store in crisper drawer", "dairy": "Keep refrigerated"}';
    }
    throw FlutterError('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) =>
      throw FlutterError('Binary assets not supported in mock');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'renders in production-style host without overlay exceptions on narrow width',
    (WidgetTester tester) async {
      final semanticsHandle = tester.ensureSemantics();

      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final zestoService = ZestoService(
        getSettings: () => const MascotSettings(
          enabled: true,
          frequency: MascotFrequency.always,
        ),
        displayDuration: const Duration(seconds: 1),
        assetBundle: MockAssetBundle(),
      );
      addTearDown(zestoService.dispose);

      final container = ProviderContainer(
        overrides: [zestoServiceProvider.overrideWithValue(zestoService)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (child case != null) child else const SizedBox.shrink(),
                  const ZestoOverlay(),
                ],
              );
            },
            home: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await container
          .read(zestoServiceProvider)
          .showMascot(MascotMessageType.firstItem, bypassAntiSpam: true);
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('zesto_overlay')), findsOneWidget);
      expect(find.byKey(const Key('zesto_message_text')), findsOneWidget);

      container.read(zestoServiceProvider).dismissMascot();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      semanticsHandle.dispose();
    },
  );
}
