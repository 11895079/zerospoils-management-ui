library;

/// Add/Edit Item form screen
/// Captures item name, category, location, quantity, expiry date

import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/barcode/local_barcode_catalog.dart';
import '../../core/feature_flags/feature_flag_key.dart';
import '../../core/feature_flags/feature_flags_provider.dart';
import '../../core/ocr/expiry_date_ocr_service.dart';
import '../../core/reference/reference_pack_fetchers.dart';
import '../../core/reference/reference_pack_keys.dart';
import '../../core/reference/reference_pack_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../generated_l10n/app_localizations_en.dart';
import '../../domain/models/receipt_batch.dart';
import '../../core/vision/fresh_item_cv_service.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/zesto_model.dart';
import '../../domain/models/user_category.dart';
import '../../domain/utils/local_id_generator.dart';
import '../widgets/app_button.dart';
import '../widgets/item_icon.dart';
import '../widgets/quantity_toggle.dart';
import '../barcode/barcode_capture_launcher.dart';
import '../di/repository_providers.dart';
import '../di/localization_providers.dart';
import '../di/service_locator.dart' hide itemRepositoryProvider;
import '../fresh_item/fresh_item_capture_launcher.dart';
import '../ocr/expiry_ocr_capture_launcher.dart';

enum _CameraAssistedStage { barcodeReady, barcodeLocked, expiryLocked }

class ItemFormScreen extends ConsumerStatefulWidget {
  final String? itemId; // null for add, non-null for edit
  final String? initialName;
  final String? initialReceiptBatchId;
  final double? initialPrice;

