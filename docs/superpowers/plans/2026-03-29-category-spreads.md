# Category-Based Spreads & AI Interpretation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 3-spread system with a modular 5-category / 7-spread architecture where each category has its own AI interpretation context, card positions, and a DrawCards A2UI trigger for conversational card drawing.

**Architecture:** New `ReadingCategory` + `SpreadType` enums replace the old monolithic `SpreadType`. A `PromptBuilder` module assembles system prompts from category context + persona + A2UI rules. A new `DrawCards` A2UI component lets the AI auto-trigger card drawing during conversation.

**Tech Stack:** Flutter, Riverpod, GenUI (A2UI), dartantic_ai, Supabase Edge Function, easy_localization

**Spec:** `docs/superpowers/specs/2026-03-29-category-spreads-design.md`

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/models/reading_category.dart` | ReadingCategory enum (5 categories) |
| `lib/models/spread_type.dart` | SpreadType enum (10 spreads, replaces old) |
| `lib/features/menu/pages/screens/spread_select_screen.dart` | Category → spread selection (2nd depth) |
| `lib/features/reading/prompts/prompt_builder.dart` | System prompt assembler |
| `lib/features/reading/prompts/base_prompt.dart` | Common rules (persona, boundaries, A2UI) |
| `lib/features/reading/prompts/love_prompt.dart` | Love/relationship interpretation context |
| `lib/features/reading/prompts/career_prompt.dart` | Career interpretation context |
| `lib/features/reading/prompts/fortune_prompt.dart` | Fortune/forecast interpretation context |
| `lib/features/reading/prompts/general_prompt.dart` | General reading context |
| `lib/features/reading/prompts/decision_prompt.dart` | Decision/choice context (incl. Yes/No rules) |
| `lib/features/reading/catalog/draw_cards.dart` | DrawCards A2UI component (triggers picking) |
| `lib/i18n/ko/spreads.json` | Korean translations for categories, spreads, positions |
| `lib/i18n/en/spreads.json` | English translations |

### Modified Files
| File | Changes |
|------|---------|
| `lib/models/tarot_card_data.dart` | Remove old `SpreadType` enum, keep `TarotCardData`, `DrawnCard`, `TarotDeck` |
| `lib/router/routes.dart` | Add `/spreads` route |
| `lib/router/app_router.dart` | Add spread select route, pass category + spreadType |
| `lib/features/menu/pages/screens/menu_screen.dart` | Categories → spread_select navigation |
| `lib/features/reading/pages/providers/tarot_session.dart` | Accept category, use PromptBuilder, handle DrawCards |
| `lib/features/reading/pages/screens/consultation_screen.dart` | Accept category param, handle additional draw mode |
| `lib/features/reading/catalog/tarot_catalog.dart` | Register DrawCards component |
| `lib/features/reading/services/transport.dart` | Detect DrawCards in surfaces |
| `lib/i18n/multi_file_asset_loader.dart` | Add 'spreads' to file list |
| `assets/prompts/oracle_system.txt` | Delete (replaced by PromptBuilder) |

### Deleted Files
| File | Reason |
|------|--------|
| `assets/prompts/oracle_system.txt` | Replaced by `prompts/` module |
| `lib/features/reading/catalog/spread_picker.dart` | App handles spread selection natively |

---

## Task 1: Data Models (ReadingCategory + SpreadType)

**Files:**
- Create: `clone/TARO/lib/models/reading_category.dart`
- Create: `clone/TARO/lib/models/spread_type.dart`
- Modify: `clone/TARO/lib/models/tarot_card_data.dart`

- [ ] **Step 1: Create ReadingCategory enum**

```dart
// lib/models/reading_category.dart
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
```

- [ ] **Step 2: Create new SpreadType enum**

```dart
// lib/models/spread_type.dart
import 'reading_category.dart';

enum SpreadTier { free, premium, pro }

enum SpreadType {
  // P0: Fortune
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

  // P0: Love
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

