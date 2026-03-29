# TARO 카테고리별 스프레드 & AI 해석 설계

> 2026-03-29 | P0 7개 스프레드 우선 구현

## 목표

메뉴 카테고리별로 전용 스프레드(카드 수/위치)와 AI 해석 컨텍스트를 분리하여, 연애/진로/운세 등 각 상황에 맞는 깊이 있는 타로 리딩 제공.

## 현재 문제

- `SpreadType` enum 3개뿐 (oneCard/threeCard/celticCross)
- 연애운/이번달 운세가 `threeCard`와 동일 — 카테고리 차별화 없음
- 시스템 프롬프트 1개로 모든 카테고리 공통 — AI 해석이 범용적
- 카드 위치 이름이 영어 고정 (Past/Present/Future)

## 아키텍처

### 모듈 구조

```
lib/
├── models/
│   ├── reading_category.dart     # ReadingCategory enum
│   ├── spread_type.dart          # SpreadType enum (카테고리 소속)
│   └── tarot_card_data.dart      # TarotCardData, DrawnCard, TarotDeck (기존)
├── features/
│   ├── menu/
│   │   └── pages/screens/
│   │       ├── menu_screen.dart          # 카테고리 목록 (1depth)
│   │       └── spread_select_screen.dart  # 카테고리 내 스프레드 선택 (2depth)
│   └── reading/
│       ├── prompts/                       # 카테고리별 프롬프트 모듈
│       │   ├── prompt_builder.dart        # 프롬프트 조립기
│       │   ├── base_prompt.dart           # 공통 규칙 (A2UI, 언어, 경계)
│       │   ├── love_prompt.dart           # 연애 카테고리 컨텍스트
│       │   ├── career_prompt.dart         # 진로 카테고리 컨텍스트
│       │   ├── fortune_prompt.dart        # 운세 카테고리 컨텍스트
│       │   ├── general_prompt.dart        # 일반 상담 컨텍스트
│       │   └── decision_prompt.dart       # 선택/결정 컨텍스트
│       └── ... (기존 services, pages, widgets)
└── assets/prompts/
    └── oracle_system.txt          # 삭제 → prompt_builder.dart로 대체
```

### 데이터 모델

#### ReadingCategory

```dart
// lib/models/reading_category.dart
enum ReadingCategory {
  fortune('운세', Icons.auto_awesome, '오늘의 에너지와 흐름'),
  love('연애/관계', Icons.favorite, '사랑과 관계의 방향'),
  career('진로/커리어', Icons.work, '일과 성장의 길'),
  general('일반 상담', Icons.blur_on, '어떤 질문이든'),
  decision('선택/결정', Icons.call_split, '갈림길 앞에서');

  const ReadingCategory(this.label, this.icon, this.subtitle);
  final String label;
  final IconData icon;
  final String subtitle;

  List<SpreadType> get spreads =>
      SpreadType.values.where((s) => s.category == this).toList();
}
```

#### SpreadType

