# Windows Flutter/Dart 검증 환경 복구 안내

이 문서는 Windows에서 `dart format`, `dart analyze`, `flutter test`, `flutter analyze`가 사용자 홈의 Dart 설정 폴더 권한 문제로 실행되지 않을 때의 재현 가능한 복구 절차를 기록한다. 애플리케이션 로직 문제가 아니라 개발 도구 환경 문제일 때만 적용한다.

## 확인된 증상

Codex 또는 PowerShell에서 Dart 명령을 실행할 때 다음과 비슷한 오류가 나타날 수 있다.

```text
PathAccessException: Creation failed, path =
'C:\\Users\\yohan\\AppData\\Roaming\\.dart-tool' (OS Error: Access is denied, errno = 5)
```

이 오류는 프로젝트 파일·`pubspec.yaml`·Dart 코드의 오류가 아니라, Dart가 사용하는 사용자별 설정 경로 `%APPDATA%\\.dart-tool`의 소유자 또는 ACL(접근 권한)이 깨진 상태를 의미한다. 따라서 캐시 삭제, 프로젝트 재생성, 의존성 버전 변경으로 우회하지 않는다.

## 사전 확인

1. 프로젝트 루트에서 Flutter SDK 위치를 확인한다. 이 프로젝트의 개발 환경에서는 다음 경로를 사용했다.

   ```powershell
   C:\Users\yohan\Desktop\project\flutter\bin
   ```

2. 실제 오류가 `.dart-tool` 경로 권한 오류인지 명령 출력으로 확인한다.
3. 이미 실행 중인 사용자의 IDE·에뮬레이터·개발 서버는 종료하지 않는다. 이 절차에서 새로 시작한 검증 명령만 작업 후 종료한다.

## 복구 절차

`%APPDATA%\\.dart-tool`은 사용자 프로필 밖의 시스템 설정 경로이므로, 소유권·ACL 복구는 승인된 관리자 PowerShell 또는 승인된 Codex 실행 권한으로만 수행한다.

```powershell
takeown /f "C:\Users\yohan\AppData\Roaming\.dart-tool" /r /d y
icacls "C:\Users\yohan\AppData\Roaming\.dart-tool" /grant "yohan:(OI)(CI)F" /t /c
```

- `takeown`은 현재 Windows 사용자(`yohan`)에게 폴더와 하위 항목의 소유권을 돌린다.
- `icacls`는 해당 사용자에게 하위 파일·폴더까지 전체 제어 권한을 부여한다.
- 이 명령의 대상은 반드시 위의 **단일 `.dart-tool` 경로**인지 확인한다. `%APPDATA%` 전체 또는 사용자 프로필 전체에 권한을 재귀 적용하지 않는다.
- 폴더가 존재하지 않아 권한 오류가 아닌 경우에는 이 복구 명령을 실행하지 말고, Flutter SDK 경로·PATH·`flutter pub get` 결과를 먼저 점검한다.

## 권장 검증 순서

프로젝트 루트에서 Flutter SDK의 절대 경로를 사용한다. 일반 PATH에 Flutter가 등록되어 있지 않아도 같은 결과를 얻는다.

```powershell
$flutterBin = 'C:\Users\yohan\Desktop\project\flutter\bin'
& "$flutterBin\cache\dart-sdk\bin\dart.exe" format <수정한 Dart 파일 또는 디렉터리>
& "$flutterBin\cache\dart-sdk\bin\dart.exe" analyze <수정한 Dart 파일과 관련 테스트>
& "$flutterBin\flutter.bat" test --no-pub <관련 테스트 파일>
& "$flutterBin\flutter.bat" analyze --no-pub <수정한 Dart 파일과 관련 테스트>
```

예를 들어 삿포로 지하철 1일권을 검증할 때는 아래 범위를 사용했다.

```powershell
$flutterBin = 'C:\Users\yohan\Desktop\project\flutter\bin'
& "$flutterBin\cache\dart-sdk\bin\dart.exe" format `
  lib/src/features/pass_comparison/data/sapporo_subway_pass_data.dart `
  lib/src/features/pass_comparison/domain/sapporo_subway_pass.dart `
  lib/src/features/pass_comparison/presentation/sapporo_subway_pass_page.dart `
  test/features/pass_comparison/sapporo_subway_pass_test.dart

& "$flutterBin\flutter.bat" test --no-pub `
  test/features/pass_comparison/sapporo_subway_pass_test.dart

