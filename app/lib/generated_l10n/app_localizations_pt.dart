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
  String get navigationOnboarding => 'Início';

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
  String get settingsReferenceDataRegion => 'Região dos dados de referência';

  @override
  String get settingsReferenceDataLanguage => 'Idioma dos dados de referência';

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
  String get settingsSectionAccountData => 'CONTA E DADOS';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsDataSync => 'Sincronização de dados';

  @override
  String get settingsDemoMode => 'Modo de demonstração';

  @override
  String get settingsSoon => 'Em breve';

  @override
  String get settingsDemoModeEnabled => 'Modo de demonstração ativado';

  @override
  String get settingsDemoModeDisabled => 'Modo de demonstração desativado';

  @override
  String get settingsShareAnonymousUsageData =>
      'Partilhar dados de uso anónimos';

  @override
  String get settingsShareAnonymousUsageDataSubtitle =>
      'Concede permissão para exportação para a nuvem quando disponível (ainda não disponível)';

  @override
  String get settingsCloudAnalyticsExport =>
      'Exportação de análises para a nuvem';

  @override
  String get settingsCloudAnalyticsExportSubtitle =>
      'Enviar dados de telemetria para a nuvem';

  @override
  String get settingsExportSubtitle =>
      'Descarregar o seu inventário e definições';

  @override
  String get settingsImportSubtitle =>
      'Importar um ficheiro de cópia de segurança';

  @override
  String get settingsReferenceDataPacks => 'Pacotes de dados de referência';

  @override
  String get settingsDeleteAllDataSubtitle =>
      'Remover permanentemente todos os dados (irreversível)';

  @override
  String get settingsSectionPreferences => 'PREFERÊNCIAS';

  @override
  String get settingsMealPlanning => 'Planeamento de refeições';

  @override
  String get settingsSectionSupportFeedback => 'SUPORTE E FEEDBACK';

  @override
  String get settingsHelpFaq => 'Ajuda e FAQ';

  @override
  String get settingsHelpCenterComingSoon =>
      'Centro de ajuda disponível em breve';

  @override
  String get settingsSendFeedback => 'Enviar feedback';

  @override
  String get feedbackDrawerBarrierLabel => 'Feedback';

  @override
  String get feedbackDrawerTitle => 'Enviar feedback';

  @override
  String get feedbackDrawerCloseTooltip => 'Fechar painel de feedback';

  @override
  String get feedbackDrawerIntro =>
      'Diz-nos o que está a funcionar ou a falhar. Incluímos metadados da app automaticamente.';

  @override
  String get feedbackDrawerCategoryLabel => 'Categoria';

  @override
  String get feedbackCategoryBugReport => 'Relatório de erro';

  @override
  String get feedbackCategoryFeatureRequest => 'Pedido de funcionalidade';

  @override
  String get feedbackCategoryUxFeedback => 'Feedback de UX';

  @override
  String get feedbackCategoryDarkModeReadability =>
      'Legibilidade no modo escuro';

  @override
  String get feedbackCategoryOther => 'Outro';

  @override
  String get feedbackDrawerMessageLabel => 'Mensagem';

  @override
  String get feedbackDrawerMessageHint =>
      'O que aconteceu? O que devemos melhorar?';

  @override
  String get feedbackDrawerMessageValidation =>
      'Introduz feedback antes de enviar.';

  @override
  String get feedbackDrawerEmailLabel => 'Email (opcional)';

  @override
  String get feedbackDrawerEmailHint => 'tu@exemplo.com';

  @override
  String feedbackDrawerSourceLocale(String source, String locale) {
    return 'Origem: $source • Idioma: $locale';
  }

  @override
  String get feedbackDrawerSubmitting => 'A enviar...';

  @override
  String get feedbackDrawerSubmit => 'Enviar';

  @override
  String get feedbackDrawerSent => 'Feedback enviado. Obrigado.';

  @override
  String get feedbackDrawerSignInRequired =>
      'Inicia sessão antes de enviar feedback.';

  @override
  String get settingsRateApp => 'Avaliar app';

  @override
  String get settingsThanksForSupport => 'Obrigado pelo apoio!';

  @override
  String get settingsViewTutorial => 'Ver tutorial';

  @override
  String get settingsSectionLegal => 'LEGAL';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidade';

  @override
  String get settingsPrivacyPolicyComingSoon =>
      'Política de privacidade disponível em breve';

  @override
  String get settingsTermsOfService => 'Termos de serviço';

  @override
  String get settingsTermsComingSoon => 'Termos disponíveis em breve';

  @override
  String get settingsAboutSubtitle => 'ZeroSpoils v1.0.0';

  @override
  String get settingsAboutSnackMessage =>
      'O ZeroSpoils ajuda a reduzir o desperdício de alimentos.';

  @override
  String get settingsHapticIntensityLight => 'Leve';

  @override
  String get settingsHapticIntensityMedium => 'Média';

  @override
  String get settingsHapticIntensityHeavy => 'Forte';

  @override
  String settingsLeadTimeDays(int days) {
    return '$days dias';
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
  String get inventoryFiltersTitle => 'Filtros';

  @override
  String get inventoryFilterAddedDate => 'Data de adição';

  @override
  String get inventoryFilterFrom => 'De';

  @override
  String get inventoryFilterTo => 'Até';

  @override
  String get inventoryFilterPreparedOnly => 'Apenas preparados';

  @override
  String get inventoryFilterPreparedOnlyHint =>
      'Mostrar apenas itens preparados';

  @override
  String get inventoryFilterExpiringSoonOnly => 'Apenas a expirar em breve';

  @override
  String get inventoryFilterExpiringSoonOnlyHint =>
      'Mostrar itens que expiram nos próximos 3 dias';

  @override
  String get inventoryFilterBatchLinkedOnly => 'Apenas ligados a lotes';

  @override
  String get inventoryFilterBatchLinkedOnlyHint =>
      'Mostrar apenas itens ligados a lotes de compras';

  @override
  String get inventoryFilterHideConsumedItems => 'Ocultar itens consumidos';

  @override
  String get inventoryFilterHideConsumedItemsHint =>
      'Ocultar itens marcados como consumidos ou desperdiçados';

  @override
  String get inventoryFilterReset => 'Repor';

  @override
  String get inventoryFilterApply => 'Aplicar';

  @override
  String get inventoryBatchReceiptButton => 'Lote de recibos';

  @override
  String get inventoryDemoModeHint =>
      'A mostrar itens de exemplo. Desative em Definições para usar dados reais.';

  @override
  String inventoryStreakDays(int days) {
    return '🔥 Sequência de $days dias';
  }

  @override
  String get inventoryLevelUp => 'Subir de nível';

  @override
  String get inventoryNoWasteWeek => 'Semana sem desperdício';

  @override
  String get inventoryStreakCompleted =>
      'Conseguiste! Mantém a sequência ativa.';

  @override
  String inventoryStreakRemaining(int daysRemaining) {
    return 'Regista mais $daysRemaining salvamentos para subir de nível';
  }

  @override
  String get inventoryStreakFootnote =>
      'Sem julgamentos: compara com amigos só quando ativares.';

  @override
  String get inventoryViewList => 'Vista de lista';

  @override
  String get inventoryViewTable => 'Vista de tabela';

  @override
  String get inventoryViewGrid => 'Vista em grelha';

  @override
  String get inventoryTableName => 'Nome';

  @override
  String get inventoryTableCategory => 'Categoria';

  @override
  String get inventoryTableLocation => 'Local';

  @override
  String get inventoryTableExpiry => 'Validade';

  @override
  String get inventoryTableQuantity => 'Qtd.';

  @override
  String get inventoryTableStatus => 'Estado';

  @override
  String get inventoryNoExpiry => 'Sem validade';

  @override
  String inventoryExpiryShort(String date) {
    return 'Val $date';
  }

  @override
  String get inventoryDeleteItemTitle => 'Eliminar item?';

  @override
  String inventoryDeleteItemPrompt(String itemName) {
    return 'Tens a certeza de que queres eliminar \"$itemName\" do teu inventário?';
  }

  @override
  String get inventoryActiveFilters => 'Filtros ativos:';

  @override
  String inventoryAddedFrom(String date) {
    return 'Adicionado desde $date';
  }

  @override
  String inventoryAddedTo(String date) {
    return 'Adicionado até $date';
  }

  @override
  String get inventoryClearAll => 'Limpar tudo';

  @override
  String get messageEmptyInventoryTitle => 'O teu inventário está vazio';

  @override
  String get inventoryAddFirstItem => 'Adicionar o teu primeiro item';

  @override
  String get shoppingUnableToLoadList =>
      'Não foi possível carregar a lista de compras';

  @override
  String get shoppingNextShop => 'Próximas compras';

  @override
  String get shoppingPurchased => 'Comprado';

  @override
  String shoppingConvertPurchased(int count) {
    return 'Converter comprados ($count)';
  }

  @override
  String get shoppingSourceFromShoppingList => 'Da lista de compras';

  @override
  String shoppingAddedToInventory(String itemName) {
    return '$itemName adicionado ao inventário';
  }

  @override
  String get shoppingDeleteItem => 'Eliminar item';

  @override
  String get shoppingEmptyTitle => 'A tua lista de compras está vazia';

  @override
  String get shoppingStartList => 'Começar lista de compras';

  @override
  String get shoppingUnableToLoadHistory =>
      'Não foi possível carregar o histórico de compras';

  @override
  String get shoppingNoHistory => 'Ainda não há compras registadas';

  @override
  String progressUnableToLoad(String error) {
    return 'Não foi possível carregar o progresso: $error';
  }

  @override
  String get progressSectionSummary => 'Resumo';

  @override
  String get progressStatTotalItems => 'Total de itens';

  @override
  String get progressStatAvailable => 'Disponíveis';

  @override
  String get progressStatConsumed => 'Consumidos';

  @override
  String get progressStatWasted => 'Desperdiçados';

  @override
  String get progressSectionExpiryHealth => 'Estado de validade';

  @override
  String get progressStatExpiringToday => 'Expiram hoje';

  @override
  String get progressStatThisWeek => 'Esta semana';

  @override
  String get progressStatExpiringSoon => 'A expirar em breve';

  @override
  String get progressStatExpired => 'Expirados';

  @override
  String get progressStatNoExpiry => 'Sem validade';

  @override
  String get progressSectionValueImpact => 'Impacto em valor';

  @override
  String get progressStatTotalValue => 'Valor total';

  @override
  String get progressStatConsumedValue => 'Valor consumido';

  @override
  String get progressStatWastedValue => 'Valor desperdiçado';

  @override
  String get progressStatSavedEstimate => 'Poupado (est.)';

  @override
  String get progressSectionActivity => 'Atividade';

  @override
  String get progressStatAdded7d => 'Adicionados (7d)';

  @override
  String get progressStatAdded30d => 'Adicionados (30d)';

  @override
  String get progressStatUpdated7d => 'Atualizados (7d)';

  @override
  String get progressStatUpdated30d => 'Atualizados (30d)';

  @override
  String get progressSectionCategories => 'Categorias';

  @override
  String get progressSectionLocations => 'Locais';

  @override
  String get progressSectionTypes => 'Tipos';

  @override
  String get progressSectionBadges => 'Distintivos e conquistas';

  @override
  String get progressSectionTelemetry => 'Telemetria (agregação local)';

  @override
  String get progressSectionRecentBatch => 'Lote de recibos recente';

  @override
  String get progressRecentBatchLoadError =>
      'Não foi possível carregar o lote recente';

  @override
  String get progressNoRecentBatches =>
      'Ainda não existem lotes de recibos recentes.';

  @override
  String progressRecentBatchItemsTotal(int count, String total) {
    return '$count itens · $total total';
  }

  @override
  String progressRecentBatchSource(String source) {
    return 'Origem: $source';
  }

  @override
  String get progressLocalInsightsTitle => 'Insights locais';

  @override
  String get progressLocalInsightsSubtitle =>
      'Estes insights são calculados no dispositivo a partir da tua atividade.';

  @override
  String get progressStatTotalEvents => 'Eventos totais';

  @override
  String get progressStatItemsAdded => 'Itens adicionados';

  @override
  String get progressStatItemsWasted => 'Itens desperdiçados';

  @override
  String get progressStatRemindersOpened => 'Lembretes abertos';

  @override
  String get progressTopAddSources => 'Principais fontes de adição';

  @override
  String get progressTopWasteReasons => 'Principais motivos de desperdício';

  @override
  String get progressMostViewedScreens => 'Ecrãs mais vistos';

  @override
  String get progressTabSwitches => 'Mudanças de separador';

  @override
  String get progressNoDataYet => 'Ainda sem dados';

  @override
  String expiringLoadError(String error) {
    return 'Erro ao carregar itens: $error';
  }

  @override
  String get expiringEmptyTitle => 'Tudo limpo!';

  @override
  String get expiringEmptyMessage =>
      'Nada a expirar em breve.\nExcelente trabalho a manter\no teu inventário em ordem!';

  @override
  String get expiringReviewInventory => 'Rever inventário';

  @override
  String expiringBucketSemantics(String bucketName) {
    return 'Secção de expiração $bucketName';
  }

  @override
  String get itemCardPrepared => 'Preparado';

  @override
  String itemCardWastedPercent(int percent) {
    return 'Desperdiçado $percent%';
  }

  @override
  String get itemCardUsed => 'Usado';

  @override
  String get itemCardWasted => 'Desperdiçado';

  @override
  String itemCardAddedDate(String date) {
    return 'Adicionado $date';
  }

  @override
  String get itemCardEditTooltip => 'Editar item';

  @override
  String get itemCardDeleteTooltip => 'Eliminar item';

  @override
  String get itemCardLocationFridge => '❄️ Frigorífico';

  @override
  String get itemCardLocationFreezer => '🧊 Congelador';

  @override
  String get itemCardLocationPantry => '🗄️ Despensa';

  @override
  String get itemCardLocationOther => '🏠 Outro';

  @override
  String itemCardLocationPrepared(String locationLabel, String date) {
    return '$locationLabel • Preparado em $date';
  }

  @override
  String get itemCardNoExpirySet => 'Sem validade definida';

  @override
  String get itemCardExpired => 'Expirado';

  @override
  String get itemCardExpiresToday => 'Expira hoje ⚠️';

  @override
  String get itemCardExpiresTomorrow => 'Expira amanhã';

  @override
  String itemCardExpiresInDays(int days) {
    return 'Expira em $days dias';
  }

  @override
  String get noData => 'Sem dados';

  @override
  String get loading => 'A carregar...';

  @override
  String get retry => 'Tentar novamente';
}
