// pages/edit_profile_page.dart - CHỈNH SỬA HỒ SƠ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/flashcard_service.dart';
import '../widgets/common.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final FlashcardService _service = context.read<FlashcardService>();
  late final TextEditingController _nameController = TextEditingController(text: _service.user?.username ?? '');
  late int _goal = _service.dailyGoal;
  bool _dirty = false;
  bool _saving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => _dirty = true);
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    setState(() => _nameError = name.isEmpty ? "Tên hiển thị không được để trống" : null);
    if (_nameError != null) return;
    setState(() => _saving = true);
    final result = await context.read<AuthService>().updateUsername(name);
    final updated = result.user;
    final ok = updated != null && await _service.applyProfile(updated, _goal);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.failure != null) {
      setState(() => _nameError = result.failure!.message);
      return;
    }
    if (!ok) {
      showSaveError(context, _save);
      return;
    }
    _dirty = false;
    showSnack(context, "Đã cập nhật hồ sơ");
    Navigator.pop(context);
  }

  Future<void> _close() async {
    if (!_dirty || await confirmDiscardChanges(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = <int>{10, 20, 30, 50, _goal}.toList()..sort();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chỉnh sửa hồ sơ"),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
        ),
        body: ResponsiveBody(child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: "Tên hiển thị",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              controller: TextEditingController(text: _service.user?.email ?? ''),
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                helperText: "Email dùng để đăng nhập, không đổi được trong ứng dụng.",
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _goal,
              decoration: const InputDecoration(
                labelText: "Mục tiêu mỗi ngày",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: goals.map((g) => DropdownMenuItem(value: g, child: Text("$g thẻ"))).toList(),
              onChanged: (v) => setState(() {
                _goal = v ?? _goal;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 24),
            BusyButton(busy: _saving, onPressed: _save, child: const Text("Lưu hồ sơ")),
          ],
        )),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
