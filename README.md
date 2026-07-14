# 브리핑 B안 — GitHub Actions 자동 수집 + 무료 앱

## 구조 (돈 드는 곳 없음)
```
[매일 아침 7:30 KST쯤]
GitHub Actions ──실행──▶ scripts/fetch_news.py ──RSS 수집──▶ docs/news.json 커밋
                                                              │
아이폰 앱 열면 ◀────────── raw.githubusercontent.com URL로 JSON 불러옴
```

## 폴더 내용
- `scripts/fetch_news.py` — RSS 여러 개를 긁어 news.json 생성
- `.github/workflows/update-news.yml` — 매일 아침 자동 실행 스케줄
- `*.swift` — 아이폰 앱 소스 (API 키 불필요 버전)

## 세팅 순서

### 1. GitHub 저장소 만들기
github.com에서 새 저장소 생성 (예: `news-shorts-data`). Public으로 만들 것
(raw URL로 JSON을 무료로 읽으려면 Public이어야 함. 뉴스 데이터라 민감정보 아님).

### 2. 파일 올리기 (Claude Code에 시키면 됨)
이 폴더에서 Claude Code 실행 후:
"이 폴더를 git 저장소로 초기화하고, 내 GitHub의 news-shorts-data 저장소로 푸시해줘.
그 전에 scripts/fetch_news.py를 로컬에서 실행해서 RSS가 실제로 수집되는지 확인하고,
피드 URL이 죽어있으면 살아있는 한국 언론사 RSS로 교체해줘."

※ gh CLI가 없다고 하면 `brew install gh` 후 `gh auth login` 하면 됨.

### 3. Actions 첫 실행
GitHub 저장소 페이지 → Actions 탭 → "Update morning news" → "Run workflow" 버튼으로
수동 1회 실행 → 성공하면 docs/news.json 생긴 것 확인.

### 4. 앱의 Config.swift 수정
```swift
static let newsJSONURL = "https://raw.githubusercontent.com/본인아이디/news-shorts-data/main/docs/news.json"
```
본인아이디와 저장소이름을 실제 값으로 교체.

### 5. Xcode 빌드 & 아이폰 설치
이전 안내와 동일:
- Xcode에서 iOS App 프로젝트 생성 (SwiftUI)
- swift 파일 4개 교체 (NewsShortsApp, ContentView, NewsCard, NewsService, Config)
- Signing & Capabilities에서 본인 Apple ID 팀 지정
- 아이폰 연결 후 ⌘R
- 7일마다 재빌드 필요 (무료 계정 제약)

## 알아둘 것
- GitHub Actions 무료 스케줄은 정각 보장이 안 됨 (몇 분~수십 분 지연 가능)
- RSS 피드 URL은 언론사가 바꾸면 죽음 → 그때 fetch_news.py의 FEEDS만 수정
- RSS 요약은 언론사가 제공하는 원문 스니펫이라 AI 요약보다 거칢
- 언론사 RSS는 개인 구독/이용 범위에서 쓰는 것 (재배포/상업 이용 금지) — 개인 앱이라 문제 없음
