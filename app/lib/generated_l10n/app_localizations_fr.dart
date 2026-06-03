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
  String get categoryFrozen => 'Surgelés';

  @override
  String get categoryPantry => 'Garde-manger';

  @override
  String get categoryBeverages => 'Boissons';

  @override
  String get categoryOther => 'Autre';

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
  String get inventoryFiltersTitle => 'Filters';

  @override
  String get inventoryFilterAddedDate => 'Added date';

  @override
  String get inventoryFilterFrom => 'From';

  @override
  String get inventoryFilterTo => 'To';

  @override
  String get inventoryFilterPreparedOnly => 'Prepared only';

  @override
  String get inventoryFilterPreparedOnlyHint => 'Show prepared items only';

  @override
  String get inventoryFilterExpiringSoonOnly => 'Expiring soon only';

  @override
  String get inventoryFilterExpiringSoonOnlyHint =>
      'Show items expiring within the next 3 days';

  @override
  String get inventoryFilterBatchLinkedOnly => 'Batch-linked only';

  @override
  String get inventoryFilterBatchLinkedOnlyHint =>
      'Show only items linked to shopping batches';

  @override
  String get inventoryFilterHideConsumedItems => 'Hide consumed items';

  @override
  String get inventoryFilterHideConsumedItemsHint =>
      'Hide items marked as consumed or wasted';

  @override
  String get inventoryFilterReset => 'Reset';

  @override
  String get inventoryFilterApply => 'Apply';

  @override
  String get inventoryBatchReceiptButton => 'Batch receipt';

  @override
  String get inventoryDemoModeHint =>
      'Showing sample items. Turn off in Settings to use real data.';

  @override
  String inventoryStreakDays(int days) {
    return '🔥 $days-day streak';
  }

  @override
  String get inventoryLevelUp => 'Level up';

  @override
  String get inventoryNoWasteWeek => 'No Waste Week';

  @override
  String get inventoryStreakCompleted => 'You made it! Keep the streak alive.';

  @override
  String inventoryStreakRemaining(int daysRemaining) {
    return 'Log $daysRemaining more saves to level up';
  }

  @override
  String get inventoryStreakFootnote =>
      'Judgement-free: compare with friends only when you opt in.';

  @override
  String get inventoryViewList => 'List view';

  @override
  String get inventoryViewTable => 'Table view';

  @override
  String get inventoryViewGrid => 'Grid view';

  @override
  String get inventoryTableName => 'Name';

  @override
  String get inventoryTableCategory => 'Category';

  @override
  String get inventoryTableLocation => 'Location';

  @override
  String get inventoryTableExpiry => 'Expiry';

  @override
  String get inventoryTableQuantity => 'Qty';

  @override
  String get inventoryTableStatus => 'Status';

  @override
  String get inventoryNoExpiry => 'No expiry';

  @override
  String inventoryExpiryShort(String date) {
    return 'Exp $date';
  }

  @override
  String get inventoryDeleteItemTitle => 'Delete Item?';

  @override
  String inventoryDeleteItemPrompt(String itemName) {
    return 'Are you sure you want to delete \"$itemName\" from your inventory?';
  }

  @override
  String get inventoryActiveFilters => 'Active filters:';

  @override
  String inventoryAddedFrom(String date) {
    return 'Added from $date';
  }

  @override
  String inventoryAddedTo(String date) {
    return 'Added to $date';
  }

  @override
  String get inventoryClearAll => 'Clear all';

  @override
  String get messageEmptyInventoryTitle => 'Your inventory is empty';

  @override
  String get inventoryAddFirstItem => 'Add your first item';

  @override
  String get shoppingUnableToLoadList => 'Unable to load shopping list';

  @override
  String get shoppingNextShop => 'Next Shop';

  @override
  String get shoppingPurchased => 'Purchased';

  @override
  String shoppingConvertPurchased(int count) {
    return 'Convert Purchased ($count)';
  }

  @override
  String get shoppingSourceFromShoppingList => 'From Shopping List';

  @override
  String shoppingAddedToInventory(String itemName) {
    return '$itemName added to inventory';
  }

  @override
  String get shoppingDeleteItem => 'Delete item';

  @override
  String get shoppingEmptyTitle => 'Your shopping list is empty';

  @override
  String get shoppingStartList => 'Start your shopping list';

  @override
  String get shoppingUnableToLoadHistory => 'Unable to load shopping history';

  @override
  String get shoppingNoHistory => 'No shopping trips recorded yet';

  @override
  String progressUnableToLoad(String error) {
    return 'Unable to load progress: $error';
  }

  @override
  String get progressSectionSummary => 'Summary';

  @override
  String get progressStatTotalItems => 'Total Items';

  @override
  String get progressStatAvailable => 'Available';

  @override
  String get progressStatConsumed => 'Consumed';

  @override
  String get progressStatWasted => 'Wasted';

  @override
  String get progressSectionExpiryHealth => 'Expiry Health';

  @override
  String get progressStatExpiringToday => 'Expiring Today';

  @override
  String get progressStatThisWeek => 'This Week';

  @override
  String get progressStatExpiringSoon => 'Expiring Soon';

  @override
  String get progressStatExpired => 'Expired';

  @override
  String get progressStatNoExpiry => 'No Expiry';

  @override
  String get progressSectionValueImpact => 'Value Impact';

  @override
  String get progressStatTotalValue => 'Total Value';

  @override
  String get progressStatConsumedValue => 'Consumed Value';

  @override
  String get progressStatWastedValue => 'Wasted Value';

  @override
  String get progressStatSavedEstimate => 'Saved (est.)';

  @override
  String get progressSectionActivity => 'Activity';

  @override
  String get progressStatAdded7d => 'Added (7d)';

  @override
  String get progressStatAdded30d => 'Added (30d)';

  @override
  String get progressStatUpdated7d => 'Updated (7d)';

  @override
  String get progressStatUpdated30d => 'Updated (30d)';

  @override
  String get progressSectionCategories => 'Categories';

  @override
  String get progressSectionLocations => 'Locations';

  @override
  String get progressSectionTypes => 'Types';

  @override
  String get progressSectionBadges => 'Badges & Achievements';

  @override
  String get progressSectionTelemetry => 'Telemetry (Local Aggregation)';

  @override
  String get progressSectionRecentBatch => 'Recent Receipt Batch';

  @override
  String get progressRecentBatchLoadError => 'Unable to load recent batch';

  @override
  String get progressNoRecentBatches => 'No recent receipt batches yet.';

  @override
  String progressRecentBatchItemsTotal(int count, String total) {
    return '$count items · $total total';
  }

  @override
  String progressRecentBatchSource(String source) {
    return 'Source: $source';
  }

  @override
  String get progressLocalInsightsTitle => 'Local Insights';

  @override
  String get progressLocalInsightsSubtitle =>
      'These insights are computed on-device from your activity.';

  @override
  String get progressStatTotalEvents => 'Total Events';

  @override
  String get progressStatItemsAdded => 'Items Added';

  @override
  String get progressStatItemsWasted => 'Items Wasted';

  @override
  String get progressStatRemindersOpened => 'Reminders Opened';

  @override
  String get progressTopAddSources => 'Top Add Sources';

  @override
  String get progressTopWasteReasons => 'Top Waste Reasons';

  @override
  String get progressMostViewedScreens => 'Most Viewed Screens';

  @override
  String get progressTabSwitches => 'Tab Switches';

  @override
  String get progressNoDataYet => 'No data yet';

  @override
  String expiringLoadError(String error) {
    return 'Error loading items: $error';
  }

  @override
  String get expiringEmptyTitle => 'All clear!';

  @override
  String get expiringEmptyMessage =>
      'Nothing expiring soon.\nGreat job staying on top of\nyour inventory!';

  @override
  String get expiringReviewInventory => 'Review Inventory';

  @override
  String expiringBucketSemantics(String bucketName) {
    return 'Expiring $bucketName section';
  }

  @override
  String get itemCardPrepared => 'Prepared';

  @override
  String itemCardWastedPercent(int percent) {
    return 'Wasted $percent%';
  }

  @override
  String get itemCardUsed => 'Used';

  @override
  String get itemCardWasted => 'Wasted';

  @override
  String itemCardAddedDate(String date) {
    return 'Added $date';
  }

  @override
  String get itemCardEditTooltip => 'Edit item';

  @override
  String get itemCardDeleteTooltip => 'Delete item';

  @override
  String get itemCardLocationFridge => '❄️ Fridge';

  @override
  String get itemCardLocationFreezer => '🧊 Freezer';

  @override
  String get itemCardLocationPantry => '🗄️ Pantry';

  @override
  String get itemCardLocationOther => '🏠 Other';

  @override
  String itemCardLocationPrepared(String locationLabel, String date) {
    return '$locationLabel • Prepared $date';
  }

  @override
  String get itemCardNoExpirySet => 'No expiry set';

  @override
  String get itemCardExpired => 'Expired';

  @override
  String get itemCardExpiresToday => 'Expires today ⚠️';

  @override
  String get itemCardExpiresTomorrow => 'Expires tomorrow';

  @override
  String itemCardExpiresInDays(int days) {
    return 'Expires in $days days';
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
  String get categoryFrozen => 'Surgelés';

  @override
  String get categoryPantry => 'Garde-manger';

  @override
  String get categoryBeverages => 'Boissons';

  @override
  String get categoryOther => 'Autre';

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
  String get noData => 'Pas de données';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';
}
