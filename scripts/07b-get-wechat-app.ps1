# Fetch the server edition of xiaoqian-wechat (DeepSeek API, owner relay, headless-server fixes).
param([string]$Repo = 'https://github.com/AnthonyZZH/xiaoqian-wechat.git', [string]$Branch = 'server')
$ErrorActionPreference = 'Stop'
$dst = 'C:\xiaoqian\app\wechat'
$data = 'C:\xiaoqian\data\wechat'
if (@(Get-ChildItem -Force -LiteralPath $dst -ErrorAction SilentlyContinue).Count -ne 0) { throw 'wechat_directory_not_empty' }
& git.exe clone --depth 1 --branch $Branch $Repo $dst
if ($LASTEXITCODE -ne 0) { throw 'wechat_clone_failed' }
if (-not (Test-Path -LiteralPath (Join-Path $dst 'social_brain.py'))) { throw 'not_the_server_edition' }
# Chat history, memory and settings stay outside the app folder and readable by admins only.
New-Item -ItemType Directory -Force -Path $data | Out-Null
& icacls.exe $data /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'wechat_data_acl_failed' }
Write-Output "wechat_app_cloned branch=$Branch commit=$(& git.exe -C $dst rev-parse --short HEAD)"
