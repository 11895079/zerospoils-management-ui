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
