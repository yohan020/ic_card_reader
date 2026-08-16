# IC 카드 데이터 읽기·파싱·변환·가공 전체 정리

## 0. 문서 기준

이 문서는 현재 프론트엔드 작업 트리의 실제 구현을 기준으로, 실물 Suica/PASMO 계열 IC 카드에서 읽은 정보가 최종 교통비 레코드로 저장될 때까지 거치는 모든 확인 가능한 단계를 정리한다. 외부 FeliCa 사양으로 빈칸을 추정하지 않고, 프로젝트 코드가 실제로 하는 일만 기록한다.

핵심 소스:

| 역할 | 파일 |
|---|---|
| NFC/FeliCa 읽기 및 원시 레코드 파싱 | `lib/src/features/expenses/domain/transit_ic_nfc_reader.dart` |
| 파싱 결과 공유 모델 | `lib/src/features/expenses/domain/transit_ic_parser.dart` |
| 역 코드/역명 조회 모델 | `lib/src/features/expenses/domain/transit_station_resolver.dart` |
| NFC 호출, 필터, 중복 검사, 화면 표시, 저장 | `lib/src/features/expenses/presentation/transit_ic_import_screen.dart` |
| 역명 조회 provider | `lib/src/features/sync/presentation/sync_providers.dart` |
| 역명 조회 HTTP 요청 | `lib/src/features/sync/data/kakeibo_api_client.dart` |
| 역명 조회 응답 변환 | `lib/src/features/sync/data/sync_dtos.dart` |
| 저장 controller | `lib/src/features/trips/domain/trip_state.dart` |
| 저장용 seed와 DB 변환 | `lib/src/features/expenses/domain/expense_repository.dart` |
| 최종 도메인 모델 | `lib/src/features/expenses/domain/expense.dart` |
| Drift 테이블 | `lib/src/data/local/drift_schema.dart` |
| 거래 유형 enum | `lib/src/core/domain_enums.dart` |
| Android NFC 설정 | `android/app/src/main/AndroidManifest.xml` |
| iOS NFC 설정 | `ios/Runner/Info.plist` |
| 라이브러리 버전 | `pubspec.yaml`, `pubspec.lock` |

## 1. 한눈에 보는 전체 데이터 흐름

```text
사용자가 NFC_FELICA 방식 선택
  → _readNfcCard()
  → TransitIcNfcReader.readRecentHistory(DateTime.now(), stationResolver)
  → NFC 사용 가능 여부 확인
  → ISO 18092 세션 시작
  → Android NfcFAndroid 또는 iOS FeliCaIos 태그 판별
  → IDm 취득
  → 최대 20개 이용내역 블록 Read Without Encryption
  → 각 블록을 _SuicaHistoryBlock으로 파싱
  → 인접 레코드 잔액 차이로 fare 계산
  → rail / bus / icPayment 분류
  → 조건에 맞지 않는 후보 제외
  → ParsedTransitItemDraft 생성
  → 철도 역 코드 서버 조회 및 역명/후보 적용
  → 날짜 범위 필터
  → exact/fuzzy/기존 저장 내역 중복 판정
  → IC 물품 결제는 표시 전용(scanOnly), 철도/버스는 저장 후보
  → 날짜 오름차순 정렬 및 화면 표시
  → 사용자 역명 확인/삭제/중복 저장 확인
  → TransportController.addTransportExpense()
  → TransportSeed
  → TransportExpense(type은 항상 rail로 생성됨)
  → Drift transport_expenses 테이블 저장
```

읽기 결과가 각 단계에서 어떻게 바뀌는지는 다음과 같다.

| 단계 | 데이터 형태 | 남는 정보 | 사라지거나 아직 없는 정보 |
|---|---|---|---|
| 태그 감지 | `NfcTag` | 플랫폼 태그 객체 | 없음 |
| 플랫폼 읽기 | `_RawFelicaHistory` | 전체 IDm 문자열, 원시 블록 목록 | 시스템 응답 상세 오류는 보존 안 함 |
| 블록 파싱 | `_SuicaHistoryBlock` | raw, 단말/처리 코드, 날짜, 지역/노선/역 코드, 잔액 | 바이트 2~3, 12~14 의미, 거래 순번 |
| 거래 후보 | `ParsedTransitItemDraft` | 날짜, 출발/도착, 운영사, 차액, 유형, rawText, sourceKey | 원시 모델은 private |
| 화면 행 | `_TransitImportRow` | 후보 + 선택/중복/검토/삭제 상태와 역명 후보 | 영구 저장 전용 ID 없음 |
| 저장 controller | `TransportSeed` | 날짜, 승하차명, 운영사, 운임, sourceType | IDm, 원시 블록, 잔액, sourceKey, NFC 유형 |
| DB | `TransportExpenses` | UUID, tripId, 날짜, 승하차명, 운영사, 운임, type, sourceType 등 | IDm, rawText, balance, 원시 코드, 거래 순번 |

## 2. NFC 모드 진입과 호출

NFC 방식의 parser code는 다음 상수다.

```dart
const transitIcParserNfc = 'NFC_FELICA';
```

화면은 `_parserCode == transitIcParserNfc`이면 NFC 모드로 간주한다. NFC 읽기를 시작하면 기존 이미지/OCR 상태, 이전 NFC 결과, 행, 중복 표시 상태와 카운터를 모두 초기화한다.

실제 호출 코드는 다음과 같다.

```dart
final result = await _nfcReader.readRecentHistory(
  fallbackDate: DateTime.now(),
  stationResolver: ref.read(transitStationResolverProvider),
);
_logTransitNfcItems(result.items);

_nfcItems = result.items;
_nfcCardId = result.cardId;
_nfcRawBlockCount = result.rawBlockCount;
_rows = _buildRowsFromParsedItems(result.items);
```

따라서 NFC 파싱의 기준 연도는 스캔 당시의 현재 연도이고, 역명 조회기는 backend base URL이 설정된 경우에만 제공된다.

## 3. NFC 라이브러리와 플랫폼 설정

### 3.1 라이브러리

- 패키지: `nfc_manager`
- `pubspec.yaml`: `nfc_manager: 4.0.2`
- `pubspec.lock`: direct main dependency, version `4.0.2`
- 사용 모듈:
  - `package:nfc_manager/nfc_manager.dart`
  - `package:nfc_manager/nfc_manager_android.dart`
  - `package:nfc_manager/nfc_manager_ios.dart`

### 3.2 Android

```xml
<uses-feature
    android:name="android.hardware.nfc"
    android:required="false" />
<uses-permission android:name="android.permission.NFC" />
```

- NFC 하드웨어는 선택 사항이다. NFC가 없는 기기에도 앱 설치가 가능하다.
- NFC permission이 선언되어 있다.
- 별도 NFC intent filter, foreground dispatch, tech list XML은 발견되지 않았다.
- Android 전용 네이티브 NFC 구현은 없고 Flutter 패키지의 `NfcFAndroid`를 사용한다.

