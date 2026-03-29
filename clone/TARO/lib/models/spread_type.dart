import 'reading_category.dart';

enum SpreadTier { free, premium, pro }

enum SpreadType {
  dailyOne(cardCount: 1, displayName: '오늘의 타로', positions: ['오늘의 메시지'], category: ReadingCategory.fortune, description: '카드 한 장이 전하는 오늘의 메시지', tier: SpreadTier.free),
  monthlyForecast(cardCount: 4, displayName: '이번달 운세', positions: ['이달의 테마', '도전', '기회', '조언'], category: ReadingCategory.fortune, description: '한 달의 에너지와 주의할 점', tier: SpreadTier.free),
  loveReading(cardCount: 8, displayName: '연애 리딩', positions: ['나의 감정', '상대의 감정', '관계의 과거', '현재 에너지', '숨겨진 영향', '장애물', '조언', '미래 방향'], category: ReadingCategory.love, description: '두 사람 사이의 에너지를 깊이 읽습니다', tier: SpreadTier.free),
  hiddenFeelings(cardCount: 8, displayName: '속마음', positions: ['겉으로 보여주는 모습', '실제 감정', '나에 대한 생각', '숨기는 것', '원하는 것', '두려워하는 것', '진짜 의도', '관계의 방향'], category: ReadingCategory.love, description: '상대가 나에게 관심이 있는걸까?', tier: SpreadTier.free),
  careerThree(cardCount: 3, displayName: '진로 상담', positions: ['현재 상황', '장애물', '나아갈 길'], category: ReadingCategory.career, description: '커리어의 흐름과 방향', tier: SpreadTier.free),
  threeCard(cardCount: 3, displayName: '쓰리 카드', positions: ['과거', '현재', '미래'], category: ReadingCategory.general, description: '과거, 현재, 미래의 흐름', tier: SpreadTier.free),
  yesNo(cardCount: 1, displayName: '예/아니오', positions: ['답'], category: ReadingCategory.decision, description: '단순한 질문에 명확한 답', tier: SpreadTier.free),
  compatibility(cardCount: 6, displayName: '궁합', positions: ['나의 에너지', '상대 에너지', '나의 끌림', '상대의 끌림', '강점', '과제'], category: ReadingCategory.love, description: '두 사람의 궁합을 봅니다', tier: SpreadTier.premium),
  fiveCard(cardCount: 5, displayName: '파이브 카드', positions: ['현재', '과거', '미래', '원인', '잠재력'], category: ReadingCategory.general, description: '더 깊이 있는 상담', tier: SpreadTier.premium),
  celticCross(cardCount: 10, displayName: '켈틱 크로스', positions: ['현재', '장애물', '기반', '과거', '가능성', '미래', '태도', '환경', '희망과 두려움', '최종 결과'], category: ReadingCategory.general, description: '10장으로 깊이 있는 상담', tier: SpreadTier.pro);

  const SpreadType({required this.cardCount, required this.displayName, required this.positions, required this.category, required this.description, required this.tier});
  final int cardCount;
  final String displayName;
  final List<String> positions;
  final ReadingCategory category;
  final String description;
  final SpreadTier tier;

  static List<SpreadType> forCategory(ReadingCategory cat) =>
      values.where((s) => s.category == cat && s.tier == SpreadTier.free).toList();
}
