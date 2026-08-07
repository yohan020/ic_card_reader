# IC Card Reader

일본 전국호환 선불식 교통계 IC 카드의 최근 이용내역을 기기 안에서 읽는 Flutter 앱이다.

현재는 Phase 1 NFC PoC다. NFC-F/FeliCa 카드에서 시스템 코드 `0003`, 서비스 코드 `090F`의 원시 16바이트 이력 블록을 최대 20개 읽고 개발자 화면에 표시한다. 카드 IDm은 명령 수행 중 메모리에서만 사용하며 결과, 로그, 로컬 저장소에 남기지 않는다.

## 개발 환경 준비

Flutter 3.44.9(Dart 3.12.2)로 플랫폼 러너를 생성하고 검증했다. 작업용 SDK는 `.tooling/flutter`에 있으며 Git에서 제외된다. 다른 환경에서는 Flutter 3.44 이상을 설치한 뒤 프로젝트 루트에서 다음을 실행한다.

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Android NFC permission/feature와 iOS NFC 설명·FeliCa 시스템 코드 `0003`·entitlement 연결은 프로젝트에 포함되어 있다. iOS 서명 시 Xcode의 Runner Signing & Capabilities에서 Near Field Communication Tag Reading이 실제 프로비저닝 프로파일에 포함됐는지 확인한다.

실물 카드 검증 전에는 읽기 성공으로 간주하지 않는다. 자세한 상태는 `docs/DEVELOPMENT_STATUS.md`를 참고한다.

## 익명 fixture용 로그

`flutter run`으로 실행한 debug 빌드에서 카드 읽기에 성공하면 터미널에 다음 구간이 출력된다.

```text
IC_CARD_FIXTURE_BEGIN count=20
IC_CARD_BLOCK[0]=32자리 16진수
...
IC_CARD_FIXTURE_END
```

이 구간에는 카드 IDm과 기기 식별정보가 포함되지 않는다. 단, 원시 블록 자체에는 실제 이동 이력이 있으므로 외부 공유 전 노출 가능성을 확인한다. release 빌드에서는 출력하지 않는다.

실물 카드 fixture `test/fixtures/felica/android_history_20_v1.json`은 실제 이동 이력 보호를 위해 Git에서 제외된다. 로컬에 파일이 없으면 해당 fixture 테스트는 실패로 기록되지 않고 명시적으로 skip된다.
