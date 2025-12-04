import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../models/poll_model.dart';
import '../../services/poll_service.dart';

/// Dialog for creating a new poll
class CreatePollDialog extends StatefulWidget {
  final Function(PollModel) onPollCreated;

  const CreatePollDialog({
    super.key,
    required this.onPollCreated,
  });

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pollService = PollService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _voteChargeController = TextEditingController(text: '50.0');

  // Poll options (minimum 2)
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Set default dates
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _voteChargeController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 options allowed'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 2 options required'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateVoteCharge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vote charge is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Enter a valid amount';
    }
    if (amount < 0) {
      return 'Amount cannot be negative';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext dialogContext, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: dialogContext,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (builderContext, child) {
        return Theme(
          data: Theme.of(builderContext).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accentPurple,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;

      final TimeOfDay? timePicked = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: dialogContext,
        initialTime: TimeOfDay.now(),
        builder: (builderContext, child) {
          return Theme(
            data: Theme.of(builderContext).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.accentPurple,
                onPrimary: AppColors.white,
                surface: AppColors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (timePicked != null && mounted) {
        final selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked.hour,
          timePicked.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDate = selectedDateTime;
            // If end date is before start date, adjust it
            if (_endDate != null && _endDate!.isBefore(selectedDateTime)) {
              _endDate = selectedDateTime.add(const Duration(days: 7));
            }
          } else {
            _endDate = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate options
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      setState(() {
        _errorMessage = 'At least 2 options are required';
      });
      return;
    }

    // Check for duplicate options
    final uniqueOptions = options.toSet();
    if (uniqueOptions.length != options.length) {
      setState(() {
        _errorMessage = 'Duplicate options are not allowed';
      });
      return;
    }

    // Validate dates
    if (_startDate == null || _endDate == null) {
      setState(() {
        _errorMessage = 'Please select start and end dates';
      });
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _errorMessage = 'End date must be after start date';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final response = await _pollService.createPoll(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        voteCharge: double.parse(_voteChargeController.text),
        options: options,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          widget.onPollCreated(response.data!);
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Poll created successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = response.error?.message ?? 'Failed to create poll';
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: isSmallScreen ? screenSize.width * 0.9 : 700,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.how_to_vote,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Poll',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a new poll for users to vote on',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Poll Title *',
                          hintText: 'Enter a descriptive title',
                          prefixIcon: Icon(Icons.title, color: AppColors.gray500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                          ),
                        ),
                        validator: (value) => _validateRequired(value, 'Title'),
                        maxLength: 200,
                      ),
                      const SizedBox(height: AppTheme.space20),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Provide details about the poll',
                          prefixIcon: Icon(Icons.description, color: AppColors.gray500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                          ),
                        ),
                        validator: (value) => _validateRequired(value, 'Description'),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      const SizedBox(height: AppTheme.space20),

                      // Vote Charge
                      TextFormField(
                        controller: _voteChargeController,
                        decoration: InputDecoration(
                          labelText: 'Vote Charge (NGN) *',
                          hintText: '50.0',
                          prefixIcon: Icon(Icons.attach_money, color: AppColors.gray500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                          ),
                          helperText: 'Amount users pay to vote',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: _validateVoteCharge,
                      ),
                      const SizedBox(height: AppTheme.space20),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.space16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.gray300),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: AppColors.gray500),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Start Date *',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _startDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} ${_startDate!.hour}:${_startDate!.minute.toString().padLeft(2, '0')}'
                                          : 'Select date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.space16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.gray300),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event, size: 16, color: AppColors.gray500),
                                        const SizedBox(width: 8),
                                        Text(
                                          'End Date *',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _endDate != null
                                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year} ${_endDate!.hour}:${_endDate!.minute.toString().padLeft(2, '0')}'
                                          : 'Select date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space24),

                      // Poll Options Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Poll Options',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Min: 2, Max: 10',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space12),

                      // Options List
                      ...List.generate(_optionControllers.length, (index) {
                        final controller = _optionControllers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.space12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1} *',
                                    hintText: 'Enter option text',
                                    prefixIcon: Icon(
                                      Icons.radio_button_unchecked,
                                      color: AppColors.gray500,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                                    ),
                                  ),
                                  validator: (value) => _validateRequired(value, 'Option ${index + 1}'),
                                  maxLength: 100,
                                ),
                              ),
                              if (_optionControllers.length > 2) ...[
                                const SizedBox(width: AppTheme.space8),
                                IconButton(
                                  onPressed: () => _removeOption(index),
                                  icon: Icon(Icons.remove_circle, color: AppColors.error),
                                  tooltip: 'Remove option',
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                      // Add Option Button
                      if (_optionControllers.length < 10)
                        OutlinedButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Option'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentPurple,
                            side: BorderSide(color: AppColors.accentPurple),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space20,
                              vertical: AppTheme.space12,
                            ),
                          ),
                        ),

                      // Error Message
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space20),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusLarge),
                  bottomRight: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSubmitting ? 'Creating...' : 'Create Poll'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
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
