# Architecture

## 목표와 경계

앱은 일본 전국호환 선불식 교통계 IC 카드의 최근 이력을 읽는다. NFC 통신과 파싱, 역 조회, 저장, UI를 분리하며 기본 데이터 처리는 기기 안에서 끝낸다. 카드 IDm 원문은 FeliCa 명령 수행 중 메모리에서만 사용하고 저장·로그·화면·서버 전송에서 제외한다.

현재 Android Phase 1 NFC PoC와 Phase 2의 보수적 원시 이력 파서·로컬 역명 조회·선택적 익명 신고를 구현했다. 이용내역 영구 저장은 제품 범위에서 제외했다. Phase 3 교통패스 비교는 본 앱과 분리된 Flutter Web 프로토타입, 순수 Dart 계산 엔진, ODPT 정적 역·운임 가져오기와 한국어 자동완성을 구현했다. 실제 ODPT 생성물 검증과 자동 경로 탐색은 남아 있다. iOS NFC 실기기 검증은 Apple Developer 계정 준비 후 진행한다.

## 디렉터리 구조

```text
lib/src/
  features/
    card_reader/          NFC 세션, FeliCa 프로토콜, 원시 블록 UI
    transaction_history/ Phase 2 파서·저장·표시 예정
    station_resolver/     Phase 2 번들 역 데이터 조회
    issue_report/         신고 계약 및 향후 큐
    pass_comparison/      Phase 3 순수 계산 엔진·별도 Web 프로토타입
```

의존 방향은 `presentation -> domain <- data`다. 순수 프로토콜 파서는 플러그인과 분리해 fixture 단위 테스트가 가능하다.

## Phase 1 흐름

1. `NfcManager.checkAvailability`로 활성 상태를 확인한다.
2. ISO 18092 세션을 시작하고 30초 타이머를 건다.
3. Android는 `NfcFAndroid`, iOS는 `FeliCaIos`로만 변환한다.
4. iOS는 시스템 코드 `0003` Polling을 수행한다. Android는 OS가 NFC-F Polling 후 전달한 태그를 사용한다.
5. 서비스 코드 `090F`(wire order `0F 09`)에 Read Without Encryption을 블록 0부터 최대 19까지 요청한다.
6. Android는 응답 길이·명령 코드 `07`·IDm echo·상태 플래그·블록 수를, iOS는 상태 플래그·블록 수·16바이트 길이를 검증한다.
7. 빈 블록 또는 후속 블록 실패에서 종료한다. 첫 블록 실패는 오류로 표시한다.
8. 결과에는 원시 16바이트 블록과 스캔 시각만 포함한다. IDm은 포함하지 않는다.

## Phase 1 성공 조건

- Android 실기기에서 지원 카드의 원시 이력을 안정적으로 읽는다.
- iPhone 실기기에서 같은 카드의 원시 이력을 읽는다.
- 양쪽 화면에서 IDm 없이 원시 블록을 비교할 수 있다.
- 태그 이탈·비FeliCa·상태 오류·취소·시간초과가 앱 종료 없이 안내된다.
- 사용자 제공 또는 직접 확보한 실제 블록을 개인 식별 정보 없이 fixture로 추가한다.

위 조건은 실기기 검증 전까지 완료로 표시하지 않는다.

## Phase 2 구조

- `TransitHistoryParser`: 구현됨. 16바이트 레코드를 보존하며 날짜, 단말/처리 코드, 지역·출발·도착 코드, 잔액을 파싱한다. 실물 fixture로 확인한 `16/01` 철도, `05/0D` 버스, `C8/46` 물품 구매, 잔액 증가가 동반된 `C8/49` 충전만 분류하며 나머지는 `UNKNOWN`이다.
- `AmountCalculation`: 구현됨. 인접 레코드 잔액 차이를 `CALCULATED`, `UNAVAILABLE`, `SUSPICIOUS`로 표현한다. 잔액 증가를 일반 차감으로 표시하지 않으며 날짜 순서가 비정상이면 의심 상태로 둔다.
- `AssetStationDatabase`: 구현됨. Yoiko CSV를 최초 조회 시 한 번 파싱해 완전 키와 `(line,station)` 인덱스를 만든다. 정확 조회, 제한된 지역 힌트, 단일 후보, 출발/도착 지역 교집합만 사용하며 다중 후보는 보존한다.
- `LocalStore`: SQLite에 해시된 카드 식별값, 원시 레코드/해시, 파싱 결과, 파서/DB 버전, 마지막 스캔 시각을 저장한다. IDm 원문은 금지한다.
- `IssueReportRepository`: 사용자 동의가 있을 때 한 건만 전송하며 실패 건은 로컬 큐에서 재시도한다.

