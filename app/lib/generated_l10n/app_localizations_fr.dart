// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ZeroSpoils';

  @override
  String get appDescription => 'Réduire le gaspillage alimentaire à la maison';

  @override
  String get navigationInventory => 'Inventaire';

  @override
  String get navigationShoppingList => 'Magasinage';

  @override
  String get navigationShoppingHistory => 'Historique';

  @override
  String get navigationSettings => 'Paramètres';

  @override
  String get navigationOnboarding => 'Démarrage';

  @override
  String get screenTitleInventory => 'Inventaire';

  @override
  String get screenTitleShoppingList => 'Liste d\'épicerie';

  @override
  String get screenTitleShoppingHistory => 'Historique d\'achat';

  @override
  String get screenTitleSettings => 'Paramètres';

  @override
  String get screenTitleItemDetail => 'Détails de l\'article';

  @override
  String get screenTitleAddItem => 'Ajouter un article';

  @override
  String get screenTitleEditItem => 'Modifier l\'article';

  @override
  String get screenTitleReceiptBatch => 'Lot d\'achat';

  @override
  String get screenTitleProgress => 'Progrès';

  @override
  String get screenTitleOnboarding => 'Bienvenue à ZeroSpoils';

  @override
  String get buttonAdd => 'Ajouter';

  @override
  String get buttonEdit => 'Modifier';

  @override
  String get buttonDelete => 'Supprimer';

  @override
  String get buttonSave => 'Enregistrer';

  @override
  String get buttonCancel => 'Annuler';

  @override
  String get buttonClose => 'Fermer';

  @override
  String get buttonConfirm => 'Confirmer';

  @override
  String get buttonNext => 'Suivant';

  @override
  String get buttonBack => 'Retour';

  @override
  String get buttonYes => 'Oui';

  @override
  String get buttonNo => 'Non';

  @override
  String get buttonMaybeLater => 'Plus tard';

  @override
  String get buttonEnable => 'Activer';

  @override
  String get buttonDone => 'Terminé';

  @override
  String get buttonContinue => 'Continuer';

  @override
  String get buttonRetry => 'Réessayer';

  @override
  String get buttonSearch => 'Rechercher';

  @override
  String get buttonFilter => 'Filtrer';

  @override
  String get buttonSort => 'Trier';

  @override
  String get buttonClear => 'Effacer';

  @override
  String get buttonExport => 'Exporter';

  @override
  String get buttonImport => 'Importer';

  @override
  String get labelCategory => 'Catégorie';

  @override
  String get labelLocation => 'Lieu';

  @override
  String get labelExpiry => 'Date d\'expiration';

  @override
  String get labelQuantity => 'Quantité';

  @override
  String get labelStatus => 'Statut';

  @override
  String get labelPrice => 'Prix';

  @override
  String get labelStore => 'Magasin';

  @override
  String get labelDate => 'Date';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelPaymentMethod => 'Méthode de paiement';

  @override
  String get labelBarcode => 'Code-barres';

  @override
  String get labelSearch => 'Rechercher';

  @override
  String get labelFilter => 'Filtrer';

  @override
  String get labelAll => 'Tous';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get statusConsumed => 'Consommé';

  @override
  String get statusWasted => 'Gaspillé';

  @override
  String get statusPrepared => 'Préparé';

  @override
  String get statusFresh => 'Frais';

  @override
  String get statusPackaged => 'Emballé';

  @override
  String get categoryProduce => 'Produits frais';

  @override
  String get categoryDairy => 'Produits laitiers';

  @override
  String get categoryMeat => 'Viande';

  @override
  String get categoryGrains => 'Céréales';

  @override
  String get categoryFrozen => 'Surgelés';

  @override
  String get categoryPantry => 'Garde-manger';

  @override
  String get categoryBeverages => 'Boissons';

  @override
  String get categoryOther => 'Autre';

  @override
  String get itemTypeRaw => 'Brut';

  @override
  String get itemTypePrepared => 'Cuit';

  @override
  String get itemTypePackaged => 'Emballé';

  @override
  String get locationFridge => 'Réfrigérateur';

  @override
  String get locationFreezer => 'Congélateur';

  @override
  String get locationPantry => 'Garde-manger';

  @override
  String get locationCounter => 'Comptoir';

  @override
  String get locationOther => 'Autre';

  @override
  String get paymentMethodCash => 'Comptant';

  @override
  String get paymentMethodDebit => 'Débit';

  @override
  String get paymentMethodCredit => 'Crédit';

  @override
  String get paymentMethodMobile => 'Paiement mobile';

  @override
  String get errorUnableToLoadItems => 'Impossible de charger les articles';

  @override
  String get errorNoItemsFound => 'Aucun article trouvé';

  @override
  String get errorUnexpectedError => 'Une erreur inattendue s\'est produite';

  @override
  String get errorPermissionDenied => 'Accès refusé';

  @override
  String get errorCameraPermissionRequired =>
      'La permission de la caméra est requise';

  @override
  String get errorStoragePermissionRequired =>
      'La permission de stockage est requise';

  @override
  String get errorInvalidInput => 'Entrée invalide';

  @override
  String get errorItemNotFound => 'Article non trouvé';

  @override
  String get errorDuplicateItem => 'L\'article existe déjà';

  @override
  String get messageEmptyInventory =>
      'Aucun article dans votre inventaire pour l\'instant. Ajoutez-en un pour commencer.';

  @override
  String get messageEmptyShoppingList =>
      'Votre liste d\'épicerie est vide. Ajoutez les articles dont vous avez besoin.';

  @override
  String get messageNoResults => 'Aucun résultat trouvé';

  @override
  String get messageConfirmDelete =>
      'Êtes-vous sûr de vouloir supprimer cet article?';

  @override
  String get messageConfirmDeleteAll =>
      'Êtes-vous sûr de vouloir supprimer tous les articles?';

  @override
  String get messageSaveSuccess => 'Enregistré avec succès';

  @override
  String get messageDeleteSuccess => 'Supprimé avec succès';

  @override
  String get messageDuplicatePreventedMessage =>
      'Cet article est déjà dans votre inventaire';

  @override
  String get dialogTitleCameraPermission => 'Activer la caméra';

  @override
  String get dialogMessageCameraPermission =>
      'ZeroSpoils a besoin d\'accès à la caméra pour scanner des codes-barres et capturer des reçus.';

  @override
  String get dialogTitleConfirmAction => 'Confirmer l\'action';

  @override
  String get dialogTitleDeleteConfirmation => 'Supprimer l\'article';

  @override
  String get toastItemAdded => 'Article ajouté';

  @override
  String get toastItemUpdated => 'Article mis à jour';

  @override
  String get toastItemDeleted => 'Article supprimé';

  @override
  String get toastCopiedToClipboard => 'Copié au presse-papiers';

  @override
  String get toastErrorOccurred => 'Une erreur s\'est produite';

  @override
  String get hintSearchItems => 'Rechercher des articles...';

  @override
  String get hintItemName => 'Nom de l\'article';

  @override
  String get hintNotes => 'Ajouter des notes...';

  @override
  String get settingsReminders => 'Rappels';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsFeedback => 'Rétroaction et sons';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsPrivacy => 'Confidentialité et données';

  @override
  String get settingsDarkMode => 'Mode sombre';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsReferenceDataRegion => 'Région des données de référence';

  @override
  String get settingsReferenceDataLanguage => 'Langue des données de référence';

  @override
  String get settingsDateFormat => 'Format de date';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsExportData => 'Exporter les données';

  @override
  String get settingsImportData => 'Importer les données';

  @override
  String get settingsDeleteAllData => 'Supprimer toutes les données';

  @override
  String get settingsSectionAccountData => 'COMPTE ET DONNÉES';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsDataSync => 'Synchronisation des données';

  @override
  String get settingsDemoMode => 'Mode démo';

  @override
  String get settingsSoon => 'Bientôt';

  @override
  String get settingsDemoModeEnabled => 'Mode démo activé';

  @override
  String get settingsDemoModeDisabled => 'Mode démo désactivé';

  @override
  String get settingsShareAnonymousUsageData =>
      'Partager les données d\'utilisation anonymes';

  @override
  String get settingsShareAnonymousUsageDataSubtitle =>
      'Autorise l\'export infonuagique lorsqu\'il sera disponible (pas encore disponible)';

  @override
  String get settingsCloudAnalyticsExport => 'Export infonuagique des analyses';

  @override
  String get settingsCloudAnalyticsExportSubtitle =>
      'Envoyer les données télémétriques vers le nuage';

  @override
  String get settingsExportSubtitle =>
      'Télécharger votre inventaire et vos paramètres';

  @override
  String get settingsImportSubtitle => 'Importer un fichier de sauvegarde';

  @override
  String get settingsReferenceDataPacks => 'Packs de données de référence';

  @override
  String get settingsDeleteAllDataSubtitle =>
      'Supprimer définitivement toutes les données (irréversible)';

  @override
  String get settingsSectionPreferences => 'PRÉFÉRENCES';

  @override
  String get settingsMealPlanning => 'Planification des repas';

  @override
  String get settingsSectionSupportFeedback => 'AIDE ET RÉTROACTION';

  @override
  String get settingsHelpFaq => 'Aide et FAQ';

  @override
  String get settingsHelpCenterComingSoon =>
      'Centre d\'aide bientôt disponible';

  @override
  String get settingsSendFeedback => 'Envoyer des commentaires';

  @override
  String get feedbackDrawerBarrierLabel => 'Rétroaction';

  @override
  String get feedbackDrawerTitle => 'Envoyer des commentaires';

  @override
  String get feedbackDrawerCloseTooltip => 'Fermer le panneau de rétroaction';

  @override
  String get feedbackDrawerIntro =>
      'Dites-nous ce qui fonctionne ou ce qui pose problème. Les métadonnées de l\'application sont ajoutées automatiquement.';

  @override
  String get feedbackDrawerCategoryLabel => 'Catégorie';

  @override
  String get feedbackCategoryBugReport => 'Rapport de bogue';

  @override
  String get feedbackCategoryFeatureRequest => 'Demande de fonctionnalité';

  @override
  String get feedbackCategoryUxFeedback => 'Rétroaction UX';

  @override
  String get feedbackCategoryDarkModeReadability => 'Lisibilité du mode sombre';

  @override
  String get feedbackCategoryOther => 'Autre';

  @override
  String get feedbackDrawerMessageLabel => 'Message';

  @override
  String get feedbackDrawerMessageHint =>
      'Que s\'est-il passé? Que devrions-nous améliorer?';

  @override
  String get feedbackDrawerMessageValidation =>
      'Veuillez saisir un commentaire avant l\'envoi.';

  @override
  String get feedbackDrawerEmailLabel => 'Courriel (facultatif)';

  @override
  String get feedbackDrawerEmailHint => 'vous@exemple.com';

  @override
  String feedbackDrawerSourceLocale(String source, String locale) {
    return 'Source : $source • Langue : $locale';
  }

  @override
  String get feedbackDrawerSubmitting => 'Envoi en cours...';

  @override
  String get feedbackDrawerSubmit => 'Envoyer';

  @override
  String get feedbackDrawerSent => 'Commentaire envoyé. Merci.';

  @override
  String get feedbackDrawerSignInRequired =>
      'Veuillez vous connecter avant d\'envoyer un commentaire.';

  @override
  String get settingsRateApp => 'Évaluer l\'application';

  @override
  String get settingsThanksForSupport => 'Merci pour votre soutien!';

  @override
  String get settingsViewTutorial => 'Voir le tutoriel';

  @override
  String get settingsSectionLegal => 'JURIDIQUE';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsPrivacyPolicyComingSoon =>
      'Politique de confidentialité bientôt disponible';

  @override
  String get settingsTermsOfService => 'Conditions d\'utilisation';

  @override
  String get settingsTermsComingSoon => 'Conditions bientôt disponibles';

  @override
  String get settingsAboutSubtitle => 'ZeroSpoils v1.0.0';

  @override
  String get settingsAboutSnackMessage =>
      'ZeroSpoils aide à réduire le gaspillage alimentaire.';

  @override
  String get settingsHapticIntensityLight => 'Léger';

  @override
  String get settingsHapticIntensityMedium => 'Moyen';

  @override
  String get settingsHapticIntensityHeavy => 'Lourd';

  @override
  String settingsLeadTimeDays(int days) {
    return '$days jours';
  }

  @override
  String get settingsChooseExportFormat => 'Choose export format:';

  @override
  String get settingsExportJsonCompleteBackup => 'JSON (Complete Backup)';

  @override
  String get settingsExportCsvInventoryOnly => 'CSV (Inventory Only)';

  @override
  String settingsSaveExportAs(String format) {
    return 'Save $format export as';
  }

  @override
  String settingsExportSavedTo(String format, String path) {
    return '$format export saved to: $path';
  }

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String settingsRestoreWillRestoreItems(int count) {
    return 'This will restore $count items.';
  }

  @override
  String settingsRestoreMigrationRequiredFromVersion(String version) {
    return 'Migration required from version $version';
  }

  @override
  String get settingsRestoreReplaceAllDataPrompt =>
      'All existing data will be replaced. Continue?';

  @override
  String settingsRestoreCompleted(int items) {
    return 'Restored $items items';
  }

  @override
  String settingsRestoreCompletedWithMigrations(int items, int migrations) {
    return 'Restored $items items ($migrations migrations applied)';
  }

  @override
  String settingsRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get settingsDeleteDataPromptIntro =>
      'This will permanently delete ALL your data including:';

  @override
  String get settingsDeleteDataBulletInventoryItems => 'Inventory items';

  @override
  String get settingsDeleteDataBulletShoppingLists => 'Shopping lists';

  @override
  String get settingsDeleteDataBulletWasteTrackingData => 'Waste tracking data';

  @override
  String get settingsDeleteDataBulletAllSettingsPreferences =>
      'All settings and preferences';

  @override
  String get settingsDeleteDataTypeDeleteConfirm =>
      'Type \"DELETE\" to confirm:';

  @override
  String get settingsDeleteDataHintTypeDelete => 'Type DELETE';

  @override
  String get settingsDeletePermanently => 'Delete Permanently';

  @override
  String get settingsDeleteAllDataSuccess => 'All data permanently deleted';

  @override
  String settingsDeletionFailed(String error) {
    return 'Deletion failed: $error';
  }

  @override
  String get settingsReferencePackBundledDefaultOnly => 'Bundled default only';

  @override
  String get settingsReferencePackNeverUpdated => 'Never updated';

  @override
  String settingsReferencePackDiagnostics(
    String version,
    int records,
    String updatedAt,
    String manifestUrl,
  ) {
    return 'Active barcode pack: $version ($records records)\nLast update: $updatedAt\nManifest source: Firebase Remote Config ($manifestUrl)';
  }

  @override
  String get settingsAccountNotSignedIn => 'Not signed in';

  @override
  String get settingsAccountAnonymousSession => 'Anonymous session';

  @override
  String get settingsAccountSignedIn => 'Signed in';

  @override
  String get settingsAuthServiceUnavailable =>
      'Authentication service is unavailable.';

  @override
  String settingsAccountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsAccountSignOutHint =>
      'You can sign out to return to an anonymous session.';

  @override
  String get settingsAccountUpgradeAnonymousHint =>
      'Upgrade your anonymous session to an email account.';

  @override
  String get settingsAccountSignInHint =>
      'Sign in with email to submit authenticated feedback.';

  @override
  String get settingsLabelEmail => 'Email';

  @override
  String get settingsLabelPassword => 'Password';

  @override
  String get settingsPasswordMin6Hint =>
      'Password must be at least 6 characters.';

  @override
  String get settingsForgotPassword => 'Forgot password?';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutSuccess => 'Signed out';

  @override
  String get settingsCreateAccount => 'Create Account';

  @override
  String get settingsCreateAccountSuccess => 'Account created';

  @override
  String get settingsSignIn => 'Sign In';

  @override
  String get settingsSignInSuccess => 'Signed in';

  @override
  String get settingsSignInWithGoogleSuccess => 'Signed in with Google';

  @override
  String get settingsContinueWithGoogle => 'Continue with Google';

  @override
  String get settingsContinueWithAppleSoon => 'Continue with Apple (Soon)';

  @override
  String get settingsAppleSignInSoonMessage =>
      'Apple Sign-In will be enabled after email and Google sign-in are fully verified on-device.';

  @override
  String get settingsEnterAccountEmailFirst =>
      'Enter your account email first.';

  @override
  String settingsPasswordResetEmailSent(String email) {
    return 'Password reset email sent to $email.';
  }

  @override
  String get settingsPasswordResetFailed => 'Could not start password reset.';

  @override
  String get settingsEnterValidEmail => 'Enter a valid email address.';

  @override
  String get settingsPasswordMin6Error =>
      'Password must be at least 6 characters.';

  @override
  String get settingsAuthenticationFailedTryAgain =>
      'Authentication failed. Try again.';

  @override
  String get settingsAuthErrorUserNotFound =>
      'No account found for this email.';

  @override
  String get settingsAuthErrorInvalidCredentials =>
      'Incorrect email or password.';

  @override
  String get settingsAuthErrorEmailAlreadyInUse =>
      'An account with this email already exists.';

  @override
  String get settingsAuthErrorInvalidEmail => 'Email format is invalid.';

  @override
  String get settingsAuthErrorOperationNotAllowed =>
      'Enable Email/Password in Firebase Authentication settings.';

  @override
  String get settingsAuthErrorWeakPassword => 'Choose a stronger password.';

  @override
  String settingsAuthErrorUnknown(String code) {
    return 'Authentication failed ($code).';
  }

  @override
  String get feedbackHapticFeedback => 'Rétroaction haptique';

  @override
  String get feedbackHapticFeedbackDescription =>
      'Activer la vibration lors des interactions';

  @override
  String get feedbackAudioFeedback => 'Rétroaction audio';

  @override
  String get feedbackAudioFeedbackDescription =>
      'Activer les effets sonores lors des interactions';

  @override
  String get feedbackOcrBarcodeSuccess => 'Succès de la lecture du code-barres';

  @override
  String get feedbackOcrBarcodeSuccessDescription =>
      'Vibrer et biper lorsqu\'un code-barres est reconnu';

  @override
  String get feedbackOcrExpirySuccess =>
      'Reconnaissance de la date d\'expiration';

  @override
  String get feedbackOcrExpirySuccessDescription =>
      'Vibrer et biper lorsqu\'une date d\'expiration est capturée';

  @override
  String get feedbackOcrReceiptSuccess => 'Reconnaissance du reçu';

  @override
  String get feedbackOcrReceiptSuccessDescription =>
      'Vibrer et biper lorsque les articles du reçu sont extraits';

  @override
  String get feedbackOcrProduceSuccess =>
      'Reconnaissance de l\'étiquette de produit';

  @override
  String get feedbackOcrProduceSuccessDescription =>
      'Vibrer et biper lorsqu\'une étiquette de produit est lue';

  @override
  String get feedbackBeepVolume => 'Volume du bip';

  @override
  String get feedbackBeepVolumeDescription =>
      'Ajuster le volume du bip style PDV (0-100%)';

  @override
  String get feedbackHapticIntensity => 'Intensité haptique';

  @override
  String get feedbackHapticIntensityDescription =>
      'Ajuster l\'intensité de la vibration (Léger, Moyen, Lourd)';

  @override
  String get remindersTurnedOn => 'Rappels activés';

  @override
  String get remindersTurnedOff => 'Rappels désactivés';

  @override
  String get remindersLeadTime => 'Délai d\'avertissement';

  @override
  String get remindersSound => 'Son';

  @override
  String get remindersVibration => 'Vibration';

  @override
  String get shoppingBatchCapture => 'Lot d\'achat';

  @override
  String get shoppingBatchStore => 'Magasin';

  @override
  String get shoppingBatchDate => 'Date';

  @override
  String get shoppingBatchCost => 'Coût total';

  @override
  String get shoppingBatchReceipt => 'Photo du reçu';

  @override
  String get shoppingBatchLinkedItems => 'Articles liés';

  @override
  String get shoppingBatchTakePhoto => 'Prendre une photo';

  @override
  String get shoppingBatchChoosePhoto => 'Choisir depuis la galerie';

  @override
  String get shoppingBatchLinkItems => 'Lier les articles';

  @override
  String get shoppingBatchReview => 'Révision';

  @override
  String get privacyExport => 'Exportez vos données au format CSV ou JSON';

  @override
  String get privacyDelete =>
      'Supprimer toutes les données de manière permanente';

  @override
  String get privacyDeleteWarning => 'Cette action ne peut pas être annulée';

  @override
  String get aboutTitle => 'À propos de ZeroSpoils';

  @override
  String get aboutDescription =>
      'Une application simple pour vous aider à réduire le gaspillage alimentaire à la maison';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDeveloper => 'Développé avec ❤️';

  @override
  String get expiryTodayLabel => 'Expire aujourd\'hui';

  @override
  String get expiringSoonLabel => 'Expirant bientôt';

  @override
  String expiryThresholdDays(int days) {
    return 'dans $days jours';
  }

  @override
  String daysUntilExpiry(int days) {
    return '$days jours restants';
  }

  @override
  String itemQuantityFormat(String quantity) {
    return 'Qt : $quantity';
  }

  @override
  String formattedPrice(String currency, double amount) {
    return '$currency$amount';
  }

  @override
  String get inventoryFiltersTitle => 'Filtres';

  @override
  String get inventoryFilterAddedDate => 'Date d\'ajout';

  @override
  String get inventoryFilterFrom => 'Du';

  @override
  String get inventoryFilterTo => 'Au';

  @override
  String get inventoryFilterPreparedOnly => 'Préparés seulement';

  @override
  String get inventoryFilterPreparedOnlyHint =>
      'Afficher uniquement les articles préparés';

  @override
  String get inventoryFilterExpiringSoonOnly => 'Bientôt expirés seulement';

  @override
  String get inventoryFilterExpiringSoonOnlyHint =>
      'Afficher les articles expirant dans les 3 prochains jours';

  @override
  String get inventoryFilterBatchLinkedOnly => 'Liés à un lot seulement';

  @override
  String get inventoryFilterBatchLinkedOnlyHint =>
      'Afficher seulement les articles liés à des lots d\'achat';

  @override
  String get inventoryFilterHideConsumedItems =>
      'Masquer les articles consommés';

  @override
  String get inventoryFilterHideConsumedItemsHint =>
      'Masquer les articles marqués comme consommés ou gaspillés';

  @override
  String get inventoryFilterReset => 'Réinitialiser';

  @override
  String get inventoryFilterApply => 'Appliquer';

  @override
  String get inventoryBatchReceiptButton => 'Lot de reçus';

  @override
  String get inventoryDemoModeHint =>
      'Affichage des articles d\'exemple. Désactivez ce mode dans Réglages pour utiliser les vraies données.';

  @override
  String inventoryStreakDays(int days) {
    return '🔥 Série de $days jours';
  }

  @override
  String get inventoryLevelUp => 'Monter de niveau';

  @override
  String get inventoryNoWasteWeek => 'Semaine zéro gaspillage';

  @override
  String get inventoryStreakCompleted =>
      'Vous l\'avez fait! Continuez la série.';

  @override
  String inventoryStreakRemaining(int daysRemaining) {
    return 'Enregistrez encore $daysRemaining sauvetages pour monter de niveau';
  }

  @override
  String get inventoryStreakFootnote =>
      'Sans jugement: comparez avec vos amis seulement si vous l\'activez.';

  @override
  String get inventoryViewList => 'Vue liste';

  @override
  String get inventoryViewTable => 'Vue tableau';

  @override
  String get inventoryViewGrid => 'Vue grille';

  @override
  String get inventoryTableName => 'Nom';

  @override
  String get inventoryTableCategory => 'Catégorie';

  @override
  String get inventoryTableLocation => 'Emplacement';

  @override
  String get inventoryTableExpiry => 'Expiration';

  @override
  String get inventoryTableQuantity => 'Qté';

  @override
  String get inventoryTableStatus => 'Statut';

  @override
  String get inventoryNoExpiry => 'Aucune expiration';

  @override
  String inventoryExpiryShort(String date) {
    return 'Exp $date';
  }

  @override
  String get inventoryDeleteItemTitle => 'Supprimer l\'article?';

  @override
  String inventoryDeleteItemPrompt(String itemName) {
    return 'Voulez-vous vraiment supprimer \"$itemName\" de votre inventaire?';
  }

  @override
  String get inventoryActiveFilters => 'Filtres actifs:';

  @override
  String inventoryAddedFrom(String date) {
    return 'Ajouté depuis $date';
  }

  @override
  String inventoryAddedTo(String date) {
    return 'Ajouté jusqu\'à $date';
  }

  @override
  String get inventoryClearAll => 'Tout effacer';

  @override
  String get messageEmptyInventoryTitle => 'Votre inventaire est vide';

  @override
  String get inventoryAddFirstItem => 'Ajouter votre premier article';

  @override
  String get shoppingUnableToLoadList =>
      'Impossible de charger la liste de courses';

  @override
  String get shoppingNextShop => 'Prochaines courses';

  @override
  String get shoppingPurchased => 'Acheté';

  @override
  String shoppingConvertPurchased(int count) {
    return 'Convertir les achetés ($count)';
  }

  @override
  String get shoppingSourceFromShoppingList => 'Depuis la liste de courses';

  @override
  String shoppingAddedToInventory(String itemName) {
    return '$itemName ajouté à l\'inventaire';
  }

  @override
  String get shoppingDeleteItem => 'Supprimer l\'article';

  @override
  String get shoppingEmptyTitle => 'Votre liste de courses est vide';

  @override
  String get shoppingStartList => 'Commencer votre liste de courses';

  @override
  String get shoppingUnableToLoadHistory =>
      'Impossible de charger l\'historique des courses';

  @override
  String get shoppingNoHistory => 'Aucune sortie de courses enregistrée';

  @override
  String progressUnableToLoad(String error) {
    return 'Impossible de charger la progression: $error';
  }

  @override
  String get progressSectionSummary => 'Résumé';

  @override
  String get progressStatTotalItems => 'Articles totaux';

  @override
  String get progressStatAvailable => 'Disponibles';

  @override
  String get progressStatConsumed => 'Consommés';

  @override
  String get progressStatWasted => 'Gaspillés';

  @override
  String get progressSectionExpiryHealth => 'Santé des expirations';

  @override
  String get progressStatExpiringToday => 'Expirent aujourd\'hui';

  @override
  String get progressStatThisWeek => 'Cette semaine';

  @override
  String get progressStatExpiringSoon => 'Bientôt expirés';

  @override
  String get progressStatExpired => 'Expirés';

  @override
  String get progressStatNoExpiry => 'Sans expiration';

  @override
  String get progressSectionValueImpact => 'Impact de la valeur';

  @override
  String get progressStatTotalValue => 'Valeur totale';

  @override
  String get progressStatConsumedValue => 'Valeur consommée';

  @override
  String get progressStatWastedValue => 'Valeur gaspillée';

  @override
  String get progressStatSavedEstimate => 'Économisé (est.)';

  @override
  String get progressSectionActivity => 'Activité';

  @override
  String get progressStatAdded7d => 'Ajoutés (7 j)';

  @override
  String get progressStatAdded30d => 'Ajoutés (30 j)';

  @override
  String get progressStatUpdated7d => 'Mis à jour (7 j)';

  @override
  String get progressStatUpdated30d => 'Mis à jour (30 j)';

  @override
  String get progressSectionCategories => 'Catégories';

  @override
  String get progressSectionLocations => 'Emplacements';

  @override
  String get progressSectionTypes => 'Types';

  @override
  String get progressSectionBadges => 'Badges et réalisations';

  @override
  String get progressSectionTelemetry => 'Télémétrie (agrégation locale)';

  @override
  String get progressSectionRecentBatch => 'Lot de reçus récent';

  @override
  String get progressRecentBatchLoadError =>
      'Impossible de charger le lot récent';

  @override
  String get progressNoRecentBatches => 'Aucun lot de reçus récent.';

  @override
  String progressRecentBatchItemsTotal(int count, String total) {
    return '$count articles · $total au total';
  }

  @override
  String progressRecentBatchSource(String source) {
    return 'Source: $source';
  }

  @override
  String get progressLocalInsightsTitle => 'Informations locales';

  @override
  String get progressLocalInsightsSubtitle =>
      'Ces informations sont calculées sur l\'appareil à partir de votre activité.';

  @override
  String get progressStatTotalEvents => 'Événements totaux';

  @override
  String get progressStatItemsAdded => 'Articles ajoutés';

  @override
  String get progressStatItemsWasted => 'Articles gaspillés';

  @override
  String get progressStatRemindersOpened => 'Rappels ouverts';

  @override
  String get progressTopAddSources => 'Principales sources d\'ajout';

  @override
  String get progressTopWasteReasons => 'Principales raisons de gaspillage';

  @override
  String get progressMostViewedScreens => 'Écrans les plus consultés';

  @override
  String get progressTabSwitches => 'Changements d\'onglets';

  @override
  String get progressNoDataYet => 'Pas encore de données';

  @override
  String expiringLoadError(String error) {
    return 'Erreur de chargement des articles: $error';
  }

  @override
  String get expiringEmptyTitle => 'Tout est clair!';

  @override
  String get expiringEmptyMessage =>
      'Rien n\'expire bientôt.\nBravo pour votre bonne gestion\nde l\'inventaire!';

  @override
  String get expiringReviewInventory => 'Revoir l\'inventaire';

  @override
  String expiringBucketSemantics(String bucketName) {
    return 'Section expiration $bucketName';
  }

  @override
  String get itemCardPrepared => 'Préparé';

  @override
  String itemCardWastedPercent(int percent) {
    return 'Gaspillé $percent%';
  }

  @override
  String get itemCardUsed => 'Utilisé';

  @override
  String get itemCardWasted => 'Gaspillé';

  @override
  String itemCardAddedDate(String date) {
    return 'Ajouté $date';
  }

  @override
  String get itemCardEditTooltip => 'Modifier l\'article';

  @override
  String get itemCardDeleteTooltip => 'Supprimer l\'article';

  @override
  String get itemCardLocationFridge => '❄️ Frigo';

  @override
  String get itemCardLocationFreezer => '🧊 Congélateur';

  @override
  String get itemCardLocationPantry => '🗄️ Garde-manger';

  @override
  String get itemCardLocationOther => '🏠 Autre';

  @override
  String itemCardLocationPrepared(String locationLabel, String date) {
    return '$locationLabel • Préparé le $date';
  }

  @override
  String get itemCardNoExpirySet => 'Aucune expiration définie';

  @override
  String get itemCardExpired => 'Expiré';

  @override
  String get itemCardExpiresToday => 'Expire aujourd\'hui ⚠️';

  @override
  String get itemCardExpiresTomorrow => 'Expire demain';

  @override
  String itemCardExpiresInDays(int days) {
    return 'Expire dans $days jours';
  }

  @override
  String get noData => 'Pas de données';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';
}

