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

## 프로젝트 보완 역 데이터

프로젝트가 실제 익명 fixture와 공개된 교통사업자 역 순서·공식 안내를 대조해 만든 보완 매핑은 Yoiko 원본과 별도 파일로 관리한다. 이후 다른 사업자·지역의 보완 데이터도 같은 파일 형식과 출처 표기 원칙을 따른다.

- 보완 asset: `assets/data/stations/verified_station_overrides.csv`
- 라이선스 고지: `assets/licenses/project-supplemental-station-overrides-CC-BY-4.0.txt`
- 라이선스: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- 권장 출처 표기: `IC Card Reader / yohan020 supplemental station overrides (CC BY 4.0)`

각 행의 `evidence`, `source_note`, `source_url`은 근거 수준과 확인 경로를 나타낸다. `verified_fixture`는 공개하지 않는 익명 실물 카드 fixture로 확인한 값이며, `inferred_sequence`는 공식 역 순서와 카드 코드의 제한된 패턴을 함께 사용한 추론값이다. 추론값을 공식 코드표나 실물 카드로 직접 검증한 값처럼 표시하지 않는다.

CC BY 4.0은 프로젝트가 만든 매핑, 수동 한글 표기, 근거 분류, 출처 주석과 편집 구성에만 적용된다. 역명·공개 사실·코드값에 독점 권리를 주장하지 않으며, Yoiko 원본 데이터·Wikidata·각 교통사업자 자료 등 제3자 자료의 조건을 변경하거나 재라이선스하지 않는다. 익명 fixture 원문은 이 asset과 저장소에 포함하지 않는다.

## 한국어 역명 보조 데이터

일본어 역명에 대한 한국어 표기는 Wikidata의 구조화 데이터에서 생성한다. 생성 결과는 일본어 역명 문자열이 아니라 Yoiko의 `지역·노선·역 코드` 완전 키에 연결한다.

- 생성 asset: `assets/data/stations/station_names_ko_by_code.csv`
- 수동 보완 asset: `assets/data/stations/manual_station_names_ko_by_code.csv`
- 생성 도구: `tool/generate_wikidata_station_korean_labels.mjs`
- 앱 실행 중 외부 API 호출: 없음
- 출처·고지: `assets/licenses/wikidata-station-names-CC0.txt`

Wikidata의 구조화 데이터는 CC0 Public Domain Dedication으로 제공된다. 생성기는 Yoiko 각 코드의 일본어 역명과 Wikidata의 일본어 역명 후보를 대조한 뒤, 연결 노선(`P81`)의 일본어 라벨도 함께 비교한다. 동명 역은 노선까지 일치하는 하나의 Wikidata 항목일 때만 생성 asset에 넣는다. 예를 들어 도쿄 日本橋와 오사카 日本橋는 각각 별도 코드에 `니혼바시역`과 `닛폰바시역`으로 기록된다. 노선 근거가 없거나 후보가 여럿이면 추측하지 않고 제외한다. 2026-08-17 전체 재생성 결과는 8,042개 코드이다. 앱은 표시할 때 Wikidata 생성 한글명 끝의 `역`만 일괄 제거하며, 수동 보완 표기는 입력값을 그대로 유지한다.

데이터를 갱신할 때는 다음 명령을 실행한다. 조회 캐시는 `tool/.cache/`에만 남고 Git에 포함하지 않는다.

```powershell
node tool/generate_wikidata_station_korean_labels.mjs --refresh
```

### 직접 검증한 한글 표기 추가

Wikidata 생성 파일은 다음 생성 작업에서 다시 만들어지므로 직접 수정하지 않는다. 직접 조사·검증한 표기는 `assets/data/stations/manual_station_names_ko_by_code.csv`에 다음 형식으로 한 줄씩 추가한다. localhost 문의 관리 화면의 한글 표기 요청 상세에서는 검토·확인 후 이 파일에 코드별 행을 추가하거나 같은 코드를 교체할 수 있다. 같은 일본어 역명이 생성 데이터에 있어도 수동 표기가 우선한다.

```csv
region_code,line_code,station_code,station_name_ja,station_name_ko,source_note
0,227,52,日本橋,니혼바시,직접 발음 조사 2026-08-16
```

