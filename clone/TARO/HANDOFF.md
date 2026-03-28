# TARO 핸드오프 — 2026-03-27

## Goal

A2UI 기반 타로 상담 앱. 실제 타로 상담사 앞에 앉아서 카드를 뽑고, 질문에 맞는 해석을 받고, 대화를 계속하는 경험을 구현.

---

## 이번 세션 (2026-03-27)

### 백엔드 구축 — SJ ai-gemini 패턴 미러링

1. **Supabase MCP 인증** — `supabase-taro` (`niagjmqffibeuetxxbxp`) 완료
2. **DB 테이블 3개** — `tarot_readings`, `tarot_messages`, `tarot_daily_usage` + 트리거 + RPC
3. **Edge Function `ai-tarot` v2** — SSE 스트리밍, thought 필터링, 반복 감지, 비용 기록
4. **테스트 성공** — curl SSE 확인 (200, 3.4초)
5. **env.json** — SUPABASE_URL + SUPABASE_ANON_KEY + GEMINI_API_KEY
6. **Supabase secret** — GEMINI_API_KEY 등록

### 3차 코드 리뷰 수정

| 파일 | 변경 |
|------|------|
| `tarot_session.dart` | `host` nullable, `_client.dispose()` 추가 |
| `consultation_screen.dart` | host null 체크, `_cardsSubmitted` 중복 호출 가드 |
| `persona_selector.dart` | locale 기반 ko/en 분기 |
| `cache_service.dart` | 미사용 응답 캐시 데드 코드 삭제 |
| Edge Function | `detectRepetition` 정규식 backreference 수정 |

---

## 이전 세션 완료 작업

### SJ 구조 정렬 + UI
- `core/`, `shared/`, `router/`, `i18n/` → SJ 동일 패턴
- Riverpod 3.0 + go_router + easy_localization (17개 언어)
- Splash → Menu → ConsultationScreen (단일 상담 화면)

### 상담 Phase 상태 머신
```
question → personaPick → picking → reading → chatting
```

### A2UI 카탈로그 (5개)
TarotCard, ReadingSummary, SpreadPicker, OracleMessage, DrawPrompt

### 페르소나 (4종)
mystic(신비 현자), analyst(분석가), friend(친구), direct(직설가)

### v2 UI 플로우
큰 세리프 텍스트 인사 → 추천 칩 → 페르소나 선택 → 카드 팬 → AI 해석 → 채팅

### 캐싱
Hive — 리딩 히스토리 (최근 20개), NotoSerifKR 폰트 번들링

---

## 현재 아키텍처

```
Flutter Client
  ├── env.json (SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY)
  ├── AiConfig.useEdgeFunction → true (env에 Supabase 설정 있으면)
  ├── EdgeFunctionAiClient → POST /functions/v1/ai-tarot (SSE)
  ├── GeminiAiClient → 직접 Gemini API (fallback)
  └── TaroContentGenerator → JSON 블록 파싱 → GenUI 렌더링

Supabase (niagjmqffibeuetxxbxp)
  ├── Edge Function: ai-tarot v2
  │   ├── Gemini streamGenerateContent (SSE)
  │   ├── thought 필터링 + 반복 감지
  │   └── increment_tarot_usage RPC
  ├── DB: tarot_readings, tarot_messages, tarot_daily_usage
  └── Secret: GEMINI_API_KEY
```

## 프로젝트 파일 구조

```
clone/TARO/lib/
├── main.dart, app.dart
├── core/ (config, constants, services, theme)
├── models/tarot_card_data.dart
├── shared/widgets/ (card_face, flip_card)
├── i18n/ (17개 언어 × 6 JSON + loader)
├── router/ (routes, app_router)
└── features/
    ├── splash/, menu/
    └── reading/
        ├── models/ (tarot_message, oracle_persona, reading_record)
        ├── services/ (ai_client, transport)
        ├── catalog/ (5개 A2UI 컴포넌트 + tarot_catalog)
        └── pages/
            ├── providers/tarot_session.dart
            ├── screens/consultation_screen.dart
            └── widgets/ (chat_input_field, persona_selector, question_phase, persona_pick_phase, dramatic_text)
```

---

## What Worked / What Didn't

### Worked
- 수학적 radius 계산 → 카드 절대 잘리지 않음
- Phase 상태 머신 → 깔끔한 전환
- 한 장씩 해석 → 상담 느낌
- SJ Edge Function 패턴 미러링 → 검증된 패턴 재사용
- EdgeFunctionAiClient가 이미 구현되어 있어 env.json만으로 전환

### Didn't Work (반복하지 말 것)
- 하드코딩 radius/offset → 항상 수학적 역산
- AI에 모든 카드 한번에 전송 → 한 장씩
- 별도 화면(CardPicker→CardReveal→Reading) → 단일 ConsultationScreen
- `detectRepetition`에서 backreference 빠뜨림 → 정규식은 SJ 원본 복사 후 검증

---

## Next Steps

### 1. E2E 테스트 (최우선)
```bash
cd clone/TARO
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define-from-file=env.json
```
전체 플로우: question → personaPick → picking → reading → chatting

### 2. DB 연동
- Hive 로컬 → Supabase `tarot_readings`/`tarot_messages` 서버 저장 추가
- Supabase Auth 도입 (user_id FK) — 익명 Auth or 소셜 로그인
- Edge Function `verify_jwt` → true

### 3. 구조 개선
- TarotSession → Riverpod Provider 전환
- ConsultationScreen 478줄 → 위젯 분리
- Edge Function 실패 시 GeminiAiClient fallback

### 4. 앱 런칭 전
- 모바일 빌드 (Android/iOS)
- 프롬프트 튜닝 (Oracle 응답 품질)
- 앱 아이콘/스플래시 이미지

---

## 주의사항

- **MCP**: `mcp__supabase-taro__*` 전용 (`mcp__supabase__`는 SJ)
- **env.json**: gitignored — 커밋 금지
- **Edge Function secrets**: MCP로 설정 불가, Dashboard에서만 관리
- **Gemini 3 Flash**: 반복 출력 known issue — Edge Function에서 감지/중단 처리됨

## 메모리 참조

경로: `D:\DevCache\claude-data\projects\D--Data-33-A2UI-A2UI\memory\`

| 파일 | 내용 |
|------|------|
| `taro/overview.md` | 프로젝트 전체 개요 |
| `taro/backend_setup.md` | Edge Function + DB + RPC 상세 |
| `taro/consultation_flow.md` | 상담 Phase 상태 머신 |
| `taro/code_review_log.md` | 1차/2차/3차 리뷰 전체 기록 |
| `taro/next_steps.md` | 다음 작업 목록 |
| `taro/supabase_mcp_setup.md` | MCP 인증 + 프로젝트 정보 |