/// The translations for French, as used in Canada (`fr_CA`).
class AppLocalizationsFrCa extends AppLocalizationsFr {
  AppLocalizationsFrCa() : super('fr_CA');

  @override
  String get appTitle => 'ZeroSpoils';

  @override
  String get appDescription => 'Réduire le gaspillage alimentaire à la maison';

  @override
  String get navigationInventory => 'Inventaire';

  @override
  String get navigationShoppingList => 'Magasinage';

  @override
  String get navigationShoppingHistory => 'Historique';

  @override
  String get navigationSettings => 'Paramètres';

  @override
  String get navigationOnboarding => 'Démarrage';

  @override
  String get screenTitleInventory => 'Inventaire';

  @override
  String get screenTitleShoppingList => 'Liste d\'épicerie';

  @override
  String get screenTitleShoppingHistory => 'Historique d\'achat';

  @override
  String get screenTitleSettings => 'Paramètres';

  @override
  String get screenTitleItemDetail => 'Détails de l\'article';

  @override
  String get screenTitleAddItem => 'Ajouter un article';

  @override
  String get screenTitleEditItem => 'Modifier l\'article';

  @override
  String get screenTitleReceiptBatch => 'Lot d\'achat';

  @override
  String get screenTitleProgress => 'Progrès';

