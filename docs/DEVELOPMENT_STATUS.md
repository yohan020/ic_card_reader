# Development status

- 마지막 갱신: 2026-08-10 (Asia/Seoul)
- 현재 Phase: Android 출시 준비 · 우선순위 7
- 전체 첫 출시 진행률: 약 82%
- Phase 0 진행률: 100% (자료 분석과 문서 초안)
- Phase 1 Android 진행률: 100%
- Phase 2 진행률: 100% (파서·역명 조회·거래 분류·금액·실물 카드·익명 제보 검증 완료, 영구 저장은 제품 범위에서 제외)
- 실기기 검증: Android 카드 읽기와 Supabase 익명 제보 확인, iOS는 Apple Developer 계정 준비 전 보류

## 고정 개발 우선순위

아래 순서는 사용자가 변경을 요청하기 전까지 고정한다. 현재 단계의 완료 조건을 충족한 뒤 다음 단계로 이동한다.

| 순서 | 단계 | 현재 상태 | 구현된 내용 | 남은 완료 조건 |
|---:|---|---|---|---|
| 1 | 역 코드 데이터베이스 연결 | **완료** | 허가받은 Yoiko 데이터 8,537행 연결, `50-A5-78` 형식의 코드 조회, 승·하차역과 노선명 표시, 다중 후보 보존, 실제 역 코드 검증 | 완료. 철도 사업자 표시는 필수 범위에서 제외 |
| 2 | 거래 유형 판별 | **완료** | 실물 fixture 기반 철도 `16/01`, 버스 `05/0D`, 물품 구매 `C8/46`, 잔액 증가 충전 `C8/49` 분류와 유형별 화면 표시 | 완료. 환불·정산은 실제 샘플 확보 전까지 `UNKNOWN` 유지 |
| 3 | 금액 계산 검증 | **완료** | 이전 기록과 잔액 차이 계산, 충전 증가액 표시, 증가액·날짜 이상을 일반 사용액으로 표시하지 않는 상태 처리, 실제 금액 대조 | 완료 |
| 4 | 이용내역 로컬 저장 | **생략** | 카드 IDm을 저장하지 않는 상태에서 여러 카드 기록이 잘못 합쳐질 위험을 피하기 위해 영구 저장하지 않고 현재 스캔 세션만 표시 | 제품 범위에서 제외. 다른 카드를 스캔하면 현재 화면을 새 결과로 교체 |
| 5 | 실제 카드 검증 | **완료** | Android 실물 카드에서 NFC 읽기, 역명·거래 유형·금액·잔액 및 초기 잔액 전용 카드 표시 검증 | 완료 |
| 6 | 오류 제보 기능 연결 | **완료** | Supabase DB·Edge Function 배포, 익명 인증 Repository, 미리보기·동의·전송 성공/실패 UI, 개인정보 제외 테스트, Android 실전송·접수 내역 확인 | 완료 |
| 7 | Android 출시 준비 | **진행 중** | 앱 정보·아이콘·권한·통합 문의 이메일·개인정보처리방침과 GitHub Pages용 공개 페이지 완료, 오류 제보 1년 보관·월간 정리와 백업·10분당 5건 제한·검토 상태 운영 절차 확정 | GitHub Pages 활성화·release 서명·AAB·Play Console·출시 전 최종 점검 |

현재 작업 범위는 **7번 Android 출시 준비**다. 이용내역은 영구 저장하지 않고 현재 스캔 세션에서만 유지하며, 다른 카드를 스캔하면 새 결과로 교체한다. 환불·정산은 실제 샘플 확보 전까지 `UNKNOWN`으로 유지한다. iOS 개발은 Android 우선 개발과 출시 준비를 마친 뒤 Apple Developer 계정을 준비해 재개한다.

## Android 출시 준비 순서

아래 순서는 사용자가 변경을 요청하기 전까지 출시 준비의 기본 순서로 사용한다.

1. **앱 기본 정보 확정**
   - 정식 앱 이름, 패키지 이름 유지 여부, 앱 버전과 빌드 번호를 정한다.
   - 앱 아이콘과 Play Store용 간단한 소개 문구를 준비한다.
2. **개인정보 및 권한 안내 작성**
   - 개인정보처리방침을 작성하고 NFC 사용 목적을 설명한다.
   - 오류 제보 시 Supabase로 전송되는 정보와 IDm·다른 이용내역·위치를 전송하지 않는다는 점을 명시한다.
   - Yoiko 역 코드 데이터의 출처와 이용 조건을 앱과 정책 문서에 표시한다.