```dart
// lib/models/spread_type.dart
enum SpreadType {
  // --- P0: Fortune ---
  dailyOne(
    cardCount: 1,
    displayName: '오늘의 타로',
    positions: ['오늘의 메시지'],
    category: ReadingCategory.fortune,
    description: '카드 한 장이 전하는 오늘의 메시지',
    tier: SpreadTier.free,
  ),
  monthlyForecast(
    cardCount: 4,
    displayName: '이번달 운세',
    positions: ['이달의 테마', '도전', '기회', '조언'],
    category: ReadingCategory.fortune,
    description: '한 달의 에너지와 주의할 점',
    tier: SpreadTier.free,
  ),

  // --- P0: Love ---
  loveThree(
    cardCount: 3,
    displayName: '나와 상대',
    positions: ['나', '상대방', '관계의 방향'],
    category: ReadingCategory.love,
    description: '두 사람 사이의 에너지를 읽습니다',
    tier: SpreadTier.free,
  ),
  hiddenFeelings(
    cardCount: 3,
    displayName: '속마음',
    positions: ['보여주는 모습', '숨기는 마음', '진짜 의도'],
    category: ReadingCategory.love,
    description: '상대가 나에게 관심이 있는걸까?',
    tier: SpreadTier.free,
  ),

  // --- P0: Career ---
  careerThree(
    cardCount: 3,
    displayName: '진로 상담',
    positions: ['현재 상황', '장애물', '나아갈 길'],
    category: ReadingCategory.career,
    description: '커리어의 흐름과 방향',
    tier: SpreadTier.free,
  ),

  // --- P0: General ---
  threeCard(
    cardCount: 3,
    displayName: '쓰리 카드',
    positions: ['과거', '현재', '미래'],
    category: ReadingCategory.general,
    description: '과거, 현재, 미래의 흐름',
    tier: SpreadTier.free,
  ),

  // --- P0: Decision ---
  yesNo(
    cardCount: 1,
    displayName: '예/아니오',
    positions: ['답'],
    category: ReadingCategory.decision,
    description: '단순한 질문에 명확한 답',
    tier: SpreadTier.free,
  ),

  // --- P1 (추후) ---
  compatibility(
    cardCount: 6,
    displayName: '궁합',
    positions: ['나의 에너지', '상대 에너지', '나의 끌림', '상대의 끌림', '강점', '과제'],
    category: ReadingCategory.love,
    description: '두 사람의 궁합을 봅니다',
    tier: SpreadTier.premium,
  ),
  fiveCard(
    cardCount: 5,
    displayName: '파이브 카드',
    positions: ['현재', '과거', '미래', '원인', '잠재력'],
    category: ReadingCategory.general,
    description: '더 깊이 있는 상담',
    tier: SpreadTier.premium,
  ),
  twoPaths(
    cardCount: 5,
    displayName: '두 갈래 길',
    positions: ['핵심 문제', 'A의 결과', 'A의 도전', 'B의 결과', 'B의 도전'],
    category: ReadingCategory.decision,
    description: '두 선택지를 비교합니다',
    tier: SpreadTier.premium,
  ),
  celticCross(
    cardCount: 10,
    displayName: '켈틱 크로스',
    positions: ['현재', '장애물', '기반', '과거', '가능성', '미래',
                 '태도', '환경', '희망과 두려움', '최종 결과'],
    category: ReadingCategory.general,
    description: '10장으로 깊이 있는 상담',
    tier: SpreadTier.pro,
  );

  const SpreadType({
    required this.cardCount,
    required this.displayName,
    required this.positions,
    required this.category,
    required this.description,
    required this.tier,
  });

  final int cardCount;
  final String displayName;
  final List<String> positions;
  final ReadingCategory category;
  final String description;
  final SpreadTier tier;
}

enum SpreadTier { free, premium, pro }
```

### 프롬프트 시스템

`oracle_system.txt` 단일 파일 → **PromptBuilder 모듈**로 교체.

```dart
// lib/features/reading/prompts/prompt_builder.dart
class PromptBuilder {
  /// 카테고리 + 스프레드 + 페르소나 → 최종 시스템 프롬프트 조립
  static String build({
    required ReadingCategory category,
    required SpreadType spread,
    required OraclePersona persona,
  }) {
    return [
      basePrompt,                              // 공통 규칙
      persona.aiPrompt,                        // 페르소나 말투
      _categoryContext(category),              // 카테고리 해석 방향
      _spreadContext(spread),                  // 스프레드별 위치 의미
      _a2uiRules,                              // A2UI 컴포넌트 규칙
    ].join('\n\n');
  }
}
```

#### 카테고리별 컨텍스트 예시

```dart
// love_prompt.dart
const loveContext = '''
READING CONTEXT: LOVE & RELATIONSHIPS
- Focus on emotional dynamics, attraction, communication patterns
- Each card position relates to relationship energy, not general fortune
- "나" position: the seeker's emotional state and approach to love
- "상대방" position: how the other person feels and behaves
- "관계" position: the relationship's trajectory and potential
- For 속마음 spread: emphasize what is hidden vs shown, read body language cues in the cards
- Reference suit meanings in love context:
  Cups = emotions/love, Wands = passion/desire,
  Swords = communication/conflict, Pentacles = commitment/stability
''';
```

```dart
// fortune_prompt.dart
const fortuneContext = '''
READING CONTEXT: FORTUNE & FORECAST
- Focus on timing, energy flow, and cycles
- For monthly: connect each position to specific weeks or phases of the month
- "테마": the overarching energy that colors the entire period
- "도전": obstacles to prepare for — frame as growth opportunities
- "기회": doors opening — be specific about where to look
- "조언": actionable guidance — what to do differently this month
- Reference seasonal/astrological context when relevant
''';
```

