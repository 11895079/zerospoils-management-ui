library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/zesto_model.dart';
import '../di/repository_providers.dart';

/// Lightweight visible mascot overlay for Phase 1 triggers.
class ZestoOverlay extends ConsumerStatefulWidget {
  const ZestoOverlay({super.key});

  @override
  ConsumerState<ZestoOverlay> createState() => _ZestoOverlayState();
}

class _ZestoOverlayState extends ConsumerState<ZestoOverlay>
    with SingleTickerProviderStateMixin {
  StreamSubscription<ZestoState>? _subscription;
  ZestoState _state = const ZestoState();
  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  static const _bubbleGradient = LinearGradient(
    colors: [Color(0xFFFFFAEC), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bobAnimation = Tween<double>(
      begin: 0,
      end: -4,
    ).animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));

    final service = ref.read(zestoServiceProvider);
    _state = service.currentState;
    _syncAnimationState(_state);
    _subscription = service.stateStream.listen((nextState) {
      if (!mounted) return;
      setState(() {
        _state = nextState;
      });
      _syncAnimationState(nextState);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bobController.dispose();
    super.dispose();
  }

  void _syncAnimationState(ZestoState state) {
    if (state.isVisible) {
      if (!_bobController.isAnimating) {
        _bobController.repeat(reverse: true);
      }
    } else {
      _bobController.stop();
      _bobController.value = 0;
    }
  }

  String _avatarForType(MascotMessageType? type) {
    switch (type) {
      case MascotMessageType.wasted:
        return '🥑💡';
      case MascotMessageType.badgeUnlocked:
      case MascotMessageType.streakMilestone:
      case MascotMessageType.savingsMilestone:
      case MascotMessageType.zeroWaste:
        return '🥑🎉';
      case MascotMessageType.itemAdded:
        return '🥑📦';
      case MascotMessageType.quickSave:
      case MascotMessageType.expiryAlert:
        return '🥑⏰';
      case MascotMessageType.dailyWelcome:
        return '🥑👋';
      case MascotMessageType.firstItem:
        return '🥑✨';
      case MascotMessageType.consumed:
      case MascotMessageType.celebration:
      case null:
        return '🥑';
    }
  }

  Color _accentForType(MascotMessageType? type) {
    switch (type) {
      case MascotMessageType.wasted:
        return const Color(0xFF3B82F6);
      case MascotMessageType.badgeUnlocked:
      case MascotMessageType.streakMilestone:
      case MascotMessageType.savingsMilestone:
      case MascotMessageType.zeroWaste:
      case MascotMessageType.consumed:
      case MascotMessageType.itemAdded:
      case MascotMessageType.quickSave:
      case MascotMessageType.firstItem:
      case MascotMessageType.dailyWelcome:
      case MascotMessageType.expiryAlert:
      case MascotMessageType.celebration:
      case null:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state.currentMessage == null) {
      return const SizedBox.shrink();
    }

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final accent = _accentForType(_state.currentMessageType);
    final avatar = _avatarForType(_state.currentMessageType);

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(
          right: AppSpacing.md,
          left: AppSpacing.md,
          bottom: 96,
        ),
        child: IgnorePointer(
          ignoring: !_state.isVisible,
          child: AnimatedSlide(
            offset: _state.isVisible ? Offset.zero : const Offset(0.2, 0.25),
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              key: const Key('zesto_overlay'),
              opacity: _state.isVisible ? 1 : 0,
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Material(
                elevation: 8,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                // Announce the mascot message to screen readers when it
                // appears. `liveRegion: true` triggers re-announcement on
                // each new message; the explicit label preserves message
                // text for assistive tech (which may not pick up the
                // gradient-rendered Text widget consistently otherwise).
                child: Semantics(
                  container: true,
                  liveRegion: _state.isVisible,
                  label: 'Zesto says: ${_state.currentMessage!}',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      gradient: _bubbleGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: _bobAnimation,
                          builder: (context, child) {
                            final dy = disableAnimations
                                ? 0.0
                                : _bobAnimation.value;
                            return Transform.translate(
                              offset: Offset(0, dy),
                              child: child,
                            );
                          },
                          // Decorative emoji; the Semantics wrapper above
                          // already announces the full message.
                          child: ExcludeSemantics(
                            child: Text(
                              avatar,
                              key: const Key('zesto_avatar'),
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header uses textPrimary (#333) instead of
                              // the accent green so contrast against the
                              // cream bubble (#FFFAEC) meets WCAG AA. The
                              // accent still carries color identity via
                              // the border + dismiss-icon background.
                              Text(
                                'Zesto',
                                key: const Key('zesto_name'),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _state.currentMessage!,
                                key: const Key('zesto_message_text'),
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          // Default IconButton sizing (48×48) gives a
                          // ≥44pt tap target per DoD/WCAG; the icon glyph
                          // stays compact at 18px.
                          child: IconButton(
                            key: const Key('zesto_dismiss_button'),
                            iconSize: 18,
                            tooltip: 'Dismiss Zesto',
                            onPressed: () {
                              ref.read(zestoServiceProvider).dismissMascot();
                            },
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
