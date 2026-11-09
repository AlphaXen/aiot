<#
  두 웹앱을 각각 빌드해서 deploy/mobile, deploy/admin 폴더에 넣습니다.
  각 폴더가 Vercel 프로젝트 하나가 됩니다.

  사용법 (프로젝트 루트에서):
    .\scripts\build_web.ps1              # 둘 다 빌드
    .\scripts\build_web.ps1 mobile       # 모바일 제어 앱만
    .\scripts\build_web.ps1 admin        # 관리자 대시보드만
    .\scripts\build_web.ps1 all -Deploy  # 빌드 후 vercel --prod 까지 실행

  Flutter 경로를 직접 지정하려면: -Flutter "C:\path\to\flutter\bin\flutter.bat"
#>
param(
  [ValidateSet('all', 'mobile', 'admin')] [string]$Target = 'all',
  [string]$Flutter = '',
  [switch]$Deploy
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not $Flutter) {
  $candidates = @(
    $(if ($env:FLUTTER_ROOT) { Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat' }),
    (Join-Path $env:USERPROFILE 'Flutter\flutter\bin\flutter.bat'),
    'flutter'
  ) | Where-Object { $_ }
  $Flutter = $candidates | Where-Object { $_ -eq 'flutter' -or (Test-Path $_) } | Select-Object -First 1
}
Write-Host "Flutter: $Flutter" -ForegroundColor DarkGray

$apps = @{
  mobile = @{ Entry = 'lib/main_mobile.dart'; Title = '캠퍼스 식당';  Short = '캠퍼스 식당' }
  admin  = @{ Entry = 'lib/main_admin.dart';  Title = 'AIoT Console'; Short = 'AIoT Admin' }
}
$targets = if ($Target -eq 'all') { @('mobile', 'admin') } else { @($Target) }

foreach ($t in $targets) {
  $app = $apps[$t]
  $out = "build/web_$t"
  $dest = "deploy/$t"
  Write-Host "`n▶ $t 빌드 중 ($($app.Entry))" -ForegroundColor Cyan

  & $Flutter build web -t $app.Entry -o $out --release --suppress-analytics
  if ($LASTEXITCODE -ne 0) { throw "$t 빌드 실패" }

  # 앱별 제목/매니페스트 이름 바꾸기
  $index = Join-Path $out 'index.html'
  (Get-Content $index -Raw -Encoding utf8) `
    -replace '<title>AIoT</title>', "<title>$($app.Title)</title>" `
    -replace 'content="AIoT"', "content=""$($app.Short)""" |
    Set-Content $index -Encoding utf8 -NoNewline
  $manifest = Join-Path $out 'manifest.json'
  $m = Get-Content $manifest -Raw -Encoding utf8 | ConvertFrom-Json
  $m.name = $app.Title; $m.short_name = $app.Short
  $m.description = $app.Title; $m.background_color = '#F2F2F7'; $m.theme_color = '#3E91FF'
  if ($t -eq 'admin') { $m.orientation = 'any' }
  $m | ConvertTo-Json -Depth 5 | Set-Content $manifest -Encoding utf8

  # deploy 폴더 갱신 (vercel.json, .vercel 링크는 유지)
  New-Item -ItemType Directory -Force $dest | Out-Null
  robocopy $out $dest /MIR /XF vercel.json /XD .vercel /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "$dest 복사 실패" }
  Write-Host "✔ $dest 준비 완료" -ForegroundColor Green

  if ($Deploy) {
    Push-Location $dest
    try { vercel deploy --prod } finally { Pop-Location }
  }
}
$global:LASTEXITCODE = 0
