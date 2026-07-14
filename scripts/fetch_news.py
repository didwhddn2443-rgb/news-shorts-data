#!/usr/bin/env python3
"""
매일 아침 RSS 피드를 수집해서 docs/news.json 으로 저장하는 스크립트.
GitHub Actions에서 자동 실행됨. 로컬 테스트: python scripts/fetch_news.py
"""
import json
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import feedparser

KST = timezone(timedelta(hours=9))

# 카테고리별 RSS 소스.
# 피드 URL은 언론사 사정으로 바뀔 수 있음. 실패한 피드는 건너뛰고 나머지로 진행.
FEEDS = [
    {"category": "종합", "source": "SBS뉴스", "url": "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=01"},
    {"category": "정치", "source": "SBS뉴스", "url": "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=02"},
    {"category": "경제", "source": "SBS뉴스", "url": "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=03"},
    {"category": "사회", "source": "SBS뉴스", "url": "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=07"},
    {"category": "국제", "source": "SBS뉴스", "url": "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=08"},
    # 필요하면 다른 언론사 RSS를 여기에 추가
]

PER_CATEGORY = 3          # 카테고리당 최대 기사 수
LOOKBACK_HOURS = 24       # 이 시간 이내 기사만 수집 (전날 아침 ~ 오늘 아침)


def clean_html(text: str) -> str:
    """HTML 태그와 과도한 공백 제거."""
    text = re.sub(r"<[^>]+>", "", text or "")
    text = re.sub(r"\s+", " ", text).strip()
    return text


def entry_datetime(entry) -> datetime | None:
    for key in ("published_parsed", "updated_parsed"):
        parsed = getattr(entry, key, None)
        if parsed:
            return datetime(*parsed[:6], tzinfo=timezone.utc)
    return None


def main() -> int:
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(hours=LOOKBACK_HOURS)
    cards = []

    for feed_info in FEEDS:
        try:
            parsed = feedparser.parse(feed_info["url"])
        except Exception as exc:  # noqa: BLE001
            print(f"[skip] {feed_info['url']} 파싱 실패: {exc}", file=sys.stderr)
            continue

        if parsed.bozo and not parsed.entries:
            print(f"[skip] {feed_info['url']} 응답 없음/형식 오류", file=sys.stderr)
            continue

        count = 0
        for entry in parsed.entries:
            if count >= PER_CATEGORY:
                break
            published = entry_datetime(entry)
            # 발행시각을 못 읽으면 최신 항목으로 간주하고 포함
            if published and published < cutoff:
                continue

            title = clean_html(getattr(entry, "title", ""))
            summary = clean_html(getattr(entry, "summary", getattr(entry, "description", "")))
            if not title:
                continue
            # 요약이 너무 길면 두 문장 정도로 자름
            if len(summary) > 160:
                summary = summary[:157].rstrip() + "..."

            cards.append({
                "category": feed_info["category"],
                "title": title,
                "summary": summary or "(요약이 제공되지 않은 기사입니다)",
                "source": feed_info["source"],
                "link": getattr(entry, "link", ""),
                "published": published.astimezone(KST).isoformat() if published else None,
            })
            count += 1

    if not cards:
        print("수집된 기사가 0건입니다. 피드 URL을 점검하세요.", file=sys.stderr)
        return 1

    output = {
        "generated_at": now.astimezone(KST).isoformat(),
        "count": len(cards),
        "cards": cards,
    }

    out_path = Path(__file__).resolve().parent.parent / "docs" / "news.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"완료: {len(cards)}건 → {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
