import 'package:flutter/material.dart';

import '../data/habit_repository.dart';
import '../data/todo_repository.dart';
import '../models/habit_item.dart';
import '../widgets/ad_banner.dart';
import 'habit_detail_screen.dart';
import 'habit_edit_screen.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final SortOrder _sortOrder = SortOrder.newestFirst;
  bool _loading = true;

  List<HabitItem> _incomplete = const [];
  List<HabitItem> _completed = const [];

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
      final incomplete = await HabitRepository.instance.list(
        isCompleted: false,
        order: _sortOrder,
      );
      final completed = await HabitRepository.instance.list(
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
      HabitEditScreen.route(),
    );
    if (!mounted) return;
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openDetail(int habitId) async {
    final changed = await Navigator.of(context).push<bool>(
      HabitDetailScreen.route(habitId: habitId),
    );
    if (!mounted) return;
    if (changed == true) {
      await _reload();
    }
  }

  Widget _buildList(List<HabitItem> items) {
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
          title: Text(item.name),
          subtitle: Text('${item.numerator}/${item.denominator}'),
          trailing: item.isCompleted ? const Icon(Icons.check) : null,
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
          title: const Text('継続目標一覧'),
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
