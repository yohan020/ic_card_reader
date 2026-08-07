# Known issues

| 오류 내용 | 재현 방법 | 예상 원인 | 임시 대응 | 해결 상태 |
|---|---|---|---|---|
| iOS 빌드 미실행 | Windows에서 iOS build 시도 | iOS 빌드는 macOS/Xcode 필요 | macOS CI 또는 개발 Mac에서 빌드·서명 | 미검증 |
| iOS 실기기 동작 미검증 | iPhone에서 ISO 18092 세션 시작 | Apple 서명/capability/entitlement 연결 필요 | Xcode에서 NFC capability와 `Runner.entitlements` 확인 | 미검증 |
| Android 실기기 동작 미검증 | NFC-F 지원 Android에서 스캔 | 제조사별 NFC-F/태그 이탈 동작 차이 | 최소 2종 기기로 반복 검사 | 미검증 |
| iOS 실제 원시 fixture 없음 | 단위 테스트 폴더 확인 | iPhone 실기기 기록 미확보 | 같은 카드로 iOS 스캔 후 Android 결과와 비교 | 미해결 |
| nfc_manager의 향후 Kotlin 호환성 경고 | Android build 실행 | 플러그인이 Built-in Kotlin 전환 전 KGP를 직접 적용 | 현재 빌드는 성공; 플러그인 업데이트 추적 | 열림 |
| nfc_manager는 NDK 28.2를 요청하지만 27.3으로 빌드 | Android build 실행 | 로컬 NDK 28.2가 Linux toolchain만 포함 | Windows NDK 27.3 고정으로 debug APK 성공, CI에서 28.2 재검증 | 우회 |
| 후속 블록 상태 오류가 이력 끝인지 통신 오류인지 모호 | 중간 블록에서 상태 플래그 오류 | 카드/서비스별 응답 의미 검증 부족 | 현재 첫 블록은 오류, 후속 블록은 종료 처리; 실기기 결과 기록 | 확인 필요 |
| Yoiko 데이터 앱 포함 불가 | SQLite asset 생성 시도 | 재배포 조건 미확인 | 조건 확인 전 원본 폴더에서 분석만 수행 | 미해결 |
| 역 코드 중복/충돌 | `00-06-4D`, `00-06-57` 또는 지역 없는 조회 | 원본 중복과 368개 지역 충돌 | 임의 확정 금지, 후보 유지 | 설계 반영 |
| 참고 Info.plist 형식 손상 | 원본을 XML parser로 열기 | 리터럴 `` `r`n `` 문자열 포함 | 새 Runner Info.plist에 필요한 키만 병합 | 우회 완료 |
| Android release 서명 미구성 | release 배포 시도 | 키를 소스에 포함하지 않기 위한 의도적 상태 | 배포 환경의 비밀 저장소/CI에서 서명 구성 | 출시 전 필요 |
| 디버그 로그에 실제 이동 이력이 표시됨 | debug 빌드에서 카드 스캔 성공 | fixture 확보를 위한 의도적 원시 블록 출력 | release에서는 비활성화; 공유 전 이동정보 노출 여부 확인 | 주의 필요 |

미확인 거래의 기본 철도 분류, IDm 로그, 사용자 신고의 자동 DB 반영은 알려진 문제가 아니라 명시적으로 금지된 구현이다.
