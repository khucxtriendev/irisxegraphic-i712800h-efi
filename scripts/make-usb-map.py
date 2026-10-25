#!/usr/bin/env python3
"""Preserve observed ports and identify confirmed internal devices on this P1."""
import json
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ports = {}
observed_internal = {6: "Goodix fingerprint 27C6:6594", 8: "UVC camera 174F:1812",
                     10: "Intel Bluetooth 8087:0033"}
for number in range(1, 16):
    label = f"HS{number:02}" if number <= 12 else f"SS{number - 12:02}"
    # External connector types are provisional until USB2/USB3 physical-port tests.
    ports[label] = {"port": number.to_bytes(4, "little"),
                    "UsbConnector": 255 if number in observed_internal else 0 if number <= 12 else 3}

common = {"CFBundleIdentifier": "com.dhinakg.USBToolBox.kext", "IOClass": "USBToolBox",
          "IOMatchCategory": "USBToolBox", "IOProviderClass": "IOPCIDevice"}
info = {
    "CFBundleDevelopmentRegion": "en", "CFBundleIdentifier": "com.kxt.P1Gen5.USBMap",
    "CFBundleInfoDictionaryVersion": "6.0", "CFBundleName": "P1Gen5USBMap",
    "CFBundlePackageType": "KEXT", "CFBundleShortVersionString": "1.0.0",
    "CFBundleVersion": "1.0.0", "OSBundleRequired": "Root",
    "OSBundleLibraries": {"com.dhinakg.USBToolBox.kext": "1.0.0"},
    "IOKitPersonalities": {
        "P1 PCH 51ED": {**common, "IOPCIPrimaryMatch": "0x51ed8086",
                        "IOProviderMergeProperties": {"port-count": (15).to_bytes(4, "little"),
                                                      "ports": ports}},
        # Keep enumeration on the separately observed Thunderbolt USB controller.
        # Its physical USB-C orientation/companion mapping has not been measured.
        "P1 Thunderbolt 1138": {**common, "IOPCIPrimaryMatch": "0x11388086"},
    },
}
out = ROOT / "EFI/OC/Kexts/P1Gen5USBMap.kext/Contents/Info.plist"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(plistlib.dumps(info, sort_keys=False))
(ROOT / "reports/usb-port-map.json").write_text(json.dumps({
    "source": "IORegistry of this P1, 2026-10-25; old EFI session",
    "pch": {"pci_id": "8086:51ED", "pci_address": "0:20:0", "usb2_ports": list(range(1, 13)),
            "usb3_ports": [13, 14, 15], "preserved_port_count": 15,
            "confirmed_internal": observed_internal, "external_connector_types_verified": False},
    "thunderbolt": {"pci_id": "8086:1138", "pci_address": "8:0:0",
                    "mode": "preserve enumeration; no custom port map"},
    "physical_connector_map_verified": False, "boot_tested": False,
}, indent=2) + "\n")
print("Created P1 USB map: all 15 observed PCH ports retained; HS06/08/10 internal.")