  // P0: Career
  careerThree(
    cardCount: 3,
    displayName: '진로 상담',
    positions: ['현재 상황', '장애물', '나아갈 길'],
    category: ReadingCategory.career,
    description: '커리어의 흐름과 방향',
    tier: SpreadTier.free,
  ),

  // P0: General
  threeCard(
    cardCount: 3,
    displayName: '쓰리 카드',
    positions: ['과거', '현재', '미래'],
    category: ReadingCategory.general,
    description: '과거, 현재, 미래의 흐름',
    tier: SpreadTier.free,
  ),

  // P0: Decision
  yesNo(
    cardCount: 1,
    displayName: '예/아니오',
    positions: ['답'],
    category: ReadingCategory.decision,
    description: '단순한 질문에 명확한 답',
    tier: SpreadTier.free,
  ),

  // P1 (stub — UI hidden until tier unlocked)
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
  celticCross(
    cardCount: 10,
    displayName: '켈틱 크로스',
    positions: ['현재', '장애물', '기반', '과거', '가능성', '미래', '태도', '환경', '희망과 두려움', '최종 결과'],
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

  /// Get all spreads for a category, filtered to free tier only (P0).
  static List<SpreadType> forCategory(ReadingCategory cat) =>
      values.where((s) => s.category == cat && s.tier == SpreadTier.free).toList();
}
```

- [ ] **Step 3: Remove old SpreadType from tarot_card_data.dart**

In `lib/models/tarot_card_data.dart`, delete lines 79-93 (the old `SpreadType` enum). Keep `TarotCardData`, `DrawnCard`, and `TarotDeck` classes. Update the `DrawnCard` class to import from new location if needed.

- [ ] **Step 4: Fix all imports referencing old SpreadType**

Search and replace across these files:
- `consultation_screen.dart` — `import '../../../../models/tarot_card_data.dart'` → add `import '../../../../models/spread_type.dart'`
- `menu_screen.dart` — same
- `app_router.dart` — same
- `tarot_session.dart` — same

Run: `grep -rn "SpreadType" clone/TARO/lib/` to find all references.

- [ ] **Step 5: Commit**

```bash
git add clone/TARO/lib/models/
git commit -m "feat(taro): add ReadingCategory + SpreadType enums (P0 7 spreads)"
```

---

## Task 2: Prompt System (PromptBuilder + Category Contexts)

**Files:**
- Create: `clone/TARO/lib/features/reading/prompts/base_prompt.dart`
- Create: `clone/TARO/lib/features/reading/prompts/love_prompt.dart`
- Create: `clone/TARO/lib/features/reading/prompts/career_prompt.dart`
- Create: `clone/TARO/lib/features/reading/prompts/fortune_prompt.dart`
- Create: `clone/TARO/lib/features/reading/prompts/general_prompt.dart`
- Create: `clone/TARO/lib/features/reading/prompts/decision_prompt.dart`
- Create: `clone/TARO/lib/features/reading/prompts/prompt_builder.dart`
- Delete: `clone/TARO/assets/prompts/oracle_system.txt`

- [ ] **Step 1: Create base_prompt.dart**

Contains: persona rules, language rules, boundaries, A2UI component rules (OracleMessage, TarotCard, ReadingSummary), DrawCards rules. This is the content currently in `oracle_system.txt` minus category-specific parts.

```dart
// lib/features/reading/prompts/base_prompt.dart
const basePrompt = '''
You are "The Oracle" — an ancient, wise Tarot reader conducting a live consultation.

LANGUAGE:
- Respond in the same language as the user's message.
- If the user writes in Korean, respond entirely in Korean.

BOUNDARIES:
- Never predict death, catastrophe, or serious illness
- Frame everything as guidance, reflection, and empowerment
- Reversed cards mean blocked energy or internal work needed, not doom

TAROT MASTERY:
You know all 78 Rider-Waite-Smith cards intimately — Major Arcana journey, elemental suits (Wands=Fire, Cups=Water, Swords=Air, Pentacles=Earth), positional meanings, and card relationships.
''';

const a2uiRules = '''
AVAILABLE UI COMPONENTS:
Generate rich UI by embedding A2UI JSON in markdown code fences.

Components:
1. OracleMessage: {text} — YOUR VOICE. Use for ALL speech. Never plain text.
2. TarotCard: {cardName, position, isReversed, interpretation, cardDescription} — Card interpretation
3. ReadingSummary: {title, summary, advice} — Holistic summary after all cards
4. DrawCards: {count, reason, positions, context} — Trigger card drawing (see DRAW CARDS RULES)

CRITICAL RULES:
- ALL speech MUST use OracleMessage. NEVER plain text.
- Each component in its own ```json fence with surfaceUpdate wrapper.
- Component IDs must be unique (e.g., "oracle-msg-1", "card-1", "draw-1")

CARD-BY-CARD READING:
- Cards revealed ONE AT A TIME. Interpret ONLY that card.
- When receiving "The seeker drew N cards...": brief OracleMessage only (1-2 sentences), invite tap.
- When receiving "The seeker revealed: [card]...": TarotCard + OracleMessage (2-3 sentences).
- If "LAST card": also give ReadingSummary.

DRAW CARDS RULES:
- When seeker asks about a NEW TOPIC needing cards → DrawCards(count: 1-3, context: "new_topic")
- When seeker wants MORE DEPTH → DrawCards(count: 1, context: "additional")
- When seeker just asks a FOLLOW-UP QUESTION → OracleMessage only (no DrawCards)
- NEVER DrawCards for casual chat ("thanks", "I see", "goodbye")
- DrawCards auto-triggers the card picking UI in the app

EXAMPLE surfaceUpdate:
```json
{"surfaceUpdate":{"surfaceId":"oracle-1","components":[{"id":"msg-1","component":{"OracleMessage":{"text":"..."}}}]}}
```

EXAMPLE DrawCards:
```json
{"surfaceUpdate":{"surfaceId":"draw-1","components":[{"id":"draw-1","component":{"DrawCards":{"count":3,"reason":"연애운을 보기 위해","positions":["나","상대","관계"],"context":"new_topic"}}}]}}
```
''';
```

- [ ] **Step 2: Create 5 category context files**

Each file exports a single `const String` with category-specific interpretation guidance.

`love_prompt.dart`:
```dart
const loveContext = '''
READING CONTEXT: LOVE & RELATIONSHIPS
- Focus on emotional dynamics, attraction, communication patterns
- "나" = seeker's emotional state and approach to love
- "상대방" = how the other person feels and behaves
- "관계의 방향" = the relationship's trajectory
- For 속마음: emphasize what is hidden vs shown, read between the lines
- Cups = emotions/love, Wands = passion/desire, Swords = communication/conflict, Pentacles = commitment/stability
- Be empathetic, never judgmental about relationship choices
''';
```

`career_prompt.dart`:
```dart
const careerContext = '''
READING CONTEXT: CAREER & GROWTH
- Focus on professional development, opportunities, workplace dynamics
- "현재 상황" = current career energy and satisfaction
- "장애물" = what blocks progress — frame as growth area, not doom
- "나아갈 길" = actionable direction with specific next steps
- Wands = ambition/projects, Pentacles = money/stability, Swords = decisions/strategy, Cups = satisfaction/passion
- Be practical and actionable — seekers want concrete guidance
''';
```

`fortune_prompt.dart`:
```dart
const fortuneContext = '''
READING CONTEXT: FORTUNE & FORECAST
- Focus on timing, energy flow, and cycles
- For monthly: connect positions to specific weeks or phases
- "이달의 테마" = overarching energy for the period
- "도전" = obstacles to prepare for — growth opportunities
- "기회" = doors opening — be specific about where to look
- "조언" = actionable guidance — what to do differently
- Reference seasonal context when relevant
- For daily 1-card: give focused, immediate guidance for today only
''';
```

`general_prompt.dart`:
```dart
const generalContext = '''
READING CONTEXT: GENERAL CONSULTATION
- Classic Past/Present/Future timeline reading
- "과거" = foundations and influences that shaped the current situation
- "현재" = the energy surrounding the seeker right now
- "미래" = likely trajectory if current energy continues
- Balance between insight and actionable guidance
- Connect the three cards as a narrative arc, not isolated meanings
''';
```

`decision_prompt.dart`:
```dart
const decisionContext = '''
READING CONTEXT: DECISION & CHOICE
- For 예/아니오 (Yes/No): GIVE A CLEAR ANSWER FIRST, then nuance
  Positive cards (Sun, Star, World, Aces, 6 of Wands, 10 of Cups, 9 of Pentacles) = YES
  Challenging cards (Tower, 10 of Swords, 5 of Cups, 3 of Swords, The Devil) = NO
  Neutral cards (2 of Swords, Wheel of Fortune, The Hanged Man) = NOT YET / DEPENDS
- Do NOT be vague. The seeker wants directional clarity.
- After the answer, explain supporting conditions.
- No reversals for Yes/No readings — read all cards upright.
''';
```

- [ ] **Step 3: Create prompt_builder.dart**

```dart
// lib/features/reading/prompts/prompt_builder.dart
import '../../../models/reading_category.dart';
import '../../../models/spread_type.dart';
import '../models/oracle_persona.dart';
import 'base_prompt.dart';
import 'love_prompt.dart';
import 'career_prompt.dart';
import 'fortune_prompt.dart';
import 'general_prompt.dart';
import 'decision_prompt.dart';

class PromptBuilder {
  const PromptBuilder._();

