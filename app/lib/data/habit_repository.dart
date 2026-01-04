import 'package:sqflite/sqflite.dart';

import '../models/habit_item.dart';
import 'app_database.dart';
import 'todo_repository.dart';

class HabitRepository {
  HabitRepository._();

  static final HabitRepository instance = HabitRepository._();

  Database get _db => AppDatabase.instance.db;

  Future<List<HabitItem>> list({required bool isCompleted, required SortOrder order}) async {
    final orderBy = order == SortOrder.newestFirst
        ? 'updated_at DESC, created_at DESC'
        : 'updated_at ASC, created_at ASC';

    final rows = await _db.query(
      'habits',
      where: 'is_completed = ?',
      whereArgs: [isCompleted ? 1 : 0],
      orderBy: orderBy,
    );

    return rows.map(HabitItem.fromRow).toList(growable: false);
  }

  Future<int> create({required String name, required int denominator}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.insert('habits', {
      'name': name,
      'denominator': denominator,
      'numerator': 0,
      'is_completed': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<HabitItem?> getById(int id) async {
    final rows = await _db.query('habits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return HabitItem.fromRow(rows.single);
  }

  Future<void> update({
    required int id,
    required String name,
    required int denominator,
    required int numerator,
  }) async {
    final cappedNumerator = numerator.clamp(0, denominator);
    final isCompleted = cappedNumerator >= denominator;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.update(
      'habits',
      {
        'name': name,
        'denominator': denominator,
        'numerator': cappedNumerator,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<HabitItem?> increment(int id) async {
    final habit = await getById(id);
    if (habit == null) return null;
    if (habit.isCompleted) return habit;

    final newNumerator = (habit.numerator + 1).clamp(0, habit.denominator);
    await update(
      id: id,
      name: habit.name,
      denominator: habit.denominator,
      numerator: newNumerator,
    );
    return getById(id);
  }

  Future<HabitItem?> decrement(int id) async {
    final habit = await getById(id);
    if (habit == null) return null;

    final newNumerator = (habit.numerator - 1).clamp(0, habit.denominator);
    await update(
      id: id,
      name: habit.name,
      denominator: habit.denominator,
      numerator: newNumerator,
    );
    return getById(id);
  }

  Future<void> delete(int id) async {
    await _db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }
}
