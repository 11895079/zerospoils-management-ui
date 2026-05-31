import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appLocalePreferenceKey = 'app_locale';
const appLocaleSystemTag = 'system';

const supportedAppLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('fr', 'CA'),
  Locale('es'),
  Locale('de'),
  Locale('pt'),
];

class LocaleOption {
  final String tag;
  final String label;
  final Locale? locale;

  const LocaleOption({
    required this.tag,
    required this.label,
    this.locale,
  });
}

const appLocaleOptions = [
  LocaleOption(tag: appLocaleSystemTag, label: 'System default'),
  LocaleOption(tag: 'en', label: 'English', locale: Locale('en')),
  LocaleOption(tag: 'fr', label: 'French', locale: Locale('fr')),
  LocaleOption(
    tag: 'fr_CA',
    label: 'French (Canada)',
    locale: Locale('fr', 'CA'),
  ),
  LocaleOption(tag: 'es', label: 'Spanish', locale: Locale('es')),
  LocaleOption(tag: 'de', label: 'German', locale: Locale('de')),
  LocaleOption(tag: 'pt', label: 'Portuguese', locale: Locale('pt')),
];

final appLocaleTagProvider = StateProvider<String>((ref) {
  return appLocaleSystemTag;
});

Future<void> loadAppLocalePreference(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  ref.read(appLocaleTagProvider.notifier).state =
      prefs.getString(appLocalePreferenceKey) ?? appLocaleSystemTag;
}

Future<void> setAppLocalePreference(WidgetRef ref, String tag) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(appLocalePreferenceKey, tag);
  ref.read(appLocaleTagProvider.notifier).state = tag;
}

Locale? resolveAppLocale(String tag) {
  return switch (tag) {
    appLocaleSystemTag => null,
    'en' => const Locale('en'),
    'fr' => const Locale('fr'),
    'fr_CA' => const Locale('fr', 'CA'),
    'es' => const Locale('es'),
    'de' => const Locale('de'),
    'pt' => const Locale('pt'),
    _ => null,
  };
}

String appLocaleLabelForTag(String tag) {
  return appLocaleOptions.firstWhere(
    (option) => option.tag == tag,
    orElse: () => appLocaleOptions.first,
  ).label;
}
