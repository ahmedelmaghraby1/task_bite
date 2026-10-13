import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/cubit/task_composer_state.dart';
import 'package:taskbite/features/tasks/presentation/widgets/task_composer_sheet.dart';

/// The docked primary actions: "Speak a task" and "Type a task".
///
/// Both open the same composer; only the initial tab differs, and switching
/// tabs inside the composer never loses entered content.
class PrimaryActionBar extends StatelessWidget {
  const PrimaryActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.mic_rounded,
              label: 'speakATask'.tr(context),
              filled: true,
              onTap:
                  () =>
                      showTaskComposer(context, initialTab: ComposerTab.voice),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_note_rounded,
              label: 'typeATask'.tr(context),
              filled: false,
              onTap:
                  () =>
                      showTaskComposer(context, initialTab: ComposerTab.manual),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: filled ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: filled ? null : Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: filled ? scheme.onPrimary : scheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: filled ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
