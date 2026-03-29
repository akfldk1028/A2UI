import 'package:flutter/material.dart';

enum ReadingCategory {
  fortune('운세', Icons.auto_awesome, '오늘의 에너지와 흐름'),
  love('연애/관계', Icons.favorite, '사랑과 관계의 방향'),
  career('진로/커리어', Icons.work_outline, '일과 성장의 길'),
  general('일반 상담', Icons.blur_on, '어떤 질문이든'),
  decision('선택/결정', Icons.call_split, '갈림길 앞에서');

  const ReadingCategory(this.label, this.icon, this.subtitle);
  final String label;
  final IconData icon;
  final String subtitle;
}