### 3.3 iOS

현재 `Info.plist`에서 확인되는 내용:

```xml
<key>NFCReaderUsageDescription</key>`r`n`t<string>Read IC card transit history with NFC.</string>
<key>com.apple.developer.nfc.readersession.felica.systemcodes</key>
<array>
    <string>0003</string>
</array>`r`n</dict>
```

주의할 점:

- `NFCReaderUsageDescription`과 시스템 코드 `0003`은 존재한다.
- 현재 파일에는 줄바꿈이 아니라 문자 그대로의 `` `r`n `` 및 `` `t ``가 들어가 있다. 이 plist의 실제 유효성은 불확실하다.
- `.entitlements` 파일과 `CODE_SIGN_ENTITLEMENTS` 설정은 프로젝트에서 발견되지 않았다.
- 이 문서는 상태만 기록하며 설정을 수정하지 않는다.

## 4. 세션 시작과 태그 판별

먼저 `NfcManager.instance.isAvailable()`을 호출한다. false이면 `TransitIcNfcException`으로 NFC를 사용할 수 없다는 메시지를 던진다.

세션은 다음 옵션으로 시작한다.

```dart
await NfcManager.instance.startSession(
  pollingOptions: {NfcPollingOption.iso18092},
  alertMessageIos: 'Suica/PASMO 카드를 기기 상단에 가까이 대 주세요.',
  onDiscovered: (tag) async { ... },
);
```

- ISO/IEC 18092, 즉 NFC-F/FeliCa 계열 polling만 요청한다.
- 발견된 태그를 먼저 `NfcFAndroid.from(tag)`로 변환한다.
- Android 태그가 아니면 `FeliCaIos.from(tag)`를 시도한다.
- 둘 다 null이면 비-FeliCa 카드 오류로 종료한다.
- 전체 작업은 `Completer`로 한 번만 완료되도록 `completed` flag를 둔다.
- 성공과 실패 모두 `stopSession()`을 호출한다.
- 전체 대기 timeout은 30초다.

## 5. 시스템 코드, 서비스 코드, Polling

소스 상수:

```dart
static final Uint8List _commonTransitSystemCode =
    Uint8List.fromList([0x00, 0x03]);
static final Uint8List _historyServiceCode =
    Uint8List.fromList([0x0f, 0x09]);
```

| 항목 | 실제 바이트/값 | 사용 방식 |
|---|---|---|
| 교통계 시스템 코드 | `[0x00, 0x03]` | iOS `polling(systemCode:)`; plist 문자열 `0003` |
| 이용내역 서비스 코드 | `[0x0F, 0x09]` | Android 직접 명령과 iOS `serviceCodeList`에 그대로 전달 |
| iOS request code | `FeliCaPollingRequestCodeIos.systemCode` | Polling 응답에 시스템 코드 요청 |
| iOS time slot | `FeliCaPollingTimeSlotIos.max1` | 최대 1 slot |
| 세션 option | `NfcPollingOption.iso18092` | 공통 세션 태그 기술 제한 |

별도 서비스 코드 정수 상수나 명칭 코드표는 없다. 따라서 `[0x0F, 0x09]` 외의 표기 방식은 이 프로젝트만으로 확정하지 않는다.

## 6. Android에서 이용내역 읽기

### 6.1 IDm

Android에서는 다음 값이 IDm이 된다.

```dart
final idm = tag.tag.id;
```

읽기가 끝나면 `_hex(idm)`으로 각 바이트를 2자리 대문자 16진 문자열로 이어 붙여 `cardId`로 만든다. 구분자는 없다.

### 6.2 최대 20블록 순차 읽기

```dart
for (var blockIndex = 0; blockIndex < 20; blockIndex++) {
  final response = await tag.transceive(
    _buildReadWithoutEncryptionCommand(idm, blockIndex),
  );
  final block = _parseAndroidReadResponse(response);
  if (block == null || _isEmptyBlock(block)) break;
  blocks.add(block);
}
```

- 인덱스 0부터 19까지 한 블록씩 요청한다.
- 첫 null 응답 또는 전부 0인 블록에서 즉시 중단한다.
- 중간 실패 후 뒤쪽 블록을 계속 읽지 않는다.

### 6.3 Read Without Encryption 명령 조립

```dart
final command = <int>[
  0x00,              // 이후 전체 길이로 교체
  0x06,              // Read Without Encryption command code
  ...idm,            // IDm
  0x01,              // service count
  ..._historyServiceCode,
  0x01,              // block count
  0x80, blockIndex,  // 2-byte block list element
];
command[0] = command.length;
```

명령 순서:

| 위치 | 내용 |
|---:|---|
| 0 | 전체 명령 길이 |
| 1 | `0x06` |
| 2.. | IDm 전체 바이트 |
| 다음 | 서비스 수 `0x01` |
| 다음 2바이트 | `[0x0F, 0x09]` |
| 다음 | 블록 수 `0x01` |
| 마지막 2바이트 | `[0x80, blockIndex]` |

### 6.4 Android 응답 검증 및 블록 추출

```dart
if (response.length < 13) return null;
if (response[1] != 0x07) return null;
final statusFlag1 = response[10];
final statusFlag2 = response[11];
if (statusFlag1 != 0 || statusFlag2 != 0) return null;
final blockCount = response[12];
if (blockCount < 1 || response.length < 29) return null;
return Uint8List.fromList(response.sublist(13, 29));
```

- 응답 최소 길이 13 확인
- 응답 코드 `0x07` 확인
- status flag 1/2가 모두 0인지 확인
- 블록 수가 1 이상이고 전체 길이가 최소 29인지 확인
- 응답 바이트 13부터 28까지 정확히 16바이트만 복사
- 실패 이유별 상세 오류 코드는 보존하지 않고 null로 합쳐진다.

## 7. iOS에서 이용내역 읽기

### 7.1 명시적 Polling

```dart
await tag.polling(
  systemCode: _commonTransitSystemCode,
  requestCode: FeliCaPollingRequestCodeIos.systemCode,
  timeSlot: FeliCaPollingTimeSlotIos.max1,
);
```

### 7.2 최대 20블록 순차 읽기

```dart
for (var blockIndex = 0; blockIndex < 20; blockIndex++) {
  final response = await tag.readWithoutEncryption(
    serviceCodeList: [_historyServiceCode],
    blockList: [Uint8List.fromList([0x80, blockIndex])],
  );
  if (response.statusFlag1 != 0 || response.statusFlag2 != 0) break;
  if (response.blockData.isEmpty) break;
  final block = response.blockData.first;
  if (block.length < 16 || _isEmptyBlock(block)) break;
  blocks.add(Uint8List.fromList(block));
}
```

