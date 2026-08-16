# 일본 교통카드 리더

Android NFC로 일본 전국호환 교통계 IC 카드의 최근 이용내역을 읽고, 기기 안에서 보기 쉽게 해석하는 Flutter 앱입니다.

> 현재 Android 우선으로 개발·비공개 테스트 중입니다. iOS NFC 지원은 추후 진행합니다.

## 주요 기능

- NFC-F/FeliCa 카드에서 서비스 코드 `090F`의 최근 16바이트 이용내역을 최대 20건 읽기
- 철도·버스·물품 구매·충전 등 확인된 거래 유형 표시
- 이용일, 잔액, 금액, 역 코드와 역명·노선 정보 표시
- 역명을 일본어·한국어·함께 표시 중 선택
- 현재 스캔 세션의 이용내역만 표시하며 앱 종료 후 영구 저장하지 않음
- 선택한 이용내역 1건을 익명으로 오류 제보
  - 카드 IDm, 이메일, 기기 고유 식별자는 전송하지 않음
  - 역명·버스 회사·거래 유형 보정 제보를 지원
- 교통패스 손익 비교를 위한 별도 Web 프로토타입 포함

## 지원 범위와 주의사항

- 전국 상호이용 교통계 IC 카드의 모든 거래 유형·버스 회사·역 코드를 완전히 해석하지는 않습니다.
- 실제 샘플로 검증되지 않은 값은 추측하지 않고 `미확인` 또는 `계산할 수 없음`으로 표시합니다.
- PiTaPa처럼 이용 이력 구조가 다른 카드나 포스트페이 카드의 완전한 지원은 현재 범위 밖입니다.
- Samsung 기기에서는 NFC 설정을 **기본 모드**로 두어야 읽기가 가능한 경우가 있습니다.

## 개인정보

카드 IDm은 NFC 명령 처리 중 메모리에서만 사용하며, 로그·로컬 저장소·서버에 저장하거나 전송하지 않습니다. 오류 제보는 사용자가 전송에 동의한 경우에만 선택한 이용내역 1건과 제보 내용만 전송합니다.

자세한 내용은 [개인정보처리방침](docs/PRIVACY_POLICY.md)과 [공개 페이지](https://yohan020.github.io/ic_card_reader/)를 참고하세요.

## 개발 환경

- Flutter 3.44.9 / Dart 3.12.2 이상
- NFC를 지원하는 Android 기기
- Android SDK 및 연결된 실제 기기

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

릴리스 서명 및 AAB 생성 절차는 [Android 릴리스 서명 안내](docs/ANDROID_RELEASE_SIGNING.md)를 따릅니다. 빌드 번호는 `pubspec.yaml`에서 직접 올린 뒤 생성하세요.

## 오류 제보 백엔드와 관리 화면

오류 제보는 Supabase Anonymous Auth, Edge Function, PostgreSQL을 사용합니다. 관리자용 문의 관리 화면은 localhost에서만 실행하도록 구성되어 있습니다.

```powershell
cd admin
npm install
npm run start
```

Supabase migration·함수 배포와 관리자 화면 설정은 [Supabase 운영 안내](docs/SUPABASE_SETUP.md), [문의 관리 안내](docs/ISSUE_REPORT_ADMIN.md)를 확인하세요.

## 데이터와 라이선스

- 역 코드 데이터는 허가받은 Yoiko 데이터를 앱과 함께 사용합니다. 데이터만 별도로 재배포할 수 없습니다.
- 한국어 역명 보조 표기는 Wikidata의 CC0 데이터를 기반으로 생성했습니다.
- 출처·이용 조건·갱신 방법은 [데이터 및 라이선스 안내](docs/DATA_AND_LICENSES.md)를 참고하세요.

## 문서와 검증

- [현재 개발 상태](docs/DEVELOPMENT_STATUS.md)
- [미완료 작업](docs/planning/TODO.md)
- [테스트 매트릭스](docs/TEST_MATRIX.md)
- [이용내역 파서 근거와 이력](docs/TRANSIT_HISTORY_PARSER_FIRST_REVISION.md)
- [교통패스 비교 분석](docs/planning/PASS_COMPARISON_ANALYSIS.md)

```powershell
flutter analyze --no-pub
flutter test --no-pub
node --test admin/test/*.test.mjs
```
