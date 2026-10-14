param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$adbPath = Join-Path $env:LOCALAPPDATA 'Android/sdk/platform-tools/adb.exe'
& node (Join-Path $PSScriptRoot 'seed_roster_emulator.cjs')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
try {
    & $adbPath -s $Device reverse tcp:8180 tcp:8180
    if ($LASTEXITCODE -ne 0) { throw 'Firestore port forwarding failed.' }
    & $adbPath -s $Device reverse tcp:9099 tcp:9099
    if ($LASTEXITCODE -ne 0) { throw 'Auth port forwarding failed.' }
    & flutter test --no-pub integration_test/roster_android_test.dart -d $Device
    $testExitCode = $LASTEXITCODE
} finally {
    & $adbPath -s $Device reverse --remove tcp:8180
    & $adbPath -s $Device reverse --remove tcp:9099
}
exit $testExitCode