- Android와 동일하게 인덱스 0~19를 한 블록씩 읽는다.
- status flag가 하나라도 0이 아니면 중단한다.
- block data가 비어 있거나 첫 블록 길이가 16 미만이면 중단한다.
- 전부 0인 블록에서도 중단한다.
- 응답에 블록이 여러 개 있어도 `first`만 사용한다.
- 16바이트보다 길면 Android와 달리 잘라내지 않고 전체 블록을 복사하지만, 파서는 앞의 필요한 오프셋만 읽는다.
- IDm은 Polling 이후 `tag.currentIDm`을 구분자 없는 대문자 16진 문자열로 변환한다.

## 8. 원시 읽기 결과 모델

```dart
class _RawFelicaHistory {
  final String cardId;
  final List<Uint8List> blocks;
}
```

- private 모델이다.
- `cardId`: 전체 IDm을 대문자 hex로 직렬화한 문자열
- `blocks`: 성공적으로 읽은 원시 블록 목록
- 블록이 2개 미만이면 잔액 차액을 만들 수 없으므로 전체 스캔을 실패 처리한다.

공개 반환 모델은 다음과 같다.

```dart
class TransitIcNfcReadResult {
  final String cardId;
  final int rawBlockCount;
  final List<ParsedTransitItemDraft> items;
}
```

`rawBlockCount`는 파싱 성공 건수가 아니라 읽기에 성공해 `blocks`에 추가된 원시 블록 수다.

## 9. 16바이트 이용내역 블록 구조

파서는 `block.length < 16`이면 null을 반환한다. 코드가 사용하는 바이트는 다음과 같다.

| 오프셋 | 길이 | 코드상 의미 | 변환 |
|---:|---:|---|---|
| 0 | 1 | `terminalCode` | unsigned byte 정수 |
| 1 | 1 | `processCode` | unsigned byte 정수 |
| 2..3 | 2 | 해석하지 않음 | `NOT_FOUND` |
| 4..5 | 2 | 날짜 비트 필드 | 연/월/일로 분해 |
| 6 | 1 | 승차 노선 코드 | `boardingLineCode` |
| 7 | 1 | 승차 역 코드 | `boardingStationCode` |
| 8 | 1 | 하차 노선 코드 | `alightingLineCode` |
| 9 | 1 | 하차 역 코드 | `alightingStationCode` |
| 10..11 | 2 | 이용 후 잔액 | little-endian 정수 |
| 12..14 | 3 | 해석하지 않음 | `NOT_FOUND` |
| 15 | 1 | 지역 코드 | 승차/하차에 동일 값 재사용 |

원시 레코드 모델:

```dart
class _SuicaHistoryBlock {
  final Uint8List raw;
  final int terminalCode;
  final int processCode;
  final DateTime date;
  final int regionCode;
  final int boardingLineCode;
  final int boardingStationCode;
  final int alightingLineCode;
  final int alightingStationCode;
  final int balance;
}
```

거래 순번, 장치 지역, 입출 개찰 상태, 충전 구분 등 추가 필드는 구현에서 해석하지 않는다.

## 10. 날짜 파싱

실제 계산식:

```dart
final year = 2000 + (block[4] >> 1);
final month = ((block[4] & 0x01) << 3) + (block[5] >> 5);
final day = block[5] & 0x1f;
if (month < 1 || month > 12 || day < 1 || day > 31) return null;
final parsedYear = year < 2000 || year > fallbackYear + 1
    ? fallbackYear
    : year;
```

- 연도: byte 4의 상위 7비트 + 2000
- 월: byte 4의 최하위 1비트와 byte 5의 상위 3비트 조합
- 일: byte 5의 하위 5비트
- 월/일의 단순 범위만 검사한다.
- 실제 달력 유효성(예: 2월 31일)을 별도로 검사하지 않는다. Dart `DateTime`이 넘치는 날짜를 다음 달로 정규화할 수 있다.
- 계산 연도가 `fallbackYear + 1`보다 크면 fallback year로 교체한다.
- 현재 호출에서는 `fallbackYear == DateTime.now().year`이다.
- `year < 2000` 조건은 현재 계산식상 사실상 발생하지 않는다.

중요: 잘못된 날짜 블록은 `histories` 목록에서 제거된다. 그 뒤 남은 파싱 성공 레코드끼리 인접 잔액 차이를 계산하므로, 중간 블록 하나가 날짜 오류로 빠지면 원래 서로 이웃하지 않던 두 레코드가 짝지어질 수 있다.

## 11. 잔액 파싱과 금액 계산

잔액은 다음 little-endian 계산을 사용한다.

```dart
balance = block[10] + (block[11] << 8);
```

거래 금액은 레코드 내부 금액 필드가 아니라 연속한 두 잔액의 차이다.

```dart
final current = histories[index];
final previous = histories[index + 1];
final fare = previous.balance - current.balance;
```

구현 전제:

- `histories[0]`이 최신이고 뒤로 갈수록 과거 레코드라고 가정한다.
- 현재 거래 후 잔액을 `current.balance`, 그 직전 과거 잔액을 `previous.balance`로 본다.
- 차감액은 `과거 잔액 - 현재 잔액`이다.
- `fare <= 0`이면 `non_positive_fare`로 제외한다.
- 마지막 레코드는 비교할 더 오래된 잔액이 없으므로 거래 후보가 되지 않는다.
- 원시 블록 N개에서 최대 N-1개의 후보만 생성된다.
- 충전처럼 잔액이 증가한 거래는 차이가 음수/0이 되어 제외된다.
- 충전액, 환불액, 조정액 계산은 구현되어 있지 않다.
- 잔액과 금액은 정수로 취급하며 통화 단위를 별도 필드로 보존하지 않는다. 화면에서는 엔화 포맷을 적용한다.

## 12. 노선 코드 존재 여부

```dart
bool get hasRouteCodes {
  final boarding = boardingLineCode != 0 || boardingStationCode != 0;
  final alighting = alightingLineCode != 0 || alightingStationCode != 0;
  return boarding && alighting;
}
```

- 승차 쌍은 노선 또는 역 코드 중 하나만 0이 아니어도 존재한다고 본다.
- 하차 쌍도 동일하다.
- 최종적으로 승차와 하차 쌍이 둘 다 있어야 `hasRouteCodes == true`다.
- 버스는 이 조건을 면제받는다.

## 13. 거래 유형 판별

전체 enum:

```dart
enum TransportUsageType {
  rail,
  bus,
  icPayment,
  charge,
  refund,
  adjustment,
  other,
}
```

하지만 NFC 경로가 실제로 생성하는 값은 `rail`, `bus`, `icPayment` 세 가지뿐이다.

```dart
if (block.terminalCode == 0xc8 && block.processCode == 0x46) {
  return TransportUsageType.icPayment;
}
if (block.terminalCode == 0x05 ||
    block.terminalCode == 0x0d ||
    block.processCode == 0x0f) {
  return TransportUsageType.bus;
}
return TransportUsageType.rail;
```

