# FSTQ — установка и обновление на Windows одной командой (PowerShell):
#   irm https://raw.githubusercontent.com/Shevmic/fstq-releases/main/install.ps1 | iex
# Берёт последнюю версию из GitHub Releases, ставит тихо (для текущего пользователя) и запускает.
$ErrorActionPreference = 'Stop'
$repo = 'Shevmic/fstq-releases'
Write-Host 'FSTQ: ищу последнюю версию...'
$rel = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -Headers @{ 'User-Agent' = 'FSTQ' }
$asset = $rel.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1
if (-not $asset) { throw "Не нашёл установщик .exe в $repo" }
$exe = Join-Path $env:TEMP $asset.name
Write-Host "FSTQ $($rel.tag_name): скачиваю $([math]::Round($asset.size / 1MB)) МБ..."
$ProgressPreference = 'SilentlyContinue'  # без полосы прогресса качает в разы быстрее
Invoke-WebRequest $asset.browser_download_url -OutFile $exe
# открытое приложение — закрыть (очередь сохранена и продолжится после запуска)
Get-Process FSTQ -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host 'Ставлю...'
Start-Process $exe -ArgumentList '/S' -Wait
Remove-Item $exe -ErrorAction SilentlyContinue
$app = Join-Path $env:LOCALAPPDATA 'Programs\FSTQ\FSTQ.exe'
# запускаем через explorer — без прав администратора: иначе Windows не даёт перетаскивать файлы из Проводника (UIPI)
if (Test-Path $app) { Write-Host "Готово: FSTQ $($rel.tag_name). Запускаю."; Start-Process explorer.exe -ArgumentList "`"$app`"" }
else { Write-Host 'Установлено. Запусти FSTQ из меню «Пуск».' }
