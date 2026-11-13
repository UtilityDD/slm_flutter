# Run flutter through a limited number of slots, so many agents can work in
# parallel without running out of memory (each flutter test/analyze takes
# 1–1.5 GB; this machine has 16 GB). Every agent must use this instead of
# calling flutter.bat directly:
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tool/flk.ps1 test test/x_test.dart
#   powershell -NoProfile -ExecutionPolicy Bypass -File tool/flk.ps1 analyze lib/features/game/x.dart
#
# Slots: $env:FLK_SLOTS (default 5). A slot is a directory under .flk/ holding
# the owner's PID; a slot whose process has died is reclaimed.
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$FlutterArgs)

$flutter = 'C:\Users\rouma\flutter\bin\flutter.bat'
$root = Split-Path -Parent $PSScriptRoot
$lockDir = Join-Path $root '.flk'
$slots = if ($env:FLK_SLOTS) { [int]$env:FLK_SLOTS } else { 8 }
New-Item -ItemType Directory -Force $lockDir | Out-Null

$mine = $null
$waited = 0
while (-not $mine) {
  for ($i = 1; $i -le $slots; $i++) {
    $slot = Join-Path $lockDir "slot$i"
    try {
      New-Item -ItemType Directory $slot -ErrorAction Stop | Out-Null
      [System.IO.File]::WriteAllText((Join-Path $slot 'pid'), "$PID")
      $mine = $slot
      break
    } catch {
      # Reclaim a slot whose owner is gone.
      $pidFile = Join-Path $slot 'pid'
      if (Test-Path $pidFile) {
        $owner = [int](Get-Content $pidFile -ErrorAction SilentlyContinue)
        if ($owner -and -not (Get-Process -Id $owner -ErrorAction SilentlyContinue)) {
          Remove-Item -Recurse -Force $slot -ErrorAction SilentlyContinue
        }
      } elseif ((Get-Item $slot -ErrorAction SilentlyContinue).CreationTime -lt (Get-Date).AddMinutes(-2)) {
        Remove-Item -Recurse -Force $slot -ErrorAction SilentlyContinue
      }
    }
  }
  if (-not $mine) {
    if ($waited % 30 -eq 0) { Write-Host "flk: all $slots flutter slots busy, waiting..." }
    Start-Sleep -Seconds 2
    $waited += 2
  }
}

try {
  & $flutter @FlutterArgs
  $code = $LASTEXITCODE
} finally {
  Remove-Item -Recurse -Force $mine -ErrorAction SilentlyContinue
}
exit $code
