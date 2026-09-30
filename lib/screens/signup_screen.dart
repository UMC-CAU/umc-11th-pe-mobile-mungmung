import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_spacing.dart';
import 'package:movielog/theme/app_text_styles.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.onSignupComplete});

  final VoidCallback? onSignupComplete;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final Set<String> _interactedFields = {};

  bool _agreedToTerms = false;
  bool _submitted = false;

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      _isValidEmail(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _agreedToTerms;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _refresh(String field) {
    setState(() => _interactedFields.add(field));
  }

  void _submit() {
    setState(() => _submitted = true);
    final isFormValid = _formKey.currentState!.validate();
    if (!_agreedToTerms || !isFormValid) return;
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSignupComplete?.call();
  }

  void _closeScreen() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeScreen,
        ),
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 52)
                    .clamp(0.0, double.infinity)
                    .toDouble(),
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '환영합니다!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '간단한 정보만 입력하고 시작해보세요.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(height: 64),
                      _buildField(
                        label: '닉네임',
                        hint: '닉네임을 입력해주세요',
                        controller: _nicknameController,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final nickname = value?.trim() ?? '';
                          if (nickname.isEmpty) return '닉네임을 입력해주세요.';
                          if (nickname.length < 2) {
                            return '닉네임은 2자 이상이어야 합니다.';
                          }
                          return null;
                        },
                        onChanged: (_) => _refresh('닉네임'),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      _buildField(
                        label: '이메일',
                        hint: '이메일 주소를 입력해주세요',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return '이메일 주소를 입력해주세요.';
                          if (!_isValidEmail(email)) {
                            return '올바른 이메일 형식이 아닙니다.';
                          }
                          return null;
                        },
                        onChanged: (_) => _refresh('이메일'),
                        onFieldSubmitted: (_) =>
                            _passwordFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      _buildField(
                        label: '비밀번호',
                        hint: '비밀번호를 입력해주세요',
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요.';
                          }
                          if (value.length < 8) {
                            return '비밀번호는 8자 이상이어야 합니다.';
                          }
                          return null;
                        },
                        onChanged: (_) => _refresh('비밀번호'),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const Spacer(),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          '필수 약관에 동의합니다',
                          style: AppTextStyles.bodyMedium,
                        ),
                        value: _agreedToTerms,
                        onChanged: (value) =>
                            setState(() => _agreedToTerms = value ?? false),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violet,
                            disabledBackgroundColor: AppColors.lightviolet,
                            disabledForegroundColor: AppColors.white,
                            foregroundColor: AppColors.white,
                          ),
                          child: Text(
                            '가입하기',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '이미 계정이 있나요? ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                            TextButton(
                              onPressed: _closeScreen,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '로그인',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
    required TextInputAction textInputAction,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    bool obscureText = false,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    final hasError =
        (_submitted || _interactedFields.contains(label)) &&
        !_isValidField(label, controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          scrollPadding: EdgeInsets.zero,
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: AppColors.gray,
            ),
            filled: true,
            fillColor: hasError ? const Color(0xFFFFE0DE) : AppColors.lowGray,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : Icon(
                    _isValidField(label, controller.text)
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: _isValidField(label, controller.text)
                        ? AppColors.violet
                        : Theme.of(context).colorScheme.error,
                  ),
          ),
        ),
      ],
    );
  }

  bool _isValidField(String label, String value) {
    switch (label) {
      case '닉네임':
        return value.trim().length >= 2;
      case '이메일':
        return _isValidEmail(value.trim());
      case '비밀번호':
        return value.length >= 8;
      default:
        return false;
    }
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
}
