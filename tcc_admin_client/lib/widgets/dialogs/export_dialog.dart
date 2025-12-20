import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';

enum ExportFormat { pdf, excel, csv }

class ExportDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Future<void> Function(ExportFormat format) onExport;
  final Map<String, dynamic>? filters;

  const ExportDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.onExport,
    this.filters,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppTheme.space8),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.space24),
            Text(
              'Select Export Format',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            _buildFormatOption(
              ExportFormat.pdf,
              'PDF Document',
              'Best for printing and sharing',
              Icons.picture_as_pdf,
            ),
            const SizedBox(height: AppTheme.space12),
            _buildFormatOption(
              ExportFormat.excel,
              'Excel Spreadsheet',
              'Best for data analysis and manipulation',
              Icons.table_chart,
            ),
            const SizedBox(height: AppTheme.space12),
            _buildFormatOption(
              ExportFormat.csv,
              'CSV File',
              'Best for importing to other systems',
              Icons.file_copy,
            ),
            if (widget.filters != null && widget.filters!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space24),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          'Active Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    ...widget.filters!.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.space32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppTheme.space16),
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space20,
                      vertical: AppTheme.space16,
                    ),
                  ),
                  icon: _isExporting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isExporting ? 'Exporting...' : 'Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    ExportFormat format,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedFormat == format;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.05) : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentBlue.withValues(alpha: 0.1)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.accentBlue : AppColors.gray500,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<ExportFormat>(
              value: format,
              groupValue: _selectedFormat,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFormat = value;
                  });
                }
              },
              activeColor: AppColors.accentBlue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    debugPrint('=== EXPORT DIALOG: Starting export ===');
    debugPrint('Selected format: $_selectedFormat');
    debugPrint('Active filters: ${widget.filters}');

    setState(() {
      _isExporting = true;
    });

    try {
      debugPrint('Calling onExport callback...');
      await widget.onExport(_selectedFormat);
      debugPrint('onExport callback completed successfully');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export started. The file will be downloaded shortly.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
      debugPrint('=== EXPORT DIALOG: Success ===');
    } catch (e, stackTrace) {
      debugPrint('=== EXPORT DIALOG: Exception caught ===');
      debugPrint('Exception type: ${e.runtimeType}');
      debugPrint('Exception message: ${e.toString()}');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      debugPrint('=== EXPORT DIALOG: Error shown to user ===');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
      debugPrint('=== EXPORT DIALOG: Completed ===');
    }
  }
}