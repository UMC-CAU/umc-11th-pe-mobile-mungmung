import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key, this.title = '내가 등록한 평점'});

  final String title;

  Future<bool> _confirmDelete(
    BuildContext context, {
    required bool selected,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(selected ? '선택한 평점을 삭제할까요?' : '이 평점을 삭제할까요?'),
            content: const Text('삭제한 평점은 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteOne(
    BuildContext context,
    MyRatingsViewModel model,
    int id,
  ) async {
    if (!await _confirmDelete(context, selected: false) || !context.mounted) {
      return;
    }
    try {
      await model.deleteRating(id);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is DioException
          ? writeErrorMessage(error)
          : '평점을 삭제하지 못했어요. 다시 시도해 주세요.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteSelected(
    BuildContext context,
    MyRatingsViewModel model,
  ) async {
    if (!await _confirmDelete(context, selected: true) || !context.mounted) {
      return;
    }
    await model.deleteSelectedRatings();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MyRatingsViewModel>();
    return PopScope(
      canPop: !model.isDeletingSelected,
      child: LoadingOverlay(
        isLoading: model.isDeletingSelected,
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            leading: const BackButton(),
            actions: [
              if (model.selectedRatingIds.isNotEmpty)
                IconButton(
                  tooltip: '선택한 평점 삭제',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _deleteSelected(context, model),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (model.bulkDeleteMessage case final message?)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(message),
                  ),
                Expanded(
                  child: switch (model.status) {
                    MyRatingsLoadStatus.idle ||
                    MyRatingsLoadStatus.loading => const MyRatingsLoading(),
                    MyRatingsLoadStatus.empty => const MyRatingsEmpty(),
                    MyRatingsLoadStatus.error => MyRatingsError(
                      message:
                          model.refreshWarning ??
                          model.message ??
                          '평점을 불러오지 못했습니다.',
                      onRetry: model.load,
                    ),
                    MyRatingsLoadStatus.success => MyRatingsSuccess(
                      entries: model.ratings,
                      actions: (entry) {
                        final rating = entry.rating;
                        return [
                          Checkbox(
                            semanticLabel:
                                '${entry.movie?.title ?? '영화'} 평점 선택',
                            value: model.selectedRatingIds.contains(
                              rating.ratingId,
                            ),
                            onChanged: (selected) => model.setSelected(
                              rating.ratingId,
                              selected ?? false,
                            ),
                          ),
                          IconButton(
                            tooltip: '평점 수정',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => RatingDialog(
                                onAccessError: (message) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                },
                                initialScore: rating.score,
                                initialComment: rating.comment,
                                onSubmit: (score, comment) =>
                                    model.updateRating(
                                      ratingId: rating.ratingId,
                                      score: score,
                                      comment: comment,
                                    ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '평점 삭제',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _deleteOne(context, model, rating.ratingId),
                          ),
                        ];
                      },
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      if (isLoading) ...[
        const ModalBarrier(dismissible: false, color: Colors.black45),
        const Center(child: CircularProgressIndicator(color: AppColors.white)),
      ],
    ],
  );
}

class MyRatingsLoading extends StatelessWidget {
  const MyRatingsLoading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class MyRatingsEmpty extends StatelessWidget {
  const MyRatingsEmpty({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('등록된 평점이 없습니다.'));
}

class MyRatingsError extends StatelessWidget {
  const MyRatingsError({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    ),
  );
}

class MyRatingsSuccess extends StatelessWidget {
  const MyRatingsSuccess({super.key, required this.entries, this.actions});
  final List<RatingWithMovie> entries;
  final List<Widget> Function(RatingWithMovie)? actions;
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
    itemCount: entries.length,
    separatorBuilder: (_, index) => const SizedBox(height: 14),
    itemBuilder: (context, index) => MyRatingCard(
      entry: entries[index],
      actions: actions?.call(entries[index]) ?? const [],
    ),
  );
}

class MyRatingCard extends StatelessWidget {
  const MyRatingCard({super.key, required this.entry, this.actions = const []});
  final RatingWithMovie entry;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final date = rating.createdAt.toLocal();
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.lightviolet, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TmdbPosterImage(
              posterPath: entry.movie?.posterPath,
              width: 70,
              height: 104,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.movie?.title ?? '영화 #${rating.movieId}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '별점 ${rating.score} / 5',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.violet,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (rating.comment != null) ...[
                  const SizedBox(height: 6),
                  Text(rating.comment!, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 6),
                Text('등록일 $dateLabel', style: AppTextStyles.bodySmall),
                if (actions.isNotEmpty) Wrap(children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
