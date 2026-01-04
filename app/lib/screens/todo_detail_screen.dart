import 'package:flutter/material.dart';

import '../data/todo_repository.dart';
import '../models/todo_item.dart';
import 'todo_edit_screen.dart';

class TodoDetailScreen extends StatefulWidget {
  const TodoDetailScreen({super.key, required this.todoId});

  final int todoId;

  static Route<bool> route({required int todoId}) {
    return MaterialPageRoute<bool>(
      builder: (_) => TodoDetailScreen(todoId: todoId),
    );
  }

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  TodoItem? _todo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todo = await TodoRepository.instance.getById(widget.todoId);
    if (!mounted) return;
    setState(() {
      _todo = todo;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      TodoEditScreen.route(todoId: widget.todoId),
    );
    if (!mounted) return;
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete() async {
    final todo = _todo;
    if (todo == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除しますか？'),
          content: const Text('このTodoを削除します。'),
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

    await TodoRepository.instance.delete(todo.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo詳細'),
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
          : _todo == null
              ? const Center(child: Text('見つかりませんでした'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _todo!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(_todo!.isCompleted ? '完了済み' : '未完了'),
                        ],
                      ),
                      if (!_todo!.isCompleted && (_todo!.targetDays > 1)) ...[
                        const SizedBox(height: 8),
                        Text(
                          '日数: ${_todo!.achievedDays.clamp(0, _todo!.targetDays)}/${_todo!.targetDays}',
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            const progressBarWidth = 160.0;
                            final targetDays = _todo!.targetDays <= 0 ? 1 : _todo!.targetDays;
                            final daysProgressValue = targetDays > 1
                                ? (_todo!.achievedDays.clamp(0, targetDays) / targetDays).clamp(0.0, 1.0)
                                : 0.0;

                            return SizedBox(
                              width: progressBarWidth,
                              child: LinearProgressIndicator(value: daysProgressValue),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (!_todo!.isCompleted)
                        Builder(
                          builder: (context) {
                            final todo = _todo!;
                            const progressBarWidth = 160.0;
                            final denominator = todo.denominator <= 0 ? 1 : todo.denominator;
                            final progressValue = (todo.numerator / denominator).clamp(0.0, 1.0);
                            final percent = (progressValue * 100).round();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('進捗: $percent%'),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: progressBarWidth,
                                  child: LinearProgressIndicator(value: progressValue),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(_todo!.memo.isEmpty ? '（メモなし）' : _todo!.memo),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
