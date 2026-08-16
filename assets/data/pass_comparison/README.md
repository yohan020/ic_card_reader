# ODPT pass comparison data

`odpt_pass_data.json` is generated locally and is intentionally not replaced
with made-up sample fares. Generate it with:

```powershell
$env:ODPT_ACCESS_TOKEN='issued token'
dart run tool/import_odpt_pass_data.dart
```

The access token is used only by the development-time importer and is never
written to the generated JSON or bundled into the Flutter application.
