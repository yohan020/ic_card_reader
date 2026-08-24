Osaka Amazing Pass fare dataset 2026

SCOPE
- Base Osaka Amazing Pass (not the Itami Airport edition).
- 1day adult: 3,500 yen / 2day adult: 5,000 yen.
- Includes Osaka Metro, eligible Osaka City Bus routes, and covered sections of Hankyu, Hanshin, Keihan, Kintetsu and Nankai.
- Official pass source: https://subway.osakametro.co.jp/guide/page/20260401_osaka_amazing_pass.php

OSAKA METRO: SELF-CALCULATED METHOD
The Metro fare database no longer reproduces the official 5,882-cell station-pair fare table.
It is generated independently as follows:
1. Retain only 125 adjacent-station operating-distance facts.
2. Build a 109-station graph.
3. Add fare-calculation equivalence links required by Passenger Rule Art.49:
   - Umeda / Higashi-Umeda / Nishi-Umeda
   - Shinsaibashi / Yotsubashi
4. Calculate the shortest operating-km path under Passenger Rule Art.47.
5. Convert distance into fare zone: <=3km zone1, <=7km zone2, <=13km zone3, <=19km zone4, >19km zone5.
6. Apply the nine special fare-zone pairs in Passenger Rule Art.50.
7. Apply the Yumeshima +90 yen ordinary-fare surcharge.
8. Apply 2026 adult ordinary fares: 190 / 240 / 290 / 340 / 390 yen for zones 1-5.

METRO VALIDATION
- Physical stations: 109
- Adjacent operating-distance edges: 125
- Generated ordinary station-pair rows: 5,882
- The official 2026 zone matrix was used only after generation as a validation oracle.
- Compared pairs: 5,882
- Zone mismatches: 0
- Therefore the generated fare results reproduce the official 2026 fare zones without storing or redistributing the official pair matrix itself.

METRO SOURCES
- Current passenger-service rules: https://subway.osakametro.co.jp/guide/fare/conditions_carriage/unsoyakan.php
- Current passenger-rule appendix (adjacent operating-distance facts only): https://subway.osakametro.co.jp/guide/libray/unsoyakan/ryokyaku_eigyoukisoku_bessi.pdf
- Current ordinary fares: https://subway.osakametro.co.jp/guide/fare/fare/price.php
- Yumeshima surcharge: https://subway.osakametro.co.jp/guide/fare/various_fares/kasan/kasan_unchin.php
- Official 2026 zone table (validation only): https://subway.osakametro.co.jp/guide/libray/kusuuhyou/kusuuhyou20260401.pdf
- Route map / station list: https://subway.osakametro.co.jp/guide/routemap.php

LICENSING / DATA-PROVENANCE APPROACH
- The package does not include Osaka Metro's PDF, map artwork, logos, or the official full station-pair matrix.
- The generated CSV stores independently normalized factual station names, adjacent distances, calculation rules and derived fare results.
- The official pair matrix is not a runtime dependency and is not redistributed; it was used only to confirm that the independent calculation produced identical 2026 zones.
- Source URLs are retained for provenance.
- This is a technical data-provenance approach, not a legal opinion; commercial distribution should still follow each operator's current terms.

OTHER OPERATORS
- Private-rail calculations remain in private_rail_fares_2026.csv and private_rail_edges_2026.csv.
- Operator-specific surcharges/special fares remain in fare_exceptions_2026.csv.
- Osaka City Bus ordinary adult fare remains in bus_fares_2026.csv.

FILES
- fares_osaka_amazing_pass_2026.csv: combined rail fares
- metro_fares_2026.csv: independently calculated Metro fare pairs
- metro_edges_2026.csv: 125 Metro adjacent operating-distance facts
- metro_calculation_validation_2026.csv: aggregate validation results only
- fare_exceptions_2026.csv: Metro and private-rail special rules
- private_rail_fares_2026.csv / private_rail_edges_2026.csv
- pass_products_2026.csv / pass_coverage_2026.csv / stations_covered_2026.csv
- fare_rules_2026.csv / bus_fares_2026.csv / verification_report.csv

DOCUMENTATION
- Detailed calculation and licensing notes: CALCULATION_AND_LICENSE.md


KEIHAN OPEN-SOURCE PIPELINE UPDATE (2026-08-24)
- Keihan official website is no longer used as a production data source for fares/distances.
- Main-line adjacent km: Japanese Wikipedia (https://ja.wikipedia.org/wiki/%E4%BA%AC%E9%98%AA%E6%9C%AC%E7%B7%9A)
- Nakanoshima adjacent km + fare-equivalence rule: Japanese Wikipedia (https://ja.wikipedia.org/wiki/%E4%BA%AC%E9%98%AA%E4%B8%AD%E4%B9%8B%E5%B3%B6%E7%B7%9A)
- Fare bands: MLIT (https://www.mlit.go.jp/common/001879895.pdf)
- Nakanoshima +60 surcharge: MLIT (https://www.mlit.go.jp/common/001879895.pdf, https://www.mlit.go.jp/common/001287195.pdf)
- Detailed provenance: keihan_source_provenance_2026.csv
- Licensing note: KEIHAN_DATA_NOTICE.md
