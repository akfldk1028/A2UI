import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/tarot_card_data.dart';
import '../../../../router/routes.dart';
import '../../../../shared/widgets/mystical_background.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  void _startReading(SpreadType spread) {
    context.push(
      Routes.consultation,
      extra: {'spreadType': spread},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: MysticalBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Header with celestial eye
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            TaroColors.violet.withAlpha(30),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(Icons.visibility_rounded,
                          color: TaroColors.gold, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'menu.appTitle'.tr(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFamily: 'NotoSerifKR',
                        color: TaroColors.gold,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 1,
                      color: TaroColors.gold.withAlpha(60),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'menu.welcome'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: TaroColors.violet.withAlpha(160),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Spread options — glass-morphism cards
                    ...SpreadType.values.map((spread) => _SpreadCard(
                      spread: spread,
                      onTap: () => _startReading(spread),
                    )),

                    const Spacer(),
                    Text(
                      'v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: TaroColors.gold.withAlpha(40),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpreadCard extends StatelessWidget {
  const _SpreadCard({required this.spread, required this.onTap});

  final SpreadType spread;
  final VoidCallback onTap;

  IconData get _icon => switch (spread) {
    SpreadType.oneCard => Icons.remove_red_eye_outlined,
    SpreadType.threeCard => Icons.blur_on_rounded,
    SpreadType.celticCross => Icons.apps_rounded,
  };

  List<Color> get _gradient => switch (spread) {
    SpreadType.oneCard => [const Color(0xFF2D1B69), const Color(0xFF1A0A2E)],
    SpreadType.threeCard => [const Color(0xFF1B3A69), const Color(0xFF0D1B35)],
    SpreadType.celticCross => [const Color(0xFF3D1B54), const Color(0xFF1A0A2E)],
  };

  String get _nameKey => switch (spread) {
    SpreadType.oneCard => 'card_selection.oneCardName',
    SpreadType.threeCard => 'card_selection.threeCardName',
    SpreadType.celticCross => 'card_selection.celticCrossName',
  };

  String get _descKey => switch (spread) {
    SpreadType.oneCard => 'card_selection.oneCardDesc',
    SpreadType.threeCard => 'card_selection.threeCardDesc',
    SpreadType.celticCross => 'card_selection.celticCrossDesc',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TaroColors.gold.withAlpha(40)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: TaroColors.gold.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: RadialGradient(
                      colors: [
                        TaroColors.gold.withAlpha(25),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(color: TaroColors.gold.withAlpha(30)),
                  ),
                  child: Icon(_icon, color: TaroColors.gold.withAlpha(200), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameKey.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: 'NotoSerifKR',
                          fontWeight: FontWeight.w500,
                          color: TaroColors.gold.withAlpha(230),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _descKey.tr(),
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
                    color: TaroColors.gold.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TaroColors.gold.withAlpha(40)),
                  ),
                  child: Text(
                    'card_selection.cardCount'.tr(namedArgs: {'count': '${spread.cardCount}'}),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: TaroColors.gold.withAlpha(200),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
