library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/feature_flags/feature_flag_key.dart';
import '../../core/feature_flags/feature_flags_provider.dart';
import '../../core/ocr/expiry_date_ocr_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../ocr/expiry_ocr_capture_launcher.dart';
import 'quantity_toggle.dart';

class ItemEntrySeed {
  const ItemEntrySeed({
    required this.name,
    this.brand,
    this.category,
    this.quantity,
    this.unit,
    this.purchasePrice,
    this.type,
    this.preparedDate,
  });

  final String name;
  final String? brand;
  final ItemCategory? category;
  final int? quantity;
  final Unit? unit;
  final double? purchasePrice;
  final ItemType? type;
  final DateTime? preparedDate;
}

class ItemEntryResult {
  const ItemEntryResult({
    required this.name,
    required this.brand,
    required this.category,
    required this.location,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.purchasePrice,
    required this.type,
    required this.preparedDate,
    this.addAnother = false,
    this.applyToAll = false,
  }) : skipped = false;

  const ItemEntryResult.skipped()
    : skipped = true,
      name = '',
      brand = null,
      category = ItemCategory.other,
      location = StorageLocation.fridge,
      quantity = 1,
      unit = Unit.count,
      expiryDate = null,
      purchasePrice = null,
      type = ItemType.raw,
      preparedDate = null,
      addAnother = false,
      applyToAll = false;

  final bool skipped;
  final String name;
  final String? brand;
  final ItemCategory category;
  final StorageLocation location;
  final int quantity;
  final Unit unit;
  final DateTime? expiryDate;
  final double? purchasePrice;
  final ItemType type;
  final DateTime? preparedDate;
  final bool addAnother;
  final bool applyToAll;
}

class ItemEntrySheet extends ConsumerStatefulWidget {
  const ItemEntrySheet({
    super.key,
    required this.requireExpiry,
    this.seed,
    this.sourceLabel,
    this.showSkip = false,
    this.showAddAnother = false,
    this.showApplyToAll = false,
  });

  final bool requireExpiry;
  final ItemEntrySeed? seed;
  final String? sourceLabel;
  final bool showSkip;
  final bool showAddAnother;
  final bool showApplyToAll;

  @override
  ConsumerState<ItemEntrySheet> createState() => _ItemEntrySheetState();
}

