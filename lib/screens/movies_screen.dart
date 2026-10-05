import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/services/genre_preferences.dart';
import 'package:movielog/widgets/movie_grid.dart';
import 'package:movielog/widgets/movie_states.dart';

const movieGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '액션', '코미디'];

enum MovieSort {
  original('기본 순'),
  newest('최신순'),
  rating('평점순'),
  title('제목순');

  const MovieSort(this.label);
  final String label;
}

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({
    super.key,
    this.selectedGenres = const {},
    this.movieService = const FakeMovieService(),
    this.preferences,
    this.requestTimeout = const Duration(seconds: 3),
  });

  final Set<String> selectedGenres;
  final FakeMovieService movieService;
  final GenrePreferences? preferences;
  final Duration requestTimeout;

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  late Future<List<Movie>> _moviesFuture;
  late GenrePreferences _preferences;
  late Set<String> _selectedGenres;
  bool _restoringGenres = true;
  bool _savingGenres = false;
  bool _refreshing = false;
  bool _savingSort = false;
  MovieSort _sort = MovieSort.original;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _fetchMovies();
    _preferences = widget.preferences ?? GenrePreferences();
    _selectedGenres = widget.selectedGenres.toSet();
    _restoreGenres();
  }

  Future<void> _restoreGenres() async {
    try {
      final saved = await _preferences.load();
      final savedSort = await _preferences.loadSort();
      if (!mounted) return;
      setState(() {
        _sort = MovieSort.values.firstWhere(
          (sort) => sort.name == savedSort,
          orElse: () => MovieSort.original,
        );
        if (widget.selectedGenres.isEmpty) {
          _selectedGenres = saved.where(movieGenres.contains).toSet();
        }
      });
    } catch (_) {
      if (!mounted) return;
      _showStorageMessage('저장된 목록 설정을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _restoringGenres = false);
    }
  }

  @override
  void didUpdateWidget(covariant MoviesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGenres.length != widget.selectedGenres.length ||
        !oldWidget.selectedGenres.containsAll(widget.selectedGenres)) {
      _selectedGenres = widget.selectedGenres
          .where(movieGenres.contains)
          .toSet();
    }
  }

  Future<void> _selectGenre(String? genre) async {
    if (_savingGenres || _restoringGenres) return;
    setState(() {
      if (genre == null) {
        _selectedGenres.clear();
      } else if (!_selectedGenres.remove(genre)) {
        _selectedGenres.add(genre);
      }
      _savingGenres = true;
    });
    try {
      await _preferences.save(_selectedGenres.toList());
    } catch (_) {
      if (!mounted) return;
      _showStorageMessage('장르를 저장하지 못했어요. 다시 선택해 주세요.');
    } finally {
      if (mounted) setState(() => _savingGenres = false);
    }
  }

  void _showStorageMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectSort(MovieSort sort) async {
    if (_savingSort || _restoringGenres) return;
    setState(() {
      _sort = sort;
      _savingSort = true;
    });
    try {
      await _preferences.saveSort(sort.name);
    } catch (_) {
      if (!mounted) return;
      _showStorageMessage('정렬 방식을 저장하지 못했어요. 다시 선택해 주세요.');
    } finally {
      if (mounted) setState(() => _savingSort = false);
    }
  }

  Future<List<Movie>> _fetchMovies() =>
      widget.movieService.fetchMovies().timeout(widget.requestTimeout);

  Future<List<Movie>> _startFetch() {
    final nextFuture = _fetchMovies();
    setState(() {
      _moviesFuture = nextFuture;
    });
    return nextFuture;
  }

  void _retry() {
    _startFetch();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _startFetch();
    } catch (_) {
      // FutureBuilder에서 사용자용 오류 화면을 표시한다.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Widget _scrollableState(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const CommonAppBar(title: '영화'),
    body: SafeArea(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _genreChip(
                  '전체',
                  _selectedGenres.isEmpty,
                  () => _selectGenre(null),
                ),
                for (final genre in movieGenres)
                  _genreChip(
                    genre,
                    _selectedGenres.contains(genre),
                    () => _selectGenre(genre),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('정렬 방식: '),
                DropdownButton<MovieSort>(
                  value: _sort,
                  items: MovieSort.values
                      .map(
                        (sort) => DropdownMenuItem(
                          value: sort,
                          child: Text(sort.label),
                        ),
                      )
                      .toList(),
                  onChanged: _restoringGenres || _savingSort
                      ? null
                      : (sort) {
                          if (sort != null) _selectSort(sort);
                        },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if ((snapshot.connectionState == ConnectionState.waiting &&
                        !_refreshing) ||
                    _restoringGenres) {
                  return const MovieLoading();
                }
                final movies = snapshot.data ?? <Movie>[];
                final items = _selectedGenres.isEmpty
                    ? movies.toList()
                    : movies
                          .where((m) => _selectedGenres.contains(m.genre))
                          .toList();
                switch (_sort) {
                  case MovieSort.original:
                    break;
                  case MovieSort.newest:
                    items.sort((a, b) => b.year.compareTo(a.year));
                  case MovieSort.rating:
                    items.sort((a, b) => b.rating.compareTo(a.rating));
                  case MovieSort.title:
                    items.sort((a, b) => a.title.compareTo(b.title));
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: snapshot.hasError
                      ? _scrollableState(
                          MovieError(
                            onRetry: _retry,
                            isTimeout: snapshot.error is TimeoutException,
                          ),
                        )
                      : items.isEmpty
                      ? _scrollableState(const MovieEmpty())
                      : MovieGrid(movies: items),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _genreChip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: _restoringGenres || _savingGenres ? null : (_) => onTap(),
    ),
  );
}
