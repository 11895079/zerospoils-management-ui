// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZeroSpoils';

  @override
  String get appDescription => 'Reduce household food waste';

  @override
  String get navigationInventory => 'Inventory';

  @override
  String get navigationShoppingList => 'Shopping';

  @override
  String get navigationShoppingHistory => 'History';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get screenTitleInventory => 'Inventory';

  @override
  String get screenTitleShoppingList => 'Shopping List';

  @override
  String get screenTitleShoppingHistory => 'Shopping History';

  @override
  String get screenTitleSettings => 'Settings';

  @override
  String get screenTitleItemDetail => 'Item Details';

  @override
  String get screenTitleAddItem => 'Add Item';

  @override
  String get screenTitleEditItem => 'Edit Item';

  @override
  String get screenTitleReceiptBatch => 'Shopping Batch';

  @override
  String get screenTitleProgress => 'Progress';

  @override
  String get screenTitleOnboarding => 'Welcome to ZeroSpoils';

  @override
  String get buttonAdd => 'Add';

  @override
  String get buttonEdit => 'Edit';

  @override
  String get buttonDelete => 'Delete';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonClose => 'Close';

  @override
  String get buttonConfirm => 'Confirm';

  @override
  String get buttonNext => 'Next';

  @override
  String get buttonBack => 'Back';

  @override
  String get buttonYes => 'Yes';

  @override
  String get buttonNo => 'No';

  @override
  String get buttonMaybeLater => 'Maybe Later';

  @override
  String get buttonEnable => 'Enable';

  @override
  String get buttonDone => 'Done';

  @override
  String get buttonContinue => 'Continue';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonSearch => 'Search';

  @override
  String get buttonFilter => 'Filter';

  @override
  String get buttonSort => 'Sort';

  @override
  String get buttonClear => 'Clear';

  @override
  String get buttonExport => 'Export';

  @override
  String get buttonImport => 'Import';

  @override
  String get labelCategory => 'Category';

  @override
  String get labelLocation => 'Location';

  @override
  String get labelExpiry => 'Expiry Date';

  @override
  String get labelQuantity => 'Quantity';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelPrice => 'Price';

  @override
  String get labelStore => 'Store';

  @override
  String get labelDate => 'Date';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelPaymentMethod => 'Payment Method';

  @override
  String get labelBarcode => 'Barcode';

  @override
  String get labelSearch => 'Search';

  @override
  String get labelFilter => 'Filter';

  @override
  String get labelAll => 'All';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusConsumed => 'Consumed';

  @override
  String get statusWasted => 'Wasted';

  @override
  String get statusPrepared => 'Prepared';

  @override
  String get statusFresh => 'Fresh';

  @override
  String get statusPackaged => 'Packaged';

  @override
  String get categoryProduce => 'Produce';

  @override
  String get categoryDairy => 'Dairy';

  @override
  String get categoryMeat => 'Meat';

  @override
  String get categoryFrozen => 'Frozen';

  @override
  String get categoryPantry => 'Pantry';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categoryOther => 'Other';

  @override
  String get locationFridge => 'Fridge';

  @override
  String get locationFreezer => 'Freezer';

  @override
  String get locationPantry => 'Pantry';

  @override
  String get locationCounter => 'Counter';

  @override
  String get locationOther => 'Other';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodDebit => 'Debit';

  @override
  String get paymentMethodCredit => 'Credit';

  @override
  String get paymentMethodMobile => 'Mobile Payment';

  @override
  String get errorUnableToLoadItems => 'Unable to load items';

  @override
  String get errorNoItemsFound => 'No items found';

  @override
  String get errorUnexpectedError => 'An unexpected error occurred';

  @override
  String get errorPermissionDenied => 'Permission denied';

  @override
  String get errorCameraPermissionRequired => 'Camera permission is required';

  @override
  String get errorStoragePermissionRequired => 'Storage permission is required';

  @override
  String get errorInvalidInput => 'Invalid input';

  @override
  String get errorItemNotFound => 'Item not found';

  @override
  String get errorDuplicateItem => 'Item already exists';

  @override
  String get messageEmptyInventory =>
      'No items in your inventory yet. Add one to get started.';

  @override
  String get messageEmptyShoppingList =>
      'Your shopping list is empty. Add items you need to buy.';

  @override
  String get messageNoResults => 'No results found';

  @override
  String get messageConfirmDelete =>
      'Are you sure you want to delete this item?';

  @override
  String get messageConfirmDeleteAll =>
      'Are you sure you want to delete all items?';

  @override
  String get messageSaveSuccess => 'Saved successfully';

  @override
  String get messageDeleteSuccess => 'Deleted successfully';

  @override
  String get messageDuplicatePreventedMessage =>
      'This item is already in your inventory';

  @override
  String get dialogTitleCameraPermission => 'Enable Camera';

  @override
  String get dialogMessageCameraPermission =>
      'ZeroSpoils needs camera access to scan barcodes and capture receipts.';

  @override
  String get dialogTitleConfirmAction => 'Confirm Action';

  @override
  String get dialogTitleDeleteConfirmation => 'Delete Item';

  @override
  String get toastItemAdded => 'Item added';

  @override
  String get toastItemUpdated => 'Item updated';

  @override
  String get toastItemDeleted => 'Item deleted';

  @override
  String get toastCopiedToClipboard => 'Copied to clipboard';

  @override
  String get toastErrorOccurred => 'An error occurred';

  @override
  String get hintSearchItems => 'Search items...';

  @override
  String get hintItemName => 'Item name';

  @override
  String get hintNotes => 'Add notes...';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsFeedback => 'Feedback & Sounds';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacy => 'Privacy & Data';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsReferenceDataRegion => 'Reference Data Region';

  @override
  String get settingsReferenceDataLanguage => 'Reference Data Language';

  @override
  String get settingsDateFormat => 'Date Format';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsExportData => 'Export Data';

  @override
  String get settingsImportData => 'Import Data';

  @override
  String get settingsDeleteAllData => 'Delete All Data';

  @override
  String get settingsSectionAccountData => 'ACCOUNT & DATA';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsDataSync => 'Data Sync';

  @override
  String get settingsDemoMode => 'Demo Mode';

  @override
  String get settingsSoon => 'Soon';

  @override
  String get settingsDemoModeEnabled => 'Demo mode enabled';

  @override
  String get settingsDemoModeDisabled => 'Demo mode disabled';

  @override
  String get settingsShareAnonymousUsageData => 'Share Anonymous Usage Data';

  @override
  String get settingsShareAnonymousUsageDataSubtitle =>
      'Grants permission for cloud export when available (not yet available)';

  @override
  String get settingsCloudAnalyticsExport => 'Cloud Analytics Export';

  @override
  String get settingsCloudAnalyticsExportSubtitle =>
      'Send telemetry data to cloud';

  @override
  String get settingsExportSubtitle => 'Download your inventory and settings';

  @override
  String get settingsImportSubtitle => 'Import a backup file';

  @override
  String get settingsReferenceDataPacks => 'Reference Data Packs';

  @override
  String get settingsDeleteAllDataSubtitle =>
      'Permanently remove all data (irreversible)';

  @override
  String get settingsSectionPreferences => 'PREFERENCES';

  @override
  String get settingsMealPlanning => 'Meal Planning';

  @override
  String get settingsSectionSupportFeedback => 'SUPPORT & FEEDBACK';

  @override
  String get settingsHelpFaq => 'Help & FAQ';

  @override
  String get settingsHelpCenterComingSoon => 'Help center coming soon';

  @override
  String get settingsSendFeedback => 'Send Feedback';

  @override
  String get settingsRateApp => 'Rate App';

  @override
  String get settingsThanksForSupport => 'Thanks for the support!';

  @override
  String get settingsViewTutorial => 'View Tutorial';

  @override
  String get settingsSectionLegal => 'LEGAL';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicyComingSoon => 'Privacy policy coming soon';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsTermsComingSoon => 'Terms coming soon';

  @override
  String get settingsAboutSubtitle => 'ZeroSpoils v1.0.0';

  @override
  String get settingsAboutSnackMessage => 'ZeroSpoils helps reduce food waste.';

  @override
  String get settingsHapticIntensityLight => 'Light';

  @override
  String get settingsHapticIntensityMedium => 'Medium';

  @override
  String get settingsHapticIntensityHeavy => 'Heavy';

  @override
  String settingsLeadTimeDays(int days) {
    return '$days days';
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
  String get feedbackHapticFeedback => 'Haptic Feedback';

  @override
  String get feedbackHapticFeedbackDescription =>
      'Enable vibration on user interactions';

  @override
  String get feedbackAudioFeedback => 'Audio Feedback';

  @override
  String get feedbackAudioFeedbackDescription =>
      'Enable sound effects on interactions';

  @override
  String get feedbackOcrBarcodeSuccess => 'Barcode Scan Success';

  @override
  String get feedbackOcrBarcodeSuccessDescription =>
      'Vibrate and beep when barcode is recognized';

  @override
  String get feedbackOcrExpirySuccess => 'Expiry Date Recognition';

  @override
  String get feedbackOcrExpirySuccessDescription =>
      'Vibrate and beep when expiry date is captured';

  @override
  String get feedbackOcrReceiptSuccess => 'Receipt Recognition';

  @override
  String get feedbackOcrReceiptSuccessDescription =>
      'Vibrate and beep when receipt items are extracted';

  @override
  String get feedbackOcrProduceSuccess => 'Produce Label Recognition';

  @override
  String get feedbackOcrProduceSuccessDescription =>
      'Vibrate and beep when produce sticker is read';

  @override
  String get feedbackBeepVolume => 'Beep Volume';

  @override
  String get feedbackBeepVolumeDescription =>
      'Adjust POS-style beep volume (0-100%)';

  @override
  String get feedbackHapticIntensity => 'Haptic Intensity';

  @override
  String get feedbackHapticIntensityDescription =>
      'Adjust vibration intensity (Light, Medium, Heavy)';

  @override
  String get remindersTurnedOn => 'Reminders turned on';

  @override
  String get remindersTurnedOff => 'Reminders turned off';

  @override
  String get remindersLeadTime => 'Lead Time';

  @override
  String get remindersSound => 'Sound';

  @override
  String get remindersVibration => 'Vibration';

  @override
  String get shoppingBatchCapture => 'Shopping Batch';

  @override
  String get shoppingBatchStore => 'Store';

  @override
  String get shoppingBatchDate => 'Date';

  @override
  String get shoppingBatchCost => 'Total Cost';

  @override
  String get shoppingBatchReceipt => 'Receipt Photo';

  @override
  String get shoppingBatchLinkedItems => 'Linked Items';

  @override
  String get shoppingBatchTakePhoto => 'Take Photo';

  @override
  String get shoppingBatchChoosePhoto => 'Choose from Library';

  @override
  String get shoppingBatchLinkItems => 'Link Items';

  @override
  String get shoppingBatchReview => 'Review';

  @override
  String get privacyExport => 'Export your data as CSV or JSON';

  @override
  String get privacyDelete => 'Delete all data permanently';

  @override
  String get privacyDeleteWarning => 'This action cannot be undone';

  @override
  String get aboutTitle => 'About ZeroSpoils';

  @override
  String get aboutDescription =>
      'A simple app to help you reduce food waste at home';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutDeveloper => 'Developed with ❤️';

  @override
  String get expiryTodayLabel => 'Expires today';

  @override
  String get expiringSoonLabel => 'Expiring soon';

  @override
  String expiryThresholdDays(int days) {
    return 'within $days days';
  }

  @override
  String daysUntilExpiry(int days) {
    return '$days days left';
  }

  @override
  String itemQuantityFormat(String quantity) {
    return 'Qty: $quantity';
  }

  @override
  String formattedPrice(String currency, double amount) {
    return '$currency$amount';
  }

  @override
  String get noData => 'No data';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';
}
