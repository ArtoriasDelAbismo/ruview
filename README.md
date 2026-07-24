
## To create a venv use:
```bash
    python3 -m venv venv && source venv/bin/activate
```

## To install requirements run:
```bash
    pip install -r requirements-minimal.txt
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
```


## 2. Once the firmware is flashed proceed with provisioning

The easiest way to write NVS settings:

```bash
python3 core/firmware/esp32-csi-node/provision.py --port /dev/ttyACM0 \
  --ssid "network name(NO 5G)" --password "password" \
  --target-ip 192.168.0.112   to give the node a new id add: --node-id <whatever number>
```

## 3. Serial monitoring
```
    python3 -m serial.tools.miniterm /dev/ttyACM0 115200

```

## Usefull commands

# Show networks on windows
```bash
  netsh wlan show profiles
```

# Show network data on windows
```bash
  netsh wlan show profile name="Somos TLab Amarras" key=clear
```
  


