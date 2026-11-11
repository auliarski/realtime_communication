$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidSdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$emulatorExe = Join-Path $androidSdk 'emulator\emulator.exe'
$adbExe = Join-Path $androidSdk 'platform-tools\adb.exe'

if (-not (Test-Path $emulatorExe)) {
    Write-Error "Android Emulator tidak ditemukan di $emulatorExe. Pastikan Android Studio dan Android SDK sudah terinstall."
    exit 1
}

$avdName = 'Medium_Phone_API_36.1'

Write-Host "Mengecek emulator '$avdName'..."
& $emulatorExe -list-avds | Out-String | % { $_.Trim() } | ForEach-Object {
    if ($_ -eq $avdName) {
        $found = $true
    }
}

if (-not $found) {
    Write-Error "Emulator '$avdName' tidak tersedia. Jalankan Android Studio > Device Manager untuk membuat AVD terlebih dahulu."
    exit 1
}

Write-Host "Menjalankan emulator..."
Start-Process $emulatorExe -ArgumentList "-avd $avdName" -NoNewWindow

Write-Host "Menunggu emulator siap..."
for ($i = 0; $i -lt 60; $i++) {
    $deviceList = & $adbExe devices 2>$null
    if ($deviceList -match 'emulator-5554\s+device') {
        Write-Host "Emulator siap."
        break
    }
    Start-Sleep -Seconds 2
}

$deviceList = & $adbExe devices 2>$null
if ($deviceList -notmatch 'emulator-5554\s+device') {
    Write-Error "Emulator tidak merespons dalam waktu yang ditentukan. Cek AVD dan status emulator secara manual."
    exit 1
}

Push-Location $projectRoot
try {
    Write-Host "Menjalankan Flutter di emulator..."
    flutter run -d emulator-5554
}
finally {
    Pop-Location
}