  @override
  String get screenTitleOnboarding => 'Bienvenue à ZeroSpoils';

  @override
  String get buttonAdd => 'Ajouter';

  @override
  String get buttonEdit => 'Modifier';

  @override
  String get buttonDelete => 'Supprimer';

  @override
  String get buttonSave => 'Enregistrer';

  @override
  String get buttonCancel => 'Annuler';

  @override
  String get buttonClose => 'Fermer';

  @override
  String get buttonConfirm => 'Confirmer';

  @override
  String get buttonNext => 'Suivant';

  @override
  String get buttonBack => 'Retour';

  @override
  String get buttonYes => 'Oui';

  @override
  String get buttonNo => 'Non';

  @override
  String get buttonMaybeLater => 'Plus tard';

  @override
  String get buttonEnable => 'Activer';

  @override
  String get buttonDone => 'Terminé';

  @override
  String get buttonContinue => 'Continuer';

  @override
  String get buttonRetry => 'Réessayer';

  @override
  String get buttonSearch => 'Rechercher';

  @override
  String get buttonFilter => 'Filtrer';

  @override
  String get buttonSort => 'Trier';

  @override
  String get buttonClear => 'Effacer';

  @override
  String get buttonExport => 'Exporter';

  @override
  String get buttonImport => 'Importer';

