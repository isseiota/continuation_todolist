import 'package:flutter/material.dart';

import '../data/habit_repository.dart';
import '../models/habit_item.dart';
import 'habit_edit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  static Route<bool> route({required int habitId}) {
    return MaterialPageRoute<bool>(
      builder: (_) => HabitDetailScreen(habitId: habitId),
    );
  }

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  HabitItem? _habit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habit = await HabitRepository.instance.getById(widget.habitId);
    if (!mounted) return;
    setState(() {
      _habit = habit;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      HabitEditScreen.route(habitId: widget.habitId),
    );
    if (!mounted) return;
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete() async {
    final habit = _habit;
    if (habit == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除しますか？'),
          content: const Text('この継続目標を削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('閉じる'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await HabitRepository.instance.delete(habit.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _increment() async {
    final before = _habit;
    if (before == null) return;

    final updated = await HabitRepository.instance.increment(before.id);
    if (!mounted) return;

    setState(() {
      _habit = updated;
    });

    final after = updated;
    if (after == null) return;

    if (!before.isCompleted && after.isCompleted) {
      final undo = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('達成しました！'),
            content: const Text('おめでとうございます！'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('閉じる'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('取り消し'),
              ),
            ],
          );
        },
      );

      if (undo == true) {
        await HabitRepository.instance.decrement(before.id);
        await _load();
      }
    }
  }

  Future<void> _decrement() async {
    final habit = _habit;
    if (habit == null) return;

    final updated = await HabitRepository.instance.decrement(habit.id);
    if (!mounted) return;
    setState(() {
      _habit = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habit = _habit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('継続目標詳細'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _edit,
            icon: const Icon(Icons.edit),
            tooltip: '編集',
          ),
          IconButton(
            onPressed: _loading ? null : _delete,
            icon: const Icon(Icons.delete),
            tooltip: '削除',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : habit == null
              ? const Center(child: Text('見つかりませんでした'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${habit.numerator}/${habit.denominator}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(child: Text(habit.isCompleted ? '完了済み' : '未完了')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: habit.numerator <= 0 ? null : _decrement,
                              child: const Text('－1'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: habit.isCompleted ? null : _increment,
                              child: const Text('＋1'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
