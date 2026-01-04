import 'package:sqflite/sqflite.dart';

import '../models/todo_item.dart';
import 'app_database.dart';

enum SortOrder {
  newestFirst,
  oldestFirst,
}

class TodoRepository {
  TodoRepository._();

  static final TodoRepository instance = TodoRepository._();

  Database get _db => AppDatabase.instance.db;

  Future<List<TodoItem>> list({required bool isCompleted, required SortOrder order}) async {
    final orderBy = order == SortOrder.newestFirst
        ? 'created_at DESC, updated_at DESC'
        : 'created_at ASC, updated_at ASC';

    final rows = await _db.query(
      'todos',
      where: 'is_completed = ?',
      whereArgs: [isCompleted ? 1 : 0],
      orderBy: orderBy,
    );

    return rows.map(TodoItem.fromRow).toList(growable: false);
  }

  Future<int> create({
    required String title,
    required int denominator,
    required int targetDays,
    String memo = '',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.insert('todos', {
      'title': title,
      'memo': memo,
      'numerator': 0,
      'denominator': denominator,
      'target_days': targetDays,
      'achieved_days': 0,
      'is_completed': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<TodoItem?> getById(int id) async {
    final rows = await _db.query('todos', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return TodoItem.fromRow(rows.single);
  }

  Future<void> updateTodo({
    required int id,
    required String title,
    required String memo,
    required int numerator,
    required int denominator,
    required int targetDays,
    required int achievedDays,
    required bool isCompleted,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.update(
      'todos',
      {
        'title': title,
        'memo': memo,
        'numerator': numerator,
        'denominator': denominator,
        'target_days': targetDays,
        'achieved_days': achievedDays,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateProgress({
    required int id,
    required int numerator,
    required int achievedDays,
    required bool isCompleted,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.update(
      'todos',
      {
        'numerator': numerator,
        'achieved_days': achievedDays,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setCompleted({required int id, required bool isCompleted}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawUpdate(
      'UPDATE todos '
      'SET is_completed = ?, '
      'numerator = CASE WHEN ? = 1 THEN denominator ELSE 0 END, '
      'achieved_days = CASE WHEN ? = 1 THEN target_days ELSE 0 END, '
      'updated_at = ? '
      'WHERE id = ?',
      [isCompleted ? 1 : 0, isCompleted ? 1 : 0, isCompleted ? 1 : 0, now, id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
