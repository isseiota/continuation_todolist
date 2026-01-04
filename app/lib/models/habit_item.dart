class HabitItem {
  HabitItem({
    required this.id,
    required this.name,
    required this.denominator,
    required this.numerator,
    required this.isCompleted,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });

  final int id;
  final String name;
  final int denominator;
  final int numerator;
  final bool isCompleted;
  final int createdAtMillis;
  final int updatedAtMillis;

  HabitItem copyWith({
    String? name,
    int? denominator,
    int? numerator,
    bool? isCompleted,
    int? createdAtMillis,
    int? updatedAtMillis,
  }) {
    return HabitItem(
      id: id,
      name: name ?? this.name,
      denominator: denominator ?? this.denominator,
      numerator: numerator ?? this.numerator,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
  }

  static HabitItem fromRow(Map<String, Object?> row) {
    return HabitItem(
      id: row['id'] as int,
      name: row['name'] as String,
      denominator: row['denominator'] as int,
      numerator: row['numerator'] as int,
      isCompleted: (row['is_completed'] as int) == 1,
      createdAtMillis: row['created_at'] as int,
      updatedAtMillis: row['updated_at'] as int,
    );
  }
}
