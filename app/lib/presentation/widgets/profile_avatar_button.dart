library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';

class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Profile',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Widget buildFallbackButton() {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: CircleAvatar(
          radius: 13,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    late final dynamic authService;
    try {
      authService = ref.read(firebaseAuthServiceProvider);
    } catch (_) {
      return buildFallbackButton();
    }

    return StreamBuilder<User?>(
      stream: authService.authStateChangesSafe,
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? authService.currentUser;
        final photoUrl = user?.photoURL;
        final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
        final localTheme = Theme.of(context);

        final avatar = CircleAvatar(
          radius: 13,
          backgroundColor: hasPhoto
              ? localTheme.colorScheme.surfaceContainerHighest
              : localTheme.colorScheme.primaryContainer,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          child: hasPhoto
              ? null
              : Icon(
                  Icons.person,
                  size: 16,
                  color: localTheme.colorScheme.onPrimaryContainer,
                ),
        );

        return IconButton(tooltip: tooltip, onPressed: onPressed, icon: avatar);
      },
    );
  }
}