| 결과 | 조건 |
|---|---|
| `icPayment` | terminal `0xC8` AND process `0x46` |
| `bus` | terminal `0x05` OR terminal `0x0D` OR process `0x0F` |
| `rail` | 위 조건에 해당하지 않는 모든 레코드 |
| `charge` | 생성 규칙 없음 |
| `refund` | 생성 규칙 없음 |
| `adjustment` | 생성 규칙 없음 |
| `other` | 생성 규칙 없음 |

알 수 없는 terminal/process 조합도 `other`가 아니라 기본적으로 `rail`이 된다.

전체 terminal/process 코드표는 프로젝트에 없다. 위 네 코드 외의 의미는 `NOT_FOUND`다.

## 14. 거래 후보 제외 규칙

```dart
if (fare <= 0) return 'non_positive_fare';
if (type == TransportUsageType.bus) return null;
if (!block.hasRouteCodes) return 'missing_route_codes';
return null;
```

정리:

1. 모든 유형에서 fare가 0 이하이면 제외한다.
2. 버스는 fare가 양수이면 승하차 코드가 없어도 유지한다.
3. 철도는 승차/하차 코드 쌍이 모두 있어야 한다.
4. `icPayment`도 버스가 아니므로 `hasRouteCodes`가 필요하다.

마지막 조건은 주의가 필요하다. 화면에는 IC 물품 결제를 확인용으로 표시하는 기능이 있지만, 실제 물품 구매 블록의 노선 코드가 비어 있다면 파싱 단계에서 먼저 제거된다. 프로젝트에는 이 조건을 검증하는 NFC 원시 테스트가 없다.

## 15. 파싱된 거래 모델로 변환

공유 모델:

```dart
class ParsedTransitItemDraft {
  final DateTime date;
  final String departureStation;
  final String arrivalStation;
  final String? transportOperator;
  final int fare;
  final TransportUsageType type;
  final String rawText;
  final String sourceKey;
  final String? imagePath;
}
```

NFC 변환 규칙:

| 필드 | 값 |
|---|---|
| `date` | 파싱된 날짜 |
| `departureStation` | 철도: `승차 LL-SS`; 버스: `버스`; IC 결제: `IC 지불` |
| `arrivalStation` | 철도: `하차 LL-SS`; 버스/IC 결제: 빈 문자열 |
| `transportOperator` | 항상 `IC NFC` |
| `fare` | 이전 잔액 - 현재 잔액 |
| `type` | rail/bus/icPayment 판별 결과 |
| `rawText` | IDm, 코드, 잔액, 전체 raw block을 담은 줄 단위 문자열 |
| `sourceKey` | 날짜/출발/도착/잔액/운임 조합 |
| `imagePath` | NFC에서는 지정하지 않아 null |

철도 코드 라벨은 노선/역 코드를 2자리 대문자 hex로 바꾼다.

```dart
String _stationCodeLabel(String prefix, int lineCode, int stationCode) {
  return '$prefix ${_hexByte(lineCode)}-${_hexByte(stationCode)}';
}
```

## 16. rawText의 전체 구조

각 거래 후보는 다음 줄을 가진다.

```text
card=<전체 IDm 대문자 hex>
terminal=<2자리 대문자 hex>
process=<2자리 대문자 hex>
balance=<현재 잔액 10진수>
previousBalance=<이전 잔액 10진수>
regionCode=<지역 코드 10진수>
boardingRegionCode=<지역 코드 10진수>
boardingLineCode=<승차 노선 코드 10진수>
boardingStationCode=<승차 역 코드 10진수>
alightingRegionCode=<지역 코드 10진수>
alightingLineCode=<하차 노선 코드 10진수>
alightingStationCode=<하차 역 코드 10진수>
block=<원시 블록 전체 대문자 hex>
```

역명 조회가 unresolved 후보를 반환하면 다음 줄이 추가될 수 있다.

```text
boardingStationCandidates=<후보1>|<후보2>|...
alightingStationCandidates=<후보1>|<후보2>|...
```

특성:

- terminal/process/raw block은 hex 문자열이다.
- balance와 지역/노선/역 코드는 10진수 문자열이다.
- 전체 IDm이 마스킹 없이 들어간다.
- `rawText`는 디버깅과 역명 후보 전달에 쓰이는 비정형 내부 문자열이다.
- 최종 DB에는 저장되지 않는다.

## 17. sourceKey 생성

```dart
String _nfcSourceKey(
  DateTime date,
  String departure,
  String arrival,
  int fare, {
  int? balance,
}) {
  final balanceKey = balance == null ? '' : balance.toString();
  return '${date.year}-${date.month}-${date.day}|'
      '$departure|$arrival|$balanceKey|$fare';
}
```

예시 형식:

```text
2026-8-9|승차 01-02|하차 03-04|1234|210
```

- 월/일 leading zero는 유지하지 않는다.
- 카드 IDm, terminal, process, 원시 블록, 거래 순번은 포함하지 않는다.
- 역명 조회 후 `departureStation`/`arrivalStation`을 `copyWith`로 바꿔도 `sourceKey`는 원래 코드 라벨 기준 값을 유지한다.
- 화면은 `sourceKey`를 분리해 네 번째 요소, 즉 balance만 다시 꺼낸다.

## 18. 역 코드 추출과 표현 형식

원시 `rawText`를 줄 단위 `key=value`로 파싱하고 `int.tryParse()`를 사용한다.

```dart
final regionCode = values['${prefix}RegionCode'] ?? values['regionCode'];
final lineCode = values['${prefix}LineCode'];
final stationCode = values['${prefix}StationCode'];
return TransitStationCode(
  regionCode: regionCode,
  lineCode: lineCode,
  stationCode: stationCode,
);
```

따라서 rawText 내부 값은 10진수 정수 문자열이어야 한다. `0x` prefix나 hex 문자열은 이 경로에서 읽히지 않는다.

`TransitStationCode`의 실제 타입과 JSON:

```dart
final int regionCode;
final int lineCode;
final int stationCode;

String get key =>
    '${_hexByte(regionCode)}-${_hexByte(lineCode)}-${_hexByte(stationCode)}';

Map<String, Object?> toJson() => {
  'regionCode': regionCode,
  'lineCode': lineCode,
  'stationCode': stationCode,
  'regionCodeHex': _hexByte(regionCode),
  'lineCodeHex': _hexByte(lineCode),
  'stationCodeHex': _hexByte(stationCode),
};
```

| 값 | Dart/JSON 기본 표현 | hex 보조 표현 | leading zero |
|---|---|---|---|
| `regionCode` | `int`, JSON number | `regionCodeHex`, 2자리 대문자 문자열 | hex에서 유지 |
| `lineCode` | `int`, JSON number | `lineCodeHex`, 2자리 대문자 문자열 | hex에서 유지 |
| `stationCode` | `int`, JSON number | `stationCodeHex`, 2자리 대문자 문자열 | hex에서 유지 |

