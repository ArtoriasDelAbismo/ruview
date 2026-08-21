
## To create a venv in wsl use:
```bash
    python3 -m venv venv && source venv/bin/activate
```

## To create a venv in powershell use:
  ```bash
    python -m venv venv; venv\Scripts\Activate.ps1
  ```

## To install requirements run:
```bash
    pip install -r requirements-minimal.txt
```

## Share USB from Windows to Linux 
- Install usbipd tool in powershell 
Run as admin:
```bash
  winget install -e --id dorssel.usbipd-win
```
- List available connected usb, bind and attach the desired one:
```bash
  usbipd list
  usbipd bind --busid 1-1 (or desired id)
  usbipd attach --wsl --busid 1-1
```
**Note:** `attach` does not persist across a physical unplug/replug of the board.
Every time the ESP32 is disconnected and reconnected (including power-cycling it,
see below), `/dev/ttyACM0` disappears from WSL until you run
`usbipd attach --wsl --busid <id>` again. `bind` only needs to be done once.
- List usb devices on debian based distros
Install usbutils package:
```bash
  sudo apt install usbutils -y
```
List connected devices
```bash
  lsusb
```

## Flash firmware on esp32-c6 node
```
python -m esptool --chip esp32c6 --port /dev/ttyACM0 --baud 460800 \
  write-flash --flash-mode dio --flash-size 4MB \
  0x0     core/firmware/esp32-csi-node/release_bins/c6-adr110/bootloader.bin \
  0x8000  core/firmware/esp32-csi-node/release_bins/c6-adr110/partition-table.bin \
  0xf000  core/firmware/esp32-csi-node/release_bins/c6-adr110/ota_data_initial.bin \
  0x20000 core/firmware/esp32-csi-node/release_bins/c6-adr110/esp32-csi-node.bin

```

## Flash firmware on esp32-s3 node
```
    python -m esptool --chip esp32s3 --port /dev/ttyACM0 --baud 460800 \
  write-flash --flash-mode dio --flash-size 8MB \
  0x0     core/firmware/esp32-csi-node/release_bins/bootloader.bin \
  0x8000  core/firmware/esp32-csi-node/release_bins/partition-table.bin \
  0xf000  core/firmware/esp32-csi-node/release_bins/ota_data_initial.bin \
  0x20000 core/firmware/esp32-csi-node/release_bins/esp32-csi-node.bin
```

## 1. To initialize sensing server run:
```bash
    docker run -p 3000:3000 -p 3001:3001 -p 5005:5005/udp -e RUVIEW_ALLOW_UNAUTHENTICATED=1 ruvnet/wifi-densepose:latest # ---- USE THIS ----

    # ---- OR, if you need to reach the dashboard/API from another device on the LAN ----
    docker run -p 3000:3000 -p 3001:3001 -p 5005:5005/udp \
  -e RUVIEW_ALLOW_UNAUTHENTICATED=1 \
  -e SENSING_ALLOWED_HOSTS=192.168.0.112:3000,192.168.0.112:3001,192.168.0.112 \
  ruvnet/wifi-densepose:latest
```
Replace `192.168.0.112` with your own machine's LAN IP (`ipconfig` on Windows —
use the WiFi/Ethernet adapter's address, not the `vEthernet (WSL)` one). Without
this allowlist, the server rejects any request whose `Host` header isn't
localhost with "Host header not in allowlist (DNS-rebinding defense)".