  const ItemFormScreen({
    super.key,
    this.itemId,
    this.initialName,
    this.initialReceiptBatchId,
    this.initialPrice,
  });

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _CategoryOption {
  final String id;
  final String label;
  final bool isCustom;
  final ItemCategory? builtIn;
  final UserCategory? custom;

  const _CategoryOption({
    required this.id,
    required this.label,
    required this.isCustom,
    this.builtIn,
    this.custom,
  });

  @override
  bool operator ==(Object other) {
    return other is _CategoryOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class _RecentItemDefaults {
  final String name;
  final String? brand;
  final ItemCategory category;
  final StorageLocation location;
  final String? customCategoryId;
  final String? customCategoryName;
  final DateTime updatedAt;

  const _RecentItemDefaults({
    required this.name,
    this.brand,
    required this.category,
    required this.location,
    required this.updatedAt,
    this.customCategoryId,
    this.customCategoryName,
  });
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  static const List<Color> _categoryColors = [
    Color(0xFFFFD6A5),
    Color(0xFFFDFFB6),
    Color(0xFFCAFFBF),
    Color(0xFF9BF6FF),
    Color(0xFFA0C4FF),
    Color(0xFFBDB2FF),
    Color(0xFFFFC6FF),
    Color(0xFFFFADAD),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();

  ItemCategory _selectedCategory = ItemCategory.produce;
  UserCategory? _selectedUserCategory;
  List<UserCategory> _userCategories = [];
  ItemType _selectedType = ItemType.raw;
  DateTime? _selectedPreparedDate;
  StorageLocation _selectedLocation = StorageLocation.fridge;
  Unit _selectedUnit = Unit.count;
  DateTime? _selectedExpiryDate;
  DateTime? _existingCreatedAt; // preserve original creation time when editing
  bool _isLoading = false;
  bool _categoryTouched = false;
  bool _ocrInProgress = false;
  bool _barcodeScanInProgress = false;
  bool _freshItemCvInProgress = false;
  bool _loadingReceiptBatches = false;
  _CameraAssistedStage _cameraAssistedStage = _CameraAssistedStage.barcodeReady;
  String? _cameraBarcodeValue;
  String? _cameraFreshItemSuggestionName;
  String? _cameraFreshItemSuggestionSource;
  String? _cameraSuggestedName;
  String? _cameraSuggestionSource;
  String? _cameraAcceptedExpiryFormat;
  String? _selectedReceiptBatchId;
  String? _loadedReceiptBatchId;
  String? _existingReceiptBatchItemId;
  List<ReceiptBatch> _availableReceiptBatches = const [];
  List<_RecentItemDefaults> _recentItemDefaults = const [];
  List<String> _recentBrands = const [];
  final Map<ItemCategory, String> _referenceCategoryLabels = {};
  final Map<ItemCategory, Set<String>> _referenceCategoryTerms = {};
  final Map<StorageLocation, String> _referenceLocationLabels = {};
  final Map<ItemType, String> _referenceTypeLabels = {};

  bool get _isEditMode => widget.itemId != null;

  bool get _supportsExpiryOcrPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _supportsFreshItemCvPlatform => _supportsExpiryOcrPlatform;

  @override
  void initState() {
    super.initState();
    _loadUserCategories();
    _loadRecentItemDefaults();
    _loadReceiptBatches();
    _loadReferencePackSuggestions();
    if (!_isEditMode) {
      if (widget.initialName != null && widget.initialName!.trim().isNotEmpty) {
        _nameController.text = widget.initialName!.trim();
      }
      if (widget.initialPrice != null && widget.initialPrice! >= 0) {
        _priceController.text = widget.initialPrice!.toStringAsFixed(2);
      }
      _selectedReceiptBatchId = widget.initialReceiptBatchId;
    }
    if (_isEditMode) {
      _loadItem();
    }
  }

  Future<void> _loadReferencePackSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Populate from cached reference packs immediately — no network on the
      // critical path when opening the form.
      _applyReferenceRecords(prefs);
      // Refresh opportunistically in the background. This never blocks the
      // form, and a failed sync never becomes an unhandled async error.
      unawaited(_refreshReferencePacksInBackground(prefs));
    } catch (_) {
      // Best-effort enhancement only. Built-in category/location flows remain usable.
    }
  }

  Future<void> _refreshReferencePacksInBackground(
    SharedPreferences prefs,
  ) async {
    try {
      final region = effectiveReferencePackRegion(
        regionTag:
            prefs.getString(referencePackRegionPreferenceKey) ??
            referencePackAutomaticTag,
        activeBarcodeRegion: prefs.getString(
          ReferencePackKeys.activeBarcodePackRegion,
        ),
      );
      final locale = effectiveReferencePackLanguage(
        languageTag:
            prefs.getString(referencePackLanguagePreferenceKey) ??
            referencePackAutomaticTag,
        appLocaleTag:
            prefs.getString(appLocalePreferenceKey) ?? appLocaleSystemTag,
      );

      final service = ReferencePackService(preferences: prefs);

      final manifestProvider = FirebaseRemoteConfigManifestUrlProvider();
      final downloader = HttpReferencePackDownloader();

      await service.syncBarcodeCatalogPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: region,
      );
      await service.syncCategoriesPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: region,
        locale: locale,
      );
      await service.syncLocationsPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: region,
        locale: locale,
      );
      await service.syncTypesPack(
        manifestUrlProvider: manifestProvider,
        downloader: downloader,
        region: region,
        locale: locale,
      );

      // Re-apply with freshly synced records once the network catches up.
      _applyReferenceRecords(prefs);
      ref.invalidate(localBarcodeCatalogProvider);
      ref.invalidate(referencePackLabelSnapshotProvider);
    } catch (_) {
      // Network refresh is best-effort; cached data already populated the UI.
    }
  }

  void _applyReferenceRecords(SharedPreferences prefs) {
    final categoryRecords = ReferencePackService.activeCategoryRecords(prefs);
    final locationRecords = ReferencePackService.activeLocationRecords(prefs);
    final typeRecords = ReferencePackService.activeTypeRecords(prefs);

    if (!mounted) {
      return;
    }

    setState(() {
      _referenceCategoryLabels
        ..clear()
        ..addEntries(
          categoryRecords.map(
            (record) => MapEntry(record.appCategory, record.label),
          ),
        );

      _referenceCategoryTerms
        ..clear()
        ..addEntries(
          categoryRecords.map((record) {
            final terms = <String>{
              record.label.toLowerCase(),
              record.id.toLowerCase(),
              ...record.synonyms.map((synonym) => synonym.toLowerCase()),
            };
            return MapEntry(record.appCategory, terms);
          }),
        );

      _referenceLocationLabels
        ..clear()
        ..addEntries(
          locationRecords.map(
            (record) => MapEntry(record.appLocation, record.label),
          ),
        );

      _referenceTypeLabels
        ..clear()
        ..addEntries(
          typeRecords.map((record) => MapEntry(record.appType, record.label)),
        );
    });
  }

  Future<void> _loadReceiptBatches() async {
    setState(() => _loadingReceiptBatches = true);
    try {
      final batches = await Future<List<ReceiptBatch>>.sync(() async {
        final repository = ref.read(receiptBatchRepositoryProvider);
        await repository.init();
        return repository.getAllBatches();
      });
      if (!mounted) return;
      setState(() {
        _availableReceiptBatches = batches;
        _loadingReceiptBatches = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableReceiptBatches = const [];
        _loadingReceiptBatches = false;
      });
    }
  }

  String _receiptBatchLabel(ReceiptBatch batch) {
    final date = batch.purchasedAt ?? batch.createdAt;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final dateLabel = '${date.year}-$month-$day';
    if (batch.storeName != null && batch.storeName!.trim().isNotEmpty) {
      return '${batch.storeName!.trim()} · $dateLabel';
    }
    return 'Batch · $dateLabel';
  }

  Color _randomPastelColor() {
    final random = Random();
    return _categoryColors[random.nextInt(_categoryColors.length)];
  }

  Widget _buildCategoryIcon(_CategoryOption option, {double size = 18}) {
    if (option.isCustom) {
      final icon = option.custom?.icon?.trim().isNotEmpty == true
          ? option.custom!.icon!.trim()
          : '🏷️';
      final colorValue = option.custom?.color;
      if (colorValue != null) {
        return CircleAvatar(
          radius: size * 0.7,
          backgroundColor: Color(colorValue),
          child: Text(icon, style: TextStyle(fontSize: size * 0.75)),
        );
      }
      return Text(icon, style: TextStyle(fontSize: size));
    }

    return Text(
      _getCategoryEmoji(option.builtIn!),
      style: TextStyle(fontSize: size),
    );
  }

  Future<void> _loadUserCategories() async {
    final repo = ref.read(userCategoryRepositoryProvider);
    final categories = await repo.getAll();
    if (!mounted) return;
    setState(() {
      _userCategories = categories..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _loadRecentItemDefaults() async {
    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.init();
      final items = await repository.getAllItems();

      final recentByName = <String, _RecentItemDefaults>{};
      final sortedItems = [...items]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      for (final item in sortedItems) {
        final normalizedName = item.name.trim().toLowerCase();
        if (normalizedName.isEmpty ||
            recentByName.containsKey(normalizedName)) {
          continue;
        }

        recentByName[normalizedName] = _RecentItemDefaults(
          name: item.name.trim(),
          brand: item.brand?.trim(),
          category: item.category,
          location: item.location,
          customCategoryId: item.customCategoryId,
          customCategoryName: item.customCategoryName,
          updatedAt: item.updatedAt,
        );
      }

      final recentBrands = <String>[];
      final seenBrands = <String>{};
      for (final item in sortedItems) {
        final brand = item.brand?.trim();
        if (brand == null || brand.isEmpty) {
          continue;
        }

        final normalizedBrand = brand.toLowerCase();
        if (seenBrands.add(normalizedBrand)) {
          recentBrands.add(brand);
        }
      }

      if (!mounted) return;
      setState(() {
        _recentItemDefaults = recentByName.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _recentBrands = recentBrands;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recentItemDefaults = const [];
        _recentBrands = const [];
      });
    }
  }

  List<_RecentItemDefaults> _recentSuggestionsForQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return _recentItemDefaults
        .where((item) => item.name.toLowerCase().contains(normalizedQuery))
        .take(3)
        .toList();
  }

  List<String> _recentBrandSuggestions(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final brands = normalizedQuery.isEmpty
        ? _recentBrands
        : _recentBrands
              .where((brand) => brand.toLowerCase().contains(normalizedQuery))
              .toList();

    return brands.take(6).toList();
  }

  _RecentItemDefaults? _findRecentDefaultsForName(String? name) {
    final normalizedName = name?.trim().toLowerCase();
    if (normalizedName == null || normalizedName.isEmpty) {
      return null;
    }

    for (final item in _recentItemDefaults) {
      if (item.name.toLowerCase() == normalizedName) {
        return item;
      }
    }
    return null;
  }

  UserCategory? _resolveRecentUserCategory(_RecentItemDefaults defaults) {
    final customCategoryId = defaults.customCategoryId;
    if (customCategoryId == null) {
      return null;
    }

    for (final category in _userCategories) {
      if (category.id == customCategoryId) {
        return category;
      }
    }

    return UserCategory(
      id: customCategoryId,
      name: defaults.customCategoryName ?? 'Custom',
      createdAt: DateTime.now(),
    );
  }

  void _applyRecentItemDefaults(_RecentItemDefaults defaults) {
    setState(() {
      _nameController.text = defaults.name;
      _brandController.text = defaults.brand ?? '';
      _selectedCategory = defaults.category;
      _selectedUserCategory = _resolveRecentUserCategory(defaults);
      _selectedLocation = defaults.location;
    });
  }

  void _applyRecentSuggestion(_RecentItemDefaults defaults) {
    _applyRecentItemDefaults(defaults);
  }

  Future<void> _openBrandPicker() async {
    final searchController = TextEditingController(text: _brandController.text);
    var query = _brandController.text;

    try {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final theme = Theme.of(context);
              final trimmedQuery = query.trim();
              final options = _recentBrandSuggestions(query);
              final hasExactMatch =
                  trimmedQuery.isNotEmpty &&
                  options.any(
                    (brand) =>
                        brand.toLowerCase() == trimmedQuery.toLowerCase(),
                  );

              return Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select brand', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search brands',
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() => query = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: ListView(
                          children: [
                            if (trimmedQuery.isNotEmpty && !hasExactMatch)
                              ListTile(
                                leading: const Icon(Icons.add),
                                title: Text('Use "$trimmedQuery"'),
                                onTap: () =>
                                    Navigator.pop(context, trimmedQuery),
                              ),
                            if (options.isNotEmpty) ...[
                              Text(
                                'Recent brands',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              ...options.map(
                                (brand) => ListTile(
                                  title: Text(brand),
                                  onTap: () => Navigator.pop(context, brand),
                                ),
                              ),
                            ],
                            if (options.isEmpty && trimmedQuery.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                child: Text(
                                  'No recent brands yet. Type one manually.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                            if (options.isEmpty && trimmedQuery.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                child: Text(
                                  'No recent brands match your search.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (selected == null) {
        return;
      }

      setState(() {
        _brandController.text = selected;
      });
    } finally {
      searchController.dispose();
    }
  }

  String _entryMethodForSave() {
    final barcodeAccepted = _cameraBarcodeValue != null;
    final freshItemAccepted = _cameraFreshItemSuggestionName != null;
    final expiryAccepted = _cameraAcceptedExpiryFormat != null;

    if (barcodeAccepted && expiryAccepted) {
      return 'camera_barcode_and_expiry';
    }
    if (barcodeAccepted) {
      return 'camera_barcode';
    }
    if (freshItemAccepted && expiryAccepted) {
      return 'camera_fresh_item_and_expiry';
    }
    if (freshItemAccepted) {
      return 'camera_fresh_item';
    }
    if (expiryAccepted) {
      return 'camera_expiry';
    }
    return 'manual';
  }

  void _maybeAutoSetCategory(String value) {
    if (_categoryTouched) return;
    final inferred = _inferCategoryFromName(value);
    if (inferred == null || inferred == _selectedCategory) return;
    setState(() => _selectedCategory = inferred);
  }

  ItemCategory? _inferCategoryFromName(String value) {
    final name = value.trim().toLowerCase();
    if (name.isEmpty) return null;

    for (final entry in _referenceCategoryTerms.entries) {
      for (final term in entry.value) {
        if (term.isNotEmpty && name.contains(term)) {
          return entry.key;
        }
      }
    }

    // Dairy
    if (name.contains('milk') ||
        name.contains('cheese') ||
        name.contains('yogurt') ||
        name.contains('butter') ||
        name.contains('cream') ||
        name.contains('egg')) {
      return ItemCategory.dairy;
    }

    // Meat & seafood
    if (name.contains('chicken') ||
        name.contains('beef') ||
        name.contains('pork') ||
        name.contains('turkey') ||
        name.contains('fish') ||
        name.contains('salmon') ||
        name.contains('shrimp') ||
        name.contains('bacon') ||
        name.contains('sausage')) {
      return ItemCategory.meat;
    }

    // Grains & starches
    if (name.contains('rice') ||
        name.contains('pasta') ||
        name.contains('noodle') ||
        name.contains('bread') ||
        name.contains('flour') ||
        name.contains('oat') ||
        name.contains('cereal') ||
        name.contains('tortilla')) {
      return ItemCategory.grains;
    }

    // Pantry
    if (name.contains('oil') ||
        name.contains('vinegar') ||
        name.contains('spice') ||
        name.contains('sauce') ||
        name.contains('ketchup') ||
        name.contains('mustard') ||
        name.contains('mayo') ||
        name.contains('honey') ||
        name.contains('sugar') ||
        name.contains('salt') ||
        name.contains('pepper')) {
      return ItemCategory.pantry;
    }

    // Produce
    if (name.contains('apple') ||
        name.contains('banana') ||
        name.contains('orange') ||
        name.contains('berry') ||
        name.contains('lemon') ||
        name.contains('lime') ||
        name.contains('avocado') ||
        name.contains('tomato') ||
        name.contains('carrot') ||
        name.contains('lettuce') ||
        name.contains('spinach') ||
        name.contains('onion') ||
        name.contains('garlic') ||
        name.contains('pepper') ||
        name.contains('potato') ||
        name.contains('mushroom') ||
        name.contains('cucumber') ||
        name.contains('broccoli')) {
      return ItemCategory.produce;
    }

    return null;
  }

  List<_CategoryOption> _buildCategoryOptions() {
    final builtIns = ItemCategory.values
        .map(
          (category) => _CategoryOption(
            id: 'builtin_${category.name}',
            label: _localizedCategoryLabel(category),
            isCustom: false,
            builtIn: category,
          ),
        )
        .toList();

    final customs = _userCategories
        .map(
          (cat) => _CategoryOption(
            id: 'custom_${cat.id}',
            label: cat.name,
            isCustom: true,
            custom: cat,
          ),
        )
        .toList();

    return [...builtIns, ...customs];
  }

  Future<void> _openCategoryPicker() async {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final searchController = TextEditingController();
    final newCategoryController = TextEditingController();
    final iconController = TextEditingController();
    final existingNames = {
      ...ItemCategory.values.map(
        (c) => _localizedCategoryLabel(c).toLowerCase(),
      ),
      ..._userCategories.map((c) => c.name.toLowerCase()),
    };
    var query = '';
    var isAdding = false;
    Color? selectedColor;

    try {
      final selected = await showModalBottomSheet<_CategoryOption>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final options = _buildCategoryOptions()
                  .where(
                    (option) => option.label.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
              final builtIns = options
                  .where((option) => !option.isCustom)
                  .toList();
              final customs = options
                  .where((option) => option.isCustom)
                  .toList();
              final theme = Theme.of(context);

              Future<void> handleDelete(UserCategory category) async {
                final deleted = await _deleteCategoryFlow(category);
                if (!deleted) return;
                setSheetState(() {});
              }

              Future<void> handleCreate() async {
                final name = newCategoryController.text.trim();
                if (name.isEmpty) return;
                if (existingNames.contains(name.toLowerCase())) {
                  _showSnack('Category already exists');
                  return;
                }

                final category = UserCategory(
                  id: LocalIdGenerator.next(prefix: 'category'),
                  name: name,
                  icon: iconController.text.trim().isEmpty
                      ? null
                      : iconController.text.trim(),
                  color: (selectedColor ?? _randomPastelColor()).toARGB32(),
                  createdAt: DateTime.now(),
                );
                final repo = ref.read(userCategoryRepositoryProvider);
                await repo.upsert(category);
                ref.read(telemetryClientProvider).enqueue({
                  'name': 'category_created',
                  'properties': {'name': category.name, 'is_custom': true},
                });

                if (!mounted || !context.mounted) return;
                setState(() {
                  _userCategories = [..._userCategories, category]
                    ..sort((a, b) => a.name.compareTo(b.name));
                  _selectedUserCategory = category;
                  _selectedCategory = ItemCategory.other;
                  _categoryTouched = true;
                });
                Navigator.pop(
                  context,
                  _CategoryOption(
                    id: 'custom_${category.id}',
                    label: category.name,
                    isCustom: true,
                    custom: category,
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.itemFormSelectCategory,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search categories',
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() => query = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: ListView(
                          children: [
                            if (builtIns.isNotEmpty) ...[
                              Text(
                                'Built-in',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              ...builtIns.map(
                                (option) => ListTile(
                                  leading: _buildCategoryIcon(option),
                                  title: Text(option.label),
                                  onTap: () => Navigator.pop(context, option),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (customs.isNotEmpty) ...[
                              Text(
                                'Custom',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              ...customs.map(
                                (option) => ListTile(
                                  leading: _buildCategoryIcon(option),
                                  title: Text(option.label),
                                  onTap: () => Navigator.pop(context, option),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () async {
                                      if (option.custom == null) return;
                                      await handleDelete(option.custom!);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (builtIns.isEmpty && customs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                child: Text(
                                  'No categories match your search.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isAdding)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                setSheetState(() => isAdding = true),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add new category'),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: newCategoryController,
                              decoration: const InputDecoration(
                                hintText: 'Category name',
                              ),
                              autofocus: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: iconController,
                              decoration: const InputDecoration(
                                hintText: 'Optional icon (emoji)',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Pick a color (optional)',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              children: _categoryColors
                                  .map(
                                    (color) => GestureDetector(
                                      onTap: () => setSheetState(
                                        () => selectedColor = color,
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                          border: Border.all(
                                            color: selectedColor == color
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    newCategoryController.clear();
                                    iconController.clear();
                                    selectedColor = null;
                                    setSheetState(() => isAdding = false);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ElevatedButton(
                                  onPressed: handleCreate,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (selected == null) return;
      setState(() {
        _categoryTouched = true;
        if (selected.isCustom) {
          _selectedUserCategory = selected.custom;
          _selectedCategory = ItemCategory.other;
        } else {
          _selectedCategory = selected.builtIn!;
          _selectedUserCategory = null;
        }
      });
    } finally {
      searchController.dispose();
      newCategoryController.dispose();
      iconController.dispose();
    }
  }

  Future<bool> _deleteCategoryFlow(UserCategory category) async {
    final itemRepo = ref.read(itemRepositoryProvider);
    final categoryRepo = ref.read(userCategoryRepositoryProvider);
    await itemRepo.init();
    await categoryRepo.init();

    final items = await itemRepo.getAllItems();
    if (!context.mounted) return false;
    final affected = items
        .where((item) => item.customCategoryId == category.id)
        .toList();

    _CategoryOption? reassignOption;

    if (affected.isNotEmpty) {
      if (!mounted) return false;
      final options = _buildCategoryOptions()
          .where(
            (option) => !option.isCustom || option.custom?.id != category.id,
          )
          .toList();

      final defaultOption = options.firstWhere(
        (option) => !option.isCustom && option.builtIn == ItemCategory.other,
        orElse: () => options.first,
      );

      reassignOption = await showDialog<_CategoryOption>(
        context: context,
        builder: (context) {
          var selected = defaultOption;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Reassign items'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${affected.length} items use "${category.name}".'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<_CategoryOption>(
                      initialValue: selected,
                      items: options
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selected = value);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text('Reassign & delete'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (reassignOption == null) return false;

      for (final item in affected) {
        if (reassignOption.isCustom) {
          final custom = reassignOption.custom;
          if (custom == null) continue;
          await itemRepo.saveItem(
            item.copyWith(
              category: ItemCategory.other,
              customCategoryId: custom.id,
              customCategoryName: custom.name,
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          await itemRepo.saveItem(
            item.copyWith(
              category: reassignOption.builtIn,
              customCategoryId: null,
              customCategoryName: null,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    } else {
      if (!mounted) return false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete category'),
            content: Text('Delete "${category.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return false;
    }

    await categoryRepo.delete(category.id);
    ref.read(telemetryClientProvider).enqueue({
      'name': 'category_deleted',
      'properties': {'name': category.name, 'items_affected': affected.length},
    });

    setState(() {
      _userCategories =
          _userCategories
              .where((existing) => existing.id != category.id)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      if (_selectedUserCategory?.id == category.id) {
        if (reassignOption != null) {
          if (reassignOption.isCustom) {
            _selectedUserCategory = reassignOption.custom;
            _selectedCategory = ItemCategory.other;
          } else {
            _selectedUserCategory = null;
            _selectedCategory = reassignOption.builtIn!;
          }
        } else {
          _selectedUserCategory = null;
          _selectedCategory = ItemCategory.other;
        }
      }
    });

    ref.invalidate(itemsFutureProvider);
    return true;
  }

  Future<void> _scanExpiryDate() async {
    if (_ocrInProgress) return;
    if (!_supportsExpiryOcrPlatform) {
      _showSnack('Expiry OCR is not available on this platform yet');
      return;
    }

    bool expiryOcrEnabled;
    String preferredDateFormat;
    try {
      expiryOcrEnabled = await ref.read(
        isFlagEnabledProvider(FeatureFlagKey.expiryDateOcr).future,
      );
      preferredDateFormat = await ref.read(dateFormatPreferenceProvider.future);
    } catch (_) {
      expiryOcrEnabled = false;
      preferredDateFormat = 'MM/DD/YYYY';
    }

    if (!expiryOcrEnabled) {
      _showSnack('Expiry OCR is currently unavailable');
      return;
    }

    final shouldContinue = await _showExpiryOcrGuidance();
    if (!shouldContinue || !mounted) {
      return;
    }

    final textDirection = Directionality.of(context);

    setState(() => _ocrInProgress = true);

    try {
      final scanResult = await ref.read(expiryOcrCaptureLauncherProvider)(
        context: context,
        preferredDateFormat: preferredDateFormat,
      );
      if (!mounted) return;

      if (scanResult.isSuccess) {
        final parsed = scanResult.parsed!;
        setState(() {
          _selectedExpiryDate = parsed.date;
          _cameraAcceptedExpiryFormat = parsed.format;
          if (_cameraBarcodeValue != null) {
            _cameraAssistedStage = _CameraAssistedStage.expiryLocked;
          }
        });
        // ignore: deprecated_member_use
        SemanticsService.announce(
          'Expiry date detected: ${parsed.date.month}/${parsed.date.day}/${parsed.date.year}',
          textDirection,
        );
        ref.read(telemetryClientProvider).enqueue({
          'name': 'expiry_date_scanned',
          'properties': {'success': true, 'format_detected': parsed.format},
        });
        return;
      }

      switch (scanResult.failure) {
        case ExpiryDateOcrFailure.cancelled:
          return;
        case ExpiryDateOcrFailure.noDateDetected:
          _showSnack('No expiry date detected');
          ref.read(telemetryClientProvider).enqueue({
            'name': 'expiry_date_scanned',
            'properties': {'success': false, 'format_detected': 'none'},
          });
          return;
        case ExpiryDateOcrFailure.permissionDenied:
          _showSnack(
            'Camera permission denied. Enable it in Settings to scan expiry dates.',
          );
          ref.read(telemetryClientProvider).enqueue({
            'name': 'expiry_date_scanned',
            'properties': {
              'success': false,
              'format_detected': 'permission_denied',
            },
          });
          return;
        case ExpiryDateOcrFailure.unavailable:
          _showSnack('Expiry OCR is not available on this platform yet');
          return;
        case ExpiryDateOcrFailure.unknown:
        case null:
          _showSnack('Unable to scan expiry date');
          ref.read(telemetryClientProvider).enqueue({
            'name': 'expiry_date_scanned',
            'properties': {'success': false, 'format_detected': 'error'},
          });
          return;
      }
    } finally {
      if (mounted) setState(() => _ocrInProgress = false);
    }
  }

  Future<void> _scanBarcode() async {
    if (_barcodeScanInProgress) return;

    setState(() => _barcodeScanInProgress = true);

    try {
      final result = await ref.read(barcodeCaptureLauncherProvider)(
        context: context,
      );
      if (!mounted) return;

      if (result.isSuccess) {
        _applyBarcodeCapture(result);
        ref.read(telemetryClientProvider).enqueue({
          'name': 'camera_assisted_barcode_scanned',
          'properties': {
            'success': true,
            'barcode_length': result.rawValue!.length,
            'has_suggestion': result.suggestedName != null,
            'source': result.source ?? 'unknown',
          },
        });
        return;
      }

      switch (result.failure) {
        case BarcodeCaptureFailure.cancelled:
          return;
        case BarcodeCaptureFailure.invalidBarcode:
          _showSnack('Enter a valid 8 to 14 digit barcode');
          ref.read(telemetryClientProvider).enqueue({
            'name': 'camera_assisted_barcode_scanned',
            'properties': {'success': false, 'reason': 'invalid_barcode'},
          });
          return;
        case null:
          return;
      }
    } finally {
      if (mounted) {
        setState(() => _barcodeScanInProgress = false);
      }
    }
  }

  Future<void> _scanFreshItem() async {
    if (_freshItemCvInProgress) return;
    if (!_supportsFreshItemCvPlatform) {
      _showSnack('Fresh item scan is not available on this platform yet');
      return;
    }

    bool freshItemCvEnabled;
    try {
      freshItemCvEnabled = await ref.read(
        isFlagEnabledProvider(FeatureFlagKey.freshItemCv).future,
      );
    } catch (_) {
      freshItemCvEnabled = false;
    }

    if (!freshItemCvEnabled) {
      _showSnack('Fresh item scan is currently unavailable');
      return;
    }

    if (!mounted) return;

    setState(() => _freshItemCvInProgress = true);

    try {
      final result = await ref.read(freshItemCaptureLauncherProvider)(
        context: context,
      );
      if (!mounted) return;

      if (result.isSuccess) {
        final selected = await _showFreshItemSuggestionPicker(
          result.suggestions,
        );
        if (!mounted || selected == null) {
          return;
        }

        _applyFreshItemSuggestion(selected);
        ref.read(telemetryClientProvider).enqueue({
          'name': 'fresh_item_cv_scanned',
          'properties': {
            'success': true,
            'suggestion_count': result.suggestions.length,
            'selected_name': selected.name,
            'selected_category': selected.category.name,
            'selected_type': selected.itemType.name,
            'source': selected.source,
          },
        });
        return;
      }

      switch (result.failure) {
        case FreshItemCaptureFailure.cancelled:
          return;
        case FreshItemCaptureFailure.noItemDetected:
          _showSnack('No recognizable fresh item detected');
          ref.read(telemetryClientProvider).enqueue({
            'name': 'fresh_item_cv_scanned',
            'properties': {'success': false, 'reason': 'no_item_detected'},
          });
          return;
        case FreshItemCaptureFailure.unavailable:
          _showSnack('Fresh item scan is not available on this platform yet');
          return;
        case FreshItemCaptureFailure.unknown:
        case null:
          _showSnack('Unable to identify the fresh item');
          ref.read(telemetryClientProvider).enqueue({
            'name': 'fresh_item_cv_scanned',
            'properties': {'success': false, 'reason': 'error'},
          });
          return;
      }
    } finally {
      if (mounted) {
        setState(() => _freshItemCvInProgress = false);
      }
    }
  }

  Future<FreshItemCvSuggestion?> _showFreshItemSuggestionPicker(
    List<FreshItemCvSuggestion> suggestions,
  ) async {
    return showModalBottomSheet<FreshItemCvSuggestion>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose item suggestion', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pick the closest match to prefill name, category, type, and storage.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                for (var index = 0; index < suggestions.length; index++)
                  ListTile(
                    key: Key('fresh_item_cv_suggestion_$index'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(suggestions[index].name),
                    subtitle: Text(
                      '${_localizedCategoryLabel(suggestions[index].category)} • ${_localizedLocationLabel(suggestions[index].location)} • ${(suggestions[index].confidence * 100).round()}% match',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.of(context).pop(suggestions[index]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyFreshItemSuggestion(FreshItemCvSuggestion suggestion) {
    setState(() {
      _nameController.text = suggestion.name;
      _selectedCategory = suggestion.category;
      _selectedUserCategory = null;
      _selectedLocation = suggestion.location;
      _selectedType = suggestion.itemType;
      _cameraFreshItemSuggestionName = suggestion.name;
      _cameraFreshItemSuggestionSource = suggestion.source;

      if (suggestion.itemType == ItemType.prepared) {
        _selectedPreparedDate ??= DateTime.now();
      } else {
        _selectedPreparedDate = null;
      }
    });
  }

  void _applyBarcodeCapture(BarcodeCaptureResult result) {
    final suggestedName = result.suggestedName?.trim();
    final suggestedBrand = result.suggestedBrand?.trim();
    final previousSuggestedName = _cameraSuggestedName;
    final currentName = _nameController.text.trim();
    final recentDefaults = _findRecentDefaultsForName(suggestedName);
    final shouldApplySuggestedName =
        !_isEditMode &&
        suggestedName != null &&
        (currentName.isEmpty ||
            (previousSuggestedName != null &&
                currentName == previousSuggestedName));

    if (shouldApplySuggestedName) {
      _nameController.text = suggestedName;
    }

    final normalizedBarcode = normalizeBarcodeValue(result.rawValue!)!;

    setState(() {
      _cameraBarcodeValue = normalizedBarcode;
      _cameraSuggestedName = suggestedName;
      _cameraSuggestionSource = result.source;
      _cameraAssistedStage = _CameraAssistedStage.barcodeLocked;
      _selectedType = ItemType.packaged;
      _selectedPreparedDate = null;

      if (recentDefaults != null) {
        _brandController.text = recentDefaults.brand ?? '';
        if (!_categoryTouched) {
          _selectedCategory = recentDefaults.category;
          _selectedUserCategory = _resolveRecentUserCategory(recentDefaults);
        }
        _selectedLocation = recentDefaults.location;
      } else if (_brandController.text.trim().isEmpty &&
          suggestedBrand != null &&
          suggestedBrand.isNotEmpty) {
        _brandController.text = suggestedBrand;
      } else if (!_categoryTouched) {
        if (result.suggestedCategory != null) {
          _selectedCategory = result.suggestedCategory!;
          _selectedUserCategory = null;
        } else if (suggestedName != null) {
          final inferredCategory = _inferCategoryFromName(suggestedName);
          if (inferredCategory != null) {
            _selectedCategory = inferredCategory;
            _selectedUserCategory = null;
          }
        }
      }
    });
  }

  Future<bool> _showExpiryOcrGuidance() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            key: const Key('expiry_ocr_guidance_dialog'),
            title: const Text('Point camera at expiry date'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Align the expiry text inside the camera frame.'),
                SizedBox(height: 8),
                Text('Use good lighting and hold the package steady.'),
                SizedBox(height: 8),
                Text(
                  'Canadian labels may show BB/MA before the date instead of EXP.',
                ),
                SizedBox(height: 8),
                Text(
                  'For embossed dates, tilt the package so side lighting creates shadow contrast.',
                ),
                SizedBox(height: 8),
                Text('You can always edit the detected date before saving.'),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('expiry_ocr_guidance_cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('expiry_ocr_guidance_continue'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Open Camera'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.init();
      final item = await repository.getItem(widget.itemId!);

      if (mounted) {
        if (item != null) {
          setState(() {
            _nameController.text = item.name;
            _brandController.text = item.brand ?? '';
            _selectedCategory = item.category;
            _selectedUserCategory = item.customCategoryId == null
                ? null
                : _userCategories.firstWhere(
                    (cat) => cat.id == item.customCategoryId,
                    orElse: () => UserCategory(
                      id: item.customCategoryId!,
                      name: item.customCategoryName ?? 'Custom',
                      createdAt: DateTime.now(),
                    ),
                  );
            _selectedType = item.type;
            _selectedPreparedDate = item.preparedDate;
            _selectedLocation = item.location;
            _selectedUnit = item.unit;
            _quantityController.text = item.quantity.toString();
            if (item.purchasePrice != null) {
              _priceController.text = item.purchasePrice!.toStringAsFixed(2);
            }
            _selectedExpiryDate = item.expiryDate;
            _selectedReceiptBatchId = item.receiptBatchId;
            _loadedReceiptBatchId = item.receiptBatchId;
            _existingReceiptBatchItemId = item.receiptBatchItemId;
            _existingCreatedAt = item.createdAt;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item not found'),
            ), // simple user feedback
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading item: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _normalizedBrand() {
    final brand = _brandController.text.trim();
    return brand.isEmpty ? null : brand;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _cameraAcceptedExpiryFormat = null;
      });
    }
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _performSave();
  }

  Future<void> _performSave() async {
    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.init();
      final existingItems = _isEditMode
          ? <Item>[]
          : await repository.getAllItems();
      final inventoryCountBeforeAdd = existingItems.length;
      final entryMethod = _entryMethodForSave();
      final cameraUsed = entryMethod != 'manual';
      final cameraBarcodeAccepted = _cameraBarcodeValue != null;
      final cameraFreshItemAccepted = _cameraFreshItemSuggestionName != null;
      final cameraExpiryAccepted = _cameraAcceptedExpiryFormat != null;

      final quantity = int.tryParse(_quantityController.text);
      final price = _priceController.text.isEmpty
          ? null
          : double.tryParse(_priceController.text.replaceAll(r'$', ''));
      final selectedReceiptBatchId = _selectedReceiptBatchId;
      final preserveBatchItemId =
          _isEditMode && selectedReceiptBatchId == _loadedReceiptBatchId;

      final item = Item(
        id: _isEditMode
            ? widget.itemId!
            : LocalIdGenerator.next(prefix: 'item'),
        name: _nameController.text.trim(),
        brand: _normalizedBrand(),
        category: _selectedCategory,
        customCategoryId: _selectedUserCategory?.id,
        customCategoryName: _selectedUserCategory?.name,
        type: _selectedType,
        preparedDate: _selectedPreparedDate,
        location: _selectedLocation,
        quantity: quantity == null || quantity <= 0 ? 1 : quantity,
        unit: _selectedUnit,
        expiryDate: _selectedExpiryDate,
        purchasePrice: price,
        receiptBatchId: selectedReceiptBatchId,
        receiptBatchItemId: preserveBatchItemId
            ? _existingReceiptBatchItemId
            : null,
        status: ItemStatus.available,
        wasteReason: null,
        createdAt: _existingCreatedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveItem(item);

      if (!_isEditMode) {
        final zestoService = ref.read(zestoServiceProvider);
        final addMessageType = inventoryCountBeforeAdd == 0
            ? MascotMessageType.firstItem
            : MascotMessageType.itemAdded;
        unawaited(
          zestoService.showMascot(addMessageType, bypassAntiSpam: true),
        );

        final allItemsAfterAdd = [...existingItems, item];
        final expiringWithin24hCount = allItemsAfterAdd
            .where((it) => it.status == ItemStatus.available)
            .where((it) => it.expiryDate != null)
            .where((it) {
              final hours = it.expiryDate!.difference(DateTime.now()).inHours;
              return hours >= 0 && hours < 24;
            })
            .length;
        unawaited(
          zestoService.onInventoryScannedForExpiry(
            expiringWithin24hCount: expiringWithin24hCount,
          ),
        );
      }

      if (_cameraBarcodeValue != null) {
        await ref
            .read(learnedBarcodeMappingStoreProvider)
            .saveMapping(
              rawValue: _cameraBarcodeValue!,
              name: item.name,
              category: item.category,
              brand: item.brand,
            );
      }

      // No longer disables demo mode on item save. Only settings screen can change demo mode.

      // Force refresh of inventory list
      ref.invalidate(itemsFutureProvider);

      // Telemetry: item added or updated
      final telemetry = ref.read(telemetryClientProvider);
      telemetry.enqueue({
        'name': _isEditMode ? 'item_updated' : 'item_added',
        'properties': {
          'item_id': item.id,
          'source': entryMethod,
          'entry_method': entryMethod,
          'camera_used': cameraUsed,
          'category': item.categoryLabel,
          'is_custom_category': item.customCategoryId != null,
          'location': item.location.name,
          'quantity': item.quantity,
          'has_expiry': item.expiryDate != null,
          'has_expiry_date': item.expiryDate != null,
          'camera_barcode_accepted': cameraBarcodeAccepted,
          'camera_fresh_item_accepted': cameraFreshItemAccepted,
          'camera_expiry_accepted': cameraExpiryAccepted,
          'camera_barcode_source': cameraBarcodeAccepted
              ? (_cameraSuggestionSource ?? 'unknown')
              : 'none',
          'camera_fresh_item_source': cameraFreshItemAccepted
              ? (_cameraFreshItemSuggestionSource ?? 'unknown')
              : 'none',
          'camera_expiry_format': _cameraAcceptedExpiryFormat ?? 'none',
        },
      });
      telemetry.enqueue({
        'name': 'category_assigned',
        'properties': {
          'category': item.categoryLabel,
          'is_custom': item.customCategoryId != null,
        },
      });
      if (_cameraBarcodeValue != null) {
        telemetry.enqueue({
          'name': 'camera_assisted_barcode_learned',
          'properties': {
            'barcode_length': _cameraBarcodeValue!.length,
            'category': item.category.name,
          },
        });
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} saved successfully')),
        );
        Navigator.pop(context, item);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final expiryOcrEnabledAsync = ref.watch(
      isFlagEnabledProvider(FeatureFlagKey.expiryDateOcr),
    );
    final freshItemCvEnabledAsync = ref.watch(
      isFlagEnabledProvider(FeatureFlagKey.freshItemCv),
    );
    final showExpiryOcrButton = expiryOcrEnabledAsync.maybeWhen(
      data: (enabled) => enabled && _supportsExpiryOcrPlatform,
      orElse: () => false,
    );
    final showFreshItemCvButton = freshItemCvEnabledAsync.maybeWhen(
      data: (enabled) => enabled && _supportsFreshItemCvPlatform,
      orElse: () => false,
    );
    final showCameraAssistedPanel =
        showExpiryOcrButton || showFreshItemCvButton;
    final recentSuggestions = _recentSuggestionsForQuery(_nameController.text);
    final recentBrandSuggestions = _recentBrandSuggestions(
      _brandController.text,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Item' : 'Add Item'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            if (showCameraAssistedPanel) ...[
              _buildCameraAssistedAddPanel(
                theme,
                showExpiryOcrButton: showExpiryOcrButton,
                showFreshItemCvButton: showFreshItemCvButton,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _buildIconPreview(),
            const SizedBox(height: AppSpacing.lg),
            // Name field (required)
            _buildFormGroup(
              label: 'Name *',
              labelKey: const Key('item_form_name_label'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    key: const Key('item_form_name_field'),
                    controller: _nameController,
                    decoration: _buildInputDecoration(hintText: 'e.g., Milk'),
                    onChanged: (value) {
                      if (!_isEditMode) {
                        _maybeAutoSetCategory(value);
                      }
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  if (!_isEditMode && recentSuggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (
                          var index = 0;
                          index < recentSuggestions.length;
                          index++
                        )
                          ActionChip(
                            key: Key('recent_item_suggestion_$index'),
                            label: Text(recentSuggestions[index].name),
                            onPressed: () => _applyRecentSuggestion(
                              recentSuggestions[index],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            _buildFormGroup(
              label: 'Brand (optional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    key: const Key('item_form_brand_field'),
                    controller: _brandController,
                    decoration: _buildInputDecoration(
                      hintText: 'e.g., Chobani',
                      suffixIcon: IconButton(
                        key: const Key('item_form_brand_picker_button'),
                        tooltip: 'Search recent brands',
                        onPressed: _openBrandPicker,
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (recentBrandSuggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (
                          var index = 0;
                          index < recentBrandSuggestions.length;
                          index++
                        )
                          ActionChip(
                            key: Key('recent_brand_suggestion_$index'),
                            label: Text(recentBrandSuggestions[index]),
                            onPressed: () {
                              setState(() {
                                _brandController.text =
                                    recentBrandSuggestions[index];
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Category dropdown (required)
            _buildFormGroup(
              label: '${l10n.labelCategory} *',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _openCategoryPicker,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: InputDecorator(
                      decoration: _buildInputDecoration(
                        hintText: l10n.itemFormSelectCategory,
                      ),
                      child: Row(
                        children: [
                          _buildCategoryIcon(
                            _selectedUserCategory != null
                                ? _CategoryOption(
                                    id: 'custom_${_selectedUserCategory!.id}',
                                    label: _selectedUserCategory!.name,
                                    isCustom: true,
                                    custom: _selectedUserCategory,
                                  )
                                : _CategoryOption(
                                    id: 'builtin_${_selectedCategory.name}',
                                    label: _localizedCategoryLabel(
                                      _selectedCategory,
                                    ),
                                    isCustom: false,
                                    builtIn: _selectedCategory,
                                  ),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              key: const Key('item_form_category_value'),
                              _selectedUserCategory?.name ??
                                  _localizedCategoryLabel(_selectedCategory),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.expand_more,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Type toggle (Raw vs Prepared)
            _buildFormGroup(
              label: '${l10n.labelType} *',
              child: SegmentedButton<ItemType>(
                segments: [
                  ButtonSegment(
                    value: ItemType.raw,
                    label: Text(
                      _localizedTypeLabel(ItemType.raw),
                      key: const Key('item_type_raw_label'),
                    ),
                  ),
                  ButtonSegment(
                    value: ItemType.prepared,
                    label: Text(
                      _localizedTypeLabel(ItemType.prepared),
                      key: const Key('item_type_prepared_label'),
                    ),
                  ),
                  ButtonSegment(
                    value: ItemType.packaged,
                    label: Text(
                      _localizedTypeLabel(ItemType.packaged),
                      key: const Key('item_type_packaged_label'),
                    ),
                  ),
                ],
                selected: {_selectedType},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  final selected = selection.first;
                  setState(() {
                    _selectedType = selected;
                    if (selected == ItemType.raw) {
                      _selectedLocation = StorageLocation.fridge;
                      _selectedExpiryDate = DateTime.now().add(
                        const Duration(days: 7),
                      );
                      _selectedPreparedDate = null;
                      _cameraAcceptedExpiryFormat = null;
                    } else if (selected == ItemType.prepared) {
                      _selectedPreparedDate = DateTime.now();
                      _selectedLocation = StorageLocation.freezer;
                      _selectedExpiryDate = DateTime.now().add(
                        const Duration(days: 30),
                      );
                      _cameraAcceptedExpiryFormat = null;
                    } else {
                      _selectedPreparedDate = null;
                      _selectedLocation = StorageLocation.pantry;
                      _selectedExpiryDate = DateTime.now().add(
                        const Duration(days: 30),
                      );
                      _cameraAcceptedExpiryFormat = null;
                    }
                  });
                },
              ),
            ),

            // Prepared date (only shown if type is Prepared)
            if (_selectedType == ItemType.prepared)
              _buildFormGroup(
                label: 'Prepared Date',
                child: GestureDetector(
                  key: const Key('item_form_prepared_date'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedPreparedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedPreparedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedPreparedDate == null
                              ? 'Select date'
                              : 'Prepared: ${_selectedPreparedDate!.toLocal().toString().split(' ')[0]}',
                          style: AppTextStyles.body.copyWith(
                            color: _selectedPreparedDate == null
                                ? theme.textTheme.bodySmall?.color
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const Text('📅', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),
              ),

            // Location dropdown (required)
            _buildFormGroup(
              label: 'Location *',
              child: DropdownButtonFormField<StorageLocation>(
                key: const Key('item_form_location_dropdown'),
                initialValue: _selectedLocation,
                decoration: _buildInputDecoration(hintText: 'Select location'),
                items: StorageLocation.values
                    .map(
                      (loc) => DropdownMenuItem(
                        value: loc,
                        child: Row(
                          children: [
                            Text(
                              _getLocationEmoji(loc),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(_localizedLocationLabel(loc)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLocation = value);
                  }
                },
              ),
            ),

            // Quantity and Unit in a row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormGroup(
                    label: 'Quantity',
                    child: QuantityToggle(
                      quantity: int.tryParse(_quantityController.text) ?? 1,
                      isEnabled: !_isLoading,
                      onConfirm: (newQty) {
                        setState(() {
                          _quantityController.text = newQty.toString();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 3,
                  child: _buildFormGroup(
                    label: 'Unit',
                    child: DropdownButtonFormField<Unit>(
                      key: const Key('item_form_unit_dropdown'),
                      initialValue: _selectedUnit,
                      decoration: _buildInputDecoration(
                        hintText: 'Select unit',
                      ),
                      items: Unit.values
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUnit = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Price field (optional)
            _buildFormGroup(
              label: 'Price Paid (optional) 💵',
              child: TextFormField(
                key: const Key('item_form_price_field'),
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _buildInputDecoration(
                  hintText: '\$3.99 total for this item',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final cleanValue = value.replaceAll(r'$', '');
                    final price = double.tryParse(cleanValue);
                    if (price == null || price < 0) {
                      return 'Enter a valid price';
                    }
                  }
                  return null;
                },
              ),
            ),

            // Optional receipt batch linkage
            _buildFormGroup(
              label: 'Shopping Batch (optional)',
              child: _loadingReceiptBatches
                  ? Text(
                      'Loading shopping batches...',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : DropdownButtonFormField<String?>(
                      key: const Key('item_form_batch_dropdown'),
                      initialValue: _selectedReceiptBatchId,
                      decoration: _buildInputDecoration(
                        hintText: 'Select batch',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No batch'),
                        ),
                        ..._availableReceiptBatches.map(
                          (batch) => DropdownMenuItem<String?>(
                            value: batch.id,
                            child: Text(_receiptBatchLabel(batch)),
                          ),
                        ),
                        if (_selectedReceiptBatchId != null &&
                            !_availableReceiptBatches.any(
                              (batch) => batch.id == _selectedReceiptBatchId,
                            ))
                          DropdownMenuItem<String?>(
                            value: _selectedReceiptBatchId,
                            child: Text(
                              'Linked batch (${_selectedReceiptBatchId!})',
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedReceiptBatchId = value);
                      },
                    ),
            ),

            // Expiry date picker with camera button
            _buildFormGroup(
              label: 'Expiry Date',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    key: const Key('item_form_expiry_date'),
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              key: const Key('item_form_expiry_date_value'),
                              _selectedExpiryDate == null
                                  ? 'Select date'
                                  : 'Expires: ${_selectedExpiryDate!.toLocal().toString().split(' ')[0]}',
                              style: AppTextStyles.body.copyWith(
                                color: _selectedExpiryDate == null
                                    ? theme.textTheme.bodySmall?.color
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              if (showExpiryOcrButton)
                                Tooltip(
                                  message: 'Scan expiry date',
                                  child: Semantics(
                                    button: true,
                                    label: 'Scan expiry date',
                                    child: IconButton(
                                      key: const Key('expiry_date_scan_button'),
                                      icon: _ocrInProgress
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              Icons.camera_alt_outlined,
                                              size: 20,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                      ),
                                      onPressed: _ocrInProgress
                                          ? null
                                          : _scanExpiryDate,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showExpiryOcrButton) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Scan the product label to fill the expiry date offline.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              height: 50,
              child: AppButton(
                key: const Key('item_form_save_button'),
                text: _isEditMode ? 'Update Item' : 'Add Item',
                onPressed: _isLoading ? null : _saveItem,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Cancel button
            SizedBox(
              height: 50,
              child: AppButton(
                key: const Key('item_form_cancel_button'),
                text: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
                secondary: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraAssistedAddPanel(
    ThemeData theme, {
    required bool showExpiryOcrButton,
    required bool showFreshItemCvButton,
  }) {
    final barcodeLocked =
        _cameraAssistedStage == _CameraAssistedStage.barcodeLocked ||
        _cameraAssistedStage == _CameraAssistedStage.expiryLocked;
    final expiryLocked =
        _cameraAssistedStage == _CameraAssistedStage.expiryLocked;
    final hasFreshItemSuggestion = _cameraFreshItemSuggestionName != null;
    final statusTitle = expiryLocked
        ? 'Expiry locked'
        : barcodeLocked
        ? 'Barcode locked'
        : hasFreshItemSuggestion
        ? 'Fresh item identified'
        : 'Scan barcode or fresh item';
    final statusMessage = expiryLocked
        ? 'Expiry has been captured. You can review the date below or rescan before saving.'
        : barcodeLocked
        ? 'Review the detected item details, then capture expiry from this panel next.'
        : hasFreshItemSuggestion
        ? 'Review the suggested item details below before saving or rescan for a different match.'
        : 'Use barcode for packaged items or fresh item scan for loose produce, meat, and prepared foods.';

    return Container(
      key: const Key('camera_assisted_add_panel'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Camera-assisted add', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            key: const Key('camera_assisted_barcode_stage'),
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Center(
              child: _barcodeScanInProgress
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          barcodeLocked
                              ? Icons.qr_code_2
                              : hasFreshItemSuggestion
                              ? Icons.eco_outlined
                              : Icons.photo_camera_back_outlined,
                          size: 36,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          barcodeLocked
                              ? 'Barcode captured for this item'
                              : hasFreshItemSuggestion
                              ? 'Fresh item suggestion ready'
                              : 'Barcode stage ready',
                          style: AppTextStyles.body.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_cameraBarcodeValue != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _cameraBarcodeValue!,
                            key: const Key('camera_assisted_detected_barcode'),
                            style: AppTextStyles.body.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('camera_assisted_scan_barcode_button'),
              onPressed: _barcodeScanInProgress ? null : _scanBarcode,
              icon: Icon(
                barcodeLocked
                    ? Icons.center_focus_strong
                    : Icons.qr_code_scanner,
              ),
              label: Text(barcodeLocked ? 'Rescan barcode' : 'Scan barcode'),
            ),
          ),
          if (showFreshItemCvButton) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('camera_assisted_scan_fresh_item_button'),
                onPressed: _freshItemCvInProgress ? null : _scanFreshItem,
                icon: _freshItemCvInProgress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        hasFreshItemSuggestion
                            ? Icons.center_focus_strong
                            : Icons.eco_outlined,
                      ),
                label: Text(
                  hasFreshItemSuggestion
                      ? 'Rescan fresh item'
                      : 'Identify fresh item',
                ),
              ),
            ),
          ],
          if (barcodeLocked && showExpiryOcrButton) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('camera_assisted_scan_expiry_button'),
                onPressed: _ocrInProgress ? null : _scanExpiryDate,
                icon: Icon(
                  expiryLocked
                      ? Icons.calendar_month
                      : Icons.document_scanner_outlined,
                ),
                label: Text(
                  expiryLocked ? 'Rescan expiry' : 'Scan expiry next',
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            statusTitle,
            key: Key(
              expiryLocked
                  ? 'camera_assisted_status_expiry_locked'
                  : barcodeLocked
                  ? 'camera_assisted_status_barcode_locked'
                  : hasFreshItemSuggestion
                  ? 'camera_assisted_status_fresh_item_detected'
                  : 'camera_assisted_status_barcode_ready',
            ),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            statusMessage,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          if (_cameraBarcodeValue != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Barcode: $_cameraBarcodeValue',
                    key: const Key('camera_assisted_detected_barcode_summary'),
                    style: AppTextStyles.body,
                  ),
                  if (_cameraSuggestedName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Suggested item: $_cameraSuggestedName',
                      key: const Key('camera_assisted_detected_name'),
                      style: AppTextStyles.body,
                    ),
                  ],
                  if (_cameraSuggestionSource != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Source: $_cameraSuggestionSource',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_cameraFreshItemSuggestionName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fresh item: $_cameraFreshItemSuggestionName',
                    key: const Key('camera_assisted_detected_fresh_item'),
                    style: AppTextStyles.body,
                  ),
                  if (_cameraFreshItemSuggestionSource != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Source: $_cameraFreshItemSuggestionSource',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_selectedExpiryDate != null && barcodeLocked) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Detected expiry: ${_selectedExpiryDate!.year.toString().padLeft(4, '0')}-${_selectedExpiryDate!.month.toString().padLeft(2, '0')}-${_selectedExpiryDate!.day.toString().padLeft(2, '0')}',
              key: const Key('camera_assisted_detected_expiry'),
              style: AppTextStyles.body,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            showExpiryOcrButton
                ? 'Expiry scan starts after barcode and will auto-lock once the date is stable.'
                : 'Fresh item suggestions prefill the form so you can confirm details faster.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPreview() {
    final theme = Theme.of(context);
    final name = _nameController.text.trim();
    final displayName = name.isEmpty
        ? (_isEditMode ? 'Item' : 'New item')
        : name;
    final brand = _normalizedBrand();
    final subtitle = brand == null
        ? (_selectedUserCategory?.name ??
              _localizedCategoryLabel(_selectedCategory))
        : '$brand • ${_selectedUserCategory?.name ?? _localizedCategoryLabel(_selectedCategory)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          ItemIcon(
            itemName: displayName,
            category: _selectedCategory,
            size: 40,
            showBackground: true,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key: const Key('item_form_preview_title'),
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormGroup({
    required String label,
    required Widget child,
    Key? labelKey,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key: labelKey,
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.textTheme.bodySmall?.color,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    );
  }

  String _localizedCategoryLabel(ItemCategory category) {
    final reference = _referenceCategoryLabels[category];
    if (reference != null && reference.trim().isNotEmpty) {
      return reference;
    }

    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    switch (category) {
      case ItemCategory.produce:
        return l10n.categoryProduce;
      case ItemCategory.dairy:
        return l10n.categoryDairy;
      case ItemCategory.meat:
        return l10n.categoryMeat;
      case ItemCategory.grains:
        return l10n.categoryGrains;
      case ItemCategory.pantry:
        return l10n.categoryPantry;
      case ItemCategory.other:
        return l10n.categoryOther;
    }
  }

  String _localizedLocationLabel(StorageLocation location) {
    final reference = _referenceLocationLabels[location];
    if (reference != null && reference.trim().isNotEmpty) {
      return reference;
    }

    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    switch (location) {
      case StorageLocation.fridge:
        return l10n.locationFridge;
      case StorageLocation.pantry:
        return l10n.locationPantry;
      case StorageLocation.freezer:
        return l10n.locationFreezer;
      case StorageLocation.other:
        return l10n.locationOther;
    }
  }

  String _localizedTypeLabel(ItemType type) {
    final reference = _referenceTypeLabels[type];
    if (reference != null && reference.trim().isNotEmpty) {
      return reference;
    }

    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    switch (type) {
      case ItemType.raw:
        return l10n.itemTypeRaw;
      case ItemType.prepared:
        return l10n.itemTypePrepared;
      case ItemType.packaged:
        return l10n.itemTypePackaged;
    }
  }

  String _getCategoryEmoji(ItemCategory category) {
    switch (category) {
      case ItemCategory.dairy:
        return '🥛';
      case ItemCategory.produce:
        return '🍎';
      case ItemCategory.meat:
        return '🍗';
      case ItemCategory.grains:
        return '🍞';
      case ItemCategory.pantry:
        return '🗄️';
      case ItemCategory.other:
        return '📦';
    }
  }

  String _getLocationEmoji(StorageLocation location) {
    switch (location) {
      case StorageLocation.fridge:
        return '❄️';
      case StorageLocation.freezer:
        return '🧊';
      case StorageLocation.pantry:
        return '🗄️';
      default:
        return '🏠';
    }
  }
}

/// Extension to convert Color to int32 for Hive storage
extension ColorExtension on Color {
  int toARGB32() {
    return ((a * 255).round() << 24) |
        ((r * 255).round() << 16) |
        ((g * 255).round() << 8) |
        ((b * 255).round());
  }
}
