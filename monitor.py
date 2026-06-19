import requests
import time
import os

URL = "http://localhost:3000/api/v1/sensing/latest"

def clear():
    os.system('clear')

while True:
    try:
        r = requests.get(URL, timeout=2)
        d = r.json()

        nf = d["node_features"][0]
        cls = nf["classification"]
        feat = nf["features"]
        amp = d["nodes"][0]["amplitude"]

        clear()
        print(f"=== RuView monitor (tick {d['tick']}) ===\n")
        print(f"presence:      {cls['presence']}")
        print(f"motion_level:  {cls['motion_level']}")
        print(f"confidence:    {cls['confidence']:.2f}")
        print(f"rssi_dbm:      {nf['rssi_dbm']:.1f}")
        print(f"motion_power:  {feat['motion_band_power']:.1f}")
        print(f"breath_power:  {feat['breathing_band_power']:.1f}")
        print(f"variance:      {feat['variance']:.1f}")
        print()
        print(f"amplitude (primeros 20 subcarriers):")
        bar_max = max(amp[:20]) or 1
        for i, v in enumerate(amp[:20]):
            bar = "#" * int((v / bar_max) * 30)
            print(f"  sc{i:02d} {v:6.1f} {bar}")

    except Exception as e:
        print(f"Error: {e}")

    time.sleep(1)