조회 map key는 `RR-LL-SS` 형태다. 예를 들어 값이 각각 0, 10, 3이라면 `00-0A-03`이 된다.

현재 구현은 byte 15 하나를 승차/하차 `regionCode` 양쪽에 동일하게 사용한다. 승차와 하차 지역을 별도로 추출하지 않는다.

## 19. 역명 조회 요청

역명 조회는 철도 항목에만 적용한다.

```dart
bool _shouldResolveStationNames(TransportUsageType type) {
  return type == TransportUsageType.rail;
}
```

절차:

1. 각 철도 item의 rawText에서 승차/하차 `TransitStationCode`를 복원한다.
2. `code.key` 기준으로 중복 코드를 제거한다.
3. resolver가 null이거나 코드가 없으면 원래 item을 유지한다.
4. API 호출 실패도 잡아서 원래 item을 유지한다.

resolver는 `KAKEIBO_API_BASE_URL`이 비어 있으면 null이다.

API client는 `X-App-Version: 1.0.0`, `Accept-Encoding: gzip` 헤더를 사용한다. 현재 provider가 client의 `platform` 인자에 실제 실행 플랫폼을 판별하지 않고 항상 `android`를 전달하므로, iOS에서 역명을 조회하더라도 `X-Platform: android`가 전송된다.

HTTP 요청:

```dart
await _dio.post<Map<String, Object?>>(
  '/api/v1/transit/stations/resolve',
  data: {
    'stations': [for (final code in uniqueCodes) code.toJson()],
  },
);
```

요청 형태:

```json
{
  "stations": [
    {
      "regionCode": 0,
      "lineCode": 10,
      "stationCode": 3,
      "regionCodeHex": "00",
      "lineCodeHex": "0A",
      "stationCodeHex": "03"
    }
  ]
}
```

## 20. 역명 조회 응답 가공

응답은 `data.stations` 또는 `data.resolvedStations` 배열을 허용한다. 각 항목은 `ResolvedTransitStation.fromJson()`으로 바뀐다.

주요 필드:

- 원 요청 코드: region/line/station, decimal 또는 `*Hex` fallback
- `stationName` 또는 `name`
- `resolved`
- `matchStrategy`
- `lineName`
- `operatorName`
- `source`
- `confidence`
- `matchedRegionCode`, `matchedRegionCodeHex`
- `candidates`

응답 코드 파싱 우선순위:

1. decimal/int 필드 `_readInt()`
2. 없으면 `*Hex` 문자열을 radix 16으로 파싱
3. 둘 다 없으면 0

`_readInt()`는 int, num, 10진 문자열을 허용한다. 문자열 hex는 별도 `*Hex` 필드에서만 처리한다.

station name이 비어 있고 후보도 비어 있는 응답 항목은 버린다. 나머지는 `station.code.key`로 map에 저장한다.

적용 규칙:

- `resolved == true`이고 station name이 비어 있지 않으면 기존 `승차 LL-SS`/`하차 LL-SS`를 trim한 역명으로 교체한다.
- 응답이 없거나 resolved가 아니면 기존 코드 라벨을 유지한다.
- resolved가 아니면서 candidates가 있으면 후보 이름을 중복 제거하여 rawText의 candidate 줄로 넣는다.
- resolved된 경우 candidates가 있어도 candidate 줄을 추가하지 않는다.
- resolver가 반환한 `lineName`과 `operatorName`은 NFC item의 화면명이나 `transportOperator`에 적용하지 않는다. 운영사는 계속 `IC NFC`다.

## 21. 화면용 행 생성과 날짜 필터

`ParsedTransitItemDraft`는 `_TransitImportRow`로 감싼다.

행에 추가되는 상태:

- `selected`
- `duplicate`
- `note`
- `fuzzyDuplicate`
- `needsStationReview`
- `stationReviewResolved`
- `removed`
- 출발/도착 역명 후보 목록

날짜 범위 모드:

| 모드 | 범위 |
|---|---|
| `trip` | 여행 시작일~종료일 |
| `today` | 오늘 하루 |
| `custom` | 사용자가 고른 범위. 없으면 여행 범위 |

- 비교 시 시간은 버리고 `DateTime(year, month, day)`만 사용한다.
- 시작일과 종료일 모두 포함한다.
- 범위 밖 item은 행으로 만들지 않고 `_lastFilteredOutCount`만 증가한다.
- 가져온 입력이 있으면 화면상 날짜 범위 선택기가 잠긴다.
- 최종 행은 날짜 오름차순으로 정렬한다. 같은 날짜는 원래 행 순서를 유지한다.

## 22. IC 물품 결제의 scanOnly 처리

```dart
bool _isScanOnlyItem(ParsedTransitItemDraft item) {
  return item.type == TransportUsageType.icPayment;
}
```

- `icPayment`는 `selected: false`로 생성된다.
- 확인용 별도 목록으로 보인다.
- 안내 문구는 “지불 내역은 확인용으로만 표시하고 저장하지 않아요.”이다.
- 저장 대상 필터에서도 `!row.scanOnly`를 요구하므로 저장되지 않는다.
- 철도와 버스는 기본적으로 `selected: true`다.
- 중복인 철도/버스도 처음에는 선택된 상태다. 자동 삭제가 아니라 별도 중복 목록/확인 절차를 거친다.

## 23. 역명 후보와 사용자 확인

rawText의 candidate 줄을 `|`로 분리하고 현재 표시 이름을 fallback 후보로 합친다. `_normalizeStation()` 기준으로 중복 제거한다.

```dart
String _normalizeStation(String value) {
  return value
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('駅', '')
      .trim();
}
```

후보가 출발 또는 도착 중 한쪽이라도 2개 이상이면 `needsReview == true`다. 정확히는 후보 수가 `> 1`일 때다.

사용자는 다음을 할 수 있다.

- 후보 중 하나 선택
- 직접 역명 입력
- 출발역/도착역 모름 선택
- 확인 후 행을 selected 상태로 전환

확인 결과는 item의 `departureStation`/`arrivalStation`만 `copyWith`로 바꾼다. `sourceKey`와 rawText의 원본 코드/후보는 갱신되지 않는다. 확인 후 중복 여부를 다시 계산한다.

## 24. 정확 중복 판정

화면용 exact key:

```dart
final date = _dateOnly(item.date);
final departure = _normalizeStation(item.departureStation);
final arrival = _normalizeStation(item.arrivalStation);
final balance = _balanceKey(item);
return '${date.year}-${date.month}-${date.day}|'
    '$departure|$arrival|$balance|${item.fare}|${item.type.index}';
```

구성 요소:

