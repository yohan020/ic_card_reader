# Known issues

- 마지막 갱신: 2026-08-14 (Asia/Seoul)

| 오류 내용 | 재현 방법 | 예상 원인 | 임시 대응 | 해결 상태 |
|---|---|---|---|---|
| 문의 관리 목록이 SQL의 20건 중 1건만 표시됨 | SQL Editor는 20건, 화면 배지는 `표시 1 / 전체 20건` | 누락된 `limit`에 `Number(null)=0`이 적용되어 최소값 1로 고정됨 | null·빈 값은 기본 limit 100 사용, 단일 JSON RPC와 캐시 차단 유지 | 해결·20건 사용자 확인 |
| iOS 빌드 미실행 | Windows에서 iOS build 시도 | iOS 빌드는 macOS/Xcode 필요 | macOS CI 또는 개발 Mac에서 빌드·서명 | 미검증 |
| iOS 실기기 동작 미검증 | iPhone에서 ISO 18092 세션 시작 | Apple 서명/capability/entitlement 연결 필요 | Xcode에서 NFC capability와 `Runner.entitlements` 확인 | 미검증 |
| Android 기기별 NFC 동작 차이 | NFC-F 지원 Android에서 스캔 | 제조사별 NFC 기본 모드·카드 모드와 어댑터 상태 차이 | Galaxy S22+와 최신 Galaxy에서 검증, 비공개 테스트로 추가 기기 회귀 확인 | 부분 해결 |
| iOS 실제 원시 fixture 없음 | 단위 테스트 폴더 확인 | iPhone 실기기 기록 미확보 | 같은 카드로 iOS 스캔 후 Android 결과와 비교 | 미해결 |
| nfc_manager의 향후 Kotlin 호환성 경고 | Android build 실행 | 플러그인이 Built-in Kotlin 전환 전 KGP를 직접 적용 | 현재 빌드는 성공; 플러그인 업데이트 추적 | 열림 |
| nfc_manager의 NDK 버전 요구 | Android build 실행 | Android 플러그인이 NDK 28.2를 요구 | 앱을 NDK `28.2.13676358`로 통일 | 해결 |
| 후속 블록 상태 오류가 이력 끝인지 통신 오류인지 모호 | 중간 블록에서 상태 플래그 오류 | 카드/서비스별 응답 의미 검증 부족 | 현재 첫 블록은 오류, 후속 블록은 종료 처리; 실기기 결과 기록 | 확인 필요 |
| Yoiko 데이터 배포 조건 준수 필요 | 앱 asset 또는 배포 패키지 확인 | 단독 재배포 금지, 앱 동시 배포만 허용 | 원본 export는 Git 제외, 조건 고지와 앱 asset으로만 포함 | 대응 완료 |
| 역 코드 중복/충돌 | `00-06-4D`, `00-06-57` 또는 지역 없는 조회 | 원본 중복과 368개 지역 충돌 | 임의 확정 금지, 후보 유지 | 설계 반영 |
| 참고 Info.plist 형식 손상 | 원본을 XML parser로 열기 | 리터럴 `` `r`n `` 문자열 포함 | 새 Runner Info.plist에 필요한 키만 병합 | 우회 완료 |
| Android release 서명 관리 | release 배포 시도 | 실제 키와 비밀번호를 Git에서 제외해야 함 | 로컬 release 서명과 AAB 생성 완료, 키·비밀번호 외부 백업 유지 | 대응 완료 |
| 디버그 로그에 실제 이동 이력이 표시됨 | debug 빌드에서 카드 스캔 성공 | fixture 확보를 위한 의도적 원시 블록 출력 | release에서는 비활성화; 공유 전 이동정보 노출 여부 확인 | 주의 필요 |
| 환불·정산 등 일부 거래 유형이 `UNKNOWN` | 해당 거래가 포함된 카드 조회 | 단말/처리 코드와 실제 거래의 ground truth 미확보 | 확인된 철도·버스·물품 구매·충전만 분류하고 나머지는 추정하지 않음 | 부분 해결 |
| 일부 역 코드가 역명으로 변환되지 않음 | Yoiko CSV에 없는 코드 또는 다중 후보 코드 조회 | 데이터 범위 제한과 지역 코드 충돌 | 임의 확정하지 않고 코드·후보 경고 표시 | 부분 해결 |
| 역 CSV 최초 로딩 성능 미측정 | 앱 재시작 후 첫 카드 스캔 | 약 1.4MB CSV를 메모리 인덱스로 변환 | 실행 중 캐시, 실기기 측정 후 필요 시 SQLite asset 전환 | 확인 필요 |

미확인 거래의 기본 철도 분류, IDm 로그, 사용자 신고의 자동 DB 반영은 알려진 문제가 아니라 명시적으로 금지된 구현이다.
