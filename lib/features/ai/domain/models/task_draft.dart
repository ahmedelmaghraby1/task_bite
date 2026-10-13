/// An editable, validated task draft produced either by the AI service or by
/// the user typing manually. The draft is what gets reviewed and edited before
/// a task is persisted.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    this.dueDate,
    this.sourceTranscript,
  });

  final String title;
  final String description;
  final DateTime? dueDate;

  /// The original spoken transcript this draft was generated from, kept so
  /// the user can recover their words after a failed AI call.
  final String? sourceTranscript;

  bool get hasMeaningfulTitle => title.trim().isNotEmpty;

  bool get hasDueDate => dueDate != null;

  TaskDraft copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? sourceTranscript,
    bool clearSourceTranscript = false,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      sourceTranscript:
          clearSourceTranscript
              ? null
              : (sourceTranscript ?? this.sourceTranscript),
    );
  }

  @override
  String toString() =>
      'TaskDraft(title: "$title", description: "$description", dueDate: $dueDate)';
}
