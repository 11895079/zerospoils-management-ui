library;

/// Add/Edit Item form screen
/// Captures item name, category, location, quantity, expiry date

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/user_category.dart';
import '../../domain/utils/expiry_date_parser.dart';
import '../widgets/app_button.dart';
import '../widgets/item_icon.dart';
import '../widgets/quantity_toggle.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' hide itemRepositoryProvider;

class ItemFormScreen extends ConsumerStatefulWidget {
  final String? itemId; // null for add, non-null for edit

  const ItemFormScreen({super.key, this.itemId});

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
  final ImagePicker _imagePicker = ImagePicker();
  final ExpiryDateParser _expiryDateParser = const ExpiryDateParser();

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

  bool get _isEditMode => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _loadUserCategories();
    if (_isEditMode) {
      _loadItem();
    }
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

  void _maybeAutoSetCategory(String value) {
    if (_categoryTouched) return;
    final inferred = _inferCategoryFromName(value);
    if (inferred == null || inferred == _selectedCategory) return;
    setState(() => _selectedCategory = inferred);
  }

  ItemCategory? _inferCategoryFromName(String value) {
    final name = value.trim().toLowerCase();
    if (name.isEmpty) return null;

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
            label: category.displayName,
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
    final searchController = TextEditingController();
    final newCategoryController = TextEditingController();
    final iconController = TextEditingController();
    final existingNames = {
      ...ItemCategory.values.map((c) => c.displayName.toLowerCase()),
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
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
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
                      Text('Select category', style: AppTextStyles.h3),
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
    if (kIsWeb) {
      _showSnack('Expiry OCR is not available on web yet');
      return;
    }

    setState(() => _ocrInProgress = true);
    TextRecognizer? textRecognizer;

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) {
        return;
      }

      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final input = InputImage.fromFilePath(photo.path);
      final result = await textRecognizer.processImage(input);

      final parsed = _expiryDateParser.parse(result.text);
      if (parsed == null) {
        _showSnack('No expiry date detected');
        ref.read(telemetryClientProvider).enqueue({
          'name': 'expiry_date_scanned',
          'properties': {'success': false, 'format_detected': 'none'},
        });
        return;
      }

      setState(() => _selectedExpiryDate = parsed.date);
      _showSnack('Expiry date detected');
      ref.read(telemetryClientProvider).enqueue({
        'name': 'expiry_date_scanned',
        'properties': {'success': true, 'format_detected': parsed.format},
      });
    } on PlatformException catch (_) {
      _showSnack('Camera permission denied');
      ref.read(telemetryClientProvider).enqueue({
        'name': 'expiry_date_scanned',
        'properties': {
          'success': false,
          'format_detected': 'permission_denied',
        },
      });
    } catch (_) {
      _showSnack('Unable to scan expiry date');
      ref.read(telemetryClientProvider).enqueue({
        'name': 'expiry_date_scanned',
        'properties': {'success': false, 'format_detected': 'error'},
      });
    } finally {
      await textRecognizer?.close();
      if (mounted) setState(() => _ocrInProgress = false);
    }
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
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
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

      final quantity = int.tryParse(_quantityController.text);
      final price = _priceController.text.isEmpty
          ? null
          : double.tryParse(_priceController.text.replaceAll(r'$', ''));

      final item = Item(
        id: _isEditMode
            ? widget.itemId!
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
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
        status: ItemStatus.available,
        wasteReason: null,
        createdAt: _existingCreatedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveItem(item);

      // No longer disables demo mode on item save. Only settings screen can change demo mode.

      // Force refresh of inventory list
      ref.invalidate(itemsFutureProvider);

      // Telemetry: item added or updated
      final telemetry = ref.read(telemetryClientProvider);
      telemetry.enqueue({
        'name': _isEditMode ? 'item_updated' : 'item_added',
        'properties': {
          'item_id': item.id,
          'category': item.categoryLabel,
          'is_custom_category': item.customCategoryId != null,
          'location': item.location.name,
          'quantity': item.quantity,
          'has_expiry': item.expiryDate != null,
        },
      });
      telemetry.enqueue({
        'name': 'category_assigned',
        'properties': {
          'category': item.categoryLabel,
          'is_custom': item.customCategoryId != null,
        },
      });

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} saved successfully')),
        );
        Navigator.pop(context);
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
    final isPro = ref.watch(proEntitlementProvider);
    final ocrEnabled = ref.watch(expiryDateOcrFeatureProvider);
    final showExpiryOcrButton = isPro && ocrEnabled && !kIsWeb;

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
            _buildIconPreview(),
            const SizedBox(height: AppSpacing.lg),
            // Name field (required)
            _buildFormGroup(
              label: 'Name *',
              child: TextFormField(
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
            ),

            // Category dropdown (required)
            _buildFormGroup(
              label: 'Category *',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _openCategoryPicker,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: InputDecorator(
                      decoration: _buildInputDecoration(
                        hintText: 'Select category',
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
                                    label: _selectedCategory.displayName,
                                    isCustom: false,
                                    builtIn: _selectedCategory,
                                  ),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedUserCategory?.name ??
                                  _selectedCategory.displayName,
                              style: AppTextStyles.body,
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
              label: 'Type *',
              child: SegmentedButton<ItemType>(
                segments: const [
                  ButtonSegment(
                    value: ItemType.raw,
                    label: Text('Raw', key: Key('item_type_raw_label')),
                  ),
                  ButtonSegment(
                    value: ItemType.prepared,
                    label: Text(
                      'Prepared',
                      key: Key('item_type_prepared_label'),
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
                    } else {
                      _selectedPreparedDate = DateTime.now();
                      _selectedLocation = StorageLocation.freezer;
                      _selectedExpiryDate = DateTime.now().add(
                        const Duration(days: 30),
                      );
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
                            Text(loc.displayName),
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
                  const SizedBox(height: 4),
                  Text(
                    'Or scan the expiry date with camera',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
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

  Widget _buildIconPreview() {
    final theme = Theme.of(context);
    final name = _nameController.text.trim();
    final displayName = name.isEmpty
        ? (_isEditMode ? 'Item' : 'New item')
        : name;

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
                  displayName,
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedUserCategory?.name ?? _selectedCategory.displayName,
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

  Widget _buildFormGroup({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    final theme = Theme.of(context);

    return InputDecoration(
      hintText: hintText,
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
