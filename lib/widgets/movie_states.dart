import 'package:flutter/material.dart';

class MovieLoading extends StatelessWidget {
  const MovieLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('영화를 불러오고 있어요.'),
      ],
    ),
  );
}

class MovieEmpty extends StatelessWidget {
  const MovieEmpty({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('표시할 영화가 없어요. 다른 장르를 선택해 주세요.'));
}

class MovieError extends StatelessWidget {
  const MovieError({super.key, required this.onRetry, this.isTimeout = false});
  final VoidCallback onRetry;
  final bool isTimeout;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isTimeout
              ? '응답 시간이 초과되었어요. 다시 시도해 주세요.'
              : '영화를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}
