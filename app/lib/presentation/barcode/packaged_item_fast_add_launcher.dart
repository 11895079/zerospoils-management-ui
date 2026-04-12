library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/packaged_item_fast_add_screen.dart';

typedef PackagedItemFastAddLauncher =
    Future<PackagedItemFastAddResult> Function({required BuildContext context});

final packagedItemFastAddLauncherProvider =
    Provider<PackagedItemFastAddLauncher>((ref) {
      return ({required BuildContext context}) async {
        final result = await Navigator.of(context)
            .push<PackagedItemFastAddResult>(
              MaterialPageRoute(
                builder: (_) => const PackagedItemFastAddScreen(),
                fullscreenDialog: true,
              ),
            );

        return result ?? const PackagedItemFastAddResult.cancelled();
      };
    });
