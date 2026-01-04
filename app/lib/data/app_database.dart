import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'mokuhyo_tsumia_todo.db');

    _db = await openDatabase(
      fullPath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE todos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  memo TEXT NOT NULL DEFAULT '',
  numerator INTEGER NOT NULL DEFAULT 0,
  denominator INTEGER NOT NULL DEFAULT 1,
  target_days INTEGER NOT NULL DEFAULT 1,
  achieved_days INTEGER NOT NULL DEFAULT 0,
  is_completed INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''');

        await db.execute('''
CREATE TABLE habits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  denominator INTEGER NOT NULL,
  numerator INTEGER NOT NULL,
  is_completed INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE todos ADD COLUMN denominator INTEGER NOT NULL DEFAULT 1',
          );
        }

        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE todos ADD COLUMN numerator INTEGER NOT NULL DEFAULT 0',
          );
        }

        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE todos ADD COLUMN target_days INTEGER NOT NULL DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE todos ADD COLUMN achieved_days INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('Database is not initialized. Call AppDatabase.init() first.');
    }
    return database;
  }
}
