# ODPT pass comparison data

`odpt_pass_data.json` is generated locally and is intentionally not replaced
with made-up sample fares. Generate it with:

```powershell
$odptLine = Get-Content .env | Where-Object { $_ -match '^ODPT_ACCESS_TOKEN=' } | Select-Object -First 1
$env:ODPT_ACCESS_TOKEN = $odptLine.Substring('ODPT_ACCESS_TOKEN='.Length).Trim()
dart run tool/import_odpt_pass_data.dart
Remove-Item Env:ODPT_ACCESS_TOKEN
```

The access token is used only by the development-time importer and is never
written to the generated JSON or bundled into the Flutter application.

The importer uses ODPT's complete `.json` dump endpoint and filters Tokyo
Metro and Toei locally. Do not replace it with the regular search endpoint:
that endpoint can return only the first 1,000 fare rows per operator.

`manual_odpt_station_names_ko.csv` is the user-maintained Korean-label
override file. It uses stable `odpt_station_id` values (multiple IDs for one
grouped physical station are separated by `|`), so a later ODPT import keeps
the same labels. To apply edits to an already generated local asset without
downloading ODPT again:

```powershell
dart run tool/apply_odpt_korean_overrides.dart
```

`tokunai_jr_data.json` contains 77 JR East stations in the Tokunai Pass
coverage area and all 2,926 unordered adult IC-fare pairs for the 2026
prototype. The table is a **derived reference dataset**: it was calculated and
reviewed from Wikidata-based network distances plus the 2026 JR East fare
table. It is not a JR East fare-search export, so the UI labels its result as a
reference and asks users to confirm official conditions before purchase.

To recreate the asset from the reviewed CSV:

```powershell
dart run tool/import_tokunai_derived_fares.dart --input path/to/fares_tokyo_wards_2026_corrected_full_graph.csv
```

The importer maps Japanese station names to stable app IDs and refuses an
incomplete or duplicated matrix. On a fare revision, regenerate the CSV and
compare representative pairs with JR East's official result before replacing
the bundled asset.

When a complete pair-by-pair official fare record is available, copy
`tool/tokunai_verified_fares.template.json`, replace its placeholder rows, and
run:

```powershell
dart run tool/build_tokunai_fare_data.dart --input path/to/verified_fares.json
```

The builder accepts only HTTPS `www.jreast.co.jp` evidence URLs and refuses to
write the app asset until every unordered pair in the station directory has an
adult IC fare. This prevents a partial table from silently enabling an
incomplete automatic calculation.

## Osaka Amazing Pass Web prototype

`osaka_amazing_pass_fares_2026.json` is a compact runtime asset generated from
the reviewed CSV package in
`osaka_amazing_pass_fare_data_2026_keihan_open_sources/`. It contains 183
covered rail stations, all 6,394 same-operator unordered adult fare pairs, the
Osaka City Bus adult flat fare, 196 adjacent rail edges, 27 reviewed
cross-operator interchange connections, version metadata and source notices.
It does not copy route-search result pages or timetables.

Regenerate it after replacing and reviewing the source package:

```powershell
dart run tool/import_osaka_amazing_pass_fares.dart
```

The importer refuses a missing station, duplicate pair, non-positive fare,
unexpected 2026 pass price, incomplete row count or a Keihan production source
that contains `keihan.co.jp`. Korean labels are joined from the project’s
code-based station assets and a small reviewed fallback for eight uncovered
stations; Japanese names remain the lookup identity.

The same transit-fare-only flow is available in the Web prototype and the
Android pass-selection screen. It automatically looks up same-operator fares,
finds a distance-based route through reviewed interchange connections, splits
that route into operator legs, and adds each operator fare plus eligible Osaka
City Bus rides. This is not a timetable or fastest-route search. Attraction
admission, excluded/on-demand buses, express tickets and seat fees are not
included. See
`assets/licenses/osaka-amazing-pass-fares-DATA-NOTICE.md` for sources,
attribution and limitations.