**If `docker run` fails with `Bind for 0.0.0.0:5005 failed: port is already
allocated`:** a container from an earlier run is still up and holding that
port (env vars like `SENSING_ALLOWED_HOSTS` require a restart to apply, so
it's easy to forget one is still running). Find and stop it, then re-run:
```bash
docker ps
docker stop <container name or id>
```

### If running native Docker inside WSL2 (not Docker Desktop): forward the ports to Windows

Check which one you have:
```bash
docker info | grep "Operating System"
```
If it reports your WSL distro's OS (e.g. "Debian GNU/Linux") rather than
"Docker Desktop", the container's ports are only reachable from inside WSL2 —
**nothing on your physical LAN, including the ESP32 nodes, can reach it**
until you forward the ports from Windows. WSL2's default NAT networking only
auto-forwards `localhost` traffic from Windows into WSL2; it does not forward
traffic arriving at your Windows machine's real LAN IP from another device.

From an elevated (Administrator) PowerShell, run both of these every time
Windows/WSL restarts (the WSL2 internal IP changes on every restart):
```powershell
powershell -ExecutionPolicy Bypass -File \\wsl.localhost\<distro>\path\to\ruview\scripts\wsl-portproxy.ps1
```
This forwards TCP 3000/3001 via `netsh portproxy` and opens matching firewall
rules. Then, in a **separate** PowerShell window that you leave running for
as long as you want live CSI data, forward the UDP CSI stream (needed because
`netsh portproxy` does not support UDP on some Windows 10 builds):
```powershell
powershell -ExecutionPolicy Bypass -File \\wsl.localhost\<distro>\path\to\ruview\scripts\wsl-udp-relay.ps1
```
Replace `<distro>` with your WSL distro name (`wsl -l` to check) and the path
with your actual checkout location.

**If either script fails with `Could not determine WSL2 IP` and a garbled
hex dump:** this is `wsl.exe`'s UTF-16LE stdout getting mis-decoded by
PowerShell (mojibake) — it can happen inconsistently depending on console
codepage/elevation/how the script was invoked. Both scripts set
`$env:WSL_UTF8 = "1"` before calling `wsl hostname -I`, which tells `wsl.exe`
to emit plain UTF-8 instead and avoids this. If you're running an older copy
of these scripts without that line, re-pull/update them.


## 2. Once the firmware is flashed proceed with provisioning

First install the NVS partition generator (without it, the script falls back
to writing an unencrypted `nvs_config.csv` with your WiFi password in
plaintext, and does not flash anything):
```bash
pip install esp-idf-nvs-partition-gen
```

The easiest way to write NVS settings:

```bash
python3 core/firmware/esp32-csi-node/provision.py --port /dev/ttyACM0 \
  --ssid "network name(NO 5G)" --password "password" \
  --target-ip 192.168.0.112   to give the node a new id add: --node-id <0-255>
```
`--target-ip` must be your machine's real LAN IP (see the note above), not a
WSL-internal address. `--node-id` is stored as a single byte on the device —
values outside 0-255 silently overflow. Use a distinct id per node (e.g. `1`,
`2`, ...) so they show up separately in `/api/v1/nodes`.

Usefull commands to preview network data on windows:
- List available networks
```bash
  netsh wlan show profiles
```
- Show info of a particular network
```bash
  netsh wlan show profile name="YourNetworkName" key=clear
```

## After flashing and provisioning the board needs to be unplugged and re-plugged

This is a known firmware quirk (see `core/docs/TROUBLESHOOTING.md` #1): the
node can associate with WiFi and look healthy while the CSI callback never
actually fires, so `yield=0pps` forever in the serial log and no data reaches
the server. Physically unplug the USB cable, wait ~2s, replug it — then
**re-run `usbipd attach`** (see note above) since replugging drops the WSL
passthrough. If a physical unplug doesn't fix it, try a DTR reset instead:
`python -m serial.tools.miniterm --dtr 0 /dev/ttyACM0 115200` then Ctrl+C.
Confirm it worked by watching for `csi_collector: CSI cb #...` lines and
`yield=` climbing above 0 in the serial monitor.

## 3. Serial monitoring
```
    python3 -m serial.tools.miniterm /dev/ttyACM0 115200

```

## 4. Assign TDM slots to nodes

```bash
  python3 core/firmware/esp32-csi-node/provision.py --port /dev/ttyACM0 --tdm-slot 0 --tdm-total 2

  One slot for every node and total number of nodes to use
```

  