`source_note`에는 확인 방법 또는 출처를 짧게 남긴다. 이 파일은 비어 있는 헤더만으로도 유효하며, 새 줄을 추가한 뒤 `flutter analyze`와 `flutter test`를 실행해 확인한다.

## 기존 참고 자료

`ic_card_export/`는 수정하지 않는 참고 자료이며 Git 추적에서 제외한다. 기존 Suica Viewer CSV와 MIT 고지는 앱 asset에서 제거했지만 분석 참고 자료는 원본 폴더에 그대로 둔다. Kotlin·PostgreSQL·기존 Dart 코드는 개념과 검증 규칙만 참고하고 앱 구조에 맞게 재작성한다.

## 프로젝트 코드 라이선스

별도 조건이 명시된 데이터 asset과 제3자 자료를 제외한 프로젝트 소스 코드는 루트의 [`LICENSE`](../LICENSE)에 따라 MIT License로 제공한다. 코드 라이선스는 Yoiko 데이터의 동시 배포 조건이나 외부 데이터의 원래 라이선스를 대체하지 않는다.

## 교통패스 비교용 도쿠나이 역 목록

도쿠나이 패스 Web 프로토타입의 역 자동완성은 JR 동일본의 도쿠나이 패스 공식 이용 가능 지역 안내를 바탕으로 만든 74개 역의 검색용 목록이다.

- asset: `assets/data/pass_comparison/tokunai_jr_data.json`
- 공식 안내: `https://www.jreast.co.jp/ko/multi/pass/tokunai_pass.html?lang=en`
- 용도: 패스 적용 JR 역 자동완성만 제공
- 포함하지 않는 정보: 역간 거리, 경로, 일반 운임, 운임 특례

이 목록은 운임표가 아니므로 일반 운임이나 손익을 산출하는 근거로 사용하지 않는다. 정확한 영업킬로·특례를 검증한 별도 운임 데이터가 확보되기 전에는 도쿠나이 패스의 자동 손익 계산을 활성화하지 않는다.

## 오사카 주유패스 자동 운임 파생 데이터

Web 검증 프로토타입과 Android 앱은 `assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json`을 사용한다. 이 asset은 사용자 제공 검증 패키지의 인접 영업거리·공개 운임 규칙·특례를 앱용 구조로 변환한 것으로, 일반판 주유패스 대상 철도 183역과 동일 사업자 역쌍 성인 일반 운임 6,394건, 인접 철도 간선 196개, 검토한 사업자 간 환승 연결 27개, 오사카 시티버스 성인 일반 노선 정액 운임 ¥210을 포함한다. 관광시설 가치, 노선 검색 결과 원문, 시각표, 로고와 이미지는 포함하지 않는다.

사업자 간 경로는 정적 철도 그래프에서 영업거리와 환승 부담을 가중치로 사용해 추천한다. 시간표 기반 최속 경로가 아니며, 선택 경로를 사업자별 승차 구간으로 나눈 뒤 기존 운임표를 합산한다. 앱은 이 한계를 표시하고 사용자가 실제 이용 경로와 최신 공식 조건을 확인하도록 안내한다.

- 생성 도구: `tool/import_osaka_amazing_pass_fares.dart`
- 출처·제한 고지: `assets/licenses/osaka-amazing-pass-fares-DATA-NOTICE.md`
- 게이한 생산 데이터: `keihan.co.jp`를 사용하지 않고 Japanese Wikipedia의 인접 영업거리 사실과 일본 국토교통성 공개 운임 자료를 기준으로 독립 계산
- Wikipedia 관련 고지: Wikipedia contributors, CC BY-SA 4.0 및 Wikimedia 이용조건

생성기는 역·운임 행 개수, 누락 역, 중복 역쌍, 양수 운임, 2026년 패스 가격, 오사카 시티버스 운임과 게이한 출처 도메인을 검사하며 하나라도 어긋나면 asset을 교체하지 않는다. 파생 운임의 정확성을 보장하지 않으므로 프로토타입은 참고용으로 표시하고 실제 구매 전 최신 공식 안내 확인을 요구한다. 이 고지는 제3자 자료를 프로젝트 MIT License로 재라이선스하지 않는다.

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
