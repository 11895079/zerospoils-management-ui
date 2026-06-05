import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr', 'CA'),
    Locale('es'),
    Locale('de'),
    Locale('pt'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ZeroSpoils'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Reduce household food waste'**
  String get appDescription;

  /// No description provided for @navigationInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navigationInventory;

  /// No description provided for @navigationShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navigationShoppingList;

  /// No description provided for @navigationShoppingHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navigationShoppingHistory;

  /// No description provided for @navigationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSettings;

  /// No description provided for @navigationOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get navigationOnboarding;

  /// No description provided for @screenTitleInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get screenTitleInventory;

  /// No description provided for @screenTitleShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get screenTitleShoppingList;

  /// No description provided for @screenTitleShoppingHistory.
  ///
  /// In en, this message translates to:
  /// **'Shopping History'**
  String get screenTitleShoppingHistory;

  /// No description provided for @screenTitleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get screenTitleSettings;

  /// No description provided for @screenTitleItemDetail.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get screenTitleItemDetail;

  /// No description provided for @screenTitleAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get screenTitleAddItem;

  /// No description provided for @screenTitleEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get screenTitleEditItem;

  /// No description provided for @screenTitleReceiptBatch.
  ///
  /// In en, this message translates to:
  /// **'Shopping Batch'**
  String get screenTitleReceiptBatch;

  /// No description provided for @screenTitleProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get screenTitleProgress;

  /// No description provided for @screenTitleOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ZeroSpoils'**
  String get screenTitleOnboarding;

  /// No description provided for @buttonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get buttonAdd;

  /// No description provided for @buttonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get buttonEdit;

  /// No description provided for @buttonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get buttonClose;

  /// No description provided for @buttonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get buttonConfirm;

  /// No description provided for @buttonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get buttonNext;

  /// No description provided for @buttonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get buttonBack;

  /// No description provided for @buttonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get buttonYes;

  /// No description provided for @buttonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get buttonNo;

  /// No description provided for @buttonMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get buttonMaybeLater;

  /// No description provided for @buttonEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get buttonEnable;

  /// No description provided for @buttonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get buttonDone;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @buttonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// No description provided for @buttonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get buttonSearch;

  /// No description provided for @buttonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get buttonFilter;

  /// No description provided for @buttonSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get buttonSort;

  /// No description provided for @buttonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get buttonClear;

  /// No description provided for @buttonExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get buttonExport;

  /// No description provided for @buttonImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get buttonImport;

  /// No description provided for @labelCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labelCategory;

  /// No description provided for @labelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get labelLocation;

  /// No description provided for @labelExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get labelExpiry;

  /// No description provided for @labelQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get labelQuantity;

  /// No description provided for @labelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// No description provided for @labelPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get labelPrice;

  /// No description provided for @labelStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get labelStore;

  /// No description provided for @labelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @labelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get labelNotes;

  /// No description provided for @labelPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get labelPaymentMethod;

  /// No description provided for @labelBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get labelBarcode;

  /// No description provided for @labelSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get labelSearch;

  /// No description provided for @labelFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get labelFilter;

  /// No description provided for @labelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labelAll;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get statusConsumed;

  /// No description provided for @statusWasted.
  ///
  /// In en, this message translates to:
  /// **'Wasted'**
  String get statusWasted;

  /// No description provided for @statusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get statusPrepared;

  /// No description provided for @statusFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get statusFresh;

  /// No description provided for @statusPackaged.
  ///
  /// In en, this message translates to:
  /// **'Packaged'**
  String get statusPackaged;

  /// No description provided for @categoryProduce.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get categoryProduce;

  /// No description provided for @categoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get categoryDairy;

  /// No description provided for @categoryMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get categoryMeat;

  /// No description provided for @categoryGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get categoryGrains;

  /// No description provided for @categoryFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get categoryFrozen;

  /// No description provided for @categoryPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get categoryPantry;

  /// No description provided for @categoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @itemTypeRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get itemTypeRaw;

  /// No description provided for @itemTypePrepared.
  ///
  /// In en, this message translates to:
  /// **'Cooked'**
  String get itemTypePrepared;

  /// No description provided for @itemTypePackaged.
  ///
  /// In en, this message translates to:
  /// **'Packaged'**
  String get itemTypePackaged;

  /// No description provided for @locationFridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get locationFridge;

  /// No description provided for @locationFreezer.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get locationFreezer;

  /// No description provided for @locationPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get locationPantry;

  /// No description provided for @locationCounter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get locationCounter;

  /// No description provided for @locationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get locationOther;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get paymentMethodDebit;

  /// No description provided for @paymentMethodCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get paymentMethodCredit;

  /// No description provided for @paymentMethodMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Payment'**
  String get paymentMethodMobile;

  /// No description provided for @errorUnableToLoadItems.
  ///
  /// In en, this message translates to:
  /// **'Unable to load items'**
  String get errorUnableToLoadItems;

  /// No description provided for @errorNoItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get errorNoItemsFound;

  /// No description provided for @errorUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get errorUnexpectedError;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get errorPermissionDenied;

  /// No description provided for @errorCameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get errorCameraPermissionRequired;

  /// No description provided for @errorStoragePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get errorStoragePermissionRequired;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get errorInvalidInput;

  /// No description provided for @errorItemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Item not found'**
  String get errorItemNotFound;

  /// No description provided for @errorDuplicateItem.
  ///
  /// In en, this message translates to:
  /// **'Item already exists'**
  String get errorDuplicateItem;

  /// No description provided for @messageEmptyInventory.
  ///
  /// In en, this message translates to:
  /// **'No items in your inventory yet. Add one to get started.'**
  String get messageEmptyInventory;

  /// No description provided for @messageEmptyShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty. Add items you need to buy.'**
  String get messageEmptyShoppingList;

  /// No description provided for @messageNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get messageNoResults;

  /// No description provided for @messageConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get messageConfirmDelete;

  /// No description provided for @messageConfirmDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all items?'**
  String get messageConfirmDeleteAll;

  /// No description provided for @messageSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get messageSaveSuccess;

  /// No description provided for @messageDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get messageDeleteSuccess;

  /// No description provided for @messageDuplicatePreventedMessage.
  ///
  /// In en, this message translates to:
  /// **'This item is already in your inventory'**
  String get messageDuplicatePreventedMessage;

  /// No description provided for @dialogTitleCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Enable Camera'**
  String get dialogTitleCameraPermission;

  /// No description provided for @dialogMessageCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'ZeroSpoils needs camera access to scan barcodes and capture receipts.'**
  String get dialogMessageCameraPermission;

  /// No description provided for @dialogTitleConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get dialogTitleConfirmAction;

  /// No description provided for @dialogTitleDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get dialogTitleDeleteConfirmation;

  /// No description provided for @toastItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added'**
  String get toastItemAdded;

  /// No description provided for @toastItemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated'**
  String get toastItemUpdated;

  /// No description provided for @toastItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get toastItemDeleted;

  /// No description provided for @toastCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get toastCopiedToClipboard;

  /// No description provided for @toastErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get toastErrorOccurred;

  /// No description provided for @hintSearchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get hintSearchItems;

  /// No description provided for @hintItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get hintItemName;

  /// No description provided for @hintNotes.
  ///
  /// In en, this message translates to:
  /// **'Add notes...'**
  String get hintNotes;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Sounds'**
  String get settingsFeedback;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get settingsPrivacy;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @itemFormSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get itemFormSelectCategory;

  /// No description provided for @drawerHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get drawerHeaderSubtitle;

  /// No description provided for @zestoDismissLabel.
  ///
  /// In en, this message translates to:
  /// **'Dismiss Zesto'**
  String get zestoDismissLabel;

  /// No description provided for @zestoSaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Zesto says: {message}'**
  String zestoSaysLabel(String message);

  /// No description provided for @settingsReferenceDataRegion.
  ///
  /// In en, this message translates to:
  /// **'Reference Data Region'**
  String get settingsReferenceDataRegion;

  /// No description provided for @settingsReferenceDataLanguage.
  ///
  /// In en, this message translates to:
  /// **'Reference Data Language'**
  String get settingsReferenceDataLanguage;

  /// No description provided for @settingsDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get settingsDateFormat;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settingsExportData;

  /// No description provided for @settingsImportData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImportData;

  /// No description provided for @settingsDeleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get settingsDeleteAllData;

  /// No description provided for @settingsSectionAccountData.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & DATA'**
  String get settingsSectionAccountData;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsDataSync.
  ///
  /// In en, this message translates to:
  /// **'Data Sync'**
  String get settingsDataSync;

  /// No description provided for @settingsDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get settingsDemoMode;

  /// No description provided for @settingsSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get settingsSoon;

  /// No description provided for @settingsDemoModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Demo mode enabled'**
  String get settingsDemoModeEnabled;

  /// No description provided for @settingsDemoModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Demo mode disabled'**
  String get settingsDemoModeDisabled;

  /// No description provided for @settingsShareAnonymousUsageData.
  ///
  /// In en, this message translates to:
  /// **'Share Anonymous Usage Data'**
  String get settingsShareAnonymousUsageData;

  /// No description provided for @settingsShareAnonymousUsageDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grants permission for cloud export when available (not yet available)'**
  String get settingsShareAnonymousUsageDataSubtitle;

  /// No description provided for @settingsCloudAnalyticsExport.
  ///
  /// In en, this message translates to:
  /// **'Cloud Analytics Export'**
  String get settingsCloudAnalyticsExport;

  /// No description provided for @settingsCloudAnalyticsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send telemetry data to cloud'**
  String get settingsCloudAnalyticsExportSubtitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download your inventory and settings'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import a backup file'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsReferenceDataPacks.
  ///
  /// In en, this message translates to:
  /// **'Reference Data Packs'**
  String get settingsReferenceDataPacks;

  /// No description provided for @settingsDeleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove all data (irreversible)'**
  String get settingsDeleteAllDataSubtitle;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsMealPlanning.
  ///
  /// In en, this message translates to:
  /// **'Meal Planning'**
  String get settingsMealPlanning;

  /// No description provided for @settingsSectionSupportFeedback.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT & FEEDBACK'**
  String get settingsSectionSupportFeedback;

  /// No description provided for @settingsHelpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get settingsHelpFaq;

  /// No description provided for @settingsHelpCenterComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help center coming soon'**
  String get settingsHelpCenterComingSoon;

  /// No description provided for @settingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settingsSendFeedback;

  /// No description provided for @feedbackDrawerBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackDrawerBarrierLabel;

  /// No description provided for @feedbackDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackDrawerTitle;

  /// No description provided for @feedbackDrawerCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close feedback'**
  String get feedbackDrawerCloseTooltip;

  /// No description provided for @feedbackDrawerIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us what is working or broken. We include app metadata automatically.'**
  String get feedbackDrawerIntro;

  /// No description provided for @feedbackDrawerCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get feedbackDrawerCategoryLabel;

  /// No description provided for @feedbackCategoryBugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug report'**
  String get feedbackCategoryBugReport;

  /// No description provided for @feedbackCategoryFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get feedbackCategoryFeatureRequest;

  /// No description provided for @feedbackCategoryUxFeedback.
  ///
  /// In en, this message translates to:
  /// **'UX feedback'**
  String get feedbackCategoryUxFeedback;

  /// No description provided for @feedbackCategoryDarkModeReadability.
  ///
  /// In en, this message translates to:
  /// **'Dark mode readability'**
  String get feedbackCategoryDarkModeReadability;

  /// No description provided for @feedbackCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCategoryOther;

  /// No description provided for @feedbackDrawerMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get feedbackDrawerMessageLabel;

  /// No description provided for @feedbackDrawerMessageHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? What should we improve?'**
  String get feedbackDrawerMessageHint;

  /// No description provided for @feedbackDrawerMessageValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter feedback before submitting.'**
  String get feedbackDrawerMessageValidation;

  /// No description provided for @feedbackDrawerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get feedbackDrawerEmailLabel;

  /// No description provided for @feedbackDrawerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get feedbackDrawerEmailHint;

  /// No description provided for @feedbackDrawerSourceLocale.
  ///
  /// In en, this message translates to:
  /// **'Source: {source} • Locale: {locale}'**
  String feedbackDrawerSourceLocale(String source, String locale);

  /// No description provided for @feedbackDrawerSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get feedbackDrawerSubmitting;

  /// No description provided for @feedbackDrawerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackDrawerSubmit;

  /// No description provided for @feedbackDrawerSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent. Thank you.'**
  String get feedbackDrawerSent;

  /// No description provided for @feedbackDrawerSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before sending feedback.'**
  String get feedbackDrawerSignInRequired;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get settingsRateApp;

  /// No description provided for @settingsThanksForSupport.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the support!'**
  String get settingsThanksForSupport;

  /// No description provided for @settingsViewTutorial.
  ///
  /// In en, this message translates to:
  /// **'View Tutorial'**
  String get settingsViewTutorial;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get settingsSectionLegal;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicyComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy coming soon'**
  String get settingsPrivacyPolicyComingSoon;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsTermsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Terms coming soon'**
  String get settingsTermsComingSoon;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ZeroSpoils v1.0.0'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAboutSnackMessage.
  ///
  /// In en, this message translates to:
  /// **'ZeroSpoils helps reduce food waste.'**
  String get settingsAboutSnackMessage;

  /// No description provided for @settingsHapticIntensityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsHapticIntensityLight;

  /// No description provided for @settingsHapticIntensityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsHapticIntensityMedium;

  /// No description provided for @settingsHapticIntensityHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get settingsHapticIntensityHeavy;

  /// No description provided for @settingsLeadTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String settingsLeadTimeDays(int days);

  /// No description provided for @settingsChooseExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose export format:'**
  String get settingsChooseExportFormat;

  /// No description provided for @settingsExportJsonCompleteBackup.
  ///
  /// In en, this message translates to:
  /// **'JSON (Complete Backup)'**
  String get settingsExportJsonCompleteBackup;

  /// No description provided for @settingsExportCsvInventoryOnly.
  ///
  /// In en, this message translates to:
  /// **'CSV (Inventory Only)'**
  String get settingsExportCsvInventoryOnly;

  /// No description provided for @settingsSaveExportAs.
  ///
  /// In en, this message translates to:
  /// **'Save {format} export as'**
  String settingsSaveExportAs(String format);

  /// No description provided for @settingsExportSavedTo.
  ///
  /// In en, this message translates to:
  /// **'{format} export saved to: {path}'**
  String settingsExportSavedTo(String format, String path);

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsRestoreWillRestoreItems.
  ///
  /// In en, this message translates to:
  /// **'This will restore {count} items.'**
  String settingsRestoreWillRestoreItems(int count);

  /// No description provided for @settingsRestoreMigrationRequiredFromVersion.
  ///
  /// In en, this message translates to:
  /// **'Migration required from version {version}'**
  String settingsRestoreMigrationRequiredFromVersion(String version);

  /// No description provided for @settingsRestoreReplaceAllDataPrompt.
  ///
  /// In en, this message translates to:
  /// **'All existing data will be replaced. Continue?'**
  String get settingsRestoreReplaceAllDataPrompt;

  /// No description provided for @settingsRestoreCompleted.
  ///
  /// In en, this message translates to:
  /// **'Restored {items} items'**
  String settingsRestoreCompleted(int items);

  /// No description provided for @settingsRestoreCompletedWithMigrations.
  ///
  /// In en, this message translates to:
  /// **'Restored {items} items ({migrations} migrations applied)'**
  String settingsRestoreCompletedWithMigrations(int items, int migrations);

  /// No description provided for @settingsRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String settingsRestoreFailed(String error);

  /// No description provided for @settingsDeleteDataPromptIntro.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL your data including:'**
  String get settingsDeleteDataPromptIntro;

  /// No description provided for @settingsDeleteDataBulletInventoryItems.
  ///
  /// In en, this message translates to:
  /// **'Inventory items'**
  String get settingsDeleteDataBulletInventoryItems;

  /// No description provided for @settingsDeleteDataBulletShoppingLists.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists'**
  String get settingsDeleteDataBulletShoppingLists;

  /// No description provided for @settingsDeleteDataBulletWasteTrackingData.
  ///
  /// In en, this message translates to:
  /// **'Waste tracking data'**
  String get settingsDeleteDataBulletWasteTrackingData;

  /// No description provided for @settingsDeleteDataBulletAllSettingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'All settings and preferences'**
  String get settingsDeleteDataBulletAllSettingsPreferences;

  /// No description provided for @settingsDeleteDataTypeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"DELETE\" to confirm:'**
  String get settingsDeleteDataTypeDeleteConfirm;

  /// No description provided for @settingsDeleteDataHintTypeDelete.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE'**
  String get settingsDeleteDataHintTypeDelete;

  /// No description provided for @settingsDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get settingsDeletePermanently;

  /// No description provided for @settingsDeleteAllDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data permanently deleted'**
  String get settingsDeleteAllDataSuccess;

  /// No description provided for @settingsDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed: {error}'**
  String settingsDeletionFailed(String error);

  /// No description provided for @settingsReferencePackBundledDefaultOnly.
  ///
  /// In en, this message translates to:
  /// **'Bundled default only'**
  String get settingsReferencePackBundledDefaultOnly;

  /// No description provided for @settingsReferencePackNeverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Never updated'**
  String get settingsReferencePackNeverUpdated;

  /// No description provided for @settingsReferencePackDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Active barcode pack: {version} ({records} records)\nLast update: {updatedAt}\nManifest source: Firebase Remote Config ({manifestUrl})'**
  String settingsReferencePackDiagnostics(
    String version,
    int records,
    String updatedAt,
    String manifestUrl,
  );

  /// No description provided for @settingsAccountNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settingsAccountNotSignedIn;

  /// No description provided for @settingsAccountAnonymousSession.
  ///
  /// In en, this message translates to:
  /// **'Anonymous session'**
  String get settingsAccountAnonymousSession;

  /// No description provided for @settingsAccountSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get settingsAccountSignedIn;

  /// No description provided for @settingsAuthServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Authentication service is unavailable.'**
  String get settingsAuthServiceUnavailable;

  /// No description provided for @settingsAccountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String settingsAccountSignedInAs(String email);

  /// No description provided for @settingsAccountSignOutHint.
  ///
  /// In en, this message translates to:
  /// **'You can sign out to return to an anonymous session.'**
  String get settingsAccountSignOutHint;

  /// No description provided for @settingsAccountUpgradeAnonymousHint.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your anonymous session to an email account.'**
  String get settingsAccountUpgradeAnonymousHint;

  /// No description provided for @settingsAccountSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email to submit authenticated feedback.'**
  String get settingsAccountSignInHint;

  /// No description provided for @settingsLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsLabelEmail;

  /// No description provided for @settingsLabelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsLabelPassword;

  /// No description provided for @settingsPasswordMin6Hint.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get settingsPasswordMin6Hint;

  /// No description provided for @settingsForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get settingsForgotPassword;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get settingsSignOutSuccess;

  /// No description provided for @settingsCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get settingsCreateAccount;

  /// No description provided for @settingsCreateAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get settingsCreateAccountSuccess;

  /// No description provided for @settingsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settingsSignIn;

  /// No description provided for @settingsSignInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get settingsSignInSuccess;

  /// No description provided for @settingsSignInWithGoogleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get settingsSignInWithGoogleSuccess;

  /// No description provided for @settingsContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get settingsContinueWithGoogle;

  /// No description provided for @settingsContinueWithAppleSoon.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple (Soon)'**
  String get settingsContinueWithAppleSoon;

  /// No description provided for @settingsAppleSignInSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In will be enabled after email and Google sign-in are fully verified on-device.'**
  String get settingsAppleSignInSoonMessage;

  /// No description provided for @settingsEnterAccountEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email first.'**
  String get settingsEnterAccountEmailFirst;

  /// No description provided for @settingsPasswordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}.'**
  String settingsPasswordResetEmailSent(String email);

  /// No description provided for @settingsPasswordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start password reset.'**
  String get settingsPasswordResetFailed;

  /// No description provided for @settingsEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get settingsEnterValidEmail;

  /// No description provided for @settingsPasswordMin6Error.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get settingsPasswordMin6Error;

  /// No description provided for @settingsAuthenticationFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Try again.'**
  String get settingsAuthenticationFailedTryAgain;

  /// No description provided for @settingsAuthErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get settingsAuthErrorUserNotFound;

  /// No description provided for @settingsAuthErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get settingsAuthErrorInvalidCredentials;

  /// No description provided for @settingsAuthErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get settingsAuthErrorEmailAlreadyInUse;

  /// No description provided for @settingsAuthErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Email format is invalid.'**
  String get settingsAuthErrorInvalidEmail;

  /// No description provided for @settingsAuthErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Enable Email/Password in Firebase Authentication settings.'**
  String get settingsAuthErrorOperationNotAllowed;

  /// No description provided for @settingsAuthErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get settingsAuthErrorWeakPassword;

  /// No description provided for @settingsAuthErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed ({code}).'**
  String settingsAuthErrorUnknown(String code);

  /// No description provided for @feedbackHapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get feedbackHapticFeedback;

  /// No description provided for @feedbackHapticFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable vibration on user interactions'**
  String get feedbackHapticFeedbackDescription;

  /// No description provided for @feedbackAudioFeedback.
  ///
  /// In en, this message translates to:
  /// **'Audio Feedback'**
  String get feedbackAudioFeedback;

  /// No description provided for @feedbackAudioFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable sound effects on interactions'**
  String get feedbackAudioFeedbackDescription;

  /// No description provided for @feedbackOcrBarcodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Barcode Scan Success'**
  String get feedbackOcrBarcodeSuccess;

  /// No description provided for @feedbackOcrBarcodeSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate and beep when barcode is recognized'**
  String get feedbackOcrBarcodeSuccessDescription;

  /// No description provided for @feedbackOcrExpirySuccess.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date Recognition'**
  String get feedbackOcrExpirySuccess;

  /// No description provided for @feedbackOcrExpirySuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate and beep when expiry date is captured'**
  String get feedbackOcrExpirySuccessDescription;

  /// No description provided for @feedbackOcrReceiptSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt Recognition'**
  String get feedbackOcrReceiptSuccess;

  /// No description provided for @feedbackOcrReceiptSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate and beep when receipt items are extracted'**
  String get feedbackOcrReceiptSuccessDescription;

  /// No description provided for @feedbackOcrProduceSuccess.
  ///
  /// In en, this message translates to:
  /// **'Produce Label Recognition'**
  String get feedbackOcrProduceSuccess;

  /// No description provided for @feedbackOcrProduceSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate and beep when produce sticker is read'**
  String get feedbackOcrProduceSuccessDescription;

  /// No description provided for @feedbackBeepVolume.
  ///
  /// In en, this message translates to:
  /// **'Beep Volume'**
  String get feedbackBeepVolume;

  /// No description provided for @feedbackBeepVolumeDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust POS-style beep volume (0-100%)'**
  String get feedbackBeepVolumeDescription;

  /// No description provided for @feedbackHapticIntensity.
  ///
  /// In en, this message translates to:
  /// **'Haptic Intensity'**
  String get feedbackHapticIntensity;

  /// No description provided for @feedbackHapticIntensityDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust vibration intensity (Light, Medium, Heavy)'**
  String get feedbackHapticIntensityDescription;

  /// No description provided for @remindersTurnedOn.
  ///
  /// In en, this message translates to:
  /// **'Reminders turned on'**
  String get remindersTurnedOn;

  /// No description provided for @remindersTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Reminders turned off'**
  String get remindersTurnedOff;

  /// No description provided for @remindersLeadTime.
  ///
  /// In en, this message translates to:
  /// **'Lead Time'**
  String get remindersLeadTime;

  /// No description provided for @remindersSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get remindersSound;

  /// No description provided for @remindersVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get remindersVibration;

  /// No description provided for @shoppingBatchCapture.
  ///
  /// In en, this message translates to:
  /// **'Shopping Batch'**
  String get shoppingBatchCapture;

  /// No description provided for @shoppingBatchStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get shoppingBatchStore;

  /// No description provided for @shoppingBatchDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get shoppingBatchDate;

  /// No description provided for @shoppingBatchCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get shoppingBatchCost;

  /// No description provided for @shoppingBatchReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt Photo'**
  String get shoppingBatchReceipt;

  /// No description provided for @shoppingBatchLinkedItems.
  ///
  /// In en, this message translates to:
  /// **'Linked Items'**
  String get shoppingBatchLinkedItems;

  /// No description provided for @shoppingBatchTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get shoppingBatchTakePhoto;

  /// No description provided for @shoppingBatchChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get shoppingBatchChoosePhoto;

  /// No description provided for @shoppingBatchLinkItems.
  ///
  /// In en, this message translates to:
  /// **'Link Items'**
  String get shoppingBatchLinkItems;

  /// No description provided for @shoppingBatchReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get shoppingBatchReview;

  /// No description provided for @privacyExport.
  ///
  /// In en, this message translates to:
  /// **'Export your data as CSV or JSON'**
  String get privacyExport;

  /// No description provided for @privacyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete all data permanently'**
  String get privacyDelete;

  /// No description provided for @privacyDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get privacyDeleteWarning;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About ZeroSpoils'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A simple app to help you reduce food waste at home'**
  String get aboutDescription;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developed with ❤️'**
  String get aboutDeveloper;

  /// No description provided for @expiryTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiryTodayLabel;

  /// No description provided for @expiringSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoonLabel;

  /// No description provided for @expiryThresholdDays.
  ///
  /// In en, this message translates to:
  /// **'within {days} days'**
  String expiryThresholdDays(int days);

  /// No description provided for @daysUntilExpiry.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysUntilExpiry(int days);

  /// No description provided for @itemQuantityFormat.
  ///
  /// In en, this message translates to:
  /// **'Qty: {quantity}'**
  String itemQuantityFormat(String quantity);

  /// No description provided for @formattedPrice.
  ///
  /// In en, this message translates to:
  /// **'{currency}{amount}'**
  String formattedPrice(String currency, double amount);

  /// No description provided for @inventoryFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get inventoryFiltersTitle;

  /// No description provided for @inventoryFilterAddedDate.
  ///
  /// In en, this message translates to:
  /// **'Added date'**
  String get inventoryFilterAddedDate;

  /// No description provided for @inventoryFilterFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get inventoryFilterFrom;

  /// No description provided for @inventoryFilterTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get inventoryFilterTo;

  /// No description provided for @inventoryFilterPreparedOnly.
  ///
  /// In en, this message translates to:
  /// **'Prepared only'**
  String get inventoryFilterPreparedOnly;

  /// No description provided for @inventoryFilterPreparedOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Show prepared items only'**
  String get inventoryFilterPreparedOnlyHint;

  /// No description provided for @inventoryFilterExpiringSoonOnly.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon only'**
  String get inventoryFilterExpiringSoonOnly;

  /// No description provided for @inventoryFilterExpiringSoonOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Show items expiring within the next 3 days'**
  String get inventoryFilterExpiringSoonOnlyHint;

  /// No description provided for @inventoryFilterBatchLinkedOnly.
  ///
  /// In en, this message translates to:
  /// **'Batch-linked only'**
  String get inventoryFilterBatchLinkedOnly;

  /// No description provided for @inventoryFilterBatchLinkedOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Show only items linked to shopping batches'**
  String get inventoryFilterBatchLinkedOnlyHint;

  /// No description provided for @inventoryFilterHideConsumedItems.
  ///
  /// In en, this message translates to:
  /// **'Hide consumed items'**
  String get inventoryFilterHideConsumedItems;

  /// No description provided for @inventoryFilterHideConsumedItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Hide items marked as consumed or wasted'**
  String get inventoryFilterHideConsumedItemsHint;

  /// No description provided for @inventoryFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get inventoryFilterReset;

  /// No description provided for @inventoryFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get inventoryFilterApply;

  /// No description provided for @inventoryBatchReceiptButton.
  ///
  /// In en, this message translates to:
  /// **'Batch receipt'**
  String get inventoryBatchReceiptButton;

  /// No description provided for @inventoryDemoModeHint.
  ///
  /// In en, this message translates to:
  /// **'Showing sample items. Turn off in Settings to use real data.'**
  String get inventoryDemoModeHint;

  /// No description provided for @inventoryStreakDays.
  ///
  /// In en, this message translates to:
  /// **'🔥 {days}-day streak'**
  String inventoryStreakDays(int days);

  /// No description provided for @inventoryLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Level up'**
  String get inventoryLevelUp;

  /// No description provided for @inventoryNoWasteWeek.
  ///
  /// In en, this message translates to:
  /// **'No Waste Week'**
  String get inventoryNoWasteWeek;

  /// No description provided for @inventoryStreakCompleted.
  ///
  /// In en, this message translates to:
  /// **'You made it! Keep the streak alive.'**
  String get inventoryStreakCompleted;

  /// No description provided for @inventoryStreakRemaining.
  ///
  /// In en, this message translates to:
  /// **'Log {daysRemaining} more saves to level up'**
  String inventoryStreakRemaining(int daysRemaining);

  /// No description provided for @inventoryStreakFootnote.
  ///
  /// In en, this message translates to:
  /// **'Judgement-free: compare with friends only when you opt in.'**
  String get inventoryStreakFootnote;

  /// No description provided for @inventoryViewList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get inventoryViewList;

  /// No description provided for @inventoryViewTable.
  ///
  /// In en, this message translates to:
  /// **'Table view'**
  String get inventoryViewTable;

  /// No description provided for @inventoryViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get inventoryViewGrid;

  /// No description provided for @inventoryTableName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryTableName;

  /// No description provided for @inventoryTableCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryTableCategory;

  /// No description provided for @inventoryTableLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get inventoryTableLocation;

  /// No description provided for @inventoryTableExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get inventoryTableExpiry;

  /// No description provided for @inventoryTableQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get inventoryTableQuantity;

  /// No description provided for @inventoryTableStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inventoryTableStatus;

  /// No description provided for @inventoryNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get inventoryNoExpiry;

  /// No description provided for @inventoryExpiryShort.
  ///
  /// In en, this message translates to:
  /// **'Exp {date}'**
  String inventoryExpiryShort(String date);

  /// No description provided for @inventoryDeleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item?'**
  String get inventoryDeleteItemTitle;

  /// No description provided for @inventoryDeleteItemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{itemName}\" from your inventory?'**
  String inventoryDeleteItemPrompt(String itemName);

  /// No description provided for @inventoryActiveFilters.
  ///
  /// In en, this message translates to:
  /// **'Active filters:'**
  String get inventoryActiveFilters;

  /// No description provided for @inventoryAddedFrom.
  ///
  /// In en, this message translates to:
  /// **'Added from {date}'**
  String inventoryAddedFrom(String date);

  /// No description provided for @inventoryAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {date}'**
  String inventoryAddedTo(String date);

  /// No description provided for @inventoryClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get inventoryClearAll;

  /// No description provided for @messageEmptyInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your inventory is empty'**
  String get messageEmptyInventoryTitle;

  /// No description provided for @inventoryAddFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get inventoryAddFirstItem;

  /// No description provided for @shoppingUnableToLoadList.
  ///
  /// In en, this message translates to:
  /// **'Unable to load shopping list'**
  String get shoppingUnableToLoadList;

  /// No description provided for @shoppingNextShop.
  ///
  /// In en, this message translates to:
  /// **'Next Shop'**
  String get shoppingNextShop;

  /// No description provided for @shoppingPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get shoppingPurchased;

  /// No description provided for @shoppingConvertPurchased.
  ///
  /// In en, this message translates to:
  /// **'Convert Purchased ({count})'**
  String shoppingConvertPurchased(int count);

  /// No description provided for @shoppingSourceFromShoppingList.
  ///
  /// In en, this message translates to:
  /// **'From Shopping List'**
  String get shoppingSourceFromShoppingList;

  /// No description provided for @shoppingAddedToInventory.
  ///
  /// In en, this message translates to:
  /// **'{itemName} added to inventory'**
  String shoppingAddedToInventory(String itemName);

  /// No description provided for @shoppingDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get shoppingDeleteItem;

  /// No description provided for @shoppingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get shoppingEmptyTitle;

  /// No description provided for @shoppingStartList.
  ///
  /// In en, this message translates to:
  /// **'Start your shopping list'**
  String get shoppingStartList;

  /// No description provided for @shoppingUnableToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Unable to load shopping history'**
  String get shoppingUnableToLoadHistory;

  /// No description provided for @shoppingNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No shopping trips recorded yet'**
  String get shoppingNoHistory;

  /// No description provided for @progressUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load progress: {error}'**
  String progressUnableToLoad(String error);

  /// No description provided for @progressSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get progressSectionSummary;

  /// No description provided for @progressStatTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get progressStatTotalItems;

  /// No description provided for @progressStatAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get progressStatAvailable;

  /// No description provided for @progressStatConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get progressStatConsumed;

  /// No description provided for @progressStatWasted.
  ///
  /// In en, this message translates to:
  /// **'Wasted'**
  String get progressStatWasted;

  /// No description provided for @progressSectionExpiryHealth.
  ///
  /// In en, this message translates to:
  /// **'Expiry Health'**
  String get progressSectionExpiryHealth;

  /// No description provided for @progressStatExpiringToday.
  ///
  /// In en, this message translates to:
  /// **'Expiring Today'**
  String get progressStatExpiringToday;

  /// No description provided for @progressStatThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get progressStatThisWeek;

  /// No description provided for @progressStatExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get progressStatExpiringSoon;

  /// No description provided for @progressStatExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get progressStatExpired;

  /// No description provided for @progressStatNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No Expiry'**
  String get progressStatNoExpiry;

  /// No description provided for @progressSectionValueImpact.
  ///
  /// In en, this message translates to:
  /// **'Value Impact'**
  String get progressSectionValueImpact;

  /// No description provided for @progressStatTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get progressStatTotalValue;

  /// No description provided for @progressStatConsumedValue.
  ///
  /// In en, this message translates to:
  /// **'Consumed Value'**
  String get progressStatConsumedValue;

  /// No description provided for @progressStatWastedValue.
  ///
  /// In en, this message translates to:
  /// **'Wasted Value'**
  String get progressStatWastedValue;

  /// No description provided for @progressStatSavedEstimate.
  ///
  /// In en, this message translates to:
  /// **'Saved (est.)'**
  String get progressStatSavedEstimate;

  /// No description provided for @progressSectionActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get progressSectionActivity;

  /// No description provided for @progressStatAdded7d.
  ///
  /// In en, this message translates to:
  /// **'Added (7d)'**
  String get progressStatAdded7d;

  /// No description provided for @progressStatAdded30d.
  ///
  /// In en, this message translates to:
  /// **'Added (30d)'**
  String get progressStatAdded30d;

  /// No description provided for @progressStatUpdated7d.
  ///
  /// In en, this message translates to:
  /// **'Updated (7d)'**
  String get progressStatUpdated7d;

  /// No description provided for @progressStatUpdated30d.
  ///
  /// In en, this message translates to:
  /// **'Updated (30d)'**
  String get progressStatUpdated30d;

  /// No description provided for @progressSectionCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get progressSectionCategories;

  /// No description provided for @progressSectionLocations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get progressSectionLocations;

  /// No description provided for @progressSectionTypes.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get progressSectionTypes;

  /// No description provided for @progressSectionBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges & Achievements'**
  String get progressSectionBadges;

  /// No description provided for @progressSectionTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Telemetry (Local Aggregation)'**
  String get progressSectionTelemetry;

  /// No description provided for @progressSectionRecentBatch.
  ///
  /// In en, this message translates to:
  /// **'Recent Receipt Batch'**
  String get progressSectionRecentBatch;

  /// No description provided for @progressRecentBatchLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load recent batch'**
  String get progressRecentBatchLoadError;

  /// No description provided for @progressNoRecentBatches.
  ///
  /// In en, this message translates to:
  /// **'No recent receipt batches yet.'**
  String get progressNoRecentBatches;

  /// No description provided for @progressRecentBatchItemsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {total} total'**
  String progressRecentBatchItemsTotal(int count, String total);

  /// No description provided for @progressRecentBatchSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String progressRecentBatchSource(String source);

  /// No description provided for @progressLocalInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Insights'**
  String get progressLocalInsightsTitle;

  /// No description provided for @progressLocalInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These insights are computed on-device from your activity.'**
  String get progressLocalInsightsSubtitle;

  /// No description provided for @progressStatTotalEvents.
  ///
  /// In en, this message translates to:
  /// **'Total Events'**
  String get progressStatTotalEvents;

  /// No description provided for @progressStatItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'Items Added'**
  String get progressStatItemsAdded;

  /// No description provided for @progressStatItemsWasted.
  ///
  /// In en, this message translates to:
  /// **'Items Wasted'**
  String get progressStatItemsWasted;

  /// No description provided for @progressStatRemindersOpened.
  ///
  /// In en, this message translates to:
  /// **'Reminders Opened'**
  String get progressStatRemindersOpened;

  /// No description provided for @progressTopAddSources.
  ///
  /// In en, this message translates to:
  /// **'Top Add Sources'**
  String get progressTopAddSources;

  /// No description provided for @progressTopWasteReasons.
  ///
  /// In en, this message translates to:
  /// **'Top Waste Reasons'**
  String get progressTopWasteReasons;

  /// No description provided for @progressMostViewedScreens.
  ///
  /// In en, this message translates to:
  /// **'Most Viewed Screens'**
  String get progressMostViewedScreens;

  /// No description provided for @progressTabSwitches.
  ///
  /// In en, this message translates to:
  /// **'Tab Switches'**
  String get progressTabSwitches;

  /// No description provided for @progressNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get progressNoDataYet;

  /// No description provided for @expiringLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading items: {error}'**
  String expiringLoadError(String error);

  /// No description provided for @expiringEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get expiringEmptyTitle;

  /// No description provided for @expiringEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring soon.\nGreat job staying on top of\nyour inventory!'**
  String get expiringEmptyMessage;

  /// No description provided for @expiringReviewInventory.
  ///
  /// In en, this message translates to:
  /// **'Review Inventory'**
  String get expiringReviewInventory;

  /// No description provided for @expiringBucketSemantics.
  ///
  /// In en, this message translates to:
  /// **'Expiring {bucketName} section'**
  String expiringBucketSemantics(String bucketName);

  /// No description provided for @itemCardPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get itemCardPrepared;

  /// No description provided for @itemCardWastedPercent.
  ///
  /// In en, this message translates to:
  /// **'Wasted {percent}%'**
  String itemCardWastedPercent(int percent);

  /// No description provided for @itemCardUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get itemCardUsed;

  /// No description provided for @itemCardWasted.
  ///
  /// In en, this message translates to:
  /// **'Wasted'**
  String get itemCardWasted;

  /// No description provided for @itemCardAddedDate.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String itemCardAddedDate(String date);

  /// No description provided for @itemCardEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get itemCardEditTooltip;

  /// No description provided for @itemCardDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get itemCardDeleteTooltip;

  /// No description provided for @itemCardLocationFridge.
  ///
  /// In en, this message translates to:
  /// **'❄️ Fridge'**
  String get itemCardLocationFridge;

  /// No description provided for @itemCardLocationFreezer.
  ///
  /// In en, this message translates to:
  /// **'🧊 Freezer'**
  String get itemCardLocationFreezer;

  /// No description provided for @itemCardLocationPantry.
  ///
  /// In en, this message translates to:
  /// **'🗄️ Pantry'**
  String get itemCardLocationPantry;

  /// No description provided for @itemCardLocationOther.
  ///
  /// In en, this message translates to:
  /// **'🏠 Other'**
  String get itemCardLocationOther;

  /// No description provided for @itemCardLocationPrepared.
  ///
  /// In en, this message translates to:
  /// **'{locationLabel} • Prepared {date}'**
  String itemCardLocationPrepared(String locationLabel, String date);

  /// No description provided for @itemCardNoExpirySet.
  ///
  /// In en, this message translates to:
  /// **'No expiry set'**
  String get itemCardNoExpirySet;

  /// No description provided for @itemCardExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get itemCardExpired;

  /// No description provided for @itemCardExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today ⚠️'**
  String get itemCardExpiresToday;

  /// No description provided for @itemCardExpiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expires tomorrow'**
  String get itemCardExpiresTomorrow;

  /// No description provided for @itemCardExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String itemCardExpiresInDays(int days);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'fr':
      {
        switch (locale.countryCode) {
          case 'CA':
            return AppLocalizationsFrCa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
