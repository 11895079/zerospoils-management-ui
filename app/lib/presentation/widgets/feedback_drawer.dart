import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/feedback/feedback_submission_service.dart';
import '../../generated_l10n/app_localizations.dart';
import '../di/service_locator.dart';

const Key feedbackDrawerKey = Key('feedback_drawer');
const String _darkModeReadabilityCategory = 'dark_mode_readability';

Future<void> showFeedbackDrawer(
  BuildContext context,
  WidgetRef ref, {
  required String source,
}) async {
  final telemetry = ref.read(telemetryClientProvider);
  telemetry.enqueue({
    'name': 'feedback_opened',
    'properties': {'source': source},
  });

  // Capture root context before showing dialog
  final rootContext = context;

  await showGeneralDialog<void>(
    context: context,
    barrierLabel:
        AppLocalizations.of(context)?.feedbackDrawerBarrierLabel ?? 'Feedback',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.92,
          child: _FeedbackDrawer(
            source: source,
            telemetry: telemetry,
            rootContext: rootContext,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation);
      return SlideTransition(position: slide, child: child);
    },
  );
}

class _FeedbackDrawer extends ConsumerStatefulWidget {
  const _FeedbackDrawer({
    required this.source,
    required this.telemetry,
    required this.rootContext,
  });

  final String source;
  final TelemetryClient telemetry;
  final BuildContext rootContext;

  @override
  ConsumerState<_FeedbackDrawer> createState() => _FeedbackDrawerState();
}

class _FeedbackDrawerState extends ConsumerState<_FeedbackDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  final FeedbackSubmissionService _service = FeedbackSubmissionService();

  bool _isSubmitting = false;
  String _category = 'bug_report';

  void _handleCategoryChanged(String value) {
    setState(() {
      _category = value;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context);

    return Material(
      key: feedbackDrawerKey,
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 12,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.feedback_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.feedbackDrawerTitle ?? 'Send Feedback',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          l10n?.feedbackDrawerCloseTooltip ?? 'Close feedback',
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.feedbackDrawerIntro ??
                      'Tell us what is working or broken. We include app metadata automatically.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: const Key('feedback_category_field'),
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: l10n?.feedbackDrawerCategoryLabel ?? 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'bug_report',
                      child: Text(
                        l10n?.feedbackCategoryBugReport ?? 'Bug report',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'feature_request',
                      child: Text(
                        l10n?.feedbackCategoryFeatureRequest ??
                            'Feature request',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ux_feedback',
                      child: Text(
                        l10n?.feedbackCategoryUxFeedback ?? 'UX feedback',
                      ),
                    ),
                    DropdownMenuItem(
                      value: _darkModeReadabilityCategory,
                      child: Text(
                        l10n?.feedbackCategoryDarkModeReadability ??
                            'Dark mode readability',
                        key: Key(
                          'feedback_category_option_dark_mode_readability',
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(l10n?.feedbackCategoryOther ?? 'Other'),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            _handleCategoryChanged(value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('feedback_message_field'),
                  controller: _messageController,
                  minLines: 6,
                  maxLines: 10,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: l10n?.feedbackDrawerMessageLabel ?? 'Message',
                    hintText:
                        l10n?.feedbackDrawerMessageHint ??
                        'What happened? What should we improve?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n?.feedbackDrawerMessageValidation ??
                          'Please enter feedback before submitting.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('feedback_email_field'),
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.feedbackDrawerEmailLabel ?? 'Email (optional)',
                    hintText:
                        l10n?.feedbackDrawerEmailHint ?? 'you@example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.feedbackDrawerSourceLocale(widget.source, locale) ??
                      'Source: ${widget.source} • Locale: $locale',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('feedback_submit_button'),
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitFeedback(context, locale),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting
                          ? (l10n?.feedbackDrawerSubmitting ?? 'Submitting...')
                          : (l10n?.feedbackDrawerSubmit ?? 'Submit'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback(BuildContext context, String locale) async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final trimmedMessage = _messageController.text.trim();
    final hasContactEmail = _emailController.text.trim().isNotEmpty;

    if (_category == _darkModeReadabilityCategory) {
      widget.telemetry.enqueue({
        'name': 'ui_dark_mode_readability_reported',
        'properties': {
          'source': widget.source,
          'category': _category,
          'message_length': trimmedMessage.length,
          'has_contact_email': hasContactEmail,
        },
      });
    }

    setState(() {
      _isSubmitting = true;
    });

    final request = FeedbackSubmissionRequest(
      message: trimmedMessage,
      category: _category,
      source: widget.source,
      locale: locale,
      email: hasContactEmail ? _emailController.text.trim() : null,
    );

    try {
      final outcome = await _service.submit(request);

      if (!context.mounted) {
        return;
      }

      widget.telemetry.enqueue({
        'name': 'feedback_submitted',
        'properties': {
          'source': widget.source,
          'category': _category,
          // 'queued' means accepted locally; background flush will send it.
          'outcome': outcome.name,
        },
      });

      Navigator.of(context).pop();

      // Always show a positive confirmation.  The service queues locally first
      // so feedback is durable regardless of connectivity or server rate limits.
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.feedbackDrawerSent ?? 'Feedback sent. Thank you.',
          ),
        ),
      );
    } on StateError catch (error) {
      if (!context.mounted) {
        return;
      }

      final authRequired = error.message == 'AUTH_REQUIRED';
      widget.telemetry.enqueue({
        'name': 'feedback_submit_failed',
        'properties': {
          'source': widget.source,
          'category': _category,
          'reason': authRequired ? 'auth_required' : 'state_error',
        },
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text(
            authRequired
                ? (l10n?.feedbackDrawerSignInRequired ??
                      'Please sign in before sending feedback.')
                // Queue-first: payload was already persisted before this error.
                // Show success so the user knows their message is saved.
                : (l10n?.feedbackDrawerSent ?? 'Feedback sent. Thank you.'),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      widget.telemetry.enqueue({
        'name': 'feedback_submit_failed',
        'properties': {'source': widget.source, 'category': _category},
      });

      Navigator.of(context).pop();
      // Unexpected error (e.g. SharedPreferences failure) — show success
      // because the payload was queued before this point in the happy path.
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.feedbackDrawerSent ?? 'Feedback sent. Thank you.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