3. **오류 제보 운영 보완**
   - 익명 로그인 악용 방지, 무료 DB 정기 백업, 오래된 익명 Auth 사용자 정리 방식을 정한다.
   - `RECEIVED`·`REVIEWING`·`VERIFIED`·`APPLIED`·`REJECTED` 상태의 운영 절차를 정한다.
   - 네트워크 중단 시 실패 안내와 수동 다시 시도를 최종 확인한다.
4. **Android release 설정**
   - 출시용 서명 키를 만들고 Git 저장소 밖에서 안전하게 관리한다.
   - release 난독화·최적화 정책과 버전 정보를 확정한다.
   - 서명된 Android App Bundle(AAB)을 생성한다.
5. **Play Console 준비**
   - 앱을 등록하고 아이콘·스크린샷·설명·개인정보처리방침 주소를 입력한다.
   - 데이터 보안 설문, NFC 기능과 지원 기기 안내를 작성한다.
   - 내부 테스트 트랙에 AAB을 업로드한다.
6. **출시 전 최종 점검**
   - 화면 크기, 라이트·다크 모드, NFC 꺼짐·카드 모드·시간 초과를 확인한다.
   - 이용내역 없는 카드와 다수 기록 카드, 오류 제보 성공·실패를 확인한다.
   - release 빌드에서 IDm과 원시 기록이 로그에 남지 않는지 확인한다.

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
- 16바이트 원시 이력에서 날짜·단말/처리·지역·출발/도착·잔액을 추출하는 `phase2-parser-v1` 구현.
- 인접 잔액 차이의 `CALCULATED`·`UNAVAILABLE`·`SUSPICIOUS` 상태 구현. 잔액 증가를 차감액으로 표시하지 않음.
- 스캔 성공 화면에 추출 날짜·코드·잔액·금액 상태를 표시하는 확장 카드 추가.
- 검증되지 않은 거래 유형은 `UNKNOWN`으로 보존.
- 실제 샘플이 없는 환불·정산은 분류 규칙을 만들지 않고 `UNKNOWN`으로 유지하는 회귀 테스트 추가.
- 초기 관리 기록 `08/07`·`12/07`·`22/07`은 다음 거래의 금액 계산 기준 잔액으로 사용한 뒤 화면에서만 제외하고, 단말/처리 코드 `00/00` 블록부터 읽기·파싱을 종료.
- 실물 카드와 비교 앱 결과를 근거로 `C7/46`을 물품 구매로 추가 분류.
- 스캔 중 Android NFC가 `꺼지는 중/꺼짐`으로 바뀌면 상태 스트림에서 즉시 감지하고 네이티브 `stopSession`을 다시 호출하지 않은 채 안전하게 오류 화면으로 복귀.
- Samsung 기기의 카드 전용 모드 상태값 `5`에서 `nfc_manager 4.2.1` 네이티브 수신기가 프로세스를 종료하는 원인을 확인하고, 이를 읽기 불가(`OFF`)로 전달해 스캔을 종료하고 기본 모드 변경을 안내하는 로컬 플러그인 패치 적용.
- 실물 20블록 fixture를 근거로 철도 7건, 버스 4건, 물품 구매 8건, 충전 1건을 분류하고 충전 증가액 `+¥2,000` 표시.
- 철도 기록에만 승하차역을 조회·표시하고 버스·물품 구매·충전에는 의미 없는 역 코드를 노출하지 않도록 분리.
- 버스 회사 고유 코드는 확인 전까지 추정하지 않고 목록에 `버스 회사 미확인`, 상세 화면에 `회사 고유 코드 미해석`으로 안내.
- 이용내역 아이콘을 거래 유형별 색상으로 구분하고, 상세 경로의 역명을 강조하며 충전액은 초록색으로 표시.
- 이용내역 상단에 가장 최근 거래 후 잔액을 `현재 카드 잔액`으로 표시하고 기준을 함께 안내.
- 이용내역이 없는 새 카드도 숨겨진 초기 관리 기록의 잔액을 사용해 `현재 카드 잔액`을 표시하고 `초기 잔액 기록 기준`으로 안내.
- 스캔 완료의 `확인 필요` 집계에서 가장 오래된 기록의 정상적인 `계산 불가`를 제외하고 실제 이상·미확인 기록만 계산.
- 오류 제보 3단계 전체에 선택한 이용내역 요약을 표시하고 제보 화면의 글자 굵기를 완화.
- 오류 제보 진행도를 현재 단계까지 채워지는 3분할 가로 막대와 `현재/3 단계` 문구로 표시.
- Supabase PostgreSQL migration과 RLS, 익명 사용자 JWT를 검증하는 Edge Function을 배포하고 Android에서 실제 익명 제보 접수와 Table Editor 저장을 확인.
- 제보 완료 모달을 앱의 하늘색 디자인에 맞추고 접수 번호와 IDm·다른 이용내역 미전송 안내를 표시.
- 사용 허가를 받은 Yoiko 역 코드 8,537행을 앱 asset으로 포함하고 허가 조건 고지 등록.
- 정확 지역 코드, 안전한 지역 힌트(`50 -> 01`, `F0 -> 03`), 단일 노선·역 후보, 승하차 지역 교집합 순의 보수적 역 조회 구현.
- 다중 후보와 미등록 역은 임의 확정하지 않고 원시 코드를 유지.
- 홈 최근 기록, 이용내역 목록, 상세 화면에 확인된 역명·노선명을 연결.
- 실물 fixture 첫 기록 `50-A5-78 -> 50-AC-38`을 `名鉄名古屋 -> 中部国際空港`으로 조회하는 테스트 추가.
- 실제 역 코드 검증 완료. 철도 사업자 표시는 제품 필수 범위에서 제외하고 역명·노선명만 제공.
- 카드에 남아 있는 가장 오래된 기록은 `계산 불가`로 유지하고, 상세 화면에서 이전 잔액 기록이 없어 금액을 계산할 수 없다는 원인을 안내.
- 하늘색 Material 3 UI, 스캔 진행/완료, 이용내역, 설정, 개발자, 신고 초안 화면 구현.

