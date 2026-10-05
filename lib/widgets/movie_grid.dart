import 'package:flutter/material.dart';
import 'package:movielog/main.dart' show MovieCard;
import 'package:movielog/models/movie.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
        childAspectRatio: .62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: movies.length,
      itemBuilder: (context, i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: MovieCard(movie: movies[i])),
          const SizedBox(height: 7),
          Text(
            movies[i].title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${movies[i].year} · ${movies[i].genre}',
            style: const TextStyle(color: AppColors.gray),
          ),
        ],
      ),
    ),
  );
}
