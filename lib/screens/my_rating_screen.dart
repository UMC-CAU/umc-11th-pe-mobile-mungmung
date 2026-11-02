import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('내가 등록한 평점'),
      centerTitle: true,
      leading: const BackButton(),
    ),
    body: SafeArea(
      child: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Text(
                '학습용 memberId 1의 공개 평점입니다.',
                style: AppTextStyles.bodySmall,
              ),
            ),
            Expanded(
              child: switch (viewModel.status) {
                MyRatingsLoadStatus.idle ||
                MyRatingsLoadStatus.loading => const MyRatingsLoading(),
                MyRatingsLoadStatus.empty => const MyRatingsEmpty(),
                MyRatingsLoadStatus.error => MyRatingsError(
                  message: viewModel.message ?? '평점을 불러오지 못했습니다.',
                  onRetry: viewModel.load,
                ),
                MyRatingsLoadStatus.success => MyRatingsSuccess(
                  entries: viewModel.ratings,
                ),
              },
            ),
          ],
        ),
      ),
    ),
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
  const MyRatingsSuccess({super.key, required this.entries});
  final List<RatingWithMovie> entries;
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
    itemCount: entries.length,
    separatorBuilder: (_, index) => const SizedBox(height: 14),
    itemBuilder: (context, index) => MyRatingCard(entry: entries[index]),
  );
}

class MyRatingCard extends StatelessWidget {
  const MyRatingCard({super.key, required this.entry});
  final RatingWithMovie entry;
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
