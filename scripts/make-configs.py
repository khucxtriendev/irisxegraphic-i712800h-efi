#!/usr/bin/env python3
"""Generate local trial configs from the frozen ThinkPad EFI, preserving identity."""
import copy
import json
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPLE = "7C436110-AB2A-4BBB-A880-FE41995C9F82"
ACID = "4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102"
base = plistlib.loads((ROOT / "backup/EFI/OC/config.plist").read_bytes())


def add_args(config, *args):
    values = config["NVRAM"]["Add"][APPLE]["boot-args"].split()
    for value in args:
        if value not in values:
            values.append(value)
    config["NVRAM"]["Add"][APPLE]["boot-args"] = " ".join(values)


def kext_entry(name):
    info = plistlib.loads((ROOT / "EFI/OC/Kexts" / name / "Contents/Info.plist").read_bytes())
    exe = info.get("CFBundleExecutable")
    return dict(Arch="x86_64", BundlePath=name,
                Comment="ThinkPad P1 Gen 5; verify hardware behavior after boot",
                Enabled=True, ExecutablePath="Contents/MacOS/" + exe if exe else "",
                MaxKernel="25.99.99", MinKernel="25.0.0", PlistPath="Contents/Info.plist")


candidate = copy.deepcopy(base)
# These fields label the actual CPU; the kernel's compatibility CPUID is retained.
candidate["NVRAM"]["Add"].setdefault(ACID, {}).update(
    {"revcpu": 1, "revcpuname": "Intel Core i7-12800H"})
candidate["UEFI"]["Output"]["Resolution"] = "Max"
# Upstream defaults this request floor to 1500 MHz for the Dell's i7-1360P.
# Intel specifies 1400 MHz maximum graphics frequency for this i7-12800H.
# This changes the driver's request, not the CPU package PL1/PL2 or hardware fuses.
add_args(candidate, "ngreengtfreq=1400")
# Restore this machine's earlier audio route. Layout 11 is a trial, not a proven fix.
entries = candidate["Kernel"]["Add"]
entries[:] = [x for x in entries if x["BundlePath"] not in ["AppleALC.kext", "SimpleHDA.kext"]]
insert = next(i for i, x in enumerate(entries) if x["BundlePath"] == "Lilu.kext") + 1
entries[insert:insert] = [kext_entry("AppleALC.kext"), kext_entry("SimpleHDA.kext")]
add_args(candidate, "keepsyms=1", "-alcbeta", "alcid=11")
# HDAS is the live ACPI device at PCI 00:1f.3 (8086:51C8). Keep the real ID.
candidate["DeviceProperties"]["Add"].setdefault("PciRoot(0x0)/Pci(0x1F,0x3)", {}).update(
    {"layout-id": (11).to_bytes(4, "little"), "hda-gfx": "onboard-1"})
# Use exactly the Intel stack required on Monterey and newer. Values are DATA,
# and Delete ensures a stale controller cache cannot override Add on first boot.
candidate["NVRAM"]["Add"][APPLE].update({
    "bluetoothExternalDongleFailed": bytes(1),
    "bluetoothInternalControllerInfo": bytes(14),
})
for entry in entries:
    if entry["BundlePath"] == "UTBDefault.kext":
        entry["Enabled"] = False
    if entry["BundlePath"] in ("IntelBluetoothInjector.kext", "BrcmBluetoothInjector.kext"):
        entry["Enabled"] = False
    if entry["BundlePath"] in ("IntelBluetoothFirmware.kext", "IntelBTPatcher.kext", "BlueToolFixup.kext"):
        entry["Enabled"] = True
entries.insert(next(i for i, e in enumerate(entries) if e["BundlePath"] == "USBToolBox.kext") + 1,
               kext_entry("P1Gen5USBMap.kext"))
candidate["Kernel"]["Quirks"]["XhciPortLimit"] = False
# Preserve the machine's matched I2C/GPIO drivers and PS2 TrackPoint path.
# Only one VoodooInput is injected, shared by the enabled input consumers.
for entry in entries:
    if entry["BundlePath"].endswith("VoodooInput.kext"):
        entry["Enabled"] = entry["BundlePath"].startswith("VoodooI2C.kext/")
# Ensure the selected values replace existing NVRAM values on boot.
for guid, names in [(APPLE, ["boot-args", "bluetoothExternalDongleFailed", "bluetoothInternalControllerInfo"]), (ACID, ["revcpu", "revcpuname"])]:
    dest = candidate["NVRAM"]["Delete"].setdefault(guid, [])
    for name in names:
        if name not in dest:
            dest.append(name)

profiles = {"config-baseline.plist": base, "config-thinkpad.plist": candidate}
sensors = copy.deepcopy(candidate)
add_args(sensors, "lilucpu=16")
profiles["config-sensors-trial.plist"] = sensors
decode = copy.deepcopy(candidate)
add_args(decode, "-ngreengva")
profiles["config-decode-trial.plist"] = decode
install = copy.deepcopy(base)
for entry in install["Kernel"]["Add"]:
    if entry["BundlePath"] in ["NootedGreen.kext", "WhateverGreen.kext"]:
        entry["Enabled"] = False
igpu = install["DeviceProperties"]["Add"].get("PciRoot(0x0)/Pci(0x2,0x0)", {})
for key in ["device-id", "AAPL,ig-platform-id"]:
    igpu.pop(key, None)
install["NVRAM"]["Add"][APPLE]["boot-args"] = "-v keepsyms=1 amfi_get_out_of_my_way=1 disablesleep=1"
profiles["config-install-trial.plist"] = install
for name, config in profiles.items():
    (ROOT / "profiles" / name).write_bytes(plistlib.dumps(config, sort_keys=False))
(ROOT / "EFI/OC/config.plist").write_bytes(plistlib.dumps(candidate, sort_keys=False))


def changes(a, b, path=""):
    if type(a) is not type(b):
        return [path]
    if isinstance(a, dict):
        result = []
        for key in sorted(a.keys() | b.keys()):
            result += ([f"{path}/{key}"] if key not in a or key not in b
                       else changes(a[key], b[key], f"{path}/{key}"))
        return result
    if isinstance(a, list):
        return [] if a == b else [path]
    return [] if a == b else [path]


(ROOT / "reports/config-changes.json").write_text(json.dumps(
    {name: changes(base, config) for name, config in profiles.items()}, indent=2) + "\n")
print("Generated ThinkPad trial + baseline, sensors, decode and installer profiles.")
