import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/investment_opportunity_model.dart';
import '../../services/investment_service.dart';
import '../../utils/validators.dart';

/// Dialog for editing an existing investment opportunity
class EditOpportunityDialog extends StatefulWidget {
  final InvestmentOpportunityModel opportunity;
  final Function(InvestmentOpportunityModel) onOpportunityUpdated;

  const EditOpportunityDialog({
    super.key,
    required this.opportunity,
    required this.onOpportunityUpdated,
  });

  @override
  State<EditOpportunityDialog> createState() => _EditOpportunityDialogState();
}

class _EditOpportunityDialogState extends State<EditOpportunityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _investmentService = InvestmentService();

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _minInvestmentController;
  late final TextEditingController _maxInvestmentController;
  late final TextEditingController _returnRateController;
  late final TextEditingController _totalUnitsController;
  late final TextEditingController _imageUrlController;

  // Form state
  late int _selectedTenure;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _titleController = TextEditingController(text: widget.opportunity.title);
    _descriptionController = TextEditingController(text: widget.opportunity.description);
    _minInvestmentController = TextEditingController(text: widget.opportunity.minInvestment.toString());
    _maxInvestmentController = TextEditingController(text: widget.opportunity.maxInvestment.toString());
    _returnRateController = TextEditingController(text: widget.opportunity.returnRate.toString());
    _totalUnitsController = TextEditingController(text: widget.opportunity.totalUnits.toString());
    _imageUrlController = TextEditingController(text: widget.opportunity.imageUrl ?? '');
    _selectedTenure = widget.opportunity.tenureMonths;
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

  bool _hasChanges() {
    return _titleController.text != widget.opportunity.title ||
        _descriptionController.text != widget.opportunity.description ||
        double.tryParse(_minInvestmentController.text) != widget.opportunity.minInvestment ||
        double.tryParse(_maxInvestmentController.text) != widget.opportunity.maxInvestment ||
        double.tryParse(_returnRateController.text) != widget.opportunity.returnRate ||
        int.tryParse(_totalUnitsController.text) != widget.opportunity.totalUnits ||
        _imageUrlController.text != (widget.opportunity.imageUrl ?? '') ||
        _selectedTenure != widget.opportunity.tenureMonths;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasChanges()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final response = await _investmentService.updateInvestmentOpportunity(
        opportunityId: widget.opportunity.id,
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
        widget.onOpportunityUpdated(opportunity);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Investment opportunity updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to update opportunity';
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
    final hasSoldUnits = widget.opportunity.soldUnits > 0;

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
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  topRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit,
                    color: AppColors.warning,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Text(
                    'Edit Investment Opportunity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.warning,
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
                      // Warning banner if there are sold units
                      if (hasSoldUnits) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: AppColors.warning),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(
                                child: Text(
                                  'This opportunity has ${widget.opportunity.soldUnits} active investors. '
                                  'Changing critical fields (tenure, return rate) may affect them.',
                                  style: const TextStyle(color: AppColors.warning, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                      ],

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

                      // Category (Read-only)
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppColors.bgPrimary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: AppTheme.space8),
                            Text(
                              widget.opportunity.categoryDisplayName,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Text(
                              '(Cannot be changed)',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
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
                                    fillColor: hasSoldUnits ? AppColors.warning.withValues(alpha: 0.05) : AppColors.white,
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
                                    fillColor: hasSoldUnits ? AppColors.warning.withValues(alpha: 0.05) : AppColors.white,
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
                          helperText: 'Available: ${widget.opportunity.availableUnits} | Sold: ${widget.opportunity.soldUnits}',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          final error = Validators.validateNumberRange(value, widget.opportunity.soldUnits.toDouble(), 1000, 'Total units');
                          if (error != null) return error;

                          final newTotal = int.tryParse(value ?? '');
                          if (newTotal != null && newTotal < widget.opportunity.soldUnits) {
                            return 'Cannot be less than sold units (${widget.opportunity.soldUnits})';
                          }
                          return null;
                        },
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
                        : const Icon(Icons.save),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
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
