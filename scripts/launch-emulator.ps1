# Launch Android Emulator (optimized for Windows 11 + Hyper-V)
# Usage: .\scripts\launch-emulator.ps1 [emulator-name]

param(
    [string]$EmulatorName = "Pixel_8_Pro"
)

$androidHome = "C:\Users\olubi\AppData\Local\Android\sdk"
$emulatorPath = "$androidHome\emulator\emulator.exe"

Write-Host "🚀 Launching Android Emulator: $EmulatorName" -ForegroundColor Cyan
Write-Host "⏳ This may take 2-3 minutes on first boot..." -ForegroundColor Yellow

# Kill any existing emulator processes
Get-Process | Where-Object {$_.ProcessName -like "*qemu*"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Launch emulator with optimized settings for Hyper-V
& $emulatorPath -avd $EmulatorName `
    -gpu auto `
    -no-boot-anim `
    -no-snapshot-load `
    -accel on

Write-Host "✅ Emulator process started" -ForegroundColor Green
Write-Host "Run 'flutter devices' to check when it's ready" -ForegroundColor Cyan
