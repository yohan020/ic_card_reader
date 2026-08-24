# Osaka Amazing Pass fare data notice

- Dataset version: `osaka-amazing-pass-routing-2026.08.24`
- Validity baseline: 2026-04-01
- Scope: adult ordinary one-way transit fares and suggested transfer routes
  used by the Web prototype and Android app
- Generated asset: `assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json`

The generated asset contains 183 covered rail stations, 6,394 unordered rail
fare pairs, 196 adjacent rail edges, 27 reviewed interchange connections and
the Osaka City Bus adult flat fare. It does not contain
attraction admission values, route-search result pages, timetables, logos or
images. Cross-operator routes are suggested from the bundled graph using rail
distance and transfer penalties; they are not fastest-route or timetable
results. Some fares are independently calculated from adjacent operating
distance facts and public fare rules, so users must confirm the actual route
and latest official conditions before purchase.

## Sources and attribution

- Osaka Metro passenger/fare rules:
  https://subway.osakametro.co.jp/guide/fare/conditions_carriage/unsoyakan.php
- Osaka City Bus ordinary fare:
  https://citybus-osaka.co.jp/howto/
- Osaka Amazing Pass covered operators and sections:
  https://osaka-amazing-pass.com/en/howto_about_1day.html
- Hankyu public fare material:
  https://www.hankyu.co.jp/files/upload/topics/220803/2023040_fare.pdf
- Hanshin public fare material:
  https://www.hanshin.co.jp/ticket/
- Kintetsu public fare material:
  https://www.kintetsu.co.jp/gyoumu/kippu/pdf/kirotei_20260314.pdf
- Nankai public fare material:
  https://www.nankai.co.jp/lib/traffic/guide/pdf/kisoku/01_20250401.pdf
- Keihan Main Line adjacent operating-distance facts:
  https://ja.wikipedia.org/wiki/%E4%BA%AC%E9%98%AA%E6%9C%AC%E7%B7%9A
- Keihan Nakanoshima Line adjacent operating-distance facts and fare
  equivalence facts:
  https://ja.wikipedia.org/wiki/%E4%BA%AC%E9%98%AA%E4%B8%AD%E4%B9%8B%E5%B3%B6%E7%B7%9A
- Keihan fare bands and Nakanoshima surcharge source:
  https://www.mlit.go.jp/common/001879895.pdf

Some Keihan line and operating-distance information was normalized with
reference to information published by Wikipedia contributors. Wikipedia
content is available under CC BY-SA 4.0 and the Wikimedia Terms of Use:
https://creativecommons.org/licenses/by-sa/4.0/
https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use

The production Keihan rows do not use `keihan.co.jp` as a source. Fare rules
were independently applied using Japanese Ministry of Land, Infrastructure,
Transport and Tourism public documents. This notice does not relicense any
third-party source or constitute legal advice.
