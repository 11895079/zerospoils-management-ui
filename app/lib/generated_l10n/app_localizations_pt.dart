// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ZeroSpoils';

  @override
  String get appDescription => 'Reduza o desperdício de alimentos em casa';

  @override
  String get navigationInventory => 'Inventário';

  @override
  String get navigationShoppingList => 'Compras';

  @override
  String get navigationShoppingHistory => 'Histórico';

  @override
  String get navigationSettings => 'Definições';

  @override
  String get screenTitleInventory => 'Inventário';

  @override
  String get screenTitleShoppingList => 'Lista de Compras';

  @override
  String get screenTitleShoppingHistory => 'Histórico de Compras';

  @override
  String get screenTitleSettings => 'Definições';

  @override
  String get screenTitleItemDetail => 'Detalhes do Item';

  @override
  String get screenTitleAddItem => 'Adicionar Item';

  @override
  String get screenTitleEditItem => 'Editar Item';

  @override
  String get screenTitleReceiptBatch => 'Lote de Compras';

  @override
  String get screenTitleProgress => 'Progresso';

  @override
  String get screenTitleOnboarding => 'Bem-vindo ao ZeroSpoils';

  @override
  String get buttonAdd => 'Adicionar';

  @override
  String get buttonEdit => 'Editar';

  @override
  String get buttonDelete => 'Eliminar';

  @override
  String get buttonSave => 'Guardar';

  @override
  String get buttonCancel => 'Cancelar';

  @override
  String get buttonClose => 'Fechar';

  @override
  String get buttonConfirm => 'Confirmar';

  @override
  String get buttonNext => 'Seguinte';

  @override
  String get buttonBack => 'Voltar';

  @override
  String get buttonYes => 'Sim';

  @override
  String get buttonNo => 'Não';

  @override
  String get buttonMaybeLater => 'Talvez mais tarde';

  @override
  String get buttonEnable => 'Ativar';

  @override
  String get buttonDone => 'Concluído';

  @override
  String get buttonContinue => 'Continuar';

  @override
  String get buttonRetry => 'Tentar novamente';

  @override
  String get buttonSearch => 'Pesquisar';

  @override
  String get buttonFilter => 'Filtrar';

  @override
  String get buttonSort => 'Ordenar';

  @override
  String get buttonClear => 'Limpar';

  @override
  String get buttonExport => 'Exportar';

  @override
  String get buttonImport => 'Importar';

  @override
  String get labelCategory => 'Categoria';

  @override
  String get labelLocation => 'Local';

  @override
  String get labelExpiry => 'Data de validade';

  @override
  String get labelQuantity => 'Quantidade';

  @override
  String get labelStatus => 'Estado';

  @override
  String get labelPrice => 'Preço';

  @override
  String get labelStore => 'Loja';

  @override
  String get labelDate => 'Data';

  @override
  String get labelNotes => 'Notas';

  @override
  String get labelPaymentMethod => 'Método de pagamento';

  @override
  String get labelBarcode => 'Código de barras';

  @override
  String get labelSearch => 'Pesquisar';

  @override
  String get labelFilter => 'Filtrar';

  @override
  String get labelAll => 'Todos';

  @override
  String get statusAvailable => 'Disponível';

  @override
  String get statusConsumed => 'Consumido';

  @override
  String get statusWasted => 'Desperdiçado';

  @override
  String get statusPrepared => 'Preparado';

  @override
  String get statusFresh => 'Fresco';

  @override
  String get statusPackaged => 'Embalado';

  @override
  String get categoryProduce => 'Frescos';

  @override
  String get categoryDairy => 'Laticínios';

  @override
  String get categoryMeat => 'Carne';

  @override
  String get categoryFrozen => 'Congelados';

  @override
  String get categoryPantry => 'Despensa';

  @override
  String get categoryBeverages => 'Bebidas';

  @override
  String get categoryOther => 'Outro';

  @override
  String get locationFridge => 'Frigorífico';

  @override
  String get locationFreezer => 'Congelador';

  @override
  String get locationPantry => 'Despensa';

  @override
  String get locationCounter => 'Bancada';

  @override
  String get locationOther => 'Outro';

  @override
  String get paymentMethodCash => 'Dinheiro';

  @override
  String get paymentMethodDebit => 'Débito';

  @override
  String get paymentMethodCredit => 'Crédito';

  @override
  String get paymentMethodMobile => 'Pagamento móvel';

  @override
  String get errorUnableToLoadItems => 'Não foi possível carregar os itens';

  @override
  String get errorNoItemsFound => 'Nenhum item encontrado';

  @override
  String get errorUnexpectedError => 'Ocorreu um erro inesperado';

  @override
  String get errorPermissionDenied => 'Permissão negada';

  @override
  String get errorCameraPermissionRequired =>
      'É necessária permissão da câmara';

  @override
  String get errorStoragePermissionRequired =>
      'É necessária permissão de armazenamento';

  @override
  String get errorInvalidInput => 'Entrada inválida';

  @override
  String get errorItemNotFound => 'Item não encontrado';

  @override
  String get errorDuplicateItem => 'O item já existe';

  @override
  String get messageEmptyInventory =>
      'Ainda não há itens no seu inventário. Adicione um para começar.';

  @override
  String get messageEmptyShoppingList =>
      'A sua lista de compras está vazia. Adicione os itens que precisa comprar.';

  @override
  String get messageNoResults => 'Nenhum resultado encontrado';

  @override
  String get messageConfirmDelete =>
      'Tem a certeza de que pretende eliminar este item?';

  @override
  String get messageConfirmDeleteAll =>
      'Tem a certeza de que pretende eliminar todos os itens?';

  @override
  String get messageSaveSuccess => 'Guardado com sucesso';

  @override
  String get messageDeleteSuccess => 'Eliminado com sucesso';

  @override
  String get messageDuplicatePreventedMessage =>
      'Este item já está no seu inventário';

  @override
  String get dialogTitleCameraPermission => 'Ativar câmara';

  @override
  String get dialogMessageCameraPermission =>
      'O ZeroSpoils precisa de acesso à câmara para digitalizar códigos de barras e capturar recibos.';

  @override
  String get dialogTitleConfirmAction => 'Confirmar ação';

  @override
  String get dialogTitleDeleteConfirmation => 'Eliminar item';

  @override
  String get toastItemAdded => 'Item adicionado';

  @override
  String get toastItemUpdated => 'Item atualizado';

  @override
  String get toastItemDeleted => 'Item eliminado';

  @override
  String get toastCopiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get toastErrorOccurred => 'Ocorreu um erro';

  @override
  String get hintSearchItems => 'Pesquisar itens...';

  @override
  String get hintItemName => 'Nome do item';

  @override
  String get hintNotes => 'Adicionar notas...';

  @override
  String get settingsReminders => 'Lembretes';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsFeedback => 'Feedback e sons';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsPrivacy => 'Privacidade e dados';

  @override
  String get settingsDarkMode => 'Modo escuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsDateFormat => 'Formato de data';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsExportData => 'Exportar dados';

  @override
  String get settingsImportData => 'Importar dados';

  @override
  String get settingsDeleteAllData => 'Eliminar todos os dados';

  @override
  String get feedbackHapticFeedback => 'Feedback tátil';

  @override
  String get feedbackHapticFeedbackDescription =>
      'Ativar vibração nas interações do utilizador';

  @override
  String get feedbackAudioFeedback => 'Feedback de áudio';

  @override
  String get feedbackAudioFeedbackDescription =>
      'Ativar efeitos sonoros nas interações';

  @override
  String get feedbackOcrBarcodeSuccess =>
      'Leitura de código de barras com sucesso';

  @override
  String get feedbackOcrBarcodeSuccessDescription =>
      'Vibrar e emitir som quando um código de barras for reconhecido';

  @override
  String get feedbackOcrExpirySuccess => 'Reconhecimento da data de validade';

  @override
  String get feedbackOcrExpirySuccessDescription =>
      'Vibrar e emitir som quando a data de validade for capturada';

  @override
  String get feedbackOcrReceiptSuccess => 'Reconhecimento de recibo';

  @override
  String get feedbackOcrReceiptSuccessDescription =>
      'Vibrar e emitir som quando os itens do recibo forem extraídos';

  @override
  String get feedbackOcrProduceSuccess =>
      'Reconhecimento de etiqueta de produto';

  @override
  String get feedbackOcrProduceSuccessDescription =>
      'Vibrar e emitir som quando a etiqueta do produto for lida';

  @override
  String get feedbackBeepVolume => 'Volume do sinal sonoro';

  @override
  String get feedbackBeepVolumeDescription =>
      'Ajustar volume do sinal sonoro tipo POS (0-100%)';

  @override
  String get feedbackHapticIntensity => 'Intensidade tátil';

  @override
  String get feedbackHapticIntensityDescription =>
      'Ajustar intensidade da vibração (Leve, Média, Forte)';

  @override
  String get remindersTurnedOn => 'Lembretes ativados';

  @override
  String get remindersTurnedOff => 'Lembretes desativados';

  @override
  String get remindersLeadTime => 'Antecedência';

  @override
  String get remindersSound => 'Som';

  @override
  String get remindersVibration => 'Vibração';

  @override
  String get shoppingBatchCapture => 'Lote de Compras';

  @override
  String get shoppingBatchStore => 'Loja';

  @override
  String get shoppingBatchDate => 'Data';

  @override
  String get shoppingBatchCost => 'Custo total';

  @override
  String get shoppingBatchReceipt => 'Foto do recibo';

  @override
  String get shoppingBatchLinkedItems => 'Itens vinculados';

  @override
  String get shoppingBatchTakePhoto => 'Tirar foto';

  @override
  String get shoppingBatchChoosePhoto => 'Escolher da galeria';

  @override
  String get shoppingBatchLinkItems => 'Vincular itens';

  @override
  String get shoppingBatchReview => 'Rever';

  @override
  String get privacyExport => 'Exporte os seus dados em CSV ou JSON';

  @override
  String get privacyDelete => 'Eliminar permanentemente todos os dados';

  @override
  String get privacyDeleteWarning => 'Esta ação não pode ser desfeita';

  @override
  String get aboutTitle => 'Sobre o ZeroSpoils';

  @override
  String get aboutDescription =>
      'Uma aplicação simples para ajudar a reduzir o desperdício de alimentos em casa';

  @override
  String get aboutVersion => 'Versão';

  @override
  String get aboutDeveloper => 'Desenvolvido com ❤️';

  @override
  String get expiryTodayLabel => 'Expira hoje';

  @override
  String get expiringSoonLabel => 'A expirar em breve';

  @override
  String expiryThresholdDays(int days) {
    return 'dentro de $days dias';
  }

  @override
  String daysUntilExpiry(int days) {
    return 'faltam $days dias';
  }

  @override
  String itemQuantityFormat(String quantity) {
    return 'Qtd.: $quantity';
  }

  @override
  String formattedPrice(String currency, double amount) {
    return '$currency$amount';
  }

  @override
  String get noData => 'Sem dados';

  @override
  String get loading => 'A carregar...';

  @override
  String get retry => 'Tentar novamente';
}