  static String build({
    required ReadingCategory category,
    required SpreadType spread,
    required OraclePersona persona,
  }) {
    return [
      basePrompt,
      'PERSONA:\n${persona.aiPrompt}',
      _categoryContext(category),
      _spreadContext(spread),
      a2uiRules,
    ].join('\n\n');
  }

  static String _categoryContext(ReadingCategory category) {
    return switch (category) {
      ReadingCategory.love => loveContext,
      ReadingCategory.career => careerContext,
      ReadingCategory.fortune => fortuneContext,
      ReadingCategory.general => generalContext,
      ReadingCategory.decision => decisionContext,
    };
  }

  static String _spreadContext(SpreadType spread) {
    final positions = spread.positions.asMap().entries
        .map((e) => '  ${e.key + 1}. "${e.value}"')
        .join('\n');
    return 'CURRENT SPREAD: ${spread.displayName} (${spread.cardCount} cards)\n'
        'Card positions:\n$positions';
  }
}
```

- [ ] **Step 4: Delete oracle_system.txt**

```bash
rm clone/TARO/assets/prompts/oracle_system.txt
```

- [ ] **Step 5: Commit**

```bash
git add clone/TARO/lib/features/reading/prompts/
git add -u clone/TARO/assets/prompts/
git commit -m "feat(taro): modular prompt system with category-specific AI contexts"
```

---

## Task 3: DrawCards A2UI Component

**Files:**
- Create: `clone/TARO/lib/features/reading/catalog/draw_cards.dart`
- Modify: `clone/TARO/lib/features/reading/catalog/tarot_catalog.dart`

- [ ] **Step 1: Create DrawCards catalog component**

```dart
// lib/features/reading/catalog/draw_cards.dart
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/constants/app_colors.dart';

final drawCards = CatalogItem(
  componentName: 'DrawCards',
  jsonSchema: JsonSchemaBuilder()
    ..integerProperty('count', description: 'Number of cards to draw (1-3)')
    ..stringProperty('reason', description: 'Why cards are needed')
    ..arrayProperty('positions', items: JsonSchemaBuilder()..stringProperty('_'), description: 'Position names')
    ..stringProperty('context', description: 'initial, additional, or new_topic'),
  builder: (context, data, {onAction}) {
    final count = data['count'] as int? ?? 1;
    final reason = data['reason'] as String? ?? '';
    final positions = (data['positions'] as List?)?.cast<String>() ?? [];

    return _DrawCardsWidget(
      count: count,
      reason: reason,
      positions: positions,
      onAction: onAction,
    );
  },
);

class _DrawCardsWidget extends StatelessWidget {
  const _DrawCardsWidget({
    required this.count,
    required this.reason,
    required this.positions,
    this.onAction,
  });

