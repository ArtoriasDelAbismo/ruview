<#
Manually relays UDP :5005 (ESP32 CSI ingest) from the Windows host into
WSL2. Only needed because this Windows build's netsh portproxy rejects
protocol=udp - see wsl-portproxy.ps1 for the TCP ports (3000/3001), which
portproxy handles fine.

Leave this running in its own PowerShell window for as long as you want
the sensing server to receive live CSI data from the nodes. Re-run after
every WSL/Windows restart (it re-resolves the WSL2 IP on start).

Requires the "WSL2 RuView udp 5005" inbound firewall rule created by
wsl-portproxy.ps1's first run. Does not require Administrator.
#>

# See wsl-portproxy.ps1 for why WSL_UTF8=1 is needed: wsl.exe's default
# UTF-16LE stdout gets mis-decoded by PowerShell depending on console
# codepage/elevation/invocation context.
$env:WSL_UTF8 = "1"
$wslRaw = (wsl hostname -I) -join " "
$wslIp = [regex]::Match($wslRaw, '\d{1,3}(\.\d{1,3}){3}').Value
if (-not $wslIp) {
    $chars = ($wslRaw.ToCharArray() | ForEach-Object { [int]$_ }) -join ","
    Write-Error "Could not determine WSL2 IP. Raw output length=$($wslRaw.Length) charcodes=[$chars]. Try re-running this script."
    exit 1
}
$listener = New-Object System.Net.Sockets.UdpClient(5005)
$target = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($wslIp), 5005)
$sender = New-Object System.Net.Sockets.UdpClient

# ${wslIp}: avoids the "$var:" scope-prefix parsing gotcha that silently
# swallows the variable inside double-quoted strings (confirmed via $target
# below, which prints correctly since IPEndPoint.ToString() has no colon
# ambiguity in the interpolation itself).
Write-Host "Relaying UDP :5005 -> ${wslIp}:5005 (target endpoint: $target) (Ctrl+C to stop)"

try {
    while ($true) {
        $remote = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $data = $listener.Receive([ref]$remote)
        $sender.Send($data, $data.Length, $target) | Out-Null
    }
} finally {
    $listener.Close()
    $sender.Close()
}
