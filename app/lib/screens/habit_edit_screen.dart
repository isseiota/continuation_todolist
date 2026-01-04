import 'package:flutter/material.dart';

import '../data/habit_repository.dart';
import '../models/habit_item.dart';
import '../util/validators.dart';

class HabitEditScreen extends StatefulWidget {
  const HabitEditScreen({super.key, this.habitId});

  final int? habitId;

  static Route<bool> route({int? habitId}) {
    return MaterialPageRoute<bool>(
      builder: (_) => HabitEditScreen(habitId: habitId),
    );
  }

  @override
  State<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends State<HabitEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _denominatorController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  HabitItem? _habit;

  bool get _isEdit => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _denominatorController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isEdit) {
      _denominatorController.text = '1';
      setState(() {
        _loading = false;
      });
      return;
    }

    final habit = await HabitRepository.instance.getById(widget.habitId!);
    if (!mounted) return;

    _habit = habit;
    if (habit != null) {
      _nameController.text = habit.name;
      _denominatorController.text = habit.denominator.toString();
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final name = _nameController.text.trim();
    final denominator = int.parse(_denominatorController.text.trim());

    if (_isEdit) {
      final current = _habit;
      if (current == null) {
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      final prospectiveNumerator = current.numerator.clamp(0, denominator);
      final currentCompleted = current.numerator >= current.denominator;
      final prospectiveCompleted = prospectiveNumerator >= denominator;

      if (currentCompleted != prospectiveCompleted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('確認'),
              content: const Text('目標回数を変更すると、完了済み・未完了が切り替わる可能性があります。続行しますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('閉じる'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );

        if (ok != true) return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEdit) {
        final current = _habit;
        if (current == null) {
          if (mounted) Navigator.of(context).pop(false);
          return;
        }
        await HabitRepository.instance.update(
          id: current.id,
          name: name,
          denominator: denominator,
          numerator: current.numerator,
        );
      } else {
        await HabitRepository.instance.create(name: name, denominator: denominator);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? '継続目標編集' : '継続目標作成';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'タイトル'),
                      validator: validateRequiredTitle,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _denominatorController,
                      decoration: const InputDecoration(labelText: '目標回数'),
                      validator: validatePositiveInt,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    const Text('分子は0から開始し、目標回数を上限とします。'),
                  ],
                ),
              ),
            ),
    );
  }
}
