import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/reading_category.dart';
import '../../../../models/spread_type.dart';
import '../../../../router/routes.dart';
import '../../../../shared/widgets/mystical_background.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _onCategoryTap(BuildContext context, ReadingCategory category) {
    // 카테고리의 기본 스프레드로 바로 상담 진입
    // AI가 질문 보고 필요하면 DrawCards로 추가 카드 트리거
    final defaultSpread = SpreadType.forCategory(category).first;
    context.push(Routes.consultation, extra: {
      'category': category,
      'spreadType': defaultSpread,
    });
  }

  static List<Color> _categoryGradient(ReadingCategory category) {
    return switch (category) {
      ReadingCategory.fortune  => const [Color(0xFF2D1B69), Color(0xFF0D0520)],
      ReadingCategory.love     => const [Color(0xFF4A1B3D), Color(0xFF2A0D22)],
      ReadingCategory.career   => const [Color(0xFF1B4A3D), Color(0xFF0D2A22)],
      ReadingCategory.general  => const [Color(0xFF1B2D69), Color(0xFF0D1535)],
      ReadingCategory.decision => const [Color(0xFF3D1B54), Color(0xFF1A0A2E)],
    };
  }

  static Color? _categoryAccent(ReadingCategory category) {
    return switch (category) {
      ReadingCategory.love => TaroColors.rose,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: MysticalBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: TaroColors.gold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'TARO',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'NotoSerifKR',
                              color: TaroColors.gold,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TaroColors.surface.withAlpha(180),
                          border: Border.all(color: TaroColors.gold.withAlpha(40)),
                        ),
                        child: Icon(Icons.person_outline, color: TaroColors.gold.withAlpha(160), size: 18),
                      ),
                    ],
                  ),
                ),
              ),

              // Hero card — 오늘의 타로
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _HeroCard(
                    onTap: () => _onCategoryTap(context, ReadingCategory.fortune),
                  ),
                ),
              ),

              // Category cards — dynamically generated from ReadingCategory
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = ReadingCategory.values[index];
                      final spreads = SpreadType.forCategory(category);
                      if (spreads.isEmpty) return const SizedBox.shrink();
                      final defaultSpread = spreads.first;
                      final badge = '${defaultSpread.cardCount}장';
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 14),
                        child: _CategoryCard(
                          title: category.label,
                          subtitle: category.subtitle,
                          badge: badge,
                          icon: category.icon,
                          gradient: _categoryGradient(category),
                          accentColor: _categoryAccent(category),
                          onTap: () => _onCategoryTap(context, category),
                        ),
                      );
                    },
                    childCount: ReadingCategory.values.length,
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

/// Featured hero card for daily tarot reading
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D1B69), Color(0xFF0D0520)],
          ),
          border: Border.all(color: TaroColors.gold.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: TaroColors.gold.withAlpha(12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Star decoration
            Positioned(
              right: 30,
              top: 30,
              child: Icon(Icons.auto_awesome, color: TaroColors.gold.withAlpha(30), size: 80),
            ),
            Positioned(
              right: 60,
              bottom: 40,
              child: Icon(Icons.auto_awesome, color: TaroColors.violet.withAlpha(20), size: 40),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TaroColors.gold.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TaroColors.gold.withAlpha(60)),
                    ),
                    child: Text(
                      '1장',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: TaroColors.gold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'card_selection.oneCardName'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'NotoSerifKR',
                      color: TaroColors.gold,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'card_selection.oneCardDesc'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(150),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [TaroColors.gold, TaroColors.gold.withAlpha(200)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'menu.startReading'.tr(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF0D0520),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category card for reading types
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.accentColor,
    this.isPro = false,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Color? accentColor;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? TaroColors.gold;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: RadialGradient(
                    colors: [color.withAlpha(30), Colors.transparent],
                  ),
                  border: Border.all(color: color.withAlpha(30)),
                ),
                child: Icon(icon, color: color.withAlpha(200), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'NotoSerifKR',
                        fontWeight: FontWeight.w500,
                        color: color.withAlpha(230),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(120),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Text(
                  isPro ? '$badge · Pro' : badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withAlpha(200),
                    letterSpacing: 0.5,
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
