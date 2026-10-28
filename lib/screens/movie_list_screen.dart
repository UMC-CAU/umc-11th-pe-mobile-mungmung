import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/tmdb_movie_card.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  MovieListViewModel? _viewModel;
  int _shownErrorVersion = 0;
  bool _dialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<MovieListViewModel>();
    if (identical(next, _viewModel)) return;
    _viewModel?.removeListener(_onStateChanged);
    _viewModel = next;
    _shownErrorVersion = 0;
    next.addListener(_onStateChanged);
    _onStateChanged();
  }

  void _onStateChanged() {
    final viewModel = _viewModel!;
    if (_dialogOpen || viewModel.errorVersion <= _shownErrorVersion) return;
    _shownErrorVersion = viewModel.errorVersion;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFF0EAF9),
                    child: Icon(
                      Icons.restore,
                      color: AppColors.violet,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '영화를 불러오지 못했어요',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    viewModel.message ?? '잠시 후 다시 시도해 주세요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.gray, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F0FA),
                            foregroundColor: AppColors.violet,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.violet,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('다시 시도'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (!mounted) return;
      _dialogOpen = false;
      if (retry == true) {
        await viewModel.retry();
      } else {
        viewModel.cancelError();
      }
    });
  }

  Future<void> _showGenreSheet(MovieListViewModel viewModel) async {
    if (viewModel.isLoading || _dialogOpen) return;
    final selected = (viewModel.selectedGenreIds ?? <int>[]).toSet();
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .6,
          minChildSize: .4,
          maxChildSize: .9,
          builder: (context, controller) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAC4D0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '장르 필터',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  '여러 장르를 선택할 수 있어요',
                  style: TextStyle(color: AppColors.gray),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: controller,
                  thumbVisibility: true,
                  child: ListView(
                    controller: controller,
                    children: [
                      for (final genre in viewModel.genres)
                        CheckboxListTile(
                          key: ValueKey('genre-checkbox-${genre.id}'),
                          title: Text(genre.name),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.violet,
                          value: selected.contains(genre.id),
                          onChanged: (checked) => setSheetState(() {
                            checked == true
                                ? selected.add(genre.id)
                                : selected.remove(genre.id);
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, selected.toList()),
                      child: const Text('확인'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && result != null) await viewModel.selectGenres(result);
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<MovieListViewModel>(
    builder: (context, viewModel, child) {
      final selected = viewModel.selectedGenreIds ?? <int>[];
      final canChange = !viewModel.isLoading && !_dialogOpen;
      return Scaffold(
        appBar: CommonAppBar(
          title: '영화',
          actions: [
            IconButton(
              tooltip: '장르 필터',
              icon: const Icon(Icons.filter_list, color: AppColors.violet),
              onPressed: canChange && viewModel.genres.isNotEmpty
                  ? () => _showGenreSheet(viewModel)
                  : null,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('전체'),
                        selected: selected.isEmpty,
                        onSelected: canChange
                            ? (_) => viewModel.selectGenres(null)
                            : null,
                      ),
                    ),
                    for (final genre in viewModel.genres)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          key: ValueKey('genre-${genre.id}'),
                          label: Text(genre.name),
                          selected: selected.contains(genre.id),
                          onSelected: canChange
                              ? (checked) {
                                  final ids = selected.toList();
                                  checked
                                      ? ids.add(genre.id)
                                      : ids.remove(genre.id);
                                  viewModel.selectGenres(ids);
                                }
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
              if (viewModel.movies.isNotEmpty &&
                  !listEquals(
                    viewModel.selectedGenreIds,
                    viewModel.displayedGenreIds,
                  ))
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    '최근에 불러온 영화 목록을 표시하고 있어요.',
                    style: TextStyle(color: AppColors.gray),
                  ),
                ),
              if (viewModel.isLoading &&
                  viewModel.movies.isNotEmpty &&
                  !viewModel.isRefreshing)
                const LinearProgressIndicator(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scroll = CustomScrollView(
                      key: const PageStorageKey('movie-list-scroll'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (viewModel.movies.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: viewModel.isLoading
                                  ? const CircularProgressIndicator()
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          viewModel.status ==
                                                  MovieListLoadStatus.error
                                              ? '영화를 불러오지 못했어요.'
                                              : '표시할 영화가 없어요.',
                                        ),
                                        if (viewModel.status ==
                                            MovieListLoadStatus.error)
                                          TextButton(
                                            onPressed: viewModel.retry,
                                            child: const Text('다시 시도'),
                                          ),
                                      ],
                                    ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: constraints.maxWidth > 600
                                        ? 4
                                        : 2,
                                    childAspectRatio: .62,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => TmdbMovieCard(
                                  movie: viewModel.movies[index],
                                ),
                                childCount: viewModel.movies.length,
                              ),
                            ),
                          ),
                      ],
                    );
                    return RefreshIndicator(
                      color: AppColors.violet,
                      notificationPredicate: (notification) =>
                          !viewModel.isLoading &&
                          !_dialogOpen &&
                          notification.depth == 0,
                      onRefresh: viewModel.refresh,
                      child: scroll,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
