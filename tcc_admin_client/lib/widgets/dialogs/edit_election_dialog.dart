import 'package:flutter/material.dart';
import '../../models/election_model.dart';
import '../../services/election_service.dart';

class EditElectionDialog extends StatefulWidget {
  final Election election;

  const EditElectionDialog({Key? key, required this.election}) : super(key: key);

  @override
  State<EditElectionDialog> createState() => _EditElectionDialogState();
}

class _EditElectionDialogState extends State<EditElectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final ElectionService _electionService = ElectionService();

  late TextEditingController _titleController;
  late TextEditingController _questionController;
  late TextEditingController _votingChargeController;
  late List<TextEditingController> _optionControllers;

  DateTime? _endTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.election.title);
    _questionController = TextEditingController(text: widget.election.question);
    _votingChargeController = TextEditingController(
      text: widget.election.votingCharge.toString(),
    );
    _endTime = widget.election.endTime;

    // Initialize option controllers with existing options
    _optionControllers = widget.election.options
            ?.map((option) => TextEditingController(text: option.optionText))
            .toList() ??
        [TextEditingController(), TextEditingController()];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    _votingChargeController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _selectEndTime() async {
    final now = DateTime.now();
    final currentEndTime = _endTime ?? now.add(const Duration(days: 7));

    final date = await showDatePicker(
      context: context,
      initialDate: currentEndTime.isAfter(now) ? currentEndTime : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentEndTime),
      );

      if (time != null) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an end time')),
      );
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 2 options')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = UpdateElectionRequest(
        title: _titleController.text.trim(),
        question: _questionController.text.trim(),
        options: options,
        votingCharge: double.parse(_votingChargeController.text),
        endTime: _endTime!,
      );

      await _electionService.updateElection(widget.election.id, request);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Election updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show warning if election has votes
    if (widget.election.hasVotes) {
      return AlertDialog(
        title: const Text('Cannot Edit Election'),
        content: const Text(
          'This election cannot be edited because votes have already been cast.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Edit Election'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Elections can only be edited if no votes have been cast yet.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Election Title *',
                    hintText: 'Enter election title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (value.length > 255) {
                      return 'Title must be 255 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question *',
                    hintText: 'Enter the election question',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Question is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _votingChargeController,
                  decoration: const InputDecoration(
                    labelText: 'Voting Charge (Le) *',
                    hintText: 'Enter voting charge',
                    prefixText: 'Le ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Voting charge is required';
                    }
                    final charge = double.tryParse(value);
                    if (charge == null || charge < 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _endTime == null
                            ? 'End Time: Not selected'
                            : 'End Time: ${_endTime.toString().substring(0, 16)}',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _selectEndTime,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Options *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              hintText: 'Enter option text',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Option cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_optionControllers.length > 2) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeOption(index),
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
