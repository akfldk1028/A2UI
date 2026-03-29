import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/reading_category.dart';
import 'dramatic_text.dart';

class QuestionPhase extends StatelessWidget {
  const QuestionPhase({
    super.key,
    required this.onChipTap,
    required this.category,
  });

  final ValueChanged<String> onChipTap;
  final ReadingCategory category;

  String get _greeting => switch (category) {
    ReadingCategory.love => '사랑의 별이\n당신을 위해\n빛나고 있습니다',
    ReadingCategory.career => '커리어의 길 위에서\n무엇이 당신을\n기다리고 있을까요',
    ReadingCategory.fortune => '오늘의 별이\n당신에게 전하는\n메시지는',
    ReadingCategory.general => '그대가 찾고자 하는\n지혜의 빛은\n무엇인가',
    ReadingCategory.decision => '갈림길 앞에서\n카드가 비추는\n길은',
  };

  String get _subtitle => switch (category) {
    ReadingCategory.love => '사랑에 대한 질문을 들려주세요',
    ReadingCategory.career => '일과 성장에 대해 물어보세요',
    ReadingCategory.fortune => '궁금한 운세를 물어보세요',
    ReadingCategory.general => '마음속 질문을 들려주세요',
    ReadingCategory.decision => '고민되는 선택을 말해주세요',
  };

  IconData get _icon => switch (category) {
    ReadingCategory.love => Icons.favorite,
    ReadingCategory.career => Icons.work_outline,
    ReadingCategory.fortune => Icons.auto_awesome,
    ReadingCategory.general => Icons.visibility_rounded,
    ReadingCategory.decision => Icons.call_split,
  };

  List<({String label, IconData icon})> get _chips => switch (category) {
    ReadingCategory.love => [
      (label: '상대가 나를 어떻게 생각해?', icon: Icons.psychology_outlined),
      (label: '우리 관계의 미래는?', icon: Icons.favorite_border),
      (label: '그 사람의 속마음이 궁금해', icon: Icons.lock_outline),
      (label: '새로운 인연이 올까?', icon: Icons.people_outline),
    ],
    ReadingCategory.career => [
      (label: '이직해도 될까?', icon: Icons.swap_horiz),
      (label: '승진 가능성은?', icon: Icons.trending_up),
      (label: '나에게 맞는 일은?', icon: Icons.explore_outlined),
      (label: '사업을 시작해도 될까?', icon: Icons.rocket_launch_outlined),
    ],
    ReadingCategory.fortune => [
      (label: '이번 달 운세가 궁금해', icon: Icons.calendar_month),
      (label: '오늘 하루는 어떨까?', icon: Icons.wb_sunny_outlined),
      (label: '올해 나에게 필요한 것은?', icon: Icons.star_outline),
      (label: '다가올 행운의 시기는?', icon: Icons.access_time),
    ],
    ReadingCategory.general => [
      (label: '지금 내 상황을 봐줘', icon: Icons.remove_red_eye_outlined),
      (label: '앞으로 어떻게 해야 할까?', icon: Icons.navigation_outlined),
      (label: '숨겨진 영향을 알고 싶어', icon: Icons.visibility_off_outlined),
      (label: '최근 고민이 있어', icon: Icons.psychology_outlined),
    ],
    ReadingCategory.decision => [
      (label: 'A와 B 중 어느 쪽?', icon: Icons.call_split),
      (label: '예 또는 아니오', icon: Icons.thumbs_up_down),
      (label: '지금 결정해도 될까?', icon: Icons.timer_outlined),
      (label: '이 선택이 맞는 걸까?', icon: Icons.help_outline),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final chips = _chips;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      child: Icon(_icon, color: TaroColors.gold.withAlpha(200), size: 36),
                    ),
                  ),
                  const SizedBox(height: 44),
                  DramaticText(
                    text: _greeting,
                    fontSize: 32,
                    delay: const Duration(milliseconds: 400),
                  ),
                  const SizedBox(height: 24),
                  DramaticText(
                    text: _subtitle,
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

        // Category-specific suggestion chips
        FadeIn(
          delay: const Duration(milliseconds: 1200),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: chips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onChipTap(chip.label),
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
                        Icon(chip.icon, size: 15, color: TaroColors.gold.withAlpha(140)),
                        const SizedBox(width: 8),
                        Text(chip.label, style: TextStyle(
                          color: TaroColors.gold.withAlpha(200),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        )),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
