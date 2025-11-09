import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/services/product_service.dart';
import 'package:frontend/services/toast_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/custom_textfield.dart';

class AddEditProductDialog extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _saleTaxController;

  bool _canSell = true;
  bool _canPurchase = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _unitController = TextEditingController(text: widget.product?.unit);
    _saleTaxController = TextEditingController(
      text: widget.product?.saleTax.toString() ?? '0',
    );

    if (widget.product != null) {
      _canSell = widget.product!.canBeSold;
      _canPurchase = widget.product!.canBePurchased;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _saleTaxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_canSell && !_canPurchase) {
      AppToast.showError(context, 'Please select at least one product type');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final types = <String>[];
      if (_canSell) types.add('sale');
      if (_canPurchase) types.add('purchase');

      final productData = {
        'name': _nameController.text.trim(),
        'type': types,
        'unit': _unitController.text.trim(),
        'saleTax': double.parse(_saleTaxController.text.trim()),
      };

      final result = widget.product == null
          ? await _productService.createProduct(
              ProductModel(
                id: '',
                name: productData['name'] as String,
                type: productData['type'] as List<String>,
                unit: productData['unit'] as String,
                saleTax: productData['saleTax'] as double,
              ),
            )
          : await _productService.updateProduct(
              widget.product!.id,
              productData,
            );

      if (mounted) {
        if (result['success']) {
          AppToast.showSuccess(
            context,
            widget.product == null
                ? 'Product created successfully'
                : 'Product updated successfully',
          );
          Navigator.pop(context, true);
        } else {
          AppToast.showError(
            context,
            result['message'] ?? 'Failed to save product',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (AppColors.theme['primaryColor'] as Color)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.theme['primaryColor'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.product == null ? 'Add New Product' : 'Edit Product',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.theme['textColor'],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Enter product name',
                        labelText: 'Product Name',
                        prefixIcon: Icons.inventory_2_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Product Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.theme['textColor'],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _canSell = !_canSell),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _canSell
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _canSell
                                        ? Colors.blue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _canSell
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: _canSell
                                          ? Colors.blue
                                          : AppColors.theme['secondaryColor'],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Can be Sold',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _canSell
                                            ? Colors.blue
                                            : AppColors.theme['textColor'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _canPurchase = !_canPurchase),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _canPurchase
                                      ? Colors.purple.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _canPurchase
                                        ? Colors.purple
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _canPurchase
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: _canPurchase
                                          ? Colors.purple
                                          : AppColors.theme['secondaryColor'],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Can be Purchased',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _canPurchase
                                            ? Colors.purple
                                            : AppColors.theme['textColor'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _unitController,
                              hintText: 'e.g., Kg, Nos, Liter',
                              labelText: 'Unit of Measure',
                              prefixIcon: Icons.straighten_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter unit';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _saleTaxController,
                              hintText: 'Enter tax percentage',
                              labelText: 'Sale Tax (%)',
                              prefixIcon: Icons.percent_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter tax';
                                }
                                final tax = double.tryParse(value);
                                if (tax == null || tax < 0 || tax > 100) {
                                  return 'Invalid tax percentage';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Common units: Nos, Kg, Liter, Meter, Hour, etc.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.theme['secondaryColor'],
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.theme['textColor'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    title: widget.product == null ? 'Add Product' : 'Save Changes',
                    onTap: _save,
                    isLoading: _isLoading,
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
