class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.poster,
    required this.synopsis,
    this.rating = 4.5,
  });
  final String id, title, genre, poster, synopsis;
  final int year;
  final double rating;
}

const mockMovies = <Movie>[
  Movie(
    id: 'starlight',
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2023,
    poster: 'assets/images/posters/hero_under_the_starlight.jpg',
    rating: 4.8,
    synopsis: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 천문대에서 만나게 됩니다. 별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속은 과연 영원할 수 있을까요?',
  ),
  Movie(
    id: 'void',
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    poster: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    rating: 4.2,
    synopsis: '끝없는 우주에서 자신의 길을 찾아 나서는 탐험가의 이야기.',
  ),
  Movie(
    id: 'woods',
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    poster: 'assets/images/posters/poster_whispering_woods.jpg',
    rating: 4.9,
    synopsis: '신비한 숲에서 잃어버린 기억을 찾아가는 따뜻한 모험.',
  ),
  Movie(
    id: 'shadows',
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    poster: 'assets/images/posters/poster_night_shadows.jpg',
    rating: 3.8,
    synopsis: '도시의 어두운 골목에 감춰진 비밀을 추적한다.',
  ),
  Movie(
    id: 'afternoon',
    title: '네 번째 오후',
    genre: '로맨스',
    year: 2023,
    poster: 'assets/images/posters/poster_fourth_afternoon.jpg',
    rating: 4.6,
    synopsis: '엇갈린 오후의 약속이 두 사람의 일상을 바꾼다.',
  ),
  Movie(
    id: 'abyss',
    title: '심연의 방랑자',
    genre: '액션',
    year: 2021,
    poster: 'assets/images/posters/poster_abyss_walker.jpg',
    rating: 4.4,
    synopsis: '위험한 여정 끝에서 마주한 마지막 선택.',
  ),
];
Movie findMovieById(String id) => mockMovies.firstWhere(
  (movie) => movie.id == id,
  orElse: () => mockMovies.first,
);
