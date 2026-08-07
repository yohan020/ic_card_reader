# Data and licenses

## 분석한 원자료

`ic_card_export/`는 수정하지 않는 참고 자료다.

| 자료 | 판단 | 이식 방식 |
|---|---|---|
| `felica/transit_ic_nfc_reader.dart` | 참고 후 재작성 | 시스템/서비스 코드와 플랫폼 호출 흐름만 채택. IDm 반환·로그, 거래 추정, 혼합 책임은 제거 |
| `models/transit_station_resolver.dart` | 개념 재사용 가능 | Phase 2에서 로컬 SQLite 모델로 단순화 |
| `station_database/*.csv` | 조건부 재사용 | 라이선스 확인 후 빌드 시 SQLite로 변환 |
| `documentation/soltia48_suica-viewer_LICENSE` | 직접 포함 필요 | Suica Viewer 데이터 배포 시 MIT 고지 유지 |
| Kotlin 엔티티/DTO/Repository/Service | 참고만 | Spring/JPA 종속이므로 Dart/SQLite로 재작성 |
| PostgreSQL V3~V5 | 참고만 | SQLite 문법과 재현 가능한 migration으로 변환 |
| Kotlin 테스트 | 규칙 참고 | 정확/단일/다중 후보 사례를 Dart 테스트로 재작성 |
| Yoiko fetch 스크립트 | 개발 도구 참고 | 런타임에서 실행하지 않음 |

## 데이터 현황

- Suica Viewer CSV: 6,958 데이터 행, 고유 완전 키 6,956개, SHA-256 `bb931d56f3186765c0186797ed1ac59e2fa55af2fb8528eb052e481df1632b8f`.
- Yoiko CSV: 8,537 데이터 행, 고유 완전 키 8,537개, SHA-256 `c38cdaa4f56d7d834174ba775dd78dbfd9b58fb19c4c1c68f6c52faa7c4889e6`.
- 기존 병합 우선순위 적용 결과: 8,537개 완전 키. `(line,station)`만 같은 지역 충돌 조합은 368개이며 최대 후보 수는 3개다.
- 지역 코드는 데이터에 `00`~`03`이 있고 기존 서비스는 경험적 힌트 `50 -> 01`, `F0 -> 03`을 사용한다. 공식 의미가 확인되지 않아 확정 규칙으로 간주하지 않는다.
- 사업자 코드, 유효 기간, 공식 데이터 버전은 없다.
- Suica Viewer 원본 중 `00-06-4D`, `00-06-57`은 완전 키 중복이 있어 권위 행을 실물/공식 자료로 확인해야 한다.

## 라이선스

Suica Viewer CSV의 원 출처는 `soltia48/suica-viewer`이며 MIT License, Copyright (c) 2025 KIRISHIKI Yudai이다. 데이터 또는 substantial portion을 배포하면 저작권과 허가문을 포함한다.

Yoiko CSV는 원 출처의 최신 이용 조건과 앱 번들 재배포 허용 여부가 확인되지 않았다. 확인 전에는 새 프로젝트에 복사하거나 배포 asset으로 만들지 않는다. 현재는 원본 `ic_card_export/` 안에서 분석만 했다.

## 개인정보 원칙

- 카드 IDm 원문: 영구 저장, 로그, 화면 표시, 분석 도구, 서버 전송 금지.
- 원시 이력: 한 레코드씩 로컬 저장 가능. 신고 시 사용자가 선택하고 미리보기/동의한 한 건만 전송 가능.
- 이름, 이메일, 기기 고유 ID, 현재 위치, 전체 이동 경로: 수집·전송 금지.
- 익명 fixture: IDm과 개인 메타데이터 없이 16바이트 블록과 기대되는 프로토콜 수준 결과만 포함한다.
