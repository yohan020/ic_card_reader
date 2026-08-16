# 프로젝트 문서 안내

이 폴더는 `ic_card_reader` 프로젝트 문서를 목적별로 관리한다.

## 현재 작업 관리

- [`planning/TODO.md`](planning/TODO.md): 아직 해야 할 작업과 단계별 체크리스트
- [`DEVELOPMENT_STATUS.md`](DEVELOPMENT_STATUS.md): 완료된 구현과 현재 개발 단계의 요약
- [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md): 재현 가능한 문제, 제한사항, 보류 사유
- [`TEST_MATRIX.md`](TEST_MATRIX.md): 플랫폼과 기능별 검증 상태
- [`planning/PASS_COMPARISON_ANALYSIS.md`](planning/PASS_COMPARISON_ANALYSIS.md): 교통패스 손익 비교 기능의 데이터·API·구조 분석

## 구현 및 운영 문서

- [`ARCHITECTURE.md`](ARCHITECTURE.md): 앱 구조와 데이터 흐름
- [`TRANSIT_HISTORY_PARSER_FIRST_REVISION.md`](TRANSIT_HISTORY_PARSER_FIRST_REVISION.md): 이용내역 파서 근거와 수정 이력
- [`REPORTING_SPEC.md`](REPORTING_SPEC.md): 익명 오류 제보 사양
- [`ISSUE_REPORT_ADMIN.md`](ISSUE_REPORT_ADMIN.md): localhost 문의 관리 페이지 설정·운영 절차
- [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md): Supabase 배포와 운영 절차
- [`ANDROID_RELEASE_SIGNING.md`](ANDROID_RELEASE_SIGNING.md): Android 릴리스 서명 절차
- [`DATA_AND_LICENSES.md`](DATA_AND_LICENSES.md): 데이터 출처와 이용 조건
- [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md): 개인정보처리방침 원문
- [`index.html`](index.html): GitHub Pages 공개용 개인정보처리방침

## 에이전트 규칙

- [`agent/RULES.md`](agent/RULES.md): 세션 간 유지해야 하는 AI 에이전트 작업 규칙
- 프로젝트 루트의 `AGENTS.md`는 새 세션이 위 규칙 문서를 자동으로 찾기 위한 연결 파일이다.

## 갱신 원칙

1. 작업을 시작할 때 `planning/TODO.md`의 현재 작업을 확인한다.
2. 새 작업이 확정되면 TODO에 추가하고 상태를 `진행 중`으로 표시한다.
3. 구현과 검증이 끝난 작업만 완료 처리한다.
4. 중요한 완료 내용은 `DEVELOPMENT_STATUS.md`에도 기록한다.
5. 해결되지 않은 결함이나 제한사항은 `KNOWN_ISSUES.md`에 기록한다.
