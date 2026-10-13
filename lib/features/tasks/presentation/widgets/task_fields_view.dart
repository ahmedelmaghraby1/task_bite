import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/themes/colors.dart';

/// The task form fields shared by the manual composer tab and the AI draft
/// review: title (required), multiline description (optional) and an optional
/// due date. One widget = one consistent validation surface.
class TaskFieldsView extends StatelessWidget {
  const TaskFieldsView({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.dueDate,
    required this.onDueDateChanged,
    this.showTitleError = false,
    this.titleFocusNode,
    this.descriptionFocusNode,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onDueDateChanged;
  final bool showTitleError;
  final FocusNode? titleFocusNode;
  final FocusNode? descriptionFocusNode;

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'selectDate'.tr(context),
    );
    if (picked != null) onDueDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: titleController,
          focusNode: titleFocusNode,
          textInputAction: TextInputAction.next,
          maxLength: 120,
          decoration: InputDecoration(
            labelText: 'taskTitle'.tr(context),
            hintText: 'taskTitle'.tr(context),
            counterText: '',
            errorText: showTitleError ? 'titleRequired'.tr(context) : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          focusNode: descriptionFocusNode,
          minLines: 3,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: 'taskContent'.tr(context),
            hintText: 'taskContent'.tr(context),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 20,
                  color:
                      dueDate == null
                          ? scheme.onSurfaceVariant
                          : AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dueDate == null
                        ? 'dueDate'.tr(context)
                        : formatDate(dueDate!),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          dueDate == null
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                    ),
                  ),
                ),
                if (dueDate != null)
                  IconButton(
                    tooltip: 'clearDate'.tr(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => onDueDateChanged(null),
                  ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
