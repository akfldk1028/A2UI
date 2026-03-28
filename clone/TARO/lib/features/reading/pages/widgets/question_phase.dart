import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'dramatic_text.dart';

class QuestionPhase extends StatelessWidget {
  const QuestionPhase({super.key, required this.onChipTap});

  final ValueChanged<String> onChipTap;

  static const _chipIcons = [
    Icons.favorite_outline_rounded,
    Icons.work_outline_rounded,
    Icons.psychology_outlined,
    Icons.wb_sunny_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final chips = [
      'reading.chip1'.tr(),
      'reading.chip2'.tr(),
      'reading.chip3'.tr(),
      'reading.chip4'.tr(),
    ];

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celestial eye icon with glow
                  FadeIn(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            TaroColors.gold.withAlpha(25),
                            TaroColors.violet.withAlpha(10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Icon(Icons.visibility_rounded,
                          color: TaroColors.gold.withAlpha(200), size: 36),
                    ),
                  ),
                  const SizedBox(height: 44),

                  // Big greeting — staggered dramatic entrance
                  DramaticText(
                    text: 'reading.greeting'.tr(),
                    fontSize: 32,
                    delay: const Duration(milliseconds: 400),
                  ),
                  const SizedBox(height: 24),

                  // Sub text — violet tint instead of faded gold
                  DramaticText(
                    text: 'reading.greetingSub'.tr(),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: TaroColors.violet.withAlpha(140),
                    delay: const Duration(milliseconds: 900),
                    letterSpacing: 0.8,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Suggestion chips — glass-morphism pills with icons
        FadeIn(
          delay: const Duration(milliseconds: 1200),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(chips.length, (i) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onChipTap(chips[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: TaroColors.surface.withAlpha(160),
                      border: Border.all(color: TaroColors.gold.withAlpha(35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_chipIcons[i],
                            size: 15, color: TaroColors.gold.withAlpha(140)),
                        const SizedBox(width: 8),
                        Text(chips[i], style: TextStyle(
                          color: TaroColors.gold.withAlpha(200),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        )),
                      ],
                    ),
                  ),
                ),
              )),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
