# 교통패스 역 선택 필드 구현 가이드

## 적용 대상

교통패스 비교의 모든 이동 구간에서 출발·도착역을 고르는 필드다. 기존 패스와 새 패스 모두 이 문서를 따른다.

## 필수 구현 방식

`lib/src/features/pass_comparison/presentation/widgets/pass_station_picker_field.dart`의 `PassStationPickerField`를 직접 사용한다.

- `OutlinedButton`, `ElevatedButton`, 각 페이지의 별도 `Container` 조합으로 필드를 다시 만들지 않는다.
- 버튼 계열 위젯은 내부 최소 크기·기본 패딩이 플랫폼별로 더해져 세 줄의 실제 세로 간격이 Tokyo Subway Ticket/도쿠나이 기준과 달라진다.
- 이 공통 위젯은 기준 화면과 동일한 `Material → InkWell → Ink → SizedBox → Center → Padding → Column` 구조를 유지한다.

## 고정 레이아웃 값

| 항목 | 값 |
| --- | --- |
| 선택 전 높이 | 60dp |
| 선택 후 높이 | 76dp |
| 가로 패딩 | 8dp |
| 세로 정렬 | `Center` |
| 라벨 | 12sp, w600, 보조색 |
| 역명 | 14sp, w700, 강조색 |
| 운영사 보조정보 | `labelSmall`, 한 줄 말줄임 |
| 라벨 → 역명 | 2dp |
| 역명 → 보조정보 | 2dp |
| 모서리 반경 | 14dp |

## 새 패스 적용 예시

```dart
PassStationPickerField(
  label: '출발',
  stationName: selectedStation?.displayName,
  operatorLabel: selectedStation?.operatorLabel,
  onTap: () async {
    // 기존 역 검색 화면을 열고 선택 결과만 상태에 반영한다.
  },
)
```

데이터 준비 전에는 `onTap: null`과 `emptyLabel: '데이터 준비 중'`을 사용한다. 선택된 역의 사업자·노선 문자열은 `operatorLabel`에만 전달하고, 검색 후보에는 넣지 않는다.

## 검증 방법

1. 라이트·다크 모드에서 Tokyo Subway Ticket 또는 도쿠나이 패스와 새/수정 패스의 선택 완료 필드를 나란히 확인한다.
2. 출발만 선택한 상태와 출발·도착을 모두 선택한 상태를 확인한다.
3. 긴 운영사명에서 보조정보가 한 줄 말줄임으로 처리되고 필드 높이가 유지되는지 확인한다.
4. 역명·운영사 행의 실제 기준선과 위아래 여백이 기준 패스와 같은지 실기기 스크린샷으로 대조한다.
