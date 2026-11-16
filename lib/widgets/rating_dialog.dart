import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:movielog/widgets/movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
    this.onAccessError,
  });

  final void Function(String)? onAccessError;
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _comment = TextEditingController(text: widget.initialComment);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _score == 0) return;
    final comment = _comment.text.trim();
    if (comment.runes.length > 500) {
      setState(() => _error = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_score, comment.isEmpty ? null : comment);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      if (error is DioException &&
          const {403, 409}.contains(error.response?.statusCode) &&
          widget.onAccessError != null) {
        Navigator.pop(context, false);
        widget.onAccessError!(writeErrorMessage(error));
        return;
      }
      setState(() {
        _submitting = false;
        _error = switch (error) {
          DioException() => writeErrorMessage(error),
          StateError(:final message) => message,
          _ => '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        '평점을 남겨주세요',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: MovieRatingInput(
              rating: _score.toDouble(),
              enabled: !_submitting,
              onChanged: (value) =>
                  setState(() => _score = validateServerScore(value)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '코멘트 (선택, 최대 500자)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 500,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: '이 영화의 인상적인 장면은...',
              filled: true,
              fillColor: const Color(0xFFF9F6FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_error case final error?)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF0EBF8),
                  foregroundColor: AppColors.violet,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: _submitting
                    ? null
                    : () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MovieLogButton(
                label: '확인',
                pill: true,
                isLoading: _submitting,
                onPressed: _score > 0 && !_submitting ? _submit : null,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