  final int count;
  final String reason;
  final List<String> positions;
  final void Function(GenUiAction)? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF1A0A2E)],
        ),
        border: Border.all(color: TaroColors.gold.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style, color: TaroColors.gold, size: 32),
          const SizedBox(height: 8),
          if (reason.isNotEmpty)
            Text(
              reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TaroColors.gold.withAlpha(200),
                fontFamily: 'NotoSerifKR',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '$count장의 카드를 뽑아주세요',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 13,
            ),
          ),
          if (positions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              positions.join(' · '),
              style: TextStyle(
                color: TaroColors.gold.withAlpha(120),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Register in tarot_catalog.dart**

```dart
// Update tarot_catalog.dart
import 'draw_cards.dart';

final Catalog taroCatalog = Catalog([
  CoreCatalogItems.text,
  CoreCatalogItems.column,
  tarotCard,
  readingSummary,
  oracleMessage,
  drawCards,       // new
  // Remove: spreadPicker, drawPrompt (no longer used)
], catalogId: 'taro-catalog');
```

- [ ] **Step 3: Commit**

```bash
git add clone/TARO/lib/features/reading/catalog/
git commit -m "feat(taro): add DrawCards A2UI component for AI-triggered card draws"
```

---

## Task 4: TarotSession — Category + PromptBuilder + DrawCards Detection

**Files:**
- Modify: `clone/TARO/lib/features/reading/pages/providers/tarot_session.dart`
- Modify: `clone/TARO/lib/features/reading/services/transport.dart`

- [ ] **Step 1: Add category field and PromptBuilder to TarotSession**

In `tarot_session.dart`:
- Add `ReadingCategory? _category` field
- Add `ReadingCategory? get category => _category`
- Update `startConsultation` to accept `category` parameter
- Replace `rootBundle.loadString('assets/prompts/oracle_system.txt')` with `PromptBuilder.build(category: _category!, spread: _currentSpread!, persona: _persona)`
- Move `_ensureInitialized` to be called AFTER persona and category are known (in `confirmPersona`)
- Add `int _requestedDrawCount = 0` and `List<String> _requestedPositions = []`
- Add `requestMoreCards(int count, List<String> positions)` method that sets picking phase

- [ ] **Step 2: Detect DrawCards in transport.dart**

In `_tryEmitA2ui`, after emitting a SurfaceUpdate, check if any component is a `DrawCards`:

```dart
if (message is SurfaceUpdate) {
  for (final comp in message.components) {
    final props = comp.componentProperties;
    if (props.containsKey('DrawCards')) {
      final dc = props['DrawCards'] as Map<String, dynamic>;
      _onDrawCardsDetected?.call(
        dc['count'] as int? ?? 1,
        (dc['positions'] as List?)?.cast<String>() ?? [],
      );
    }
  }
}
```

Add a `void Function(int count, List<String> positions)? _onDrawCardsDetected` callback to `TaroContentGenerator`.

- [ ] **Step 3: Wire DrawCards callback in TarotSession**

```dart
_contentGenerator = TaroContentGenerator(
  aiClient: _client,
  systemPrompt: systemPrompt,
  onDrawCardsDetected: (count, positions) {
    _requestedDrawCount = count;
    _requestedPositions = positions;
    _phase = ConsultationPhase.picking;
    notifyListeners();
  },
);
```

- [ ] **Step 4: Commit**

```bash
git add clone/TARO/lib/features/reading/
git commit -m "feat(taro): integrate PromptBuilder + DrawCards detection in session"
```

---

## Task 5: Navigation — Spread Select Screen + Router

**Files:**
- Create: `clone/TARO/lib/features/menu/pages/screens/spread_select_screen.dart`
- Modify: `clone/TARO/lib/router/routes.dart`
- Modify: `clone/TARO/lib/router/app_router.dart`
- Modify: `clone/TARO/lib/features/menu/pages/screens/menu_screen.dart`

- [ ] **Step 1: Add route constant**

```dart
// routes.dart
abstract class Routes {
  static const String splash = '/';
  static const String menu = '/menu';
  static const String spreadSelect = '/spreads';
  static const String consultation = '/tarot';
}
```

- [ ] **Step 2: Create SpreadSelectScreen**

A screen showing spreads for a given category. If only 1 spread in category, auto-navigate to consultation.

```dart
// lib/features/menu/pages/screens/spread_select_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/reading_category.dart';
import '../../../../models/spread_type.dart';
import '../../../../router/routes.dart';
import '../../../../shared/widgets/mystical_background.dart';

class SpreadSelectScreen extends StatelessWidget {
  const SpreadSelectScreen({super.key, required this.category});
  final ReadingCategory category;

  @override
  Widget build(BuildContext context) {
    final spreads = SpreadType.forCategory(category);
    final theme = Theme.of(context);

    return Scaffold(
      body: MysticalBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                      color: TaroColors.gold.withAlpha(180),
                      onPressed: () => context.go(Routes.menu),
                    ),
                    Icon(category.icon, color: TaroColors.gold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      category.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'NotoSerifKR',
                        color: TaroColors.gold.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              // Spread list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: spreads.length,
                  itemBuilder: (context, index) {
                    final spread = spreads[index];
                    return _SpreadTile(
                      spread: spread,
                      onTap: () => context.push(
                        Routes.consultation,
                        extra: {
                          'category': category,
                          'spreadType': spread,
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpreadTile extends StatelessWidget {
  const _SpreadTile({required this.spread, required this.onTap});
  final SpreadType spread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TaroColors.gold.withAlpha(35)),
              gradient: const LinearGradient(
                colors: [Color(0xFF2D1B69), Color(0xFF1A0A2E)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spread.displayName, style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'NotoSerifKR', color: TaroColors.gold.withAlpha(230),
                      )),
                      const SizedBox(height: 4),
                      Text(spread.description, style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(120),
                      )),
                      const SizedBox(height: 6),
                      Text(
                        spread.positions.join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: TaroColors.gold.withAlpha(100), letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TaroColors.gold.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TaroColors.gold.withAlpha(40)),
                  ),
                  child: Text(
                    '${spread.cardCount}장',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: TaroColors.gold.withAlpha(200),
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
```

- [ ] **Step 3: Update app_router.dart**

Add spread select route. Update consultation route to accept category.

```dart
GoRoute(
  path: Routes.spreadSelect,
  builder: (context, state) {
    final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
    final category = extra?['category'] as ReadingCategory? ?? ReadingCategory.general;
    return SpreadSelectScreen(category: category);
  },
),
// Update consultation route to also accept category
GoRoute(
  path: Routes.consultation,
  builder: (context, state) {
    final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
    final spread = extra?['spreadType'] as SpreadType? ?? SpreadType.threeCard;
    final category = extra?['category'] as ReadingCategory? ?? spread.category;
    return ConsultationScreen(spreadType: spread, category: category);
  },
),
```

- [ ] **Step 4: Update menu_screen.dart**

Change category cards to navigate to `Routes.spreadSelect`. For single-spread categories (fortune.dailyOne, decision.yesNo), go directly to consultation.

```dart
void _onCategoryTap(BuildContext context, ReadingCategory category) {
  final spreads = SpreadType.forCategory(category);
  if (spreads.length == 1) {
    // Single spread — go directly to consultation
    context.push(Routes.consultation, extra: {
      'category': category,
      'spreadType': spreads.first,
    });
  } else {
    // Multiple spreads — show selection screen
    context.push(Routes.spreadSelect, extra: {'category': category});
  }
}
```

- [ ] **Step 5: Update ConsultationScreen to accept category**

Add `final ReadingCategory category;` parameter.

- [ ] **Step 6: Commit**

```bash
git add clone/TARO/lib/features/menu/ clone/TARO/lib/router/ clone/TARO/lib/features/reading/pages/screens/
git commit -m "feat(taro): spread select screen + 2-depth category navigation"
```

---

## Task 6: ConsultationScreen — Additional Draw Mode

**Files:**
- Modify: `clone/TARO/lib/features/reading/pages/screens/consultation_screen.dart`

- [ ] **Step 1: Handle picking phase re-entry from chatting**

When `tarotSessionProvider.phase` changes to `picking` while previously in `chatting/reading`, enable additional draw mode:

```dart
// In build(), detect phase transition to picking from chatting
if (phase == ConsultationPhase.picking) {
  final session = ref.read(tarotSessionProvider);
  if (session.requestedDrawCount > 0) {
    // Additional draw mode — reset local card state for new picks
    _selectedIndices.clear();
    _drawnCards.clear();
    _cardsSubmitted = false;
    // Use requested count instead of spreadType.cardCount
  }
}
```

Update `CardFanWidget` to use `session.requestedDrawCount` when in additional draw mode (fallback to `widget.spreadType.cardCount`).

- [ ] **Step 2: Submit additional cards back to session**

```dart
if (_pickingDone && !_cardsSubmitted) {
  _cardsSubmitted = true;
  final session = ref.read(tarotSessionProvider);
  Future.delayed(const Duration(milliseconds: 800), () {
    if (mounted) session.handleAdditionalDraw(_drawnCards);
  });
}
```

- [ ] **Step 3: Commit**

```bash
git add clone/TARO/lib/features/reading/pages/screens/
git commit -m "feat(taro): additional card draw mode in consultation screen"
```

---

## Task 7: i18n — Spreads Translations

**Files:**
- Create: `clone/TARO/lib/i18n/ko/spreads.json`
- Create: `clone/TARO/lib/i18n/en/spreads.json`
- Modify: `clone/TARO/lib/i18n/multi_file_asset_loader.dart`

- [ ] **Step 1: Create ko/spreads.json**

```json
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
  }
}
```

- [ ] **Step 2: Create en/spreads.json**

```json
{
  "category": {
    "fortune": "Fortune",
    "love": "Love & Relationship",
    "career": "Career",
    "general": "General Reading",
    "decision": "Decision"
  },
  "spread": {
    "dailyOne": {"name": "Daily Tarot", "desc": "One card message for today"},
    "loveThree": {"name": "You & Them", "desc": "Read the energy between two people"},
    "hiddenFeelings": {"name": "Hidden Feelings", "desc": "What are they really thinking?"},
    "monthlyForecast": {"name": "Monthly Forecast", "desc": "This month's energy and advice"},
    "careerThree": {"name": "Career Reading", "desc": "Your professional path forward"},
    "threeCard": {"name": "Three Card", "desc": "Past, Present, Future"},
    "yesNo": {"name": "Yes or No", "desc": "Clear answer to a simple question"}
  }
}
```

- [ ] **Step 3: Add 'spreads' to MultiFileAssetLoader**

In `multi_file_asset_loader.dart`, add `'spreads'` to the `_fileNames` list.

- [ ] **Step 4: Commit**

```bash
git add clone/TARO/lib/i18n/
git commit -m "feat(taro): add spreads i18n (ko/en) with categories and positions"
```

---

## Task 8: Cleanup & Integration Test

**Files:**
- Delete: `clone/TARO/lib/features/reading/catalog/spread_picker.dart`
- Modify: various import fixes

- [ ] **Step 1: Remove spread_picker.dart**

```bash
rm clone/TARO/lib/features/reading/catalog/spread_picker.dart
```

Remove import from `tarot_catalog.dart`.

- [ ] **Step 2: Fix all remaining import errors**

Run `flutter analyze` and fix any broken imports from the SpreadType migration.

```bash
cd clone/TARO && flutter analyze
```

- [ ] **Step 3: Build and run**

```bash
flutter run -d emulator-5554 --dart-define-from-file=env.json
```

Verify: menu → category → spread select → consultation flow works end-to-end.

- [ ] **Step 4: Final commit**

```bash
git add -A clone/TARO/
git commit -m "feat(taro): complete P0 category-based spread system"
git push origin main
```