- 날짜
- 공백과 `駅`을 제거한 출발역
- 공백과 `駅`을 제거한 도착역
- `sourceKey.split('|')[3]`으로 꺼낸 잔액
- 운임
- enum index

같은 import 안에서 이미 본 key이면 exact duplicate다.

주의:

- IDm은 key에 포함되지 않는다.
- 서로 다른 카드의 동일 날짜/구간/잔액/운임/유형도 중복으로 판정될 수 있다.
- 거래 순번이 없으므로 동일 조건의 실제 별도 거래를 구분하지 못한다.
- enum name이 아니라 index를 사용하므로 enum 순서 변경 시 key 의미가 달라질 수 있다.

## 25. 유사 중복 판정

exact duplicate가 아닐 때 기존 행을 순회한다. 이미 duplicate이거나 removed인 행은 비교 대상에서 제외한다.

필수 조건:

1. 날짜 동일
2. 운임 동일
3. 두 항목 모두 balance key가 비어 있지 않음
4. balance 동일
5. 출발역 이름이 유사
6. 도착역 이름이 유사
7. 출발/도착이 둘 다 정확히 같은 것은 아님

역명 유사도:

- 공백과 `駅` 제거 후 완전히 같으면 true
- 둘 중 하나가 2글자 미만이면 false
- 길이 차이가 2 이하이고 긴 문자열이 짧은 문자열을 포함하면 true
- 길이 차이가 1보다 크고 포함 관계가 아니면 false
- 그 외 Levenshtein 편집 거리를 계산
- 긴 이름 길이가 4 이하이면 허용 거리 1, 그보다 길면 2
- 계산 중 한 행의 최소 비용이 maxDistance보다 커지면 조기 종료

유사 중복이 발견되면 앞 행에 양쪽 역명 후보를 합치고 역명 검토 대상으로 만들 수 있다.

## 26. 기존 DB 내역과 중복 판정

기존 `TransportExpense`와 비교하는 조건:

```dart
final sameDate = transport.date.year == item.date.year &&
    transport.date.month == item.date.month &&
    transport.date.day == item.date.day;
if (!sameDate || transport.fare != item.fare) return false;

// 공백과 駅 제거 후 비교
if (arrival.isEmpty) {
  return departure == itemDeparture || departure == itemArrival;
}
return departure == itemDeparture && arrival == itemArrival;
```

- 날짜와 운임이 우선 일치해야 한다.
- 저장된 도착지가 있으면 출발/도착 모두 같은지 본다.
- 저장된 도착지가 비어 있으면 저장된 출발지가 새 item의 출발 또는 도착 중 하나와 같아도 중복이다.
- 잔액, 카드 ID, 거래 유형, 운영사, sourceType은 기존 DB 중복 비교에 사용하지 않는다.

## 27. 중복 상태 재계산과 사용자 처리

- 행 삭제 시 `selected=false`, `removed=true`로 바꾸고 전체 중복을 다시 계산한다.
- 역명 확인 후에도 전체 중복을 다시 계산한다.
- removed 행은 중복이 아닌 것으로 다시 표시하고 note를 지운다.
- 중복 행은 자동 제거되지 않는다.
- 선택된 중복 행이 있으면 저장 직전에 별도 확인 dialog를 띄운다.
- 사용자가 동의하면 중복 의심 항목도 저장된다.

화면 메시지상 “중복 의심 건은 저장 후보에서 제외”라는 표현이 있지만, 실제 row는 `selected: !scanOnly`로 생성되어 중복 철도/버스도 선택 상태일 수 있고 저장 시 확인 dialog로 통과할 수 있다. 실제 동작 판단에는 selection과 저장 필터가 우선한다.

## 28. 화면 표시 형식

카드 요약:

- 전체 IDm은 화면에 표시하지 않는다.
- `cardId` 길이가 4 이상이면 마지막 4글자만 표시한다.
- 표시: `카드 ID 끝 XXXX · 읽은 원본 블록 N건`
- cardId가 없거나 너무 짧으면 원본 블록 수만 표시한다.

거래 타일:

- 도착역이 없으면 제목은 출발 문자열만 사용한다.
- 있으면 `출발 → 도착`.
- 보조 텍스트: `날짜 · 운영사`.
- 운영사는 NFC item에서 항상 `IC NFC`.
- 금액은 `formatYenSymbol(item.fare)`로 엔화 기호 포맷.
- 중복/유사 중복은 border 색으로 구분.
- 검토/중복/scan-only 안내 note를 표시.
- 사용자가 행을 삭제할 수 있다.

디버그용 NFC item 로그는 날짜, fare, type, 출발/도착, terminal/process, 현재/이전 잔액, 승하차 코드를 출력한다.

## 29. 저장 전 필터

저장 대상:

```dart
final selectedRows = _rows
    .where((row) => row.selected && !row.scanOnly && !row.removed)
    .toList();
```

추가 조건:

- 선택된 행 중 해결되지 않은 역명 검토가 있으면 먼저 사용자 확인 sheet를 강제한다.
- 선택된 중복 행이 있으면 중복 저장 확인 dialog를 띄운다.
- `icPayment`는 scanOnly이므로 저장 대상에서 항상 제외된다.

## 30. 화면 모델에서 저장 controller로 변환

```dart
await controller.addTransportExpense(
  tripId: widget.tripId,
  date: item.date,
  boardingPlace: item.departureStation,
  boardingPlaceKo: item.departureStation,
  alightingPlace: item.arrivalStation,
  alightingPlaceKo: item.arrivalStation,
  transportOperator: item.transportOperator,
  fare: item.fare,
  sourceType: 'ic_card_nfc',
  imagePath: item.imagePath,
);
```

여기서 변환되는 내용:

- 출발역을 원문/한국어 필드 양쪽에 동일하게 넣는다.
- 도착역도 양쪽에 동일하게 넣는다.
- 운영사 `IC NFC`를 전달한다.
- 운임 정수를 전달한다.
- source type은 `ic_card_nfc`.
- NFC item의 imagePath는 null.
- `item.type`, `rawText`, `sourceKey`, `cardId`, rawBlockCount는 전달하지 않는다.

## 31. controller의 정규화

`TransportController.addTransportExpense()`는 다음 정리를 한다.

- `boardingPlace.trim()`이 비면 `교통비`로 대체
- `boardingPlaceKo` trim 후 비면 boardingPlace로 대체
- 도착지/한국어 도착지가 빈 문자열이면 null
- 운영사 trim 후 비면 `교통`으로 대체
- fare가 음수면 0. NFC 파서는 이미 양수만 통과시키므로 정상 NFC 경로에서는 그대로 유지
- `TransportSeed.needsReview`는 전달하지 않아 기본값 false
- 저장 후 전체 교통 내역을 reload

## 32. 저장소와 DB로 변환될 때의 중요 정보 손실

`addTransportSeed()`의 실제 생성 코드:

