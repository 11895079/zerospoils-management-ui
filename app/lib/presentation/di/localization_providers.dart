import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appLocalePreferenceKey = 'app_locale';
const appLocaleSystemTag = 'system';
const referencePackRegionPreferenceKey = 'reference_pack_region';
const referencePackLanguagePreferenceKey = 'reference_pack_language';
const referencePackAutomaticTag = 'automatic';

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

  const LocaleOption({required this.tag, required this.label, this.locale});
}

class ReferencePackOption {
  final String tag;
  final String label;

  const ReferencePackOption({required this.tag, required this.label});
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

const referencePackRegionOptions = [
  ReferencePackOption(tag: referencePackAutomaticTag, label: 'Automatic'),
  ReferencePackOption(tag: 'ca', label: 'Canada'),
  ReferencePackOption(tag: 'us', label: 'United States'),
];

const referencePackLanguageOptions = [
  ReferencePackOption(tag: referencePackAutomaticTag, label: 'Automatic'),
  ReferencePackOption(tag: 'en', label: 'English'),
  ReferencePackOption(tag: 'fr-CA', label: 'French (Canada)'),
  ReferencePackOption(tag: 'es-419', label: 'Spanish (Latin America)'),
];

final appLocaleTagProvider = StateProvider<String>((ref) {
  return appLocaleSystemTag;
});

final referencePackRegionTagProvider = StateProvider<String>((ref) {
  return referencePackAutomaticTag;
});

final referencePackLanguageTagProvider = StateProvider<String>((ref) {
  return referencePackAutomaticTag;
});

Future<void> loadAppLocalePreference(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  ref.read(appLocaleTagProvider.notifier).state =
      prefs.getString(appLocalePreferenceKey) ?? appLocaleSystemTag;
}

Future<void> loadReferencePackPreferences(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  ref.read(referencePackRegionTagProvider.notifier).state =
      prefs.getString(referencePackRegionPreferenceKey) ??
      referencePackAutomaticTag;
  ref.read(referencePackLanguageTagProvider.notifier).state =
      prefs.getString(referencePackLanguagePreferenceKey) ??
      referencePackAutomaticTag;
}

Future<void> setAppLocalePreference(WidgetRef ref, String tag) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(appLocalePreferenceKey, tag);
  ref.read(appLocaleTagProvider.notifier).state = tag;
}

Future<void> setReferencePackRegionPreference(WidgetRef ref, String tag) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(referencePackRegionPreferenceKey, tag);
  ref.read(referencePackRegionTagProvider.notifier).state = tag;
}

Future<void> setReferencePackLanguagePreference(
  WidgetRef ref,
  String tag,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(referencePackLanguagePreferenceKey, tag);
  ref.read(referencePackLanguageTagProvider.notifier).state = tag;
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
  return appLocaleOptions
      .firstWhere(
        (option) => option.tag == tag,
        orElse: () => appLocaleOptions.first,
      )
      .label;
}

String referencePackRegionLabelForTag(String tag) {
  return referencePackRegionOptions
      .firstWhere(
        (option) => option.tag == tag,
        orElse: () => referencePackRegionOptions.first,
      )
      .label;
}

String referencePackLanguageLabelForTag(String tag) {
  return referencePackLanguageOptions
      .firstWhere(
        (option) => option.tag == tag,
        orElse: () => referencePackLanguageOptions.first,
      )
      .label;
}

String effectiveReferencePackRegion({
  required String regionTag,
  String? activeBarcodeRegion,
  Locale? systemLocale,
}) {
  if (regionTag == 'ca' || regionTag == 'us') {
    return regionTag;
  }

  final locale =
      systemLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
  final countryCode = locale.countryCode?.toUpperCase();
  if (countryCode == 'US') {
    return 'us';
  }
  if (countryCode == 'CA') {
    return 'ca';
  }
  if (activeBarcodeRegion == 'ca' || activeBarcodeRegion == 'us') {
    return activeBarcodeRegion!;
  }
  if (locale.languageCode.toLowerCase() == 'fr') {
    return 'ca';
  }
  return 'ca';
}

String effectiveReferencePackLanguage({
  required String languageTag,
  required String appLocaleTag,
  Locale? systemLocale,
}) {
  final resolvedTag = languageTag == referencePackAutomaticTag
      ? _effectiveAppLocaleTag(appLocaleTag, systemLocale: systemLocale)
      : languageTag;

  switch (resolvedTag.replaceAll('_', '-')) {
    case 'fr-CA':
      return 'fr-CA';
    case 'es':
    case 'es-419':
      return 'es-419';
    default:
      return 'en';
  }
}

String _effectiveAppLocaleTag(String tag, {Locale? systemLocale}) {
  if (tag != appLocaleSystemTag) {
    return tag;
  }

  final locale =
      systemLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
  final countryCode = locale.countryCode?.toUpperCase();
  if (locale.languageCode.toLowerCase() == 'fr' && countryCode == 'CA') {
    return 'fr_CA';
  }
  return locale.languageCode;
}
