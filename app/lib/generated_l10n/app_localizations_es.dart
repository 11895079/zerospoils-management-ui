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
  String get categoryFrozen => 'Congelados';

  @override
  String get categoryPantry => 'Despensa';

  @override
  String get categoryBeverages => 'Bebidas';

  @override
  String get categoryOther => 'Otro';

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
  String get noData => 'Sin datos';

  @override
  String get loading => 'Cargando...';

  @override
  String get retry => 'Reintentar';
}
