import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/partner_model.dart';
import 'package:frontend/services/partner_service.dart';
import 'package:frontend/services/toast_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/custom_textfield.dart';

class AddEditPartnerDialog extends StatefulWidget {
  final PartnerModel? partner;

  const AddEditPartnerDialog({super.key, this.partner});

  @override
  State<AddEditPartnerDialog> createState() => _AddEditPartnerDialogState();
}

class _AddEditPartnerDialogState extends State<AddEditPartnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final PartnerService _partnerService = PartnerService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;

  String _type = 'Customer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.partner?.name);
    _emailController = TextEditingController(text: widget.partner?.email);
    _phoneController = TextEditingController(text: widget.partner?.phone);
    _addressController = TextEditingController(text: widget.partner?.address);
    _gstController = TextEditingController(text: widget.partner?.gstNumber);
    _type = widget.partner?.type ?? 'Customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final partnerData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'type': _type,
        if (_gstController.text.trim().isNotEmpty)
          'gstNumber': _gstController.text.trim(),
      };

      final result = widget.partner == null
          ? await _partnerService.createPartner(
              PartnerModel(
                id: '',
                name: partnerData['name'] as String,
                email: partnerData['email'] as String,
                phone: partnerData['phone'] as String,
                address: partnerData['address'] as String,
                type: partnerData['type'] as String,
                gstNumber: partnerData.containsKey('gstNumber')
                    ? partnerData['gstNumber'] as String
                    : null,
              ),
            )
          : await _partnerService.updatePartner(widget.partner!.id, partnerData);

      if (mounted) {
        if (result['success']) {
          AppToast.showSuccess(
            context,
            widget.partner == null
                ? 'Partner created successfully'
                : 'Partner updated successfully',
          );
          Navigator.pop(context, true);
        } else {
          AppToast.showError(
            context,
            result['message'] ?? 'Failed to save partner',
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
        constraints: const BoxConstraints(maxHeight: 700),
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
                    Icons.people_outline,
                    color: AppColors.theme['primaryColor'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.partner == null ? 'Add New Partner' : 'Edit Partner',
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
                      // Partner Type Selection
                      Text(
                        'Partner Type',
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
                              onTap: () => setState(() => _type = 'Customer'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _type == 'Customer'
                                      ? (AppColors.theme['primaryColor'] as Color)
                                          .withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _type == 'Customer'
                                        ? AppColors.theme['primaryColor']
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: _type == 'Customer'
                                          ? AppColors.theme['primaryColor']
                                          : AppColors.theme['secondaryColor'],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Customer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _type == 'Customer'
                                            ? AppColors.theme['primaryColor']
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
                              onTap: () => setState(() => _type = 'Vendor'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _type == 'Vendor'
                                      ? (AppColors.theme['primaryColor'] as Color)
                                          .withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _type == 'Vendor'
                                        ? AppColors.theme['primaryColor']
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.business_outlined,
                                      color: _type == 'Vendor'
                                          ? AppColors.theme['primaryColor']
                                          : AppColors.theme['secondaryColor'],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vendor',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _type == 'Vendor'
                                            ? AppColors.theme['primaryColor']
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
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Enter partner name',
                        labelText: 'Partner Name',
                        prefixIcon: Icons.business,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter partner name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter email address',
                        labelText: 'Email Address',
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'Enter phone number',
                        labelText: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        hintText: 'Enter full address',
                        labelText: 'Address',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _gstController,
                        hintText: 'Enter GST number (optional)',
                        labelText: 'GST Number',
                        prefixIcon: Icons.receipt_long_outlined,
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
                    title: widget.partner == null ? 'Add Partner' : 'Save Changes',
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
