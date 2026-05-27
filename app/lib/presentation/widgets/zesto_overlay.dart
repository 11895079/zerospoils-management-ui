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
  // While true, the overlay tree (including its Semantics live region)
  // stays in the widget tree so the exit slide/opacity animation can run.
  // Flipped to false by [_unmountTimer] after the animation finishes, at
  // which point [build] returns `SizedBox.shrink()` and the Semantics node
  // is fully removed from the tree (so screen readers don't keep an
  // invisible mascot in focus).
  bool _mountedForExit = false;
  Timer? _unmountTimer;

  // Animation durations — must match the values used in [build]'s
  // AnimatedSlide / AnimatedOpacity so we don't unmount the tree mid-fade.
  static const _slideDuration = Duration(milliseconds: 260);
  static const _opacityDuration = Duration(milliseconds: 220);
  static const _exitDuration = _slideDuration; // longer of the two

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
    _mountedForExit = _state.currentMessage != null;
    _syncAnimationState(_state);
    _subscription = service.stateStream.listen(_onState);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _unmountTimer?.cancel();
    _bobController.dispose();
    super.dispose();
  }

  void _onState(ZestoState nextState) {
    if (!mounted) return;
    final wasVisible = _state.isVisible;
    setState(() {
      _state = nextState;
      if (nextState.isVisible) {
        // New mascot (or replacement): keep the tree mounted and cancel
        // any in-flight unmount from a previous dismiss.
        _mountedForExit = true;
        _unmountTimer?.cancel();
        _unmountTimer = null;
      } else if (wasVisible) {
        // Just dismissed: schedule unmount once the exit animation
        // finishes so the Semantics live region disappears from the tree.
        _unmountTimer?.cancel();
        final disableAnimations =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        _unmountTimer = Timer(
          disableAnimations ? Duration.zero : _exitDuration,
          _onExitComplete,
        );
      }
    });
    _syncAnimationState(nextState);
  }

  void _onExitComplete() {
    if (!mounted) return;
    setState(() {
      _mountedForExit = false;
    });
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
    // Render nothing — and contribute no Semantics — when there's no
    // current mascot AND any exit animation has finished. This keeps a
    // dismissed mascot from lingering in the accessibility tree.
    if (_state.currentMessage == null || !_mountedForExit) {
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
            duration: disableAnimations ? Duration.zero : _slideDuration,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              key: const Key('zesto_overlay'),
              opacity: _state.isVisible ? 1 : 0,
              duration: disableAnimations ? Duration.zero : _opacityDuration,
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
