# A2UI Windows 환경 설정 가이드

## 개요

A2UI 샘플을 Windows 환경에서 실행할 때 발생하는 문제들과 해결 방법을 정리한 문서입니다.

## 사전 요구사항

- Node.js v22+
- Python 3.13+
- [UV](https://docs.astral.sh/uv/) (Python 패키지 매니저)
- Gemini API Key ([발급](https://aistudio.google.com/apikey))

## 발견된 이슈 및 해결

### 1. Windows cp949 인코딩 에러

**파일**: `samples/agent/adk/restaurant_finder/tools.py:39`

**증상**:
```
UnicodeDecodeError: 'cp949' codec can't decode byte 0xe2 in position 202
```

**원인**: `open(file_path)`에서 encoding을 지정하지 않으면 Windows는 기본 cp949를 사용합니다. `restaurant_data.json`에 UTF-8 문자(별점 기호 등)가 포함되어 있어 파싱 실패.

**해결**:
```python
# Before (실패)
with open(file_path) as f:

# After (성공)
with open(file_path, encoding="utf-8") as f:
```

---

### 2. A2UI Extension 미활성화 (빈 응답)

**파일**: `samples/client/lit/shell/client.ts:86`

**증상**: 프론트엔드에서 메시지를 보내면 콘솔에 `[]` (빈 배열)만 출력되고 UI가 렌더링되지 않음.

**원인**: 클라이언트의 `sendMessage` 호출 시 `message.extensions` 필드에 A2UI extension URI를 포함하지 않아서, 백엔드의 `try_activate_a2ui_extension()`이 `False`를 반환. 결과적으로 text-only agent가 선택되는데, text agent는 `_schema_manager`가 `None`이라 내부 에러 발생.

**해결**:
```typescript
// Before (extensions 미포함)
const response = await client.sendMessage({
  message: {
    messageId: crypto.randomUUID(),
    role: "user",
    parts: parts,
    kind: "message",
  },
});

// After (extensions 포함)
const response = await client.sendMessage({
  message: {
    messageId: crypto.randomUUID(),
    role: "user",
    parts: parts,
    kind: "message",
    extensions: ["https://a2ui.org/a2a-extension/a2ui/v0.8"],
  },
});
```

---

### 3. confirmation.json 유효성 검증 실패

**파일**: `samples/agent/adk/restaurant_finder/examples/confirmation.json`

**증상**:
```
Failed to validate example confirmation.json: Component 'confirmation-card'
references non-existent component 'confirmation-column' in field 'child'
```

**원인**: `confirmation-card`가 `child: "confirmation-column"`을 참조하지만, `confirmation-column` 컴포넌트가 JSON에 정의되어 있지 않음.

**해결**: `confirmation-column` Column 컴포넌트를 추가하고, 기존 자식 컴포넌트들을 `explicitList`로 연결.

```json
{
  "id": "confirmation-column",
  "component": {
    "Column": {
      "children": {
        "explicitList": [
          "confirm-title",
          "confirm-image",
          "divider1",
          "confirm-details",
          "divider2",
          "confirm-dietary",
          "divider3",
          "confirm-text"
        ]
      }
    }
  }
}
```

---

### 4. Rollup 네이티브 모듈 누락 (Windows)

**증상**:
```
Cannot find module @rollup/rollup-win32-x64-msvc
```

**원인**: npm의 optional dependencies 버그로 인해 플랫폼별 네이티브 모듈이 설치되지 않음.

**해결**:
```bash
cd samples/client/lit
rm -rf node_modules package-lock.json
npm install
```

---

### 5. 프론트엔드 URL 주의사항

기본 URL(`http://localhost:5173/`)은 Contact Manager 앱을 표시합니다.
Restaurant Finder를 사용하려면 쿼리 파라미터를 추가해야 합니다:

```
http://localhost:5173/?app=restaurant
```

## 빌드 순서

렌더러 빌드에는 의존성 순서가 있습니다:

```
1. renderers/web_core       (기반 라이브러리)
2. renderers/markdown/markdown-it  (마크다운 렌더러, web_core 의존)
3. renderers/lit             (Lit 렌더러, web_core 의존)
4. samples/client/lit/shell  (샘플 클라이언트, 위 3개 의존)
```

```bash
# 1. Web Core
cd renderers/web_core && npm install && npm run build

# 2. Markdown
cd ../markdown/markdown-it && npm install && npm run build

# 3. Lit Renderer
cd ../../lit && npm install && npm run build

# 4. Shell Client
cd ../../samples/client/lit/shell && npm install && npm run dev
```

## 실행

```bash
# 터미널 1: 백엔드 에이전트
cd samples/agent/adk/restaurant_finder
cp .env.example .env  # GEMINI_API_KEY 설정
uv run .
# → http://localhost:10002

# 터미널 2: 프론트엔드
cd samples/client/lit/shell
npm run dev
# → http://localhost:5173/?app=restaurant
```