## 진행 중인 작업

- GitHub Pages를 활성화하고 개인정보처리방침 공개 URL 접속 확인.

## 다음 작업

1. GitHub Pages를 활성화하고 `https://yohan020.github.io/ic_card_reader/` 접속을 확인한다.
2. Android release 서명과 AAB 준비로 이동한다.

## 생성·수정한 주요 파일

- `pubspec.yaml`, `README.md`, `analysis_options.yaml`
- `lib/main.dart`, `lib/src/app.dart`
- `lib/src/features/card_reader/**`
- `lib/src/features/transaction_history/**`
- `lib/src/features/station_resolver/**`
- `lib/src/features/issue_report/domain/**`
- `assets/data/stations/yoiko_station_codes.csv`
- `assets/licenses/yoiko-station-data-TERMS.txt`
- `test/features/card_reader/felica_protocol_test.dart`
- `test/features/card_reader/raw_history_fixture_log_test.dart`
- `test/features/card_reader/physical_card_fixture_test.dart`
- `test/features/transaction_history/transit_history_parser_test.dart`
- `test/features/station_resolver/asset_station_database_test.dart`
- `test/fixtures/felica/android_history_20_v1.json`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`
- `docs/*.md`

## 실행한 검사

- UTF-8로 요구사항과 원자료를 읽고 파일 목록/CSV 행 수/헤더를 확인함.
- Flutter 3.44.9 / Dart 3.12.2 로컬 도구 준비 및 플랫폼 러너 생성 성공.
- `dart format lib test`: 성공.
- `flutter analyze`: 성공, 문제 0건.
- `flutter test`: 성공, 25개 테스트 통과.
- Android 빌드: 사용자 요청에 따라 미실행.
- iOS build: 미실행(Windows 환경).
- 실물 카드: Android에서 20블록 읽기 확인. 카드 종류·기기·OS 상세는 미기록, iOS 미검증.

## 확인되지 않은 항목

- nfc_manager 4.2.1의 각 플랫폼 실기기 런타임 동작.
- Android에서 태그 발견 자체를 Polling 성공으로 볼 때 카드별 안정성.
- 서비스 코드/블록 종료 조건/상태 플래그의 카드별 실제 동작.
- 참고 코드의 단말/처리 코드 분류(실물 검증 전 사용 금지).
- PiTaPa, 충전·환불·조정의 확실한 판별 규칙.
- Yoiko 역 데이터의 정확성 및 향후 변경 사항.

## 주요 기술 결정

- Phase 1에서는 원시 블록만 다루고 미확인 거래를 분류하지 않는다.
- IDm은 Android 명령 조립/응답 확인과 iOS 세션 내부에서만 일시 사용한다.
- Android `android.hardware.nfc`는 optional로 두고 런타임 가용성을 확인한다.
- 역 데이터 v1은 Yoiko 허가 조건 고지와 함께 번들 CSV를 한 번 로드해 메모리 인덱스로 사용한다. 데이터 단독 재배포는 금지하며 로컬 이용내역 SQLite 작업에서 사전 생성 DB 전환을 재검토한다.
- 정확 지역 조회 실패 후 단일 후보만 자동 확정하며 다중 후보는 유지한다.
- 신고는 사용자 미리보기·동의 후 한 건만 선택적으로 전송하고 자동 DB 반영하지 않는다.
- Phase 3는 디렉터리 확장 지점만 두며 Phase 2 완료 전 구현하지 않는다.
