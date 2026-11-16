import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/widgets/movielog_button.dart';

class PublicRatingsScreen extends StatefulWidget {
  const PublicRatingsScreen({super.key});

  @override
  State<PublicRatingsScreen> createState() => _PublicRatingsScreenState();
}

class _PublicRatingsScreenState extends State<PublicRatingsScreen> {
  final _form = GlobalKey<FormState>();
  final _memberId = TextEditingController();

  @override
  void dispose() {
    _memberId.dispose();
    super.dispose();
  }

  void _openRatings() {
    if (_form.currentState!.validate()) {
      final id = int.parse(_memberId.text.trim());
      context.push('/my/ratings/$id');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('유저별 평점 조회'), centerTitle: true),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('조회할 회원의 ID를 입력해 주세요.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memberId,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _openRatings(),
                decoration: const InputDecoration(labelText: '회원 ID'),
                validator: (value) =>
                    (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                    ? null
                    : '양의 정수인 회원 ID를 입력해 주세요.',
              ),
              const SizedBox(height: 24),
              MovieLogButton(label: '평점 조회', onPressed: _openRatings),
            ],
          ),
        ),
      ),
    ),
  );
}
