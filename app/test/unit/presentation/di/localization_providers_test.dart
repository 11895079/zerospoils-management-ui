import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/presentation/di/localization_providers.dart';

void main() {
  group('effectiveReferencePackLanguage', () {
    test('maps French app locale to French Canada reference packs', () {
      expect(
        effectiveReferencePackLanguage(
          languageTag: referencePackAutomaticTag,
          appLocaleTag: 'fr',
        ),
        'fr-CA',
      );
    });

    test('keeps French Canada app locale on French Canada reference packs', () {
      expect(
        effectiveReferencePackLanguage(
          languageTag: referencePackAutomaticTag,
          appLocaleTag: 'fr_CA',
        ),
        'fr-CA',
      );
    });

    test('keeps Spanish locales on Spanish Latin America reference packs', () {
      expect(
        effectiveReferencePackLanguage(
          languageTag: referencePackAutomaticTag,
          appLocaleTag: 'es',
        ),
        'es-419',
      );
    });
  });
}
