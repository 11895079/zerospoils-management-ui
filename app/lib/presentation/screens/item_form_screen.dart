library;

/// Add/Edit Item form screen
/// Captures item name, category, location, quantity, expiry date

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../widgets/app_button.dart';

class ItemFormScreen extends StatefulWidget {
  final String? itemId; // null for add, non-null for edit

  const ItemFormScreen({super.key, this.itemId});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  ItemCategory _selectedCategory = ItemCategory.produce;
  StorageLocation _selectedLocation = StorageLocation.fridge;
  DateTime? _selectedExpiryDate;

  bool get _isEditMode => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // TODO: Load item from repository by itemId
      _loadItem();
    }
  }

  void _loadItem() {
    // Placeholder: In real implementation, fetch from repository
    _nameController.text = 'Existing Item';
    _quantityController.text = '2';
    _selectedCategory = ItemCategory.dairy;
    _selectedLocation = StorageLocation.fridge;
    _selectedExpiryDate = DateTime.now().add(const Duration(days: 5));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
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

    // TODO: Save to repository
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditMode ? 'Item updated!' : 'Item added!')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          _isEditMode ? 'Edit Item' : 'Add Item',
          style: AppTextStyles.h3,
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            // Name field (required)
            _buildFormGroup(
              label: 'Name *',
              child: TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(hintText: 'e.g., Milk'),
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
              child: DropdownButtonFormField<ItemCategory>(
                initialValue: _selectedCategory,
                decoration: _buildInputDecoration(hintText: 'Select category'),
                items: ItemCategory.values
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(
                              _getCategoryEmoji(cat),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(cat.displayName),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
            ),

            // Location dropdown (required)
            _buildFormGroup(
              label: 'Location *',
              child: DropdownButtonFormField<StorageLocation>(
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

            // Quantity field
            _buildFormGroup(
              label: 'Quantity',
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(hintText: '1'),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Quantity must be a positive number';
                    }
                  }
                  return null;
                },
              ),
            ),

            // Expiry date picker
            _buildFormGroup(
              label: 'Expiry Date',
              child: GestureDetector(
                onTap: () => _selectDate(context),
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
                        _selectedExpiryDate == null
                            ? 'Select date'
                            : 'Expires: ${_selectedExpiryDate!.toLocal().toString().split(' ')[0]}',
                        style: AppTextStyles.body.copyWith(
                          color: _selectedExpiryDate == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Text('📅', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              height: 50,
              child: AppButton(
                text: _isEditMode ? 'Update Item' : 'Add Item',
                onPressed: _saveItem,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Cancel button
            SizedBox(
              height: 50,
              child: AppButton(
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
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
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
