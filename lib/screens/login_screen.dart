import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/core/storage/remembered_email.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _emailStorage = RememberedEmail();
  bool _remember = false;
  bool _editedPreference = false;

  Future<void> _restoreEmail() async {
    try {
      final saved = await _emailStorage.read();
      if (!mounted || _editedPreference || saved == null || saved.isEmpty) {
        return;
      }
      setState(() {
        _remember = true;
        if (_email.text.isEmpty) _email.text = saved;
      });
    } catch (_) {
      // Preference storage is optional and never blocks login.
    }
  }

  Future<void> _submit(AuthViewModel auth) async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final remember = _remember;
    await auth.login(email, _password.text);
    if (auth.status == AuthStatus.signedIn && remember) {
      await _saveEmail(email);
    }
  }

  Future<void> _saveEmail(String? email) async {
    try {
      await _emailStorage.save(email);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이메일 저장 설정을 적용하지 못했어요.')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _restoreEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<AuthViewModel>().consumeSessionExpired()) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
        );
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('로그인')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: Column(
              children: [
                const SizedBox(height: 48),
                SvgPicture.asset('assets/logos/movielog_logo.svg', width: 84),
                const SizedBox(height: 24),
                Text(
                  'MovieLog에 로그인',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _email,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (value) =>
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value?.trim() ?? '')
                      ? null
                      : '이메일을 확인해 주세요.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _password,
                  enabled: !loading,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  validator: (value) =>
                      value?.isNotEmpty == true ? null : '비밀번호를 입력해 주세요.',
                ),
                CheckboxListTile(
                  title: const Text('이메일 저장'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _remember,
                  onChanged: loading
                      ? null
                      : (value) {
                          setState(() {
                            _editedPreference = true;
                            _remember = value ?? false;
                          });
                          if (!_remember) _saveEmail(null);
                        },
                ),
                if (auth.message case final message?) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  isLoading: loading,
                  onPressed: loading ? null : () => _submit(auth),
                ),
                TextButton(
                  onPressed: loading ? null : () => context.push('/register'),
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
