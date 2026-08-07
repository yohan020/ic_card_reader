# Architecture

## 목표와 경계

앱은 일본 전국호환 선불식 교통계 IC 카드의 최근 이력을 읽는다. NFC 통신과 파싱, 역 조회, 저장, UI를 분리하며 기본 데이터 처리는 기기 안에서 끝낸다. 카드 IDm 원문은 FeliCa 명령 수행 중 메모리에서만 사용하고 저장·로그·화면·서버 전송에서 제외한다.

현재 구현 범위는 Phase 1 NFC PoC다. Phase 2 파싱/SQLite/역명 표시와 선택적 신고 전송은 설계만 유지하며, Phase 3 교통패스 비교는 구현하지 않는다.

## 디렉터리 구조

```text
lib/src/
  features/
    card_reader/          NFC 세션, FeliCa 프로토콜, 원시 블록 UI
    transaction_history/ Phase 2 파서·저장·표시 예정
    station_resolver/     Phase 2 SQLite 조회 예정
    issue_report/         신고 계약 및 향후 큐
    pass_comparison/      Phase 3 확장 지점(현재 미구현)
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

## Phase 2 예정 구조

- `TransactionParser`: 16바이트 레코드를 보존하며 날짜, 코드, 잔액을 파싱한다. 확실한 근거가 없는 거래 유형은 `UNKNOWN`이다.
- `AmountState`: 인접 레코드 잔액 차이를 `CALCULATED`, `UNAVAILABLE`, `SUSPICIOUS`로 표현한다. 잔액 증가를 일반 차감으로 표시하지 않는다.
- `StationResolver`: `(region,line,station)` 정확 조회 후 `(line,station)` 단일 후보만 확정한다. 다중 후보는 보존하고 출발/도착 지역 교집합만 보조 근거로 쓴다.
- `LocalStore`: SQLite에 해시된 카드 식별값, 원시 레코드/해시, 파싱 결과, 파서/DB 버전, 마지막 스캔 시각을 저장한다. IDm 원문은 금지한다.
- `IssueReportRepository`: 사용자 동의가 있을 때 한 건만 전송하며 실패 건은 로컬 큐에서 재시도한다.

## CSV -> SQLite 계획

빌드 전 개발 도구가 UTF-8 CSV를 읽어 정수 코드를 정규화하고, Yoiko가 같은 완전 키를 덮어쓰는 기존 우선순위를 적용해 SQLite asset을 생성한다. 테이블은 `station_codes(region_code, line_code, station_code, station_name, line_name, operator_name, source, confidence)`와 완전 키 unique index, `(line_code, station_code)` index를 갖는다. 입력 SHA-256, 변환 스크립트 버전, 행 수를 `station_database_meta`에 기록한다. 수동 보정은 별도 migration으로 재현한다.

Yoiko 데이터의 재배포 조건이 확인되기 전에는 앱 asset 또는 공개 저장소에 포함하지 않는다.

## 주요 위험

- iOS는 실기기·유료 Apple Developer 서명·NFC Tag Reading capability·entitlements·Info.plist 시스템 코드가 모두 필요하다. Simulator에서는 검증할 수 없다.
- Android 기기마다 NFC-F 지원과 태그 이탈 동작이 다를 수 있다. NFC feature는 optional이므로 런타임 확인이 필수다.
- 참고 `Info.plist`에는 리터럴 `` `r`n `` 문자열이 섞여 있어 그대로 재사용할 수 없다.
- 참고 리더의 IDm 로그와 미확인 거래 기본 철도 분류는 채택하지 않았다. 원시 블록은 fixture 확보를 위해 debug 빌드에서만 시작/종료 marker와 함께 출력하며 release에서는 출력하지 않는다.
- 시스템/서비스 코드와 바이트 해석은 실물 카드 검증이 필요하다. PiTaPa 포스트페이는 출시 필수가 아니다.
