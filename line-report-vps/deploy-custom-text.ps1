$ErrorActionPreference = 'Stop'

$scheduler = Join-Path $PSScriptRoot 'src\scheduler.mjs'
$sshKey = Join-Path $env:USERPROFILE '.ssh\linebot_bkns_ed25519_v3'
$server = 'root@42.96.13.127'
$port = '26266'
$staged = '/tmp/dmx-scheduler-custom-text.mjs'

if (-not (Test-Path -LiteralPath $scheduler -PathType Leaf)) {
    throw "Scheduler file missing: $scheduler"
}
if (-not (Test-Path -LiteralPath $sshKey -PathType Leaf)) {
    throw "SSH key missing: $sshKey"
}

& node --check $scheduler
if ($LASTEXITCODE -ne 0) { throw 'Scheduler syntax check failed.' }

$sshOptions = @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=8', '-o', 'StrictHostKeyChecking=yes', '-i', $sshKey, '-p', $port)
$scpOptions = @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=8', '-o', 'StrictHostKeyChecking=yes', '-i', $sshKey, '-P', $port)
& scp @scpOptions $scheduler "$($server):$staged"
if ($LASTEXITCODE -ne 0) { throw 'Cannot upload scheduler to VPS; live timer was not changed.' }

$deploy = 'node --check /tmp/dmx-scheduler-custom-text.mjs && mkdir -p /opt/dmx-line-report/backup-20261126 && cp -p /opt/dmx-line-report/src/scheduler.mjs /opt/dmx-line-report/backup-20261126/scheduler.mjs && install -m 644 /tmp/dmx-scheduler-custom-text.mjs /opt/dmx-line-report/src/scheduler.mjs.new && mv -f /opt/dmx-line-report/src/scheduler.mjs.new /opt/dmx-line-report/src/scheduler.mjs && systemctl restart dmx-line-report.timer && systemctl is-active dmx-line-report.timer'
& ssh @sshOptions $server $deploy
if ($LASTEXITCODE -ne 0) { throw 'VPS deployment failed; inspect service and backup before retrying.' }

Write-Output 'Scheduler deployed and VPS timer is active.'