class _ItemEntrySheetState extends ConsumerState<ItemEntrySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _priceController;
  ItemCategory _category = ItemCategory.produce;
  ItemType _type = ItemType.raw;
  DateTime? _preparedDate;
  StorageLocation _location = StorageLocation.fridge;
  Unit _unit = Unit.count;
  int _quantity = 1;
  DateTime? _expiryDate;
  bool _applyToAll = false;
  bool _ocrInProgress = false;
  List<String> _recentBrands = const [];

  bool get _supportsExpiryOcrPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.seed?.name ?? '');
    _brandController = TextEditingController(text: widget.seed?.brand ?? '');
    _priceController = TextEditingController(
      text: widget.seed?.purchasePrice == null
          ? ''
          : widget.seed!.purchasePrice!.toStringAsFixed(2),
    );
    _quantity = widget.seed?.quantity ?? 1;
    _category = widget.seed?.category ?? ItemCategory.produce;
    _unit = widget.seed?.unit ?? Unit.count;
    _type = widget.seed?.type ?? ItemType.raw;
    _preparedDate = widget.seed?.preparedDate;
    _loadRecentBrands();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentBrands() async {
    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.init();
      final items = await repository.getAllItems();
      final sortedItems = [...items]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final seenBrands = <String>{};
      final recentBrands = <String>[];

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

      if (!mounted) {
        return;
      }

      setState(() {
        _recentBrands = recentBrands;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recentBrands = const [];
      });
    }
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
                      Text('Select brand', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search brands',
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurfaceVariant,
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
                            if (options.isNotEmpty)
                              ...options.map(
                                (brand) => ListTile(
                                  title: Text(brand),
                                  onTap: () => Navigator.pop(context, brand),
                                ),
                              ),
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

  String? _normalizedBrand() {
    final brand = _brandController.text.trim();
    return brand.isEmpty ? null : brand;
  }

  bool get _canSave {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final qtyValid = _quantity > 0;
    final expiryValid = !widget.requireExpiry || _expiryDate != null;
    return nameValid && qtyValid && expiryValid;
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

    final view = View.of(context);
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
        setState(() => _expiryDate = parsed.date);
        _showSnack('Expiry date detected');
        SemanticsService.sendAnnouncement(
          view,
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

  Future<bool> _showExpiryOcrGuidance() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            key: const Key('item_entry_expiry_ocr_guidance_dialog'),
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
                Text('You can always edit the detected date before saving.'),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('item_entry_expiry_ocr_guidance_cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('item_entry_expiry_ocr_guidance_continue'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiryOcrEnabledAsync = ref.watch(
      isFlagEnabledProvider(FeatureFlagKey.expiryDateOcr),
    );
    final showExpiryOcrButton = expiryOcrEnabledAsync.maybeWhen(
      data: (enabled) => enabled && _supportsExpiryOcrPlatform,
      orElse: () => false,
    );
    final recentBrandSuggestions = _recentBrandSuggestions(
      _brandController.text,
    );
    return Padding(
      key: const Key('item_entry_sheet'),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Item', style: AppTextStyles.h4),
            if (widget.sourceLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                key: const Key('item_entry_source_label'),
                widget.sourceLabel!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('item_entry_name'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('item_entry_brand_field'),
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand (optional)',
                suffixIcon: IconButton(
                  key: const Key('item_entry_brand_picker_button'),
                  tooltip: 'Search recent brands',
                  onPressed: _openBrandPicker,
                  icon: const Icon(Icons.arrow_drop_down),
                ),
              ),
              textInputAction: TextInputAction.next,
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
                      key: Key('item_entry_brand_suggestion_$index'),
                      label: Text(recentBrandSuggestions[index]),
                      onPressed: () {
                        setState(() {
                          _brandController.text = recentBrandSuggestions[index];
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ItemCategory>(
              key: const Key('item_entry_category'),
              initialValue: _category,
              items: ItemCategory.values
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Type', style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<ItemType>(
              segments: const [
                ButtonSegment(value: ItemType.raw, label: Text('Raw')),
                ButtonSegment(
                  value: ItemType.prepared,
                  label: Text('Prepared'),
                ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                final selected = selection.first;
                setState(() {
                  _type = selected;
                  if (selected == ItemType.raw) {
                    _preparedDate = null;
                  } else {
                    _preparedDate ??= DateTime.now();
                  }
                });
              },
            ),
            if (_type == ItemType.prepared) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Prepared Date', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton(
                key: const Key('item_entry_prepared_date'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _preparedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (picked == null) return;
                  setState(() => _preparedDate = picked);
                },
                child: Text(
                  _preparedDate == null
                      ? 'Select date'
                      : '${_preparedDate!.month}/${_preparedDate!.day}/${_preparedDate!.year}',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<StorageLocation>(
              key: const Key('item_entry_location'),
              initialValue: _location,
              items: StorageLocation.values
                  .map(
                    (loc) => DropdownMenuItem(
                      value: loc,
                      child: Text(loc.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _location = value);
              },
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity', style: AppTextStyles.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      QuantityToggle(
                        key: const Key('item_entry_quantity_toggle'),
                        quantity: _quantity,
                        isEnabled: true,
                        onConfirm: (newQty) {
                          setState(() => _quantity = newQty);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<Unit>(
                    key: const Key('item_entry_unit'),
                    initialValue: _unit,
                    items: Unit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _unit = value);
                    },
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('item_entry_price'),
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price (optional)',
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Expiry Date', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  key: const Key('item_entry_expiry_1w'),
                  onPressed: () {
                    setState(() {
                      _expiryDate = DateTime.now().add(const Duration(days: 7));
                    });
                  },
                  child: const Text('1 week'),
                ),
                OutlinedButton(
                  key: const Key('item_entry_expiry_2w'),
                  onPressed: () {
                    setState(() {
                      _expiryDate = DateTime.now().add(
                        const Duration(days: 14),
                      );
                    });
                  },
                  child: const Text('2 weeks'),
                ),
                OutlinedButton(
                  key: const Key('item_entry_expiry_4w'),
                  onPressed: () {
                    setState(() {
                      _expiryDate = DateTime.now().add(
                        const Duration(days: 28),
                      );
                    });
                  },
                  child: const Text('4 weeks'),
                ),
                OutlinedButton(
                  key: const Key('item_entry_expiry_picker'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked == null) return;
                    setState(() => _expiryDate = picked);
                  },
                  child: Text(
                    _expiryDate == null
                        ? 'Pick date'
                        : '${_expiryDate!.month}/${_expiryDate!.day}/${_expiryDate!.year}',
                  ),
                ),
                if (showExpiryOcrButton)
                  Tooltip(
                    message: 'Scan expiry date',
                    child: Semantics(
                      button: true,
                      label: 'Scan expiry date',
                      child: IconButton(
                        key: const Key('item_entry_expiry_scan_button'),
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
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        onPressed: _ocrInProgress ? null : _scanExpiryDate,
                      ),
                    ),
                  ),
              ],
            ),
            if (showExpiryOcrButton) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Scan the product label to fill the expiry date offline.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
            if (widget.showApplyToAll) ...[
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                key: const Key('item_entry_apply_all'),
                value: _applyToAll,
                onChanged: (value) {
                  setState(() => _applyToAll = value ?? false);
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Apply to all remaining items'),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (widget.showSkip)
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('item_entry_skip'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const ItemEntryResult.skipped()),
                      child: const Text('Skip'),
                    ),
                  ),
                if (widget.showSkip) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('item_entry_cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (widget.showAddAnother) ...[
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('item_entry_save_add_another'),
                      onPressed: _canSave
                          ? () {
                              final priceText = _priceController.text
                                  .replaceAll(r'$', '')
                                  .replaceAll(',', '')
                                  .trim();
                              final price = priceText.isEmpty
                                  ? null
                                  : double.tryParse(priceText);

                              Navigator.of(context).pop(
                                ItemEntryResult(
                                  name: _nameController.text.trim(),
                                  brand: _normalizedBrand(),
                                  category: _category,
                                  location: _location,
                                  quantity: _quantity,
                                  unit: _unit,
                                  expiryDate: _expiryDate,
                                  purchasePrice: price,
                                  type: _type,
                                  preparedDate: _preparedDate,
                                  addAnother: true,
                                  applyToAll: _applyToAll,
                                ),
                              );
                            }
                          : null,
                      child: const Text('Save & Add Another'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: ElevatedButton(
                    key: const Key('item_entry_save'),
                    onPressed: _canSave
                        ? () {
                            final priceText = _priceController.text
                                .replaceAll(r'$', '')
                                .replaceAll(',', '')
                                .trim();
                            final price = priceText.isEmpty
                                ? null
                                : double.tryParse(priceText);

                            Navigator.of(context).pop(
                              ItemEntryResult(
                                name: _nameController.text.trim(),
                                brand: _normalizedBrand(),
                                category: _category,
                                location: _location,
                                quantity: _quantity,
                                unit: _unit,
                                expiryDate: _expiryDate,
                                purchasePrice: price,
                                type: _type,
                                preparedDate: _preparedDate,
                                applyToAll: _applyToAll,
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
