import 'package:provider/provider.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/view_models/signup_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_spacing.dart';
import 'package:movielog/theme/app_text_styles.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    this.onSignupComplete,
    this.memberCheckService,
  });

  final VoidCallback? onSignupComplete;
  final MemberCheckService? memberCheckService;

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

  late final SignUpViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SignUpViewModel(
      widget.memberCheckService ?? MemberCheckService(createMovieLogClient()),
    );
  }

  bool _agreedToTerms = false;
  bool _submitted = false;

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      _isValidEmail(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _agreedToTerms &&
      _viewModel.nicknameCheckStatus == CheckStatus.available &&
      _viewModel.emailCheckStatus == CheckStatus.available;

  @override
  void dispose() {
    _viewModel.dispose();
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
    if (!_canSubmit || !isFormValid) return;
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSignupComplete?.call();
  }

  void _closeScreen() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignUpViewModel>.value(
      value: _viewModel,
      child: Consumer<SignUpViewModel>(
        builder: (context, viewModel, child) =>
            _buildScreen(context, viewModel),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, SignUpViewModel viewModel) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                        onChanged: (value) {
                          viewModel.onNicknameChanged(value);
                          _refresh('닉네임');
                        },
                        errorText: viewModel.nicknameErrorText,
                        checkStatus: viewModel.nicknameCheckStatus,
                        checkButton: MovieLogButton(
                          label: '중복 확인',
                          isLoading:
                              viewModel.nicknameCheckStatus ==
                              CheckStatus.checking,
                          onPressed: viewModel.canCheckNickname
                              ? () => viewModel.checkNickname(
                                  _nicknameController.text,
                                )
                              : null,
                        ),
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
                        onChanged: (value) {
                          viewModel.onEmailChanged(value);
                          _refresh('이메일');
                        },
                        errorText: viewModel.emailErrorText,
                        checkStatus: viewModel.emailCheckStatus,
                        checkButton: MovieLogButton(
                          label: '중복 확인',
                          isLoading:
                              viewModel.emailCheckStatus ==
                              CheckStatus.checking,
                          onPressed: viewModel.canCheckEmail
                              ? () =>
                                    viewModel.checkEmail(_emailController.text)
                              : null,
                        ),
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
                      MovieLogButton(
                        label: '가입하기',
                        width: double.infinity,
                        onPressed: _canSubmit ? _submit : null,
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
    String? errorText,
    CheckStatus? checkStatus,
    Widget? checkButton,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    bool obscureText = false,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    final hasError =
        errorText != null ||
        ((_submitted || _interactedFields.contains(label)) &&
            validator(controller.text) != null);
    final isConfirmed = checkStatus == null
        ? _isValidField(label, controller.text)
        : checkStatus == CheckStatus.available;

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                scrollPadding: EdgeInsets.zero,
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onFieldSubmitted: onFieldSubmitted,
                onChanged: onChanged,
                validator: (value) => validator(value) ?? errorText,
                decoration: InputDecoration(
                  errorText: errorText,
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.gray,
                  ),
                  filled: true,
                  fillColor: hasError
                      ? const Color(0xFFFFE0DE)
                      : AppColors.lowGray,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  suffixIcon:
                      controller.text.isEmpty || (!hasError && !isConfirmed)
                      ? null
                      : Icon(
                          isConfirmed
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: isConfirmed
                              ? AppColors.violet
                              : Theme.of(context).colorScheme.error,
                        ),
                ),
              ),
            ),
            if (checkButton != null) ...[const SizedBox(width: 8), checkButton],
          ],
        ),
        if (checkStatus == CheckStatus.available)
          Text(
            '사용할 수 있는 $label입니다.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.green),
          ),
        if (checkStatus == CheckStatus.checking)
          Text(
            '$label 사용 가능 여부를 확인 중입니다.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.blue),
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