```dart
final transport = domain.TransportExpense(
  id: _uuid.v4(),
  tripId: seed.tripId,
  date: seed.date,
  boardingPlace: seed.boardingPlace,
  boardingPlaceKo: seed.boardingPlaceKo,
  alightingPlace: seed.alightingPlace,
  alightingPlaceKo: seed.alightingPlaceKo,
  transportOperator: seed.transportOperator,
  fare: seed.fare,
  type: TransportUsageType.rail,
  sourceType: seed.sourceType,
  imagePath: seed.imagePath,
  needsReview: seed.needsReview,
);
```

핵심 결과:

- NFC 파서에서 `bus`였던 항목도 DB 저장 시 `type = rail`이 된다.
- 화면에서는 bus로 처리되지만 저장 후 도메인/DB에서는 rail로 읽힌다.
- `icPayment`는 애초에 저장하지 않는다.
- IDm은 저장되지 않는다.
- 현재/이전 잔액은 저장되지 않는다.
- terminal/process 코드는 저장되지 않는다.
- region/line/station 원시 코드는 저장되지 않는다.
- raw block은 저장되지 않는다.
- sourceKey는 저장되지 않는다.
- 거래 순번은 파싱도 저장도 하지 않는다.
- 새 UUID를 생성하므로 원래 카드 레코드와 직접 대응할 영구 식별자는 없다.

## 33. 최종 TransportExpense와 Drift 스키마

최종 도메인 모델 필드:

```dart
id, tripId, date,
boardingPlace, boardingPlaceKo,
alightingPlace, alightingPlaceKo,
transportOperator, fare, type,
sourceType, imagePath, needsReview
```

Drift `TransportExpenses` 테이블도 같은 의미의 컬럼을 저장한다.

```text
id TEXT PK
tripId TEXT
date DATETIME
boardingPlace TEXT
boardingPlaceKo TEXT?
alightingPlace TEXT?
alightingPlaceKo TEXT?
transportOperator TEXT?
fare INTEGER
type TEXT
sourceType TEXT
imagePath TEXT?
needsReview BOOLEAN
```

- type은 enum의 `.name` 문자열로 저장한다.
- 알 수 없는 DB type 문자열을 읽으면 `rail`로 fallback한다.
- NFC 저장 sourceType은 `ic_card_nfc`다.
- needsReview는 NFC 저장 경로에서 false다.

## 34. IDm과 카드 식별 정보의 생명주기

1. Android `tag.tag.id` 또는 iOS `tag.currentIDm`에서 IDm 취득
2. 대문자 hex 문자열로 `cardId` 생성
3. `_RawFelicaHistory.cardId`
4. 각 item의 `rawText`에 `card=<전체 값>` 삽입
5. `TransitIcNfcReadResult.cardId`로 화면에 반환
6. 화면 state `_nfcCardId`에 보관
7. UI에는 마지막 4글자만 표시
8. 저장 controller에는 전달하지 않음
9. DB에는 저장하지 않음

따라서 한 스캔 세션 동안에는 전체 IDm이 메모리와 rawText에 존재하지만, 현재 영구 교통비 레코드에는 카드 식별값이 남지 않는다.

## 35. 로그와 민감 정보 관점

NFC 리더는 `debugPrint`로 다음을 출력한다.

- 읽은 블록 수
- 각 블록 파싱 성공 여부
- 원시 블록 전체 hex
- 날짜, terminal/process, 잔액
- 지역/승하차 코드
- 유지/제외 결정과 제외 사유
- 역명 조회 요청 key, 응답 역명, 누락, 오류 stack

화면은 파싱된 item의 날짜/운임/유형/역/잔액/코드를 추가로 로그한다.

전체 IDm은 rawText에는 들어가지만 현재 `_logTransitNfcItems()`가 `card` 항목을 출력하지는 않는다. 다만 raw block 자체와 카드 관련 데이터의 디버그 출력은 민감도 검토가 필요하다. 로그 호출은 `assert`나 명시적 debug-mode 조건으로 감싸져 있지 않고 `debugPrint`를 직접 호출한다.

## 36. 오류와 중단 처리 전체 목록

| 단계 | 조건 | 결과 |
|---|---|---|
| 시작 | NFC 사용 불가 | 사용자용 `TransitIcNfcException` |
| 발견 | Android NfcF/iOS FeliCa 모두 아님 | 비-FeliCa 오류 |
| 읽기 | Android 응답 짧음/코드 불일치/status 오류/블록 없음 | 해당 블록 null, 전체 읽기 loop 중단 |
| 읽기 | iOS status 오류/data 없음/16바이트 미만 | loop 중단 |
| 읽기 | 전부 0인 블록 | loop 중단 |
| 읽기 완료 | 원시 블록 2개 미만 | 이용내역 부족 오류 |
| 파싱 | 블록 16바이트 미만 | 해당 블록 제외 |
| 파싱 | 월/일 범위 오류 | 해당 블록 제외 |
| 가공 | fare 0 이하 | 해당 후보 제외 |
| 가공 | 버스 외 유형에 노선 코드 부족 | 해당 후보 제외 |
| 가공 완료 | item 0개 | 교통 후보 없음 오류 |
| 역명 조회 | resolver 없음 | 코드 라벨 유지 |
| 역명 조회 | 빈 응답/예외 | 코드 라벨 유지, 예외는 로그만 출력 |
| 전체 세션 | 30초 초과 | 세션 종료 후 timeout 오류 |
| 화면 | 파싱 날짜가 선택 범위 밖 | 행에서 제외, 카운트 증가 |
| 저장 | 역명 후보 미확정 | 확인 sheet 강제, 취소 시 저장 중단 |
| 저장 | 중복 선택 포함 | 확인 dialog, 거절 시 저장 중단 |

## 37. 실제 구현에서 확정되지 않은 정보

다음은 프로젝트에 없거나 파싱하지 않는다.

| 항목 | 상태 |
|---|---|
| 바이트 2~3의 의미 | `NOT_FOUND` |
| 바이트 12~14의 의미 | `NOT_FOUND` |
| 거래 순번/일련번호 추출 | `NOT_FOUND` |
| terminal code 전체 코드표 | `NOT_FOUND` |
| process code 전체 코드표 | `NOT_FOUND` |
| 충전 판별 및 충전액 계산 | `NOT_FOUND` |
| 환불 판별 및 환불액 계산 | `NOT_FOUND` |
| adjustment/other 판별 | `NOT_FOUND` |
| 지역 코드의 승차/하차 별도 추출 | `NOT_FOUND` |
| 카드별 영구 식별/중복 분리 | `NOT_FOUND` |
| IDm 또는 sourceKey DB 저장 | `NOT_FOUND` |
| NFC 원시 레코드 공개 모델 | `NOT_FOUND` |
| 원시 NFC 블록 fixture | `NOT_FOUND` |
| 실제 또는 마스킹된 IDm 테스트 값 | `NOT_FOUND` |
| NFC 읽기 단위/통합 테스트 | `NOT_FOUND` |
| `_SuicaHistoryBlock.tryParse` 단위 테스트 | `NOT_FOUND` |
| iOS entitlements 파일 | `NOT_FOUND` |

