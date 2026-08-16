# Data and licenses

## 현재 앱에 포함된 역 데이터

앱은 `Yoiko 自動改札機の研究`의 역 코드 데이터 8,537행을 사용한다.

- 원본 페이지: `https://ja.ysrl.org/atc/station-code.html`
- 앱 asset: `assets/data/stations/yoiko_station_codes.csv`
- SHA-256: `c38cdaa4f56d7d834174ba775dd78dbfd9b58fb19c4c1c68f6c52faa7c4889e6`
- 앱 내 조건 고지: `assets/licenses/yoiko-station-data-TERMS.txt`
- 원본 export: `yoiko_station_export/station_codes.csv` (수정하지 않으며 Git 추적 제외)

CSV에는 지역·노선·역 코드와 사업자명·노선명·역명이 들어 있다. 완전 키 8,537개는 모두 고유하다. `(line, station)`만 같은 지역 충돌 조합은 368개이며 최대 후보 수는 3개다. 지역이 확실하지 않을 때는 임의로 역을 확정하지 않고 후보 또는 원시 코드를 유지한다.

## 사용 허가 조건

프로젝트 소유자가 2026-08-09에 전달한 허가 조건은 다음과 같다.

- データの正確性を保証しない
- データの変更や訂正を通知しない、義務がない
- データ公開は予告なく中止する場合がある
- データ単体での再配布は有償、無償を問わず許可しない
  (アプリケーションとの同時配布は問題ありません)
- データ使用による責任を一切負わない(損害は一切補償しない)

따라서 데이터 파일만 별도로 재배포하지 않는다. 앱과 동시에 배포하는 asset으로만 포함하며, 설정의 라이선스 화면에도 위 조건을 표시한다.

## 한국어 역명 보조 데이터

일본어 역명에 대한 한국어 표기는 Wikidata의 구조화 데이터에서 생성한다.

- 생성 asset: `assets/data/stations/wikidata_station_names_ko.csv`
- 생성 도구: `tool/generate_wikidata_railway_station_catalog.mjs`, `tool/generate_wikidata_station_korean_labels.mjs`
- 앱 실행 중 외부 API 호출: 없음
- 출처·고지: `assets/licenses/wikidata-station-names-CC0.txt`

Wikidata의 구조화 데이터는 CC0 Public Domain Dedication으로 제공된다. 생성기는 일본의 철도역 카탈로그를 페이지 단위로 수집한 뒤, Yoiko 역명의 원문과 `駅` 접미사가 붙은 이름을 로컬에서 대조한다. 전체 대조기 역시 모든 Yoiko 역명을 같은 규칙으로 확인해 카탈로그의 누락분을 보완한다. 후보가 여러 개인 경우 한국어 라벨이 단 하나로 일치할 때만 asset에 넣는다. 전수 대조 결과 Yoiko 고유 역명 7,320개 중 6,738개가 이 조건을 만족했으며, 그 외에는 한국어 표기를 추측하지 않고 기존 일본어 역명을 유지한다.

데이터를 갱신할 때는 다음 명령을 실행한다. 조회 캐시는 `tool/.cache/`에만 남고 Git에 포함하지 않는다.

```powershell
node tool/generate_wikidata_railway_station_catalog.mjs
node tool/generate_wikidata_station_korean_labels.mjs
```

## 기존 참고 자료

`ic_card_export/`는 수정하지 않는 참고 자료이며 Git 추적에서 제외한다. 기존 Suica Viewer CSV와 MIT 고지는 앱 asset에서 제거했지만 분석 참고 자료는 원본 폴더에 그대로 둔다. Kotlin·PostgreSQL·기존 Dart 코드는 개념과 검증 규칙만 참고하고 앱 구조에 맞게 재작성한다.

## 데이터 해석 원칙

- 데이터 정확성은 보장되지 않으므로 역명 조회 결과를 카드 원문보다 우선하는 권위 정보로 취급하지 않는다.
- 지역 코드는 데이터에 `00`~`03`이 있고 기존 서비스의 경험적 힌트 `50 -> 01`, `F0 -> 03`을 제한적으로 사용한다. 공식 의미가 확인되지 않았으므로 확정 규칙으로 간주하지 않는다.
- 사업자 코드, 유효 기간, 공식 데이터 버전은 제공되지 않는다.
- 데이터가 변경되더라도 자동 크롤링하거나 런타임에서 원본 사이트에 접속하지 않는다. 갱신은 허가 조건을 확인한 뒤 명시적으로 수행한다.
- 한국어 역명은 보조 표기일 뿐이며, 원본 일본어 역명·역 코드·노선명은 변경하지 않는다.

## 개인정보 원칙

- 카드 IDm 원문: 영구 저장, 로그, 화면 표시, 분석 도구, 서버 전송 금지.
- 원시 이력: 한 레코드씩 로컬 저장 가능. 신고 시 사용자가 선택하고 미리보기·동의한 한 건만 전송 가능.
- 이름, 이메일, 기기 고유 ID, 현재 위치, 전체 이동 경로: 수집·전송 금지.
- 익명 fixture: IDm과 개인 메타데이터 없이 16바이트 블록과 기대되는 프로토콜 수준 결과만 포함한다.
