<#
Forwards the sensing-server TCP ports (3000 HTTP, 3001 WebSocket) from the
Windows host into WSL2, so LAN devices can reach the docker container
running inside WSL2.

WSL2's default NAT networking only auto-forwards localhost traffic from
Windows into WSL2 - it does NOT forward inbound LAN traffic hitting the
Windows machine's real IP. The WSL2 internal IP also changes on every
restart, so this must be re-run each time WSL/Windows restarts.

NOTE: UDP 5005 (ESP32 CSI ingest) is NOT handled here - this Windows
build's netsh portproxy rejects protocol=udp ("El parametro no es
correcto"). Run wsl-udp-relay.ps1 alongside this script to forward the
CSI UDP stream instead.

Run from an elevated (Administrator) PowerShell:
    powershell -ExecutionPolicy Bypass -File wsl-portproxy.ps1
#>

$ports = @(
    @{ Port = 3000; Protocol = "tcp" },
    @{ Port = 3001; Protocol = "tcp" }
)

# wsl.exe defaults to UTF-16LE stdout, which gets mis-decoded (mojibake) by
# PowerShell depending on console codepage/elevation/invocation context -
# fiddling with [Console]::OutputEncoding is not reliable across all of
# those. WSL_UTF8=1 tells wsl.exe itself to emit plain UTF-8 instead,
# sidestepping the guessing game entirely.
$env:WSL_UTF8 = "1"
$wslRaw = (wsl hostname -I) -join " "
$wslIp = [regex]::Match($wslRaw, '\d{1,3}(\.\d{1,3}){3}').Value
if (-not $wslIp) {
    
    $bytesHex = ([System.Text.Encoding]::UTF8.GetBytes($wslRaw) | ForEach-Object { $_.ToString("x2") }) -join " "
    Write-Error "Could not determine WSL2 IP. Raw output length=$($wslRaw.Length) hex=[$bytesHex]. Try re-running this script."
    exit 1
}
Write-Host "WSL2 IP: $wslIp"

foreach ($p in $ports) {
    $port = $p.Port
    $proto = $p.Protocol

    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 protocol=$proto | Out-Null
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIp protocol=$proto | Out-Null

    $ruleName = "WSL2 RuView $proto $port"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol $proto.ToUpper() -LocalPort $port | Out-Null
    }
}

Write-Host "`nActive portproxy rules:"
netsh interface portproxy show v4tov4