## 38. 테스트 현황

`test/transit_ic_parser_test.dart`는 IC 카드 표 이미지 OCR 및 Apple Pay 텍스트 파서 테스트다. 실물 NFC에서 읽은 16바이트 블록, IDm, Read Without Encryption 응답, 잔액 차액 또는 NFC 거래 유형을 검증하지 않는다.

현재 발견되지 않은 테스트:

- Android Read Without Encryption command 바이트 검증
- Android 응답 parser 검증
- iOS block response 검증
- 날짜 bit parser 경계값
- little-endian 잔액
- 연속 잔액 차감액
- 중간 invalid block 시 adjacency
- rail/bus/icPayment terminal/process 분류
- route code 누락 skip
- 역 코드 JSON decimal/hex 형식
- station resolver 성공/후보/실패 fallback
- IDm 마스킹/비저장 검증
- NFC 중복 key 검증
- bus가 저장 시 rail로 바뀌는 현상 검증

## 39. 구현상 핵심 주의사항 요약

1. 원시 레코드는 최소 16바이트이며, 실제 해석하는 오프셋은 0, 1, 4~11, 15뿐이다.
2. 금액은 레코드 금액 필드가 아니라 인접 잔액 차이로 계산한다.
3. invalid 블록을 제거한 뒤 차이를 계산하므로 원래 인접 관계가 바뀔 수 있다.
4. 충전/환불/조정은 보존하지 않으며 양수가 아닌 차액은 제거한다.
5. 알려지지 않은 거래는 `other`가 아니라 rail로 기본 분류된다.
6. 버스는 역 코드 없이 허용되지만 철도와 IC 결제는 route code가 필요하다.
7. 역명 조회는 철도만 수행하고, 실패하면 hex 코드 라벨을 유지한다.
8. 역 코드 API에는 decimal int와 2자리 uppercase hex 문자열을 동시에 전달한다.
9. IDm 전체 값과 raw block은 메모리/rawText에 존재하지만 화면에는 IDm 끝 4자리만 보인다.
10. exact/fuzzy 중복 key에 카드 ID와 거래 순번이 없다.
11. 중복은 자동 삭제하지 않고 사용자 확인 후 저장할 수 있다.
12. `icPayment`는 화면 확인용이며 DB에 저장하지 않는다.
13. bus item도 저장소에서 type을 rail로 고정하여 저장한다.
14. DB에는 IDm, rawText, 잔액, 원시 코드, sourceKey가 남지 않는다.
15. 원시 NFC parser 테스트 데이터와 단위 테스트가 없다.

## 40. 최종 저장 전후 필드 매핑표

| NFC/파싱 값 | 화면에서 사용 | 최종 DB 저장 | 비고 |
|---|---:|---:|---|
| IDm/cardId 전체 | state/rawText | 아니오 | UI는 끝 4자리만 표시 |
| raw block | rawText/debug log | 아니오 | uppercase hex |
| raw block count | 카드 요약 | 아니오 | 읽기 성공 블록 수 |
| terminalCode | 유형 판별/log | 아니오 | 일부 코드만 판별 |
| processCode | 유형 판별/log | 아니오 | 일부 코드만 판별 |
| 날짜 | 필터/정렬/표시 | 예 | 시간 없는 날짜 의미 |
| 현재 잔액 | 중복 key/log | 아니오 | sourceKey에 임시 포함 |
| 이전 잔액 | fare 계산/log | 아니오 | rawText에만 존재 |
| fare | 표시/중복/선택 | 예 | integer |
| regionCode | 역 조회/log | 아니오 | byte 15 하나 |
| boarding line/station | 역 조회/코드 라벨 | 이름만 저장 | 원시 코드는 소실 |
| alighting line/station | 역 조회/코드 라벨 | 이름만 저장 | 원시 코드는 소실 |
| resolver stationName | 화면 제목 | 예 | 승하차명 필드 |
| resolver lineName | 아니오 | 아니오 | 응답 모델에만 존재 |
| resolver operatorName | 아니오 | 아니오 | item 운영사는 `IC NFC` 유지 |
| parser type rail | 화면 분류 | rail | 그대로 보이는 경우 |
| parser type bus | 화면 분류 | rail | 저장소에서 강제 변경 |
| parser type icPayment | scanOnly 표시 | 아니오 | 저장 필터 제외 |
| rawText candidates | 역명 확인 UI | 선택된 이름만 | 원 후보 목록은 소실 |
| sourceKey | exact/fuzzy 중복 | 아니오 | IDm/거래 순번 미포함 |
| transportOperator | 표시 | 예 | `IC NFC` |
| sourceType | 저장 시 설정 | 예 | `ic_card_nfc` |
| needsReview | 화면 내부 검토 | false | 저장 전 해결 강제 |

## 41. 구현이 별도로 검증하지 않는 요소

- Android Read Without Encryption 응답의 IDm이 요청 IDm과 같은지 비교하지 않는다.
- Android 응답의 `blockCount`는 1 이상인지만 확인하고, 1보다 큰 경우에도 첫 16바이트 한 블록만 반환한다.
- Android 경로에서는 iOS처럼 시스템 코드 `0003`으로 별도 `polling()`을 호출하지 않는다. 세션의 ISO 18092 옵션과 발견된 `NfcFAndroid` 태그를 사용한다.
- iOS `polling()` 반환 데이터 자체는 별도로 보관하거나 검증하지 않는다.
- 원시 블록의 정렬 방향이나 블록 인덱스 연속성을 데이터로 검증하지 않고, 읽은 순서를 최신→과거로 전제한다.
- 레코드 checksum 또는 무결성 필드를 검증하지 않는다.
- `_logRawTransitNfcBlocks()`에서 각 블록을 한 번 파싱한 뒤, 실제 `histories` 목록 생성 시 다시 파싱한다. 즉 정상 흐름에서 파싱 함수가 블록당 두 번 호출된다.
- `rawBlockCount`에는 읽기에는 성공했지만 날짜가 잘못되어 `_SuicaHistoryBlock`으로 변환되지 않은 블록도 포함될 수 있다.
- 역명 응답은 서버가 돌려준 `station.code.key`로 map을 만들며, `matchedRegionCode`는 실제 lookup key 교체에 사용하지 않는다.
- 역명 조회 결과의 confidence나 matchStrategy를 NFC 경로에서 추가 임계값 판정에 사용하지 않는다. `resolved`와 비어 있지 않은 이름만 확인한다.

이 문서는 2026-08-09 현재 작업 트리에서 확인한 실제 프론트엔드 동작을 기준으로 한다.
