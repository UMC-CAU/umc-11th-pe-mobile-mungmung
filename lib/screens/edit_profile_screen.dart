import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.member});
  final MemberInfo member;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _nickname = TextEditingController(text: widget.member.nickname);

  bool _allowExit = false;
  bool _confirming = false;
  bool get _dirty => _nickname.text.trim() != widget.member.nickname;

  Future<void> _confirmExit() async {
    if (_confirming || context.read<EditProfileViewModel>().saving) return;
    _confirming = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변경 내용을 취소할까요?'),
        content: const Text('저장하지 않은 닉네임 변경이 사라져요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 편집'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (mounted && leave == true) _leave();
  }

  void _leave() {
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/my');
      }
    });
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save(EditProfileViewModel model) async {
    if (!_form.currentState!.validate()) return;
    final saved = await model.save(_nickname.text);
    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      _leave();
    } else if (model.message case final message?) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<EditProfileViewModel>();
    return PopScope(
      canPop: _allowExit || (!_dirty && !model.saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _dirty) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('프로필 수정'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: widget.member.email,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nickname,
                    enabled: !model.saving,
                    onChanged: (_) {
                      model.clearNicknameError();
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      errorText: model.nicknameError,
                    ),
                    validator: (value) {
                      final length = (value ?? '').trim().runes.length;
                      return length >= 2 && length <= 12
                          ? null
                          : '닉네임은 2~12자로 입력해 주세요.';
                    },
                  ),
                  const SizedBox(height: 32),
                  MovieLogButton(
                    label: '저장',
                    width: double.infinity,
                    isLoading: model.saving,
                    onPressed: model.saving ? null : () => _save(model),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
