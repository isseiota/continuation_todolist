import 'package:flutter/material.dart';

import '../data/todo_repository.dart';
import '../models/todo_item.dart';
import '../util/validators.dart';

class TodoEditScreen extends StatefulWidget {
  const TodoEditScreen({super.key, this.todoId});

  final int? todoId;

  static Route<bool> route({int? todoId}) {
    return MaterialPageRoute<bool>(
      builder: (_) => TodoEditScreen(todoId: todoId),
    );
  }

  @override
  State<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends State<TodoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _denominatorController = TextEditingController();
  final _targetDaysController = TextEditingController();
  final _memoController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  TodoItem? _todo;

  bool get _isEdit => widget.todoId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _denominatorController.dispose();
    _targetDaysController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isEdit) {
      _denominatorController.text = '1';
      _targetDaysController.text = '1';
      _memoController.text = '';
      setState(() {
        _loading = false;
      });
      return;
    }

    final todo = await TodoRepository.instance.getById(widget.todoId!);
    if (!mounted) return;

    _todo = todo;
    if (todo != null) {
      _titleController.text = todo.title;
      _denominatorController.text = todo.denominator.toString();
      _targetDaysController.text = todo.targetDays.toString();
      _memoController.text = todo.memo;
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _saving = true;
    });

    try {
      final title = _titleController.text.trim();
      final denominator = int.parse(_denominatorController.text.trim());
      final targetDays = int.parse(_targetDaysController.text.trim());
      final memo = _memoController.text;

      if (_isEdit) {
        final current = _todo;
        if (current == null) {
          if (mounted) Navigator.of(context).pop(false);
          return;
        }

        final effectiveTitle = current.isCompleted ? current.title : title;
        final prospectiveNumerator = current.numerator.clamp(0, denominator);
        final prospectiveAchievedDays = targetDays <= 1 ? 0 : current.achievedDays.clamp(0, targetDays);
        final prospectiveCompleted = targetDays <= 1
            ? prospectiveNumerator >= denominator
            : prospectiveAchievedDays >= targetDays;
        await TodoRepository.instance.updateTodo(
          id: current.id,
          title: effectiveTitle,
          memo: current.memo,
          numerator: prospectiveNumerator,
          denominator: denominator,
          targetDays: targetDays,
          achievedDays: prospectiveAchievedDays,
          isCompleted: prospectiveCompleted,
        );
      } else {
        await TodoRepository.instance.create(
          title: title,
          denominator: denominator,
          targetDays: targetDays,
          memo: memo,
        );
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
    final title = _isEdit ? 'Todo編集' : 'タスク作成';

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
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'タイトル'),
                      validator: validateRequiredTitle,
                      enabled: !(_todo?.isCompleted ?? false),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _denominatorController,
                      decoration: const InputDecoration(labelText: '目標回数'),
                      validator: validatePositiveInt,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetDaysController,
                      decoration: const InputDecoration(labelText: '目標日数'),
                      validator: validatePositiveInt,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    if (!_isEdit) ...[
                      TextFormField(
                        controller: _memoController,
                        decoration: const InputDecoration(labelText: 'メモ'),
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
