---
name: feedback-changelog
description: 작업 완료 후 CHANGELOG.md 업데이트를 항상 수행해야 함
metadata:
  type: feedback
---

작업이 완료되면 사용자가 별도로 요청하지 않아도 **반드시 `docs/CHANGELOG.md`에 변경 사항을 기록**한다.

**Why:** 사용자가 "작업 내용은 항상 CHANGELOG에 작성해"라고 명시적으로 지시함. 리팩토링, 버그 수정, UI 변경 등 모든 작업이 대상.

**How to apply:** CLAUDE.md의 "작업 완료 프로토콜"에 이미 CHANGELOG 업데이트가 포함되어 있으나, 실제로 누락하는 경우가 있었음. 작업 완료 직후 CHANGELOG 업데이트를 빠뜨리지 않도록 체크.