```dart
// decision_prompt.dart
const decisionContext = '''
READING CONTEXT: DECISION & CHOICE
- For 예/아니오: give a clear directional answer first, then nuance
  Positive cards (Sun, Star, World, Aces, most Cups) = YES
  Challenging cards (Tower, 5 of Cups, 10 of Swords) = NO
  Neutral cards (2 of Swords, Wheel) = NOT YET / DEPENDS
- Do NOT be vague. The seeker wants a clear answer.
- After the answer, explain what conditions support or challenge it.
''';
```

### 네비게이션 플로우

```
메뉴 (카테고리 선택)
  └── 연애/관계 탭
       ├── 나와 상대 (3장)
       ├── 속마음 (3장)
       └── 궁합 (6장) [P1]
           └── 탭 → 질문 입력 → 페르소나 → 카드 뽑기 → AI 해석
```

**변경점:**
- `menu_screen.dart`: 카테고리 카드 → 탭하면 `spread_select_screen.dart`로 이동
- `spread_select_screen.dart` (신규): 해당 카테고리의 스프레드 목록
- 1개 스프레드만 있는 카테고리(오늘의 타로, 예/아니오)는 바로 상담으로 진입
- `ConsultationScreen`: `spreadType`에서 `category` + `spreadType` 둘 다 받음

### AI 해석 파이프라인

```
사용자 선택                    AI 프롬프트 조립
┌──────────┐                 ┌─────────────────┐
│ category │─┐               │ base_prompt      │ 공통 규칙
│ spread   │ ├──→ PromptBuilder ──→│ + persona     │ 말투
│ persona  │─┘               │ + category_ctx   │ 해석 방향
│ question │                 │ + spread_ctx     │ 위치 의미
└──────────┘                 │ + a2ui_rules     │ 컴포넌트
                             └─────────────────┘
                                      ↓
                             System Prompt → Edge Function → Gemini
```

### i18n 키 구조

```json
// ko/spreads.json (신규)
{
  "category": {
    "fortune": "운세",
    "love": "연애/관계",
    "career": "진로/커리어",
    "general": "일반 상담",
    "decision": "선택/결정"
  },
  "spread": {
    "dailyOne": {"name": "오늘의 타로", "desc": "카드 한 장이 전하는 오늘의 메시지"},
    "loveThree": {"name": "나와 상대", "desc": "두 사람 사이의 에너지를 읽습니다"},
    "hiddenFeelings": {"name": "속마음", "desc": "상대가 나에게 관심이 있는걸까?"},
    "monthlyForecast": {"name": "이번달 운세", "desc": "한 달의 에너지와 주의할 점"},
    "careerThree": {"name": "진로 상담", "desc": "커리어의 흐름과 방향"},
    "threeCard": {"name": "쓰리 카드", "desc": "과거, 현재, 미래의 흐름"},
    "yesNo": {"name": "예/아니오", "desc": "단순한 질문에 명확한 답"}
  },
  "position": {
    "todayMessage": "오늘의 메시지",
    "me": "나",
    "otherPerson": "상대방",
    "relationship": "관계의 방향",
    "shownSide": "보여주는 모습",
    "hiddenHeart": "숨기는 마음",
    "trueIntention": "진짜 의도",
    "theme": "이달의 테마",
    "challenge": "도전",
    "opportunity": "기회",
    "advice": "조언",
    "currentSituation": "현재 상황",
    "obstacle": "장애물",
    "pathForward": "나아갈 길",
    "past": "과거",
    "present": "현재",
    "future": "미래",
    "answer": "답"
  }
}
```

### 구현 순서 (P0)

1. `reading_category.dart` + `spread_type.dart` 모델 생성
2. `spread_select_screen.dart` 신규 + 라우터 추가
3. `menu_screen.dart` 카테고리 → spread_select 네비게이션 변경
4. `prompts/` 모듈 생성 (prompt_builder + 5개 카테고리 컨텍스트)
5. `tarot_session.dart`에 `category` 전달, `PromptBuilder.build()` 사용
6. `oracle_system.txt` 삭제 → PromptBuilder로 완전 대체
7. i18n `spreads.json` 추가 (ko/en)
8. 기존 `SpreadType` enum 마이그레이션 (구 3개 → 신 10개)
