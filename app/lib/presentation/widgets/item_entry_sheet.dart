library;

import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import 'quantity_toggle.dart';

class ItemEntrySeed {
  const ItemEntrySeed({
    required this.name,
    this.category,
    this.quantity,
    this.unit,
    this.purchasePrice,
    this.type,
    this.preparedDate,
  });

  final String name;
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

class ItemEntrySheet extends StatefulWidget {
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
  State<ItemEntrySheet> createState() => _ItemEntrySheetState();
}

class _ItemEntrySheetState extends State<ItemEntrySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  ItemCategory _category = ItemCategory.produce;
  ItemType _type = ItemType.raw;
  DateTime? _preparedDate;
  StorageLocation _location = StorageLocation.fridge;
  Unit _unit = Unit.count;
  int _quantity = 1;
  DateTime? _expiryDate;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.seed?.name ?? '');
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final qtyValid = _quantity > 0;
    final expiryValid = !widget.requireExpiry || _expiryDate != null;
    return nameValid && qtyValid && expiryValid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              ],
            ),
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
