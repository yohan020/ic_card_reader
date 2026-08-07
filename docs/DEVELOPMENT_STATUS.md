# Development status

- 마지막 갱신: 2026-08-07 (Asia/Seoul)
- 현재 Phase: Phase 1 NFC 카드 스캔 PoC
- 전체 첫 출시 진행률: 약 20%
- Phase 0 진행률: 100% (자료 분석과 문서 초안)
- Phase 1 소스 구현 진행률: 약 90%
- 실기기 검증: Android 20블록 읽기 확인, iOS 미검증

## 완료된 작업

- `ic_card_export/` 전체 파일 인벤토리, NFC 리더, 플랫폼 설정, DB/CSV, 조회 규칙, 테스트, 라이선스 분석.
- 원본 파일 무수정 유지.
- Flutter 앱의 feature 기반 골격과 Phase 1 domain/data/presentation 분리.
- NFC 활성 확인, 스캔 시작, 취소, 30초 시간초과, NFC-F 판별.
- 시스템 코드 `0003`, 서비스 코드 `090F`, iOS Polling, Read Without Encryption, 최대 20블록 읽기.
- Android 응답 명령/IDm echo/상태/길이 검증과 iOS 상태/길이 검증.
- IDm을 결과·로그·저장소에서 제거하고 메모리 내 통신에만 사용.
- 원시 16바이트 개발자 화면과 비FeliCa/태그 이탈/빈 이력 오류 UI.
- 순수 FeliCa 명령/응답 단위 테스트 소스 작성.
- 신고 데이터 모델/Repository 인터페이스/API·큐·운영 검토 계약 초안.
- 필수 문서 6종 초기 작성.
- Flutter 3.44.9로 Android/iOS 플랫폼 러너 생성 및 iOS entitlement 빌드 설정 연결.
- Dart format, Flutter 정적 분석, 단위/위젯 테스트, Android debug APK 빌드 성공.
- fixture 확보를 위한 debug 전용 원시 블록 터미널 로그와 개인정보 제외 포맷 테스트 추가.
- Android 실물 카드에서 읽은 IDm 없는 20블록 fixture 저장 및 형식 검증 테스트 추가.
- 실제 이동 이력 보호를 위해 실물 카드 fixture와 재배포 조건이 불명확한 `ic_card_export/`를 Git 추적 대상에서 제외.

## 진행 중인 작업

- 실기기 기반 Phase 1 성공 조건 검증.

## 다음 작업

1. Android NFC-F 지원 기기와 iPhone에서 Suica/PASMO/ICOCA를 각각 반복 스캔.
2. 세션 취소·시간초과·태그 이탈·비FeliCa·연속 스캔을 기기별 확인.
3. IDm/개인정보를 제외한 실제 16바이트 fixture와 기대 블록 수를 추가.
4. macOS/Xcode에서 iOS 빌드·서명·entitlement를 검증.
5. 양 플랫폼 원시 결과를 비교해 Phase 1 성공 조건을 판정.
6. 성공 조건 충족 후에만 Phase 2 파서/SQLite/역 조회를 시작.

## 생성·수정한 주요 파일

- `pubspec.yaml`, `README.md`, `analysis_options.yaml`
- `lib/main.dart`, `lib/src/app.dart`
- `lib/src/features/card_reader/**`
- `lib/src/features/issue_report/domain/**`
- `test/features/card_reader/felica_protocol_test.dart`
- `test/features/card_reader/raw_history_fixture_log_test.dart`
- `test/features/card_reader/physical_card_fixture_test.dart`
- `test/fixtures/felica/android_history_20_v1.json`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`
- `docs/*.md`

## 실행한 검사

- UTF-8로 요구사항과 원자료를 읽고 파일 목록/CSV 행 수/헤더를 확인함.
- Flutter 3.44.9 / Dart 3.12.2 로컬 도구 준비 및 플랫폼 러너 생성 성공.
- `dart format lib test`: 성공, 12개 파일 확인.
- `flutter analyze`: 성공, 문제 0건.
- `flutter test`: 성공, 6개 테스트 통과.
- `flutter build apk --debug`: 이전 앱 코드 변경에서 성공. 이번 fixture/test 추가 후에는 사용자 요청에 따라 미실행.
- iOS build: 미실행(Windows 환경).
- 실물 카드: Android에서 20블록 읽기 확인. 카드 종류·기기·OS 상세는 미기록, iOS 미검증.

## 확인되지 않은 항목

- nfc_manager 4.2.1의 각 플랫폼 실기기 런타임 동작.
- Android에서 태그 발견 자체를 Polling 성공으로 볼 때 카드별 안정성.
- 서비스 코드/블록 종료 조건/상태 플래그의 카드별 실제 동작.
- 참고 코드의 단말/처리 코드 분류(실물 검증 전 사용 금지).
- PiTaPa, 충전·환불·조정의 확실한 판별 규칙.
- Yoiko 앱 번들 재배포 조건과 Suica Viewer 중복 2건의 권위 값.

## 주요 기술 결정

- Phase 1에서는 원시 블록만 다루고 미확인 거래를 분류하지 않는다.
- IDm은 Android 명령 조립/응답 확인과 iOS 세션 내부에서만 일시 사용한다.
- Android `android.hardware.nfc`는 optional로 두고 런타임 가용성을 확인한다.
- 역 데이터는 런타임 CSV import 대신 빌드 시 versioned SQLite asset으로 만들 예정이다.
- 정확 지역 조회 실패 후 단일 후보만 자동 확정하며 다중 후보는 유지한다.
- 신고는 사용자 미리보기·동의 후 한 건만 선택적으로 전송하고 자동 DB 반영하지 않는다.
- Phase 3는 디렉터리 확장 지점만 두며 Phase 2 완료 전 구현하지 않는다.