## 역 데이터 저장 방식

현재 앱 asset에는 사용 허가를 받은 Yoiko CSV 8,537행과 허가 조건 고지를 포함한다. 약 1.4MB CSV는 최초 카드 스캔 후 한 번 메모리 인덱스로 변환하며 이후 같은 실행에서는 재사용한다. 원본 export는 수정하지 않고 Git 추적에서 제외한다.

## CSV -> SQLite 후속 계획

필요하면 빌드 전 개발 도구가 UTF-8 Yoiko CSV를 읽어 정수 코드를 정규화하고 SQLite asset을 생성한다. 테이블은 `station_codes(region_code, line_code, station_code, station_name, line_name, operator_name, source, confidence)`와 완전 키 unique index, `(line_code, station_code)` index를 갖는다. 입력 SHA-256, 변환 스크립트 버전, 행 수를 `station_database_meta`에 기록한다. 수동 보정은 별도 migration으로 재현한다.

로컬 이용내역 SQLite 저장을 구현할 때 역 데이터도 사전 생성 SQLite asset으로 전환할지 실기기 로딩 성능을 기준으로 결정한다. 어떤 형식으로 전환하더라도 Yoiko 데이터는 앱과 함께만 배포하고 데이터 단독 배포는 금지한다.

## 주요 위험

- iOS는 실기기·유료 Apple Developer 서명·NFC Tag Reading capability·entitlements·Info.plist 시스템 코드가 모두 필요하다. Simulator에서는 검증할 수 없다.
- Android 기기마다 NFC-F 지원과 태그 이탈 동작이 다를 수 있다. NFC feature는 optional이므로 런타임 확인이 필수다.
- 참고 `Info.plist`에는 리터럴 `` `r`n `` 문자열이 섞여 있어 그대로 재사용할 수 없다.
- 참고 리더의 IDm 로그와 미확인 거래 기본 철도 분류는 채택하지 않았다. 원시 블록은 fixture 확보를 위해 debug 빌드에서만 시작/종료 marker와 함께 출력하며 release에서는 출력하지 않는다.
- 시스템/서비스 코드와 바이트 해석은 실물 카드 검증이 필요하다. PiTaPa 포스트페이는 출시 필수가 아니다.

## Phase 3 교통패스 프로토타입

- 별도 진입점 `lib/pass_comparison_prototype.dart`로 실행하며 본 앱 내비게이션에는 포함하지 않는다.
- `PassComparisonEvaluator`는 UI나 ODPT에 의존하지 않는 순수 Dart 계산 엔진이다.
- v0.2는 개발 시 ODPT Station·Railway·RailwayFare를 정규화한 정적 JSON만 앱에서 읽으며 액세스 토큰은 앱과 저장소에 넣지 않는다.
- 역 검색은 ODPT 한국어·일본어·영어 표기와 한국어 초성 인덱스를 사용하고, 정확한 동일 사업자 운임 쌍만 자동 입력한다.
- Metro↔도에이 연결 운임, 역 그래프, 환승과 경로 후보는 v0.3 범위다.
- ODPT 연동 후에도 외부 데이터 모델을 앱 도메인 모델로 정규화하여 계산 엔진이 특정 API 응답에 직접 의존하지 않게 한다.

## localhost 문의 관리 도구

- `admin/`은 Android 앱과 분리된 무의존성 정적 웹과 Node localhost 서버다. `127.0.0.1`에만 바인딩되며 외부 호스팅하지 않는다.
- 브라우저는 Supabase 이메일·비밀번호 인증으로 관리자 JWT를 얻고 Publishable key와 함께 `issue-report-admin` Edge Function만 호출한다.
- Edge Function은 localhost Origin, 유효한 사용자 JWT, `ISSUE_REPORT_ADMIN_EMAILS` 허용 목록을 모두 확인한 뒤에만 service role 클라이언트로 제보를 조회한다.
- 상태 변경은 service role 전용 `admin_update_issue_report_review` RPC가 제보 갱신과 `issue_report_review_logs` 감사를 한 트랜잭션으로 처리한다.
- 브라우저 코드와 Git에는 `service_role`, 관리자 비밀번호, DB 비밀번호를 두지 않는다.