  @override
  String get labelCategory => 'Catégorie';

  @override
  String get labelLocation => 'Lieu';

  @override
  String get labelExpiry => 'Date d\'expiration';

  @override
  String get labelQuantity => 'Quantité';

  @override
  String get labelStatus => 'Statut';

  @override
  String get labelPrice => 'Prix';

  @override
  String get labelStore => 'Magasin';

  @override
  String get labelDate => 'Date';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelPaymentMethod => 'Méthode de paiement';

  @override
  String get labelBarcode => 'Code-barres';

  @override
  String get labelSearch => 'Rechercher';

  @override
  String get labelFilter => 'Filtrer';

  @override
  String get labelAll => 'Tous';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get statusConsumed => 'Consommé';

  @override
  String get statusWasted => 'Gaspillé';

  @override
  String get statusPrepared => 'Préparé';

  @override
  String get statusFresh => 'Frais';

  @override
  String get statusPackaged => 'Emballé';

  @override
  String get categoryProduce => 'Produits frais';

  @override
  String get categoryDairy => 'Produits laitiers';

  @override
  String get categoryMeat => 'Viande';

  @override
  String get categoryGrains => 'Céréales';

  @override
  String get categoryFrozen => 'Surgelés';

  @override
  String get categoryPantry => 'Garde-manger';

