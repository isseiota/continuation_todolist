import 'package:flutter/material.dart';

import '../data/todo_repository.dart';
import '../models/todo_item.dart';
import '../widgets/ad_banner.dart';
import 'todo_detail_screen.dart';
import 'todo_edit_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final SortOrder _sortOrder = SortOrder.newestFirst;
  bool _loading = true;

  List<TodoItem> _incomplete = const [];
  List<TodoItem> _completed = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
    });

    try {
      final incomplete = await TodoRepository.instance.list(
        isCompleted: false,
        order: _sortOrder,
      );
      final completed = await TodoRepository.instance.list(
        isCompleted: true,
        order: _sortOrder,
      );

      if (!mounted) return;
      setState(() {
        _incomplete = incomplete;
        _completed = completed;
        _loading = false;
      });
    } on StateError {
      if (!mounted) return;
      setState(() {
        _incomplete = const [];
        _completed = const [];
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final changed = await Navigator.of(context).push<bool>(
      TodoEditScreen.route(),
    );
    if (!mounted) return;
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openDetail(int todoId) async {
    final changed = await Navigator.of(context).push<bool>(
      TodoDetailScreen.route(todoId: todoId),
    );
    if (!mounted) return;
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _setCompletedWithDialog(TodoItem item, bool isCompleted) async {
    if (item.isCompleted == isCompleted) return;

    if (!isCompleted && item.targetDays > 1) {
      final targetDays = item.targetDays <= 0 ? 1 : item.targetDays;
      await TodoRepository.instance.updateProgress(
        id: item.id,
        numerator: 0,
        achievedDays: (item.achievedDays - 1).clamp(0, targetDays),
        isCompleted: false,
      );
      await _reload();
      return;
    }

    await TodoRepository.instance.setCompleted(id: item.id, isCompleted: isCompleted);
    await _reload();
    if (!mounted) return;

    if (isCompleted) {
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
        await TodoRepository.instance.setCompleted(id: item.id, isCompleted: false);
        await _reload();
      }
    }
  }

  Future<void> _incrementWithDialog(TodoItem item) async {
    if (item.isCompleted) return;
    final denominator = item.denominator <= 0 ? 1 : item.denominator;
    final targetDays = item.targetDays <= 0 ? 1 : item.targetDays;
    final currentAchievedDays = item.achievedDays.clamp(0, targetDays);

    final nextNumeratorRaw = (item.numerator + 1).clamp(0, denominator);
    final reachedDailyGoal = nextNumeratorRaw >= denominator;

    int nextAchievedDays = currentAchievedDays;
    int nextNumerator = nextNumeratorRaw;
    bool nextCompleted;

    if (targetDays > 1) {
      if (reachedDailyGoal) {
        nextAchievedDays = (currentAchievedDays + 1).clamp(0, targetDays);
        nextCompleted = nextAchievedDays >= targetDays;
        nextNumerator = nextCompleted ? denominator : 0;
      } else {
        nextCompleted = false;
      }
    } else {
      nextCompleted = nextNumeratorRaw >= denominator;
    }

    await TodoRepository.instance.updateProgress(
      id: item.id,
      numerator: nextNumerator,
      achievedDays: nextAchievedDays,
      isCompleted: nextCompleted,
    );
    await _reload();
    if (!mounted) return;

    if (targetDays > 1 && !nextCompleted) return;

    if (nextCompleted) {
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
        if (targetDays > 1) {
          await TodoRepository.instance.updateProgress(
            id: item.id,
            numerator: (denominator - 1).clamp(0, denominator),
            achievedDays: (nextAchievedDays - 1).clamp(0, targetDays),
            isCompleted: false,
          );
        } else {
          await TodoRepository.instance.updateProgress(
            id: item.id,
            numerator: (denominator - 1).clamp(0, denominator),
            achievedDays: 0,
            isCompleted: false,
          );
        }
        await _reload();
      }
    }
  }

  Widget _buildList(List<TodoItem> items) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(child: Text('（なし）'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!item.isCompleted)
                Builder(
                  builder: (context) {
                    const progressBarWidth = 160.0;
                    final targetDays = item.targetDays <= 0 ? 1 : item.targetDays;
                    final denominator = item.denominator <= 0 ? 1 : item.denominator;
                    final progressValue = (item.numerator / denominator).clamp(0.0, 1.0);
                    final percent = (progressValue * 100).round();

                    final daysProgressValue = targetDays > 1
                        ? (item.achievedDays.clamp(0, targetDays) / targetDays).clamp(0.0, 1.0)
                        : 0.0;
                    final daysPercent = (daysProgressValue * 100).round();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (targetDays > 1)
                          Text('日数: ${item.achievedDays.clamp(0, targetDays)}/$targetDays ($daysPercent%)'),
                        if (targetDays > 1) ...[
                          const SizedBox(height: 4),
                          SizedBox(
                            width: progressBarWidth,
                            child: LinearProgressIndicator(value: daysProgressValue),
                          ),
                          const SizedBox(height: 8),
                        ],
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
              if (item.memo.trim().isNotEmpty)
                Text(
                  item.memo.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: item.isCompleted
              ? OutlinedButton(
                  onPressed: () => _setCompletedWithDialog(item, false),
                  child: const Text('－'),
                )
              : (item.denominator <= 1
                  ? OutlinedButton(
                      onPressed: () => _setCompletedWithDialog(item, true),
                      child: const Text('＋'),
                    )
                  : OutlinedButton(
                      onPressed: () => _incrementWithDialog(item),
                      child: const Text('＋'),
                    )),
          onTap: () => _openDetail(item.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todo一覧'),
          actions: [
            IconButton(
              onPressed: _create,
              icon: const Icon(Icons.add),
              tooltip: '作成',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '未完了'),
              Tab(text: '完了済み'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(_incomplete),
                  _buildList(_completed),
                ],
              ),
            ),
            const SafeArea(
              top: false,
              child: AdBanner(),
            ),
          ],
        ),
      ),
    );
  }
}