& "$flutterBin\flutter.bat" analyze --no-pub `
  lib/src/features/pass_comparison/data/sapporo_subway_pass_data.dart `
  lib/src/features/pass_comparison/domain/sapporo_subway_pass.dart `
  lib/src/features/pass_comparison/presentation/sapporo_subway_pass_page.dart `
  test/features/pass_comparison/sapporo_subway_pass_test.dart
```

변경 범위가 넓다면 같은 방식으로 전체 검증을 실행한다.

```powershell
& "$flutterBin\cache\dart-sdk\bin\dart.exe" format lib test
& "$flutterBin\flutter.bat" analyze --no-pub
& "$flutterBin\flutter.bat" test --no-pub
```

`--no-pub`은 이미 의존성 해결이 끝난 현재 프로젝트에서 네트워크·패키지 재해결 없이 분석/테스트만 수행하기 위한 옵션이다. 의존성이 바뀌었거나 `.dart_tool`이 없는 경우에는 먼저 `flutter pub get`을 실행한다.

## 실제 복구 이력 (2026-09-19)

1. sandbox에서 `dart format`을 실행했을 때 `%APPDATA%\\.dart-tool` 생성 권한 오류가 재현됐다.
2. 위의 `takeown`·`icacls`를 승인된 권한으로 실행해 폴더와 설정 파일의 소유자 및 ACL을 `yohan`으로 복구했다.
3. 복구 뒤 포매터가 권한 문제가 아닌 실제 Dart 문법 오류 두 건을 발견했고, 괄호 누락을 수정했다.
4. 포매터를 다시 적용한 뒤 관련 Dart 분석은 `No issues found!`를 반환했다.
5. 삿포로 지하철 1일권 단위 테스트는 기대값을 실제 운임 데이터와 맞춘 뒤 `All tests passed!`(2개)로 통과했다.
6. 관련 파일 4개 대상 `flutter analyze --no-pub`도 `No issues found!`로 통과했다.
7. 검증 종료 뒤 `dart`·`flutter` 잔여 프로세스가 없는 것을 확인했다. 기존 사용자의 `cmd.exe` 프로세스는 소유를 확정할 수 없으므로 종료하지 않았다.

## 복구 뒤에도 실패하면

| 증상 | 우선 점검 | 조치 |
| --- | --- | --- |
| `flutter`를 찾을 수 없음 | Flutter SDK 경로와 PATH | 위 절대 경로 방식으로 실행하거나 사용자의 PATH 설정을 점검한다. |
| `.dart-tool` 접근 거부가 계속됨 | 명령 실행 주체와 ACL | 현재 사용자 계정에 권한이 적용됐는지 확인한다. Codex sandbox와 사용자 계정의 권한 경계 때문에 sandbox만 실패할 수 있으며, 승인된 사용자 컨텍스트의 검증 결과를 기준으로 판단한다. |
| `dart format`이 문법 오류를 보고함 | 오류 파일·줄 번호 | 권한 오류와 구분해 Dart 문법을 수정한 후 포매터를 다시 실행한다. |
| `flutter analyze`만 실패함 | 분석 대상·기존 진단 | 먼저 변경 파일 대상으로 실행해 새 문제인지 기존 전역 문제인지 구분하고, 범위가 안전하면 전체 분석으로 확대한다. |
| 명령 뒤 프로세스가 남음 | `Get-Process dart, flutter, cmd, powershell` | 시작 시각과 작업 세션을 대조해 에이전트가 시작한 것만 종료한다. |

## 금지 및 주의 사항

- 권한 오류를 해결하려고 프로젝트 소스·`pubspec.yaml`·lockfile을 임의로 되돌리거나 삭제하지 않는다.
- 사용자 프로필 전체, `%APPDATA%` 전체, Flutter SDK 전체에 재귀적 전체 제어 권한을 부여하지 않는다.
- 사용자가 직접 실행 중인 IDE, 앱, 에뮬레이터, 터미널을 임의로 종료하지 않는다.
- 이 복구는 빌드가 아니다. 사용자가 직접 빌드하므로 `flutter build`는 실행하지 않는다.