  @override
  String get categoryBeverages => 'Boissons';

  @override
  String get categoryOther => 'Autre';

  @override
  String get itemTypeRaw => 'Brut';

  @override
  String get itemTypePrepared => 'Cuit';

  @override
  String get itemTypePackaged => 'Emballé';

  @override
  String get locationFridge => 'Réfrigérateur';

  @override
  String get locationFreezer => 'Congélateur';

  @override
  String get locationPantry => 'Garde-manger';

  @override
  String get locationCounter => 'Comptoir';

  @override
  String get locationOther => 'Autre';

  @override
  String get paymentMethodCash => 'Comptant';

  @override
  String get paymentMethodDebit => 'Débit';

  @override
  String get paymentMethodCredit => 'Crédit';

  @override
  String get paymentMethodMobile => 'Paiement mobile';

  @override
  String get errorUnableToLoadItems => 'Impossible de charger les articles';

  @override
  String get errorNoItemsFound => 'Aucun article trouvé';

  @override
  String get errorUnexpectedError => 'Une erreur inattendue s\'est produite';

  @override
  String get errorPermissionDenied => 'Accès refusé';

  @override
  String get errorCameraPermissionRequired =>
      'La permission de la caméra est requise';

  @override
  String get errorStoragePermissionRequired =>
      'La permission de stockage est requise';

  @override
  String get errorInvalidInput => 'Entrée invalide';

  @override
  String get errorItemNotFound => 'Article non trouvé';

  @override
  String get errorDuplicateItem => 'L\'article existe déjà';

  @override
  String get messageEmptyInventory =>
      'Aucun article dans votre inventaire pour l\'instant. Ajoutez-en un pour commencer.';

  @override
  String get messageEmptyShoppingList =>
      'Votre liste d\'épicerie est vide. Ajoutez les articles dont vous avez besoin.';

  @override
  String get messageNoResults => 'Aucun résultat trouvé';

  @override
  String get messageConfirmDelete =>
      'Êtes-vous sûr de vouloir supprimer cet article?';

  @override
  String get messageConfirmDeleteAll =>
      'Êtes-vous sûr de vouloir supprimer tous les articles?';

  @override
  String get messageSaveSuccess => 'Enregistré avec succès';

  @override
  String get messageDeleteSuccess => 'Supprimé avec succès';

  @override
  String get messageDuplicatePreventedMessage =>
      'Cet article est déjà dans votre inventaire';

  @override
  String get dialogTitleCameraPermission => 'Activer la caméra';

  @override
  String get dialogMessageCameraPermission =>
      'ZeroSpoils a besoin d\'accès à la caméra pour scanner des codes-barres et capturer des reçus.';

  @override
  String get dialogTitleConfirmAction => 'Confirmer l\'action';

  @override
  String get dialogTitleDeleteConfirmation => 'Supprimer l\'article';

  @override
  String get toastItemAdded => 'Article ajouté';

  @override
  String get toastItemUpdated => 'Article mis à jour';

  @override
  String get toastItemDeleted => 'Article supprimé';

  @override
  String get toastCopiedToClipboard => 'Copié au presse-papiers';

  @override
  String get toastErrorOccurred => 'Une erreur s\'est produite';

  @override
  String get hintSearchItems => 'Rechercher des articles...';

  @override
  String get hintItemName => 'Nom de l\'article';

  @override
  String get hintNotes => 'Ajouter des notes...';

  @override
  String get settingsReminders => 'Rappels';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsFeedback => 'Rétroaction et sons';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsPrivacy => 'Confidentialité et données';

  @override
  String get settingsDarkMode => 'Mode sombre';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsReferenceDataRegion => 'Région des données de référence';

  @override
  String get settingsReferenceDataLanguage => 'Langue des données de référence';

  @override
  String get settingsDateFormat => 'Format de date';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsExportData => 'Exporter les données';

  @override
  String get settingsImportData => 'Importer les données';

  @override
  String get settingsDeleteAllData => 'Supprimer toutes les données';

  @override
  String get settingsSectionAccountData => 'COMPTE ET DONNÉES';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsDataSync => 'Synchronisation des données';

  @override
  String get settingsDemoMode => 'Mode démo';

  @override
  String get settingsSoon => 'Bientôt';

