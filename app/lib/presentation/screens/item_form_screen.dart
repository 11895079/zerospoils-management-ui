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
      SnackBar(
        content: Text(_isEditMode ? 'Item updated!' : 'Item added!'),
      ),
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                labelStyle: AppTextStyles.label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category dropdown
            DropdownButtonFormField<ItemCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                labelStyle: AppTextStyles.label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              items: ItemCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Location dropdown
            DropdownButtonFormField<StorageLocation>(
              initialValue: _selectedLocation,
              decoration: InputDecoration(
                labelText: 'Location *',
                labelStyle: AppTextStyles.label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              items: StorageLocation.values.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLocation = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quantity field
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                labelStyle: AppTextStyles.label,
                hintText: 'e.g., 1, 500 (grams)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid positive number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Expiry date picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  labelStyle: AppTextStyles.label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedExpiryDate == null
                      ? 'Select date (optional)'
                      : '${_selectedExpiryDate!.year}-${_selectedExpiryDate!.month.toString().padLeft(2, '0')}-${_selectedExpiryDate!.day.toString().padLeft(2, '0')}',
                  style: AppTextStyles.body,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Save button
            AppButton(
              onPressed: _saveItem,
              text: _isEditMode ? 'Update Item' : 'Add Item',
              fullWidth: true,
            ),

            const SizedBox(height: AppSpacing.md),

            // Cancel button
            AppButton(
              onPressed: () => Navigator.of(context).pop(),
              text: 'Cancel',
              secondary: true,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
