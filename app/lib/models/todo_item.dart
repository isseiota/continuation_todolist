class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    required this.memo,
    required this.numerator,
    required this.denominator,
    required this.targetDays,
    required this.achievedDays,
    required this.isCompleted,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  final int id;
  final String title;
  final String memo;
  final int numerator;
  final int denominator;
  final int targetDays;
  final int achievedDays;
  final bool isCompleted;
  final int createdAtMillis;
  final int updatedAtMillis;

  TodoItem copyWith({
    String? title,
    String? memo,
    int? numerator,
    int? denominator,
    int? targetDays,
    int? achievedDays,
    bool? isCompleted,
    int? createdAtMillis,
    int? updatedAtMillis,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
      targetDays: targetDays ?? this.targetDays,
      achievedDays: achievedDays ?? this.achievedDays,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  static TodoItem fromRow(Map<String, Object?> row) {
    return TodoItem(
      id: row['id'] as int,
      title: row['title'] as String,
      memo: (row['memo'] as String?) ?? '',
      numerator: (row['numerator'] as int?) ?? 0,
      denominator: (row['denominator'] as int?) ?? 1,
      targetDays: (row['target_days'] as int?) ?? 1,
      achievedDays: (row['achieved_days'] as int?) ?? 0,
      isCompleted: (row['is_completed'] as int) == 1,
      createdAtMillis: row['created_at'] as int,
      updatedAtMillis: row['updated_at'] as int,
    );
  }
}