  @override
  String get settingsDemoModeEnabled => 'Mode démo activé';

  @override
  String get settingsDemoModeDisabled => 'Mode démo désactivé';

  @override
  String get settingsShareAnonymousUsageData =>
      'Partager les données d\'utilisation anonymes';

  @override
  String get settingsShareAnonymousUsageDataSubtitle =>
      'Autorise l\'export infonuagique lorsqu\'il sera disponible (pas encore disponible)';

  @override
  String get settingsCloudAnalyticsExport => 'Export infonuagique des analyses';

  @override
  String get settingsCloudAnalyticsExportSubtitle =>
      'Envoyer les données télémétriques vers le nuage';

  @override
  String get settingsExportSubtitle =>
      'Télécharger votre inventaire et vos paramètres';

  @override
  String get settingsImportSubtitle => 'Importer un fichier de sauvegarde';

  @override
  String get settingsReferenceDataPacks => 'Packs de données de référence';

  @override
  String get settingsDeleteAllDataSubtitle =>
      'Supprimer définitivement toutes les données (irréversible)';

  @override
  String get settingsSectionPreferences => 'PRÉFÉRENCES';

  @override
  String get settingsMealPlanning => 'Planification des repas';

  @override
  String get settingsSectionSupportFeedback => 'AIDE ET RÉTROACTION';

  @override
  String get settingsHelpFaq => 'Aide et FAQ';

  @override
  String get settingsHelpCenterComingSoon =>
      'Centre d\'aide bientôt disponible';

  @override
  String get settingsSendFeedback => 'Envoyer des commentaires';

  @override
  String get feedbackDrawerBarrierLabel => 'Rétroaction';

  @override
  String get feedbackDrawerTitle => 'Envoyer des commentaires';

  @override
  String get feedbackDrawerCloseTooltip => 'Fermer le panneau de rétroaction';

  @override
  String get feedbackDrawerIntro =>
      'Dites-nous ce qui fonctionne ou ce qui ne va pas. Les métadonnées de l\'application sont incluses automatiquement.';

  @override
  String get feedbackDrawerCategoryLabel => 'Catégorie';

  @override
  String get feedbackCategoryBugReport => 'Signaler un bogue';

  @override
  String get feedbackCategoryFeatureRequest => 'Demande de fonctionnalité';

  @override
  String get feedbackCategoryUxFeedback => 'Rétroaction UX';

  @override
  String get feedbackCategoryDarkModeReadability => 'Lisibilité du mode sombre';

  @override
  String get feedbackCategoryOther => 'Autre';

  @override
  String get feedbackDrawerMessageLabel => 'Message';

  @override
  String get feedbackDrawerMessageHint =>
      'Que s\'est-il passé? Que devrait-on améliorer?';

  @override
  String get feedbackDrawerMessageValidation =>
      'Veuillez saisir un commentaire avant l\'envoi.';

  @override
  String get feedbackDrawerEmailLabel => 'Courriel (optionnel)';

  @override
  String get feedbackDrawerEmailHint => 'vous@exemple.com';

  @override
  String feedbackDrawerSourceLocale(String source, String locale) {
    return 'Source : $source • Langue : $locale';
  }

  @override
  String get feedbackDrawerSubmitting => 'Envoi en cours...';

  @override
  String get feedbackDrawerSubmit => 'Envoyer';

  @override
  String get feedbackDrawerSent => 'Commentaire envoyé. Merci.';

  @override
  String get feedbackDrawerSignInRequired =>
      'Veuillez vous connecter avant d\'envoyer un commentaire.';

  @override
  String get settingsRateApp => 'Évaluer l\'application';

  @override
  String get settingsThanksForSupport => 'Merci pour votre soutien!';

  @override
  String get settingsViewTutorial => 'Voir le tutoriel';

  @override
  String get settingsSectionLegal => 'JURIDIQUE';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsPrivacyPolicyComingSoon =>
      'Politique de confidentialité bientôt disponible';

  @override
  String get settingsTermsOfService => 'Conditions d\'utilisation';

  @override
  String get settingsTermsComingSoon => 'Conditions bientôt disponibles';

  @override
  String get settingsAboutSubtitle => 'ZeroSpoils v1.0.0';

  @override
  String get settingsAboutSnackMessage =>
      'ZeroSpoils aide à réduire le gaspillage alimentaire.';

  @override
  String get settingsHapticIntensityLight => 'Léger';

  @override
  String get settingsHapticIntensityMedium => 'Moyen';

  @override
  String get settingsHapticIntensityHeavy => 'Lourd';

  @override
  String settingsLeadTimeDays(int days) {
    return '$days jours';
  }

  @override
  String get settingsChooseExportFormat => 'Choose export format:';

  @override
  String get settingsExportJsonCompleteBackup => 'JSON (Complete Backup)';

  @override
  String get settingsExportCsvInventoryOnly => 'CSV (Inventory Only)';

  @override
  String settingsSaveExportAs(String format) {
    return 'Save $format export as';
  }

  @override
  String settingsExportSavedTo(String format, String path) {
    return '$format export saved to: $path';
  }

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String settingsRestoreWillRestoreItems(int count) {
    return 'This will restore $count items.';
  }

  @override
  String settingsRestoreMigrationRequiredFromVersion(String version) {
    return 'Migration required from version $version';
  }

  @override
  String get settingsRestoreReplaceAllDataPrompt =>
      'All existing data will be replaced. Continue?';

  @override
  String settingsRestoreCompleted(int items) {
    return 'Restored $items items';
  }

  @override
  String settingsRestoreCompletedWithMigrations(int items, int migrations) {
    return 'Restored $items items ($migrations migrations applied)';
  }

  @override
  String settingsRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get settingsDeleteDataPromptIntro =>
      'This will permanently delete ALL your data including:';

  @override
  String get settingsDeleteDataBulletInventoryItems => 'Inventory items';

  @override
  String get settingsDeleteDataBulletShoppingLists => 'Shopping lists';

  @override
  String get settingsDeleteDataBulletWasteTrackingData => 'Waste tracking data';

  @override
  String get settingsDeleteDataBulletAllSettingsPreferences =>
      'All settings and preferences';

  @override
  String get settingsDeleteDataTypeDeleteConfirm =>
      'Type \"DELETE\" to confirm:';

  @override
  String get settingsDeleteDataHintTypeDelete => 'Type DELETE';

  @override
  String get settingsDeletePermanently => 'Delete Permanently';

  @override
  String get settingsDeleteAllDataSuccess => 'All data permanently deleted';

  @override
  String settingsDeletionFailed(String error) {
    return 'Deletion failed: $error';
  }

  @override
  String get settingsReferencePackBundledDefaultOnly => 'Bundled default only';

  @override
  String get settingsReferencePackNeverUpdated => 'Never updated';

  @override
  String settingsReferencePackDiagnostics(
    String version,
    int records,
    String updatedAt,
    String manifestUrl,
  ) {
    return 'Active barcode pack: $version ($records records)\nLast update: $updatedAt\nManifest source: Firebase Remote Config ($manifestUrl)';
  }

  @override
  String get settingsAccountNotSignedIn => 'Not signed in';

  @override
  String get settingsAccountAnonymousSession => 'Anonymous session';

  @override
  String get settingsAccountSignedIn => 'Signed in';

  @override
  String get settingsAuthServiceUnavailable =>
      'Authentication service is unavailable.';

  @override
  String settingsAccountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsAccountSignOutHint =>
      'You can sign out to return to an anonymous session.';

  @override
  String get settingsAccountUpgradeAnonymousHint =>
      'Upgrade your anonymous session to an email account.';

  @override
  String get settingsAccountSignInHint =>
      'Sign in with email to submit authenticated feedback.';

  @override
  String get settingsLabelEmail => 'Email';

  @override
  String get settingsLabelPassword => 'Password';

  @override
  String get settingsPasswordMin6Hint =>
      'Password must be at least 6 characters.';

