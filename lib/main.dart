import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/app/movie_log_app.dart';
export 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/data/models/rating_dto.dart';
export 'package:movielog/models/movie.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/tmdb_movie_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MovieLogApp());
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().loadMember();
    });
  }

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.movie_outlined),
          selectedIcon: Icon(Icons.movie),
          label: '영화',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '마이',
        ),
      ],
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: CommonAppBar(
      title: 'MovieLog',
      actions: [
        IconButton(
          onPressed: () => context.go('/movies'),
          icon: const Icon(Icons.search),
        ),
      ],
    ),
    body: SafeArea(
      child: Consumer<MovieHomeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.status == MovieHomeLoadStatus.idle ||
              viewModel.status == MovieHomeLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.status == MovieHomeLoadStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(viewModel.message ?? '인기 영화를 불러오지 못했어요.'),
                  TextButton(
                    onPressed: viewModel.loadPopular,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          final movies = viewModel.popularMovies;
          if (movies.isEmpty) {
            return const Center(child: Text('표시할 인기 영화가 없어요.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 4),
              const Text(
                '오늘은 어떤\n영화를 볼까요?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TmdbMovieCard(movie: movies.first, featured: true),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '인기 영화',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/movies'),
                    child: const Text('전체보기 ›'),
                  ),
                ],
              ),
              SizedBox(
                height: 235,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 145,
                    child: TmdbMovieCard(movie: movies[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.featured = false});
  final Movie movie;
  final bool featured;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movies/${movie.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: featured ? 500 : 205,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(movie.poster, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .82),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _MovieRatingBadge(rating: movie.rating),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (featured) const Chip(label: Text('추천 신작')),
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: featured ? 26 : 16,
                      ),
                    ),
                    Text(
                      '${movie.genre} · ${movie.year}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (featured) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/movies/${movie.id}'),
                          icon: const Icon(Icons.info),
                          label: const Text('상세보기'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieRatingBadge extends StatelessWidget {
  const _MovieRatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (_, _) => const Icon(Icons.star, color: Colors.white),
          itemCount: 5,
          itemSize: 13,
          itemPadding: const EdgeInsets.only(right: 1),
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.onRate,
    this.sessionRating,
    this.onDeleteRating,
  });
  final RatingDto? sessionRating;
  final VoidCallback? onDeleteRating;
  final VoidCallback? onRate;
  final Movie movie;
  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Cinema Archive',
        onBack: () => context.pop(),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 430,
              width: double.infinity,
              child: widget.movie.poster.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined)
                  : widget.movie.poster.startsWith('https://')
                  ? Image.network(
                      widget.movie.poster,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    )
                  : Image.asset(widget.movie.poster, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('${widget.movie.year} · ${widget.movie.genre} · 120분'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: 4.5,
                        itemBuilder: (_, _) =>
                            const Icon(Icons.star, color: AppColors.violet),
                        itemCount: 5,
                        itemSize: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text('4.5 (1,245)'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(widget.movie.genre)),
                      const Chip(label: Text('감독작')),
                    ],
                  ),
                  const Divider(height: 36),
                  const Text(
                    '시놉시스',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.synopsis,
                    style: const TextStyle(height: 1.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${widget.movie.synopsis}\n\n${widget.movie.synopsis}',
                    style: const TextStyle(height: 1.8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _favorite = !_favorite);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _favorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.',
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        _favorite ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: Text(_favorite ? '즐겨찾기' : '즐겨찾기 추가'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: widget.onRate,
                      icon: const Icon(Icons.rate_review),
                      label: Text(
                        widget.sessionRating == null ? '평점 남기기' : '평점 수정',
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.sessionRating case final rating?)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star),
                    title: Text('이번 세션의 내 평점 ${rating.score}/5'),
                    subtitle: rating.comment == null
                        ? null
                        : Text(rating.comment!),
                    trailing: IconButton(
                      tooltip: '평점 삭제',
                      onPressed: widget.onDeleteRating,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
