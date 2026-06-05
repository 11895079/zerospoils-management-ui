// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ZeroSpoils';

  @override
  String get appDescription => 'Reduce el desperdicio de alimentos en el hogar';

  @override
  String get navigationInventory => 'Inventario';

  @override
  String get navigationShoppingList => 'Compras';

  @override
  String get navigationShoppingHistory => 'Historial';

  @override
  String get navigationSettings => 'Configuración';

  @override
  String get navigationOnboarding => 'Inicio';

  @override
  String get screenTitleInventory => 'Inventario';

  @override
  String get screenTitleShoppingList => 'Lista de Compras';

  @override
  String get screenTitleShoppingHistory => 'Historial de Compras';

  @override
  String get screenTitleSettings => 'Configuración';

  @override
  String get screenTitleItemDetail => 'Detalles del Artículo';

  @override
  String get screenTitleAddItem => 'Agregar Artículo';

  @override
  String get screenTitleEditItem => 'Editar Artículo';

  @override
  String get screenTitleReceiptBatch => 'Lote de Compras';

  @override
  String get screenTitleProgress => 'Progreso';

  @override
  String get screenTitleOnboarding => 'Bienvenido a ZeroSpoils';

  @override
  String get buttonAdd => 'Agregar';

  @override
  String get buttonEdit => 'Editar';

  @override
  String get buttonDelete => 'Eliminar';

  @override
  String get buttonSave => 'Guardar';

  @override
  String get buttonCancel => 'Cancelar';

  @override
  String get buttonClose => 'Cerrar';

  @override
  String get buttonConfirm => 'Confirmar';

  @override
  String get buttonNext => 'Siguiente';

  @override
  String get buttonBack => 'Atrás';

  @override
  String get buttonYes => 'Sí';

  @override
  String get buttonNo => 'No';

  @override
  String get buttonMaybeLater => 'Quizás Más Tarde';

  @override
  String get buttonEnable => 'Habilitar';

  @override
  String get buttonDone => 'Listo';

  @override
  String get buttonContinue => 'Continuar';

  @override
  String get buttonRetry => 'Reintentar';

  @override
  String get buttonSearch => 'Buscar';

  @override
  String get buttonFilter => 'Filtrar';

  @override
  String get buttonSort => 'Ordenar';

  @override
  String get buttonClear => 'Limpiar';

  @override
  String get buttonExport => 'Exportar';

  @override
  String get buttonImport => 'Importar';

  @override
  String get labelCategory => 'Categoría';

  @override
  String get labelLocation => 'Ubicación';

  @override
  String get labelExpiry => 'Fecha de Vencimiento';

  @override
  String get labelQuantity => 'Cantidad';

  @override
  String get labelStatus => 'Estado';

  @override
  String get labelPrice => 'Precio';

  @override
  String get labelStore => 'Tienda';

  @override
  String get labelDate => 'Fecha';

  @override
  String get labelNotes => 'Notas';

  @override
  String get labelPaymentMethod => 'Método de Pago';

  @override
  String get labelBarcode => 'Código de Barras';

  @override
  String get labelSearch => 'Buscar';

  @override
  String get labelFilter => 'Filtrar';

  @override
  String get labelAll => 'Todo';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get statusConsumed => 'Consumido';

  @override
  String get statusWasted => 'Desperdiciado';

  @override
  String get statusPrepared => 'Preparado';

  @override
  String get statusFresh => 'Fresco';

  @override
  String get statusPackaged => 'Empaquetado';

  @override
  String get categoryProduce => 'Productos Frescos';

  @override
  String get categoryDairy => 'Lácteos';

  @override
  String get categoryMeat => 'Carnes';

  @override
  String get categoryGrains => 'Granos';

  @override
  String get categoryFrozen => 'Congelados';

  @override
  String get categoryPantry => 'Despensa';

  @override
  String get categoryBeverages => 'Bebidas';

  @override
  String get categoryOther => 'Otro';

  @override
  String get itemTypeRaw => 'Crudo';

  @override
  String get itemTypePrepared => 'Cocinado';

  @override
  String get itemTypePackaged => 'Envasado';

  @override
  String get locationFridge => 'Refrigerador';

  @override
  String get locationFreezer => 'Congelador';

  @override
  String get locationPantry => 'Despensa';

  @override
  String get locationCounter => 'Mostrador';

  @override
  String get locationOther => 'Otro';

  @override
  String get paymentMethodCash => 'Efectivo';

  @override
  String get paymentMethodDebit => 'Débito';

  @override
  String get paymentMethodCredit => 'Crédito';

  @override
  String get paymentMethodMobile => 'Pago Móvil';

  @override
  String get errorUnableToLoadItems => 'No se pudieron cargar los artículos';

  @override
  String get errorNoItemsFound => 'No se encontraron artículos';

  @override
  String get errorUnexpectedError => 'Ocurrió un error inesperado';

  @override
  String get errorPermissionDenied => 'Permiso denegado';

  @override
  String get errorCameraPermissionRequired => 'Se requiere permiso de cámara';

  @override
  String get errorStoragePermissionRequired =>
      'Se requiere permiso de almacenamiento';

  @override
  String get errorInvalidInput => 'Entrada inválida';

  @override
  String get errorItemNotFound => 'Artículo no encontrado';

  @override
  String get errorDuplicateItem => 'El artículo ya existe';

  @override
  String get messageEmptyInventory =>
      'No hay artículos en tu inventario todavía. Agrega uno para comenzar.';

  @override
  String get messageEmptyShoppingList =>
      'Tu lista de compras está vacía. Agrega los artículos que necesitas comprar.';

  @override
  String get messageNoResults => 'No se encontraron resultados';

  @override
  String get messageConfirmDelete =>
      '¿Estás seguro de que deseas eliminar este artículo?';

  @override
  String get messageConfirmDeleteAll =>
      '¿Estás seguro de que deseas eliminar todos los artículos?';

  @override
  String get messageSaveSuccess => 'Guardado exitosamente';

  @override
  String get messageDeleteSuccess => 'Eliminado exitosamente';

  @override
  String get messageDuplicatePreventedMessage =>
      'Este artículo ya está en tu inventario';

  @override
  String get dialogTitleCameraPermission => 'Habilitar Cámara';

  @override
  String get dialogMessageCameraPermission =>
      'ZeroSpoils necesita acceso a la cámara para escanear códigos de barras y capturar recibos.';

  @override
  String get dialogTitleConfirmAction => 'Confirmar Acción';

  @override
  String get dialogTitleDeleteConfirmation => 'Eliminar Artículo';

  @override
  String get toastItemAdded => 'Artículo agregado';

  @override
  String get toastItemUpdated => 'Artículo actualizado';

  @override
  String get toastItemDeleted => 'Artículo eliminado';

  @override
  String get toastCopiedToClipboard => 'Copiado al portapapeles';

  @override
  String get toastErrorOccurred => 'Ocurrió un error';

  @override
  String get hintSearchItems => 'Buscar artículos...';

  @override
  String get hintItemName => 'Nombre del artículo';

  @override
  String get hintNotes => 'Agregar notas...';

  @override
  String get settingsReminders => 'Recordatorios';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsFeedback => 'Retroalimentación y Sonidos';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsPrivacy => 'Privacidad y Datos';

  @override
  String get settingsDarkMode => 'Modo Oscuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get labelType => 'Tipo';

  @override
  String get itemFormSelectCategory => 'Seleccionar categoría';

  @override
  String get drawerHeaderSubtitle => 'Navegación';

  @override
  String get zestoDismissLabel => 'Cerrar Zesto';

  @override
  String zestoSaysLabel(String message) {
    return 'Zesto dice: $message';
  }

  @override
  String get settingsReferenceDataRegion => 'Región de datos de referencia';

  @override
  String get settingsReferenceDataLanguage =>
      'Idioma de los datos de referencia';

  @override
  String get settingsDateFormat => 'Formato de Fecha';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsExportData => 'Exportar Datos';

  @override
  String get settingsImportData => 'Importar Datos';

  @override
  String get settingsDeleteAllData => 'Eliminar Todos los Datos';

  @override
  String get settingsSectionAccountData => 'CUENTA Y DATOS';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsDataSync => 'Sincronización de datos';

  @override
  String get settingsDemoMode => 'Modo demo';

  @override
  String get settingsSoon => 'Pronto';

  @override
  String get settingsDemoModeEnabled => 'Modo demo activado';

  @override
  String get settingsDemoModeDisabled => 'Modo demo desactivado';

  @override
  String get settingsShareAnonymousUsageData =>
      'Compartir datos de uso anónimos';

  @override
  String get settingsShareAnonymousUsageDataSubtitle =>
      'Otorga permiso para exportación a la nube cuando esté disponible (aún no disponible)';

  @override
  String get settingsCloudAnalyticsExport =>
      'Exportación de analíticas en la nube';

  @override
  String get settingsCloudAnalyticsExportSubtitle =>
      'Enviar datos de telemetría a la nube';

  @override
  String get settingsExportSubtitle => 'Descarga tu inventario y configuración';

  @override
  String get settingsImportSubtitle => 'Importar un archivo de respaldo';

  @override
  String get settingsReferenceDataPacks => 'Paquetes de datos de referencia';

  @override
  String get settingsDeleteAllDataSubtitle =>
      'Eliminar permanentemente todos los datos (irreversible)';

  @override
  String get settingsSectionPreferences => 'PREFERENCIAS';

  @override
  String get settingsMealPlanning => 'Planificación de comidas';

  @override
  String get settingsSectionSupportFeedback => 'SOPORTE Y COMENTARIOS';

  @override
  String get settingsHelpFaq => 'Ayuda y FAQ';

  @override
  String get settingsHelpCenterComingSoon => 'Centro de ayuda próximamente';

  @override
  String get settingsSendFeedback => 'Enviar comentarios';

  @override
  String get feedbackDrawerBarrierLabel => 'Comentarios';

  @override
  String get feedbackDrawerTitle => 'Enviar comentarios';

  @override
  String get feedbackDrawerCloseTooltip => 'Cerrar panel de comentarios';

  @override
  String get feedbackDrawerIntro =>
      'Cuéntanos qué funciona o qué falla. Incluimos metadatos de la app automáticamente.';

  @override
  String get feedbackDrawerCategoryLabel => 'Categoría';

  @override
  String get feedbackCategoryBugReport => 'Reporte de error';

  @override
  String get feedbackCategoryFeatureRequest => 'Solicitud de función';

  @override
  String get feedbackCategoryUxFeedback => 'Comentarios de UX';

  @override
  String get feedbackCategoryDarkModeReadability =>
      'Legibilidad en modo oscuro';

  @override
  String get feedbackCategoryOther => 'Otro';

  @override
  String get feedbackDrawerMessageLabel => 'Mensaje';

  @override
  String get feedbackDrawerMessageHint => '¿Qué pasó? ¿Qué deberíamos mejorar?';

  @override
  String get feedbackDrawerMessageValidation =>
      'Ingresa comentarios antes de enviar.';

  @override
  String get feedbackDrawerEmailLabel => 'Correo (opcional)';

  @override
  String get feedbackDrawerEmailHint => 'tu@ejemplo.com';

  @override
  String feedbackDrawerSourceLocale(String source, String locale) {
    return 'Origen: $source • Idioma: $locale';
  }

  @override
  String get feedbackDrawerSubmitting => 'Enviando...';

  @override
  String get feedbackDrawerSubmit => 'Enviar';

  @override
  String get feedbackDrawerSent => 'Comentarios enviados. Gracias.';

  @override
  String get feedbackDrawerSignInRequired =>
      'Inicia sesión antes de enviar comentarios.';

  @override
  String get settingsRateApp => 'Calificar la app';

  @override
  String get settingsThanksForSupport => '¡Gracias por tu apoyo!';

  @override
  String get settingsViewTutorial => 'Ver tutorial';

  @override
  String get settingsSectionLegal => 'LEGAL';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsPrivacyPolicyComingSoon =>
      'Política de privacidad próximamente';

  @override
  String get settingsTermsOfService => 'Términos del servicio';

  @override
  String get settingsTermsComingSoon => 'Términos próximamente';

  @override
  String get settingsAboutSubtitle => 'ZeroSpoils v1.0.0';

  @override
  String get settingsAboutSnackMessage =>
      'ZeroSpoils ayuda a reducir el desperdicio de alimentos.';

  @override
  String get settingsHapticIntensityLight => 'Ligera';

  @override
  String get settingsHapticIntensityMedium => 'Media';

  @override
  String get settingsHapticIntensityHeavy => 'Fuerte';

  @override
  String settingsLeadTimeDays(int days) {
    return '$days días';
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
  String get feedbackHapticFeedback => 'Retroalimentación Háptica';

  @override
  String get feedbackHapticFeedbackDescription =>
      'Habilitar vibración en interacciones del usuario';

  @override
  String get feedbackAudioFeedback => 'Retroalimentación de Audio';

  @override
  String get feedbackAudioFeedbackDescription =>
      'Habilitar efectos de sonido en interacciones';

  @override
  String get feedbackOcrBarcodeSuccess => 'Escaneo de Código de Barras Exitoso';

  @override
  String get feedbackOcrBarcodeSuccessDescription =>
      'Vibrar y emitir sonido cuando se reconoce un código de barras';

  @override
  String get feedbackOcrExpirySuccess =>
      'Reconocimiento de Fecha de Vencimiento';

  @override
  String get feedbackOcrExpirySuccessDescription =>
      'Vibrar y emitir sonido cuando se captura la fecha de vencimiento';

  @override
  String get feedbackOcrReceiptSuccess => 'Reconocimiento de Recibo';

  @override
  String get feedbackOcrReceiptSuccessDescription =>
      'Vibrar y emitir sonido cuando se extraen artículos del recibo';

  @override
  String get feedbackOcrProduceSuccess =>
      'Reconocimiento de Etiqueta de Producto';

  @override
  String get feedbackOcrProduceSuccessDescription =>
      'Vibrar y emitir sonido cuando se lee la etiqueta del producto';

  @override
  String get feedbackBeepVolume => 'Volumen del Sonido';

  @override
  String get feedbackBeepVolumeDescription =>
      'Ajustar volumen del sonido de caja registradora (0-100%)';

  @override
  String get feedbackHapticIntensity => 'Intensidad Háptica';

  @override
  String get feedbackHapticIntensityDescription =>
      'Ajustar intensidad de vibración (Ligera, Media, Fuerte)';

  @override
  String get remindersTurnedOn => 'Recordatorios activados';

  @override
  String get remindersTurnedOff => 'Recordatorios desactivados';

  @override
  String get remindersLeadTime => 'Tiempo de Anticipación';

  @override
  String get remindersSound => 'Sonido';

  @override
  String get remindersVibration => 'Vibración';

  @override
  String get shoppingBatchCapture => 'Lote de Compras';

  @override
  String get shoppingBatchStore => 'Tienda';

  @override
  String get shoppingBatchDate => 'Fecha';

  @override
  String get shoppingBatchCost => 'Costo Total';

  @override
  String get shoppingBatchReceipt => 'Foto de Recibo';

  @override
  String get shoppingBatchLinkedItems => 'Artículos Vinculados';

  @override
  String get shoppingBatchTakePhoto => 'Tomar Foto';

  @override
  String get shoppingBatchChoosePhoto => 'Elegir de la Galería';

  @override
  String get shoppingBatchLinkItems => 'Vincular Artículos';

  @override
  String get shoppingBatchReview => 'Revisar';

  @override
  String get privacyExport => 'Exporta tus datos como CSV o JSON';

  @override
  String get privacyDelete => 'Elimina todos los datos permanentemente';

  @override
  String get privacyDeleteWarning => 'Esta acción no se puede deshacer';

  @override
  String get aboutTitle => 'Acerca de ZeroSpoils';

  @override
  String get aboutDescription =>
      'Una aplicación simple para ayudarte a reducir el desperdicio de alimentos en casa';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutDeveloper => 'Desarrollado con ❤️';

  @override
  String get expiryTodayLabel => 'Vence hoy';

  @override
  String get expiringSoonLabel => 'Vence pronto';

  @override
  String expiryThresholdDays(int days) {
    return 'dentro de $days días';
  }

  @override
  String daysUntilExpiry(int days) {
    return '$days días restantes';
  }

  @override
  String itemQuantityFormat(String quantity) {
    return 'Cant.: $quantity';
  }

  @override
  String formattedPrice(String currency, double amount) {
    return '$currency$amount';
  }

  @override
  String get inventoryFiltersTitle => 'Filtros';

  @override
  String get inventoryFilterAddedDate => 'Fecha de agregado';

  @override
  String get inventoryFilterFrom => 'Desde';

  @override
  String get inventoryFilterTo => 'Hasta';

  @override
  String get inventoryFilterPreparedOnly => 'Solo preparados';

  @override
  String get inventoryFilterPreparedOnlyHint =>
      'Mostrar solo artículos preparados';

  @override
  String get inventoryFilterExpiringSoonOnly => 'Solo por vencer pronto';

  @override
  String get inventoryFilterExpiringSoonOnlyHint =>
      'Mostrar artículos que vencen en los próximos 3 días';

  @override
  String get inventoryFilterBatchLinkedOnly => 'Solo vinculados a lotes';

  @override
  String get inventoryFilterBatchLinkedOnlyHint =>
      'Mostrar solo artículos vinculados a lotes de compra';

  @override
  String get inventoryFilterHideConsumedItems => 'Ocultar artículos consumidos';

  @override
  String get inventoryFilterHideConsumedItemsHint =>
      'Ocultar artículos marcados como consumidos o desperdiciados';

  @override
  String get inventoryFilterReset => 'Restablecer';

  @override
  String get inventoryFilterApply => 'Aplicar';

  @override
  String get inventoryBatchReceiptButton => 'Lote de recibos';

  @override
  String get inventoryDemoModeHint =>
      'Mostrando artículos de ejemplo. Desactívalo en Ajustes para usar datos reales.';

  @override
  String inventoryStreakDays(int days) {
    return '🔥 Racha de $days días';
  }

  @override
  String get inventoryLevelUp => 'Subir de nivel';

  @override
  String get inventoryNoWasteWeek => 'Semana sin desperdicio';

  @override
  String get inventoryStreakCompleted => '¡Lo lograste! Mantén viva la racha.';

  @override
  String inventoryStreakRemaining(int daysRemaining) {
    return 'Registra $daysRemaining rescates más para subir de nivel';
  }

  @override
  String get inventoryStreakFootnote =>
      'Sin juicios: compárate con amistades solo si lo activas.';

  @override
  String get inventoryViewList => 'Vista de lista';

  @override
  String get inventoryViewTable => 'Vista de tabla';

  @override
  String get inventoryViewGrid => 'Vista de cuadrícula';

  @override
  String get inventoryTableName => 'Nombre';

  @override
  String get inventoryTableCategory => 'Categoría';

  @override
  String get inventoryTableLocation => 'Ubicación';

  @override
  String get inventoryTableExpiry => 'Vencimiento';

  @override
  String get inventoryTableQuantity => 'Cant.';

  @override
  String get inventoryTableStatus => 'Estado';

  @override
  String get inventoryNoExpiry => 'Sin vencimiento';

  @override
  String inventoryExpiryShort(String date) {
    return 'Vence $date';
  }

  @override
  String get inventoryDeleteItemTitle => '¿Eliminar artículo?';

  @override
  String inventoryDeleteItemPrompt(String itemName) {
    return '¿Seguro que deseas eliminar \"$itemName\" de tu inventario?';
  }

  @override
  String get inventoryActiveFilters => 'Filtros activos:';

  @override
  String inventoryAddedFrom(String date) {
    return 'Agregado desde $date';
  }

  @override
  String inventoryAddedTo(String date) {
    return 'Agregado hasta $date';
  }

  @override
  String get inventoryClearAll => 'Limpiar todo';

  @override
  String get messageEmptyInventoryTitle => 'Tu inventario está vacío';

  @override
  String get inventoryAddFirstItem => 'Agregar tu primer artículo';

  @override
  String get shoppingUnableToLoadList =>
      'No se pudo cargar la lista de compras';

  @override
  String get shoppingNextShop => 'Próxima compra';

  @override
  String get shoppingPurchased => 'Comprado';

  @override
  String shoppingConvertPurchased(int count) {
    return 'Convertir comprados ($count)';
  }

  @override
  String get shoppingSourceFromShoppingList => 'Desde la lista de compras';

  @override
  String shoppingAddedToInventory(String itemName) {
    return '$itemName agregado al inventario';
  }

  @override
  String get shoppingDeleteItem => 'Eliminar artículo';

  @override
  String get shoppingEmptyTitle => 'Tu lista de compras está vacía';

  @override
  String get shoppingStartList => 'Comienza tu lista de compras';

  @override
  String get shoppingUnableToLoadHistory =>
      'No se pudo cargar el historial de compras';

  @override
  String get shoppingNoHistory => 'Aún no hay compras registradas';

  @override
  String progressUnableToLoad(String error) {
    return 'No se pudo cargar el progreso: $error';
  }

  @override
  String get progressSectionSummary => 'Resumen';

  @override
  String get progressStatTotalItems => 'Total de artículos';

  @override
  String get progressStatAvailable => 'Disponibles';

  @override
  String get progressStatConsumed => 'Consumidos';

  @override
  String get progressStatWasted => 'Desperdiciados';

  @override
  String get progressSectionExpiryHealth => 'Estado de vencimiento';

  @override
  String get progressStatExpiringToday => 'Vencen hoy';

  @override
  String get progressStatThisWeek => 'Esta semana';

  @override
  String get progressStatExpiringSoon => 'Vencen pronto';

  @override
  String get progressStatExpired => 'Vencidos';

  @override
  String get progressStatNoExpiry => 'Sin vencimiento';

  @override
  String get progressSectionValueImpact => 'Impacto de valor';

  @override
  String get progressStatTotalValue => 'Valor total';

  @override
  String get progressStatConsumedValue => 'Valor consumido';

  @override
  String get progressStatWastedValue => 'Valor desperdiciado';

  @override
  String get progressStatSavedEstimate => 'Ahorrado (est.)';

  @override
  String get progressSectionActivity => 'Actividad';

  @override
  String get progressStatAdded7d => 'Agregados (7d)';

  @override
  String get progressStatAdded30d => 'Agregados (30d)';

  @override
  String get progressStatUpdated7d => 'Actualizados (7d)';

  @override
  String get progressStatUpdated30d => 'Actualizados (30d)';

  @override
  String get progressSectionCategories => 'Categorías';

  @override
  String get progressSectionLocations => 'Ubicaciones';

  @override
  String get progressSectionTypes => 'Tipos';

  @override
  String get progressSectionBadges => 'Insignias y logros';

  @override
  String get progressSectionTelemetry => 'Telemetría (agregación local)';

  @override
  String get progressSectionRecentBatch => 'Lote de recibos reciente';

  @override
  String get progressRecentBatchLoadError =>
      'No se pudo cargar el lote reciente';

  @override
  String get progressNoRecentBatches =>
      'Aún no hay lotes de recibos recientes.';

  @override
  String progressRecentBatchItemsTotal(int count, String total) {
    return '$count artículos · $total total';
  }

  @override
  String progressRecentBatchSource(String source) {
    return 'Origen: $source';
  }

  @override
  String get progressLocalInsightsTitle => 'Información local';

  @override
  String get progressLocalInsightsSubtitle =>
      'Estos datos se calculan en el dispositivo a partir de tu actividad.';

  @override
  String get progressStatTotalEvents => 'Eventos totales';

  @override
  String get progressStatItemsAdded => 'Artículos agregados';

  @override
  String get progressStatItemsWasted => 'Artículos desperdiciados';

  @override
  String get progressStatRemindersOpened => 'Recordatorios abiertos';

  @override
  String get progressTopAddSources => 'Fuentes principales de agregado';

  @override
  String get progressTopWasteReasons => 'Motivos principales de desperdicio';

  @override
  String get progressMostViewedScreens => 'Pantallas más vistas';

  @override
  String get progressTabSwitches => 'Cambios de pestaña';

  @override
  String get progressNoDataYet => 'Aún no hay datos';

  @override
  String expiringLoadError(String error) {
    return 'Error al cargar artículos: $error';
  }

  @override
  String get expiringEmptyTitle => '¡Todo bien!';

  @override
  String get expiringEmptyMessage =>
      'Nada vence pronto.\n¡Buen trabajo manteniendo\ntu inventario al día!';

  @override
  String get expiringReviewInventory => 'Revisar inventario';

  @override
  String expiringBucketSemantics(String bucketName) {
    return 'Sección de vencimiento $bucketName';
  }

  @override
  String get itemCardPrepared => 'Preparado';

  @override
  String itemCardWastedPercent(int percent) {
    return 'Desperdiciado $percent%';
  }

  @override
  String get itemCardUsed => 'Usado';

  @override
  String get itemCardWasted => 'Desperdiciado';

  @override
  String itemCardAddedDate(String date) {
    return 'Agregado $date';
  }

  @override
  String get itemCardEditTooltip => 'Editar artículo';

  @override
  String get itemCardDeleteTooltip => 'Eliminar artículo';

  @override
  String get itemCardLocationFridge => '❄️ Nevera';

  @override
  String get itemCardLocationFreezer => '🧊 Congelador';

  @override
  String get itemCardLocationPantry => '🗄️ Despensa';

  @override
  String get itemCardLocationOther => '🏠 Otro';

  @override
  String itemCardLocationPrepared(String locationLabel, String date) {
    return '$locationLabel • Preparado el $date';
  }

  @override
  String get itemCardNoExpirySet => 'Sin vencimiento definido';

  @override
  String get itemCardExpired => 'Vencido';

  @override
  String get itemCardExpiresToday => 'Vence hoy ⚠️';

  @override
  String get itemCardExpiresTomorrow => 'Vence mañana';

  @override
  String itemCardExpiresInDays(int days) {
    return 'Vence en $days días';
  }

  @override
  String get noData => 'Sin datos';

  @override
  String get loading => 'Cargando...';

  @override
  String get retry => 'Reintentar';
}
