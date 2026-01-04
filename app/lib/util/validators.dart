String? validateRequiredTitle(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return '入力してください';
  if (text.runes.length > 76) return '76文字以内で入力してください';
  return null;
}

String? validatePositiveInt(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return '入力してください';
  final parsed = int.tryParse(text);
  if (parsed == null) return '数値を入力してください';
  if (parsed < 1) return '1以上を入力してください';
  return null;
}
