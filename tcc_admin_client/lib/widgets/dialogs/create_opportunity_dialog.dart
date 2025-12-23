import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/investment_opportunity_model.dart';
import '../../services/investment_service.dart';
import '../../utils/validators.dart';

/// Dialog for creating a new investment opportunity
class CreateOpportunityDialog extends StatefulWidget {
  final Function(InvestmentOpportunityModel) onOpportunityCreated;
  final Map<String, int> opportunityCounts;

  const CreateOpportunityDialog({
    super.key,
    required this.onOpportunityCreated,
    required this.opportunityCounts,
  });

  @override
  State<CreateOpportunityDialog> createState() => _CreateOpportunityDialogState();
}

class _CreateOpportunityDialogState extends State<CreateOpportunityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _investmentService = InvestmentService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minInvestmentController = TextEditingController();
  final _maxInvestmentController = TextEditingController();
  final _returnRateController = TextEditingController();
  final _totalUnitsController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Form state
  String? _selectedCategoryId;
  int _selectedTenure = 12;
  bool _isSubmitting = false;
  String _errorMessage = '';

  // Available categories with IDs
  final Map<String, String> _categories = {};
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _minInvestmentController.dispose();
    _maxInvestmentController.dispose();
    _returnRateController.dispose();
    _totalUnitsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _investmentService.getInvestmentCategories();
      if (response.success && response.data != null) {
        setState(() {
          for (var category in response.data!) {
            // Only include Agriculture and Education
            if (category['name'] == 'AGRICULTURE' || category['name'] == 'EDUCATION') {
              _categories[category['id']] = category['name'];
            }
          }
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories';
        _isLoadingCategories = false;
      });
    }
  }

  bool _canSelectCategory(String categoryName) {
    final count = widget.opportunityCounts[categoryName] ?? 0;
    return count < 16;
  }

  int _getRemainingSlots(String categoryName) {
    final count = widget.opportunityCounts[categoryName] ?? 0;
    return 16 - count;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final response = await _investmentService.createInvestmentOpportunity(
        categoryId: _selectedCategoryId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        minInvestment: double.parse(_minInvestmentController.text),
        maxInvestment: double.parse(_maxInvestmentController.text),
        tenureMonths: _selectedTenure,
        returnRate: double.parse(_returnRateController.text),
        totalUnits: int.parse(_totalUnitsController.text),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      );

      if (response.success && response.data != null) {
        final opportunity = InvestmentOpportunityModel.fromJson(response.data!);
        widget.onOpportunityCreated(opportunity);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Investment opportunity created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to create opportunity';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  topRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_business,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Text(
                    'Create Investment Opportunity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_errorMessage.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                      ],

                      // Category selection
                      Text(
                        'Category *',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedCategoryId,
                              decoration: InputDecoration(
                                hintText: 'Select category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                filled: true,
                                fillColor: AppColors.white,
                              ),
                              items: _categories.entries.map((entry) {
                                final canSelect = _canSelectCategory(entry.value);
                                final remaining = _getRemainingSlots(entry.value);
                                return DropdownMenuItem(
                                  value: entry.key,
                                  enabled: canSelect,
                                  child: Row(
                                    children: [
                                      Text(
                                        entry.value == 'AGRICULTURE' ? 'Agriculture' : 'Education',
                                        style: TextStyle(
                                          color: canSelect ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.space8),
                                      Text(
                                        '($remaining/16 remaining)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: remaining > 0 ? AppColors.success : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: AppTheme.space16),

                      // Title
                      Text(
                        'Title *',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter opportunity title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        maxLength: 200,
                        validator: (value) =>
                            Validators.validateMinLength(value, 3, 'Title') ??
                            Validators.validateMaxLength(value, 200, 'Title'),
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Description
                      Text(
                        'Description *',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Enter detailed description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        maxLines: 4,
                        maxLength: 500,
                        validator: (value) =>
                            Validators.validateMinLength(value, 10, 'Description') ??
                            Validators.validateMaxLength(value, 500, 'Description'),
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Min and Max Investment (Row)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Min Investment (TCC) *',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                TextFormField(
                                  controller: _minInvestmentController,
                                  decoration: InputDecoration(
                                    hintText: '1000',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.white,
                                    prefixText: 'TCC ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: Validators.validatePositiveNumber,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Max Investment (TCC) *',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                TextFormField(
                                  controller: _maxInvestmentController,
                                  decoration: InputDecoration(
                                    hintText: '100000',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.white,
                                    prefixText: 'TCC ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: (value) {
                                    final error = Validators.validatePositiveNumber(value);
                                    if (error != null) return error;

                                    final minVal = double.tryParse(_minInvestmentController.text);
                                    final maxVal = double.tryParse(value ?? '');

                                    if (minVal != null && maxVal != null && maxVal <= minVal) {
                                      return 'Must be greater than min investment';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Tenure and Return Rate (Row)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tenure (Months) *',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                DropdownButtonFormField<int>(
                                  initialValue: _selectedTenure,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.white,
                                  ),
                                  items: [6, 12, 24, 36].map((months) {
                                    return DropdownMenuItem(
                                      value: months,
                                      child: Text('$months months'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTenure = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Return Rate (%) *',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                TextFormField(
                                  controller: _returnRateController,
                                  decoration: InputDecoration(
                                    hintText: '15.5',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.white,
                                    suffixText: '%',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: (value) => Validators.validateNumberRange(value, 0.1, 100, 'Return rate'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Total Units
                      Text(
                        'Total Units *',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      TextFormField(
                        controller: _totalUnitsController,
                        decoration: InputDecoration(
                          hintText: '100',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => Validators.validateNumberRange(value, 1, 1000, 'Total units'),
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Image URL (Optional)
                      Text(
                        'Image URL (Optional)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/image.jpg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            return Validators.validateUrl(value);
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusMedium),
                  bottomRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSubmitting ? 'Creating...' : 'Create Opportunity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space24,
                        vertical: AppTheme.space16,
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
  }
}