  @override
  String get settingsForgotPassword => 'Forgot password?';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutSuccess => 'Signed out';

  @override
  String get settingsCreateAccount => 'Create Account';

  @override
  String get settingsCreateAccountSuccess => 'Account created';

  @override
  String get settingsSignIn => 'Sign In';

  @override
  String get settingsSignInSuccess => 'Signed in';

  @override
  String get settingsSignInWithGoogleSuccess => 'Signed in with Google';

  @override
  String get settingsContinueWithGoogle => 'Continue with Google';

  @override
  String get settingsContinueWithAppleSoon => 'Continue with Apple (Soon)';

  @override
  String get settingsAppleSignInSoonMessage =>
      'Apple Sign-In will be enabled after email and Google sign-in are fully verified on-device.';

  @override
  String get settingsEnterAccountEmailFirst =>
      'Enter your account email first.';

  @override
  String settingsPasswordResetEmailSent(String email) {
    return 'Password reset email sent to $email.';
  }

  @override
  String get settingsPasswordResetFailed => 'Could not start password reset.';

  @override
  String get settingsEnterValidEmail => 'Enter a valid email address.';

  @override
  String get settingsPasswordMin6Error =>
      'Password must be at least 6 characters.';

  @override
  String get settingsAuthenticationFailedTryAgain =>
      'Authentication failed. Try again.';

  @override
  String get settingsAuthErrorUserNotFound =>
      'No account found for this email.';

  @override
  String get settingsAuthErrorInvalidCredentials =>
      'Incorrect email or password.';

  @override
  String get settingsAuthErrorEmailAlreadyInUse =>
      'An account with this email already exists.';

  @override
  String get settingsAuthErrorInvalidEmail => 'Email format is invalid.';

  @override
  String get settingsAuthErrorOperationNotAllowed =>
      'Enable Email/Password in Firebase Authentication settings.';

  @override
  String get settingsAuthErrorWeakPassword => 'Choose a stronger password.';

  @override
  String settingsAuthErrorUnknown(String code) {
    return 'Authentication failed ($code).';
  }

  @override
  String get feedbackHapticFeedback => 'Rétroaction haptique';

  @override
  String get feedbackHapticFeedbackDescription =>
      'Activer la vibration lors des interactions';

  @override
  String get feedbackAudioFeedback => 'Rétroaction audio';

  @override
  String get feedbackAudioFeedbackDescription =>
      'Activer les effets sonores lors des interactions';

  @override
  String get feedbackOcrBarcodeSuccess => 'Succès de la lecture du code-barres';

  @override
  String get feedbackOcrBarcodeSuccessDescription =>
      'Vibrer et biper lorsqu\'un code-barres est reconnu';

  @override
  String get feedbackOcrExpirySuccess =>
      'Reconnaissance de la date d\'expiration';

  @override
  String get feedbackOcrExpirySuccessDescription =>
      'Vibrer et biper lorsqu\'une date d\'expiration est capturée';

  @override
  String get feedbackOcrReceiptSuccess => 'Reconnaissance du reçu';

  @override
  String get feedbackOcrReceiptSuccessDescription =>
      'Vibrer et biper lorsque les articles du reçu sont extraits';

  @override
  String get feedbackOcrProduceSuccess =>
      'Reconnaissance de l\'étiquette de produit';

  @override
  String get feedbackOcrProduceSuccessDescription =>
      'Vibrer et biper lorsqu\'une étiquette de produit est lue';

  @override
  String get feedbackBeepVolume => 'Volume du bip';

  @override
  String get feedbackBeepVolumeDescription =>
      'Ajuster le volume du bip style PDV (0-100%)';

  @override
  String get feedbackHapticIntensity => 'Intensité haptique';

  @override
  String get feedbackHapticIntensityDescription =>
      'Ajuster l\'intensité de la vibration (Léger, Moyen, Lourd)';

  @override
  String get remindersTurnedOn => 'Rappels activés';

  @override
  String get remindersTurnedOff => 'Rappels désactivés';

  @override
  String get remindersLeadTime => 'Délai d\'avertissement';

  @override
  String get remindersSound => 'Son';

  @override
  String get remindersVibration => 'Vibration';

  @override
  String get shoppingBatchCapture => 'Lot d\'achat';

  @override
  String get shoppingBatchStore => 'Magasin';

  @override
  String get shoppingBatchDate => 'Date';

  @override
  String get shoppingBatchCost => 'Coût total';

  @override
  String get shoppingBatchReceipt => 'Photo du reçu';

  @override
  String get shoppingBatchLinkedItems => 'Articles liés';

  @override
  String get shoppingBatchTakePhoto => 'Prendre une photo';

  @override
  String get shoppingBatchChoosePhoto => 'Choisir depuis la galerie';

  @override
  String get shoppingBatchLinkItems => 'Lier les articles';

  @override
  String get shoppingBatchReview => 'Révision';

  @override
  String get privacyExport => 'Exportez vos données au format CSV ou JSON';

  @override
  String get privacyDelete =>
      'Supprimer toutes les données de manière permanente';

  @override
  String get privacyDeleteWarning => 'Cette action ne peut pas être annulée';

  @override
  String get aboutTitle => 'À propos de ZeroSpoils';

  @override
  String get aboutDescription =>
      'Une application simple pour vous aider à réduire le gaspillage alimentaire à la maison';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDeveloper => 'Développé avec ❤️';

  @override
  String get expiryTodayLabel => 'Expire aujourd\'hui';

  @override
  String get expiringSoonLabel => 'Expirant bientôt';

  @override
  String expiryThresholdDays(int days) {
    return 'dans $days jours';
  }

  @override
  String daysUntilExpiry(int days) {
    return '$days jours restants';
  }

  @override
  String itemQuantityFormat(String quantity) {
    return 'Qt : $quantity';
  }

  @override
  String formattedPrice(String currency, double amount) {
    return '$currency$amount';
  }

  @override
  String get inventoryFiltersTitle => 'Filtres';

  @override
  String get inventoryFilterAddedDate => 'Date d\'ajout';

  @override
  String get inventoryFilterFrom => 'Du';

  @override
  String get inventoryFilterTo => 'Au';

  @override
  String get inventoryFilterPreparedOnly => 'Préparés seulement';

  @override
  String get inventoryFilterPreparedOnlyHint =>
      'Afficher uniquement les articles préparés';

  @override
  String get inventoryFilterExpiringSoonOnly => 'Bientôt expirés seulement';

  @override
  String get inventoryFilterExpiringSoonOnlyHint =>
      'Afficher les articles expirant dans les 3 prochains jours';

  @override
  String get inventoryFilterBatchLinkedOnly => 'Liés à un lot seulement';

  @override
  String get inventoryFilterBatchLinkedOnlyHint =>
      'Afficher seulement les articles liés à des lots de magasinage';

  @override
  String get inventoryFilterHideConsumedItems =>
      'Masquer les articles consommés';

  @override
  String get inventoryFilterHideConsumedItemsHint =>
      'Masquer les articles marqués comme consommés ou gaspillés';

  @override
  String get inventoryFilterReset => 'Réinitialiser';

  @override
  String get inventoryFilterApply => 'Appliquer';

  @override
  String get inventoryBatchReceiptButton => 'Lot de reçus';

  @override
  String get inventoryDemoModeHint =>
      'Affichage des articles d\'exemple. Désactivez ce mode dans Réglages pour utiliser les vraies données.';

  @override
  String inventoryStreakDays(int days) {
    return '🔥 Série de $days jours';
  }

  @override
  String get inventoryLevelUp => 'Monter de niveau';

  @override
  String get inventoryNoWasteWeek => 'Semaine zéro gaspillage';

  @override
  String get inventoryStreakCompleted =>
      'Vous l\'avez fait! Continuez la série.';

  @override
  String inventoryStreakRemaining(int daysRemaining) {
    return 'Enregistrez encore $daysRemaining sauvetages pour monter de niveau';
  }

