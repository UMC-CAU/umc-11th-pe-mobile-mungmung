import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CommonAppBar(title: '내 프로필'),
      body: const SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 16),
        child: ProfileBody(),
      ),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final genres = ['액션', '코미디', 'SF', '로맨스', '스릴러', '드라마'];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 64, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipOval(
              child: SizedBox.square(
                dimension: 88,
                child: Image.asset(
                  'assets/images/profile/profile_movielog.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '무비러버',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 8),
          Text(
            '좋아하는 영화를 기록하고 있어요',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(
                child: StatItem(label: '본 영화', value: '342'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: StatItem(label: '평점', value: '4.2'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: StatItem(label: '즐겨찾기', value: '58'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightviolet),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: const Text('내가 등록한 평점'),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.violet,
              ),
              onTap: () => context.push('/my/ratings'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '학습용 memberId 1의 공개 평점을 조회합니다.\n프로필과 통계 수치는 디자인 예시입니다.',
            style: TextStyle(fontSize: 12, color: AppColors.gray),
          ),
          const SizedBox(height: 32),

          Text(
            '선호하는 장르',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              return Chip(
                label: Text(genre),
                backgroundColor: AppColors.lightviolet,
                labelStyle: const TextStyle(color: AppColors.violet),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title, style: titleStyle),
    centerTitle: centerTitle,
    leading: onBack == null
        ? null
        : IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
    actions: actions,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