  @override
  String get inventoryStreakFootnote =>
      'Sans jugement: comparez avec vos amis seulement si vous l\'activez.';

  @override
  String get inventoryViewList => 'Vue liste';

  @override
  String get inventoryViewTable => 'Vue tableau';

  @override
  String get inventoryViewGrid => 'Vue grille';

  @override
  String get inventoryTableName => 'Nom';

  @override
  String get inventoryTableCategory => 'Catégorie';

  @override
  String get inventoryTableLocation => 'Emplacement';

  @override
  String get inventoryTableExpiry => 'Expiration';

  @override
  String get inventoryTableQuantity => 'Qté';

  @override
  String get inventoryTableStatus => 'Statut';

  @override
  String get inventoryNoExpiry => 'Aucune expiration';

  @override
  String inventoryExpiryShort(String date) {
    return 'Exp $date';
  }

  @override
  String get inventoryDeleteItemTitle => 'Supprimer l\'article?';

  @override
  String inventoryDeleteItemPrompt(String itemName) {
    return 'Voulez-vous vraiment supprimer \"$itemName\" de votre inventaire?';
  }

  @override
  String get inventoryActiveFilters => 'Filtres actifs:';

  @override
  String inventoryAddedFrom(String date) {
    return 'Ajouté depuis $date';
  }

  @override
  String inventoryAddedTo(String date) {
    return 'Ajouté jusqu\'à $date';
  }

  @override
  String get inventoryClearAll => 'Tout effacer';

  @override
  String get messageEmptyInventoryTitle => 'Votre inventaire est vide';

  @override
  String get inventoryAddFirstItem => 'Ajouter votre premier article';

  @override
  String get shoppingUnableToLoadList =>
      'Impossible de charger la liste d\'épicerie';

  @override
  String get shoppingNextShop => 'Prochain magasinage';

  @override
  String get shoppingPurchased => 'Acheté';

  @override
  String shoppingConvertPurchased(int count) {
    return 'Convertir les achetés ($count)';
  }

  @override
  String get shoppingSourceFromShoppingList => 'Depuis la liste d\'épicerie';

  @override
  String shoppingAddedToInventory(String itemName) {
    return '$itemName ajouté à l\'inventaire';
  }

  @override
  String get shoppingDeleteItem => 'Supprimer l\'article';

  @override
  String get shoppingEmptyTitle => 'Votre liste d\'épicerie est vide';

  @override
  String get shoppingStartList => 'Commencer votre liste d\'épicerie';

  @override
  String get shoppingUnableToLoadHistory =>
      'Impossible de charger l\'historique de magasinage';

  @override
  String get shoppingNoHistory => 'Aucune sortie de magasinage enregistrée';

  @override
  String progressUnableToLoad(String error) {
    return 'Impossible de charger la progression: $error';
  }

  @override
  String get progressSectionSummary => 'Résumé';

  @override
  String get progressStatTotalItems => 'Articles totaux';

  @override
  String get progressStatAvailable => 'Disponibles';

  @override
  String get progressStatConsumed => 'Consommés';

  @override
  String get progressStatWasted => 'Gaspillés';

  @override
  String get progressSectionExpiryHealth => 'Santé des expirations';

  @override
  String get progressStatExpiringToday => 'Expirent aujourd\'hui';

  @override
  String get progressStatThisWeek => 'Cette semaine';

  @override
  String get progressStatExpiringSoon => 'Bientôt expirés';

  @override
  String get progressStatExpired => 'Expirés';

  @override
  String get progressStatNoExpiry => 'Sans expiration';

  @override
  String get progressSectionValueImpact => 'Impact de la valeur';

  @override
  String get progressStatTotalValue => 'Valeur totale';

  @override
  String get progressStatConsumedValue => 'Valeur consommée';

  @override
  String get progressStatWastedValue => 'Valeur gaspillée';

  @override
  String get progressStatSavedEstimate => 'Économisé (est.)';

  @override
  String get progressSectionActivity => 'Activité';

  @override
  String get progressStatAdded7d => 'Ajoutés (7 j)';

  @override
  String get progressStatAdded30d => 'Ajoutés (30 j)';

  @override
  String get progressStatUpdated7d => 'Mis à jour (7 j)';

  @override
  String get progressStatUpdated30d => 'Mis à jour (30 j)';

  @override
  String get progressSectionCategories => 'Catégories';

  @override
  String get progressSectionLocations => 'Emplacements';

  @override
  String get progressSectionTypes => 'Types';

  @override
  String get progressSectionBadges => 'Badges et réalisations';

  @override
  String get progressSectionTelemetry => 'Télémétrie (agrégation locale)';

  @override
  String get progressSectionRecentBatch => 'Lot de reçus récent';

  @override
  String get progressRecentBatchLoadError =>
      'Impossible de charger le lot récent';

  @override
  String get progressNoRecentBatches => 'Aucun lot de reçus récent.';

  @override
  String progressRecentBatchItemsTotal(int count, String total) {
    return '$count articles · $total au total';
  }

  @override
  String progressRecentBatchSource(String source) {
    return 'Source: $source';
  }

  @override
  String get progressLocalInsightsTitle => 'Informations locales';

  @override
  String get progressLocalInsightsSubtitle =>
      'Ces informations sont calculées sur l\'appareil à partir de votre activité.';

  @override
  String get progressStatTotalEvents => 'Événements totaux';

  @override
  String get progressStatItemsAdded => 'Articles ajoutés';

  @override
  String get progressStatItemsWasted => 'Articles gaspillés';

  @override
  String get progressStatRemindersOpened => 'Rappels ouverts';

  @override
  String get progressTopAddSources => 'Principales sources d\'ajout';

  @override
  String get progressTopWasteReasons => 'Principales raisons de gaspillage';

  @override
  String get progressMostViewedScreens => 'Écrans les plus consultés';

  @override
  String get progressTabSwitches => 'Changements d\'onglets';

  @override
  String get progressNoDataYet => 'Pas encore de données';

  @override
  String expiringLoadError(String error) {
    return 'Erreur de chargement des articles: $error';
  }

  @override
  String get expiringEmptyTitle => 'Tout est clair!';

  @override
  String get expiringEmptyMessage =>
      'Rien n\'expire bientôt.\nBravo pour votre bonne gestion\nde l\'inventaire!';

  @override
  String get expiringReviewInventory => 'Revoir l\'inventaire';

  @override
  String expiringBucketSemantics(String bucketName) {
    return 'Section expiration $bucketName';
  }

  @override
  String get itemCardPrepared => 'Préparé';

  @override
  String itemCardWastedPercent(int percent) {
    return 'Gaspillé $percent%';
  }

  @override
  String get itemCardUsed => 'Utilisé';

  @override
  String get itemCardWasted => 'Gaspillé';

  @override
  String itemCardAddedDate(String date) {
    return 'Ajouté $date';
  }

  @override
  String get itemCardEditTooltip => 'Modifier l\'article';

  @override
  String get itemCardDeleteTooltip => 'Supprimer l\'article';

  @override
  String get itemCardLocationFridge => '❄️ Frigo';

  @override
  String get itemCardLocationFreezer => '🧊 Congélateur';

  @override
  String get itemCardLocationPantry => '🗄️ Garde-manger';

  @override
  String get itemCardLocationOther => '🏠 Autre';

  @override
  String itemCardLocationPrepared(String locationLabel, String date) {
    return '$locationLabel • Préparé le $date';
  }

  @override
  String get itemCardNoExpirySet => 'Aucune expiration définie';

  @override
  String get itemCardExpired => 'Expiré';

  @override
  String get itemCardExpiresToday => 'Expire aujourd\'hui ⚠️';

  @override
  String get itemCardExpiresTomorrow => 'Expire demain';

  @override
  String itemCardExpiresInDays(int days) {
    return 'Expire dans $days jours';
  }

  @override
  String get noData => 'Pas de données';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';
}
