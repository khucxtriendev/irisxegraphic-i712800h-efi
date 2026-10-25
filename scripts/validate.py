#!/usr/bin/env python3
"""Structural validation and identity checks. Does not replace ocvalidate/boot testing."""
import hashlib
import json
import plistlib
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors = []
checks = 0


def check(ok, label):
    global checks
    checks += 1
    if not ok:
        errors.append(label)


base = plistlib.loads((ROOT / "backup/EFI/OC/config.plist").read_bytes())
configs = [ROOT / "EFI/OC/config.plist", *sorted((ROOT / "profiles").glob("*.plist"))]
for path in configs:
    config = plistlib.loads(path.read_bytes())
    tag = path.relative_to(ROOT).as_posix()
    check(config["PlatformInfo"]["Generic"] == base["PlatformInfo"]["Generic"], f"{tag}: SMBIOS identity unchanged")
    check(config["Kernel"]["Emulate"] == base["Kernel"]["Emulate"], f"{tag}: compatibility CPUID unchanged")
    check(config["ACPI"] == base["ACPI"], f"{tag}: ThinkPad ACPI unchanged")
    active = [x for x in config["Kernel"]["Add"] if x["Enabled"]]
    paths = [x["BundlePath"] for x in active]
    check(len(paths) == len(set(paths)), f"{tag}: duplicate enabled bundles")
    check(not ("WhateverGreen.kext" in paths and "NootedGreen.kext" in paths), f"{tag}: WEG/NootedGreen conflict")
    check(sum(x.endswith("VoodooInput.kext") for x in paths) == 1, f"{tag}: exactly one VoodooInput")
    bundles = []
    for entry in active:
        kext = ROOT / "EFI/OC/Kexts" / entry["BundlePath"]
        for key in ["PlistPath", "ExecutablePath"]:
            if entry[key]:
                check((kext / entry[key]).is_file(), f"{tag}: missing {entry['BundlePath']}/{entry[key]}")
        info_path = kext / entry["PlistPath"]
        if not info_path.exists():
            continue
        info = plistlib.loads(info_path.read_bytes())
        bundles.append((info.get("CFBundleIdentifier"), info.get("OSBundleLibraries", {})))
        if entry["ExecutablePath"] and (kext / entry["ExecutablePath"]).is_file():
            data = (kext / entry["ExecutablePath"]).read_bytes()
            check(len(data) > 16, f"{tag}: empty executable {entry['BundlePath']}")
            check(data[:4] in [b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca", b"\xca\xfe\xba\xbf"],
                  f"{tag}: Mach-O header {entry['BundlePath']}")
    ids = [x[0] for x in bundles]
    for i, (identifier, dependencies) in enumerate(bundles):
        for dep in dependencies:
            if dep in ids:
                check(ids.index(dep) < i, f"{tag}: {identifier} precedes dependency {dep}")
    for entry in config["ACPI"]["Add"]:
        if not entry["Enabled"]:
            continue
        f = ROOT / "EFI/OC/ACPI" / entry["Path"]
        check(f.is_file(), f"{tag}: missing AML {f.name}")
        if f.is_file():
            data = f.read_bytes()
            check(len(data) >= 36 and data[:4] == b"SSDT", f"{tag}: AML header {f.name}")
            check(struct.unpack_from("<I", data, 4)[0] == len(data), f"{tag}: AML length {f.name}")
            check(sum(data) % 256 == 0, f"{tag}: AML checksum {f.name}")
    for section, folder in [(config["UEFI"]["Drivers"], "Drivers"), (config["Misc"]["Tools"], "Tools")]:
        for entry in section:
            if entry["Enabled"]:
                check((ROOT / "EFI/OC" / folder / entry["Path"]).is_file(), f"{tag}: missing {folder}/{entry['Path']}")
    if "SimpleHDA.kext" in paths:
        check(paths.index("Lilu.kext") < paths.index("AppleALC.kext") < paths.index("SimpleHDA.kext"), f"{tag}: audio load order")
        check("keepsyms=1" in config["NVRAM"]["Add"]["7C436110-AB2A-4BBB-A880-FE41995C9F82"]["boot-args"].split(), f"{tag}: SimpleHDA requires keepsyms")
        props = config["DeviceProperties"]["Add"].get("PciRoot(0x0)/Pci(0x1F,0x3)", {})
        check(props.get("layout-id") == bytes([11, 0, 0, 0]), f"{tag}: HDAS layout-id DATA 11")
        args = config["NVRAM"]["Add"]["7C436110-AB2A-4BBB-A880-FE41995C9F82"]["boot-args"].split()
        check([a for a in args if a.startswith("alcid=")] == ["alcid=11"], f"{tag}: no conflicting audio layout")
    if "P1Gen5USBMap.kext" in paths:
        check("UTBDefault.kext" not in paths, f"{tag}: no competing default USB injector")
        check(paths.index("USBToolBox.kext") < paths.index("P1Gen5USBMap.kext"), f"{tag}: USB map dependency order")
        check(not config["Kernel"]["Quirks"]["XhciPortLimit"], f"{tag}: no obsolete port-limit patch")
        nvram = config["NVRAM"]["Add"]["7C436110-AB2A-4BBB-A880-FE41995C9F82"]
        for key, size in [("bluetoothExternalDongleFailed", 1), ("bluetoothInternalControllerInfo", 14)]:
            check(nvram.get(key) == bytes(size), f"{tag}: Bluetooth {key} DATA")
            check(key in config["NVRAM"]["Delete"]["7C436110-AB2A-4BBB-A880-FE41995C9F82"], f"{tag}: replace stale Bluetooth NVRAM")
        check(all(k in paths for k in ["IntelBluetoothFirmware.kext", "IntelBTPatcher.kext", "BlueToolFixup.kext"]), f"{tag}: Intel Bluetooth stack complete")
        check("IntelBluetoothInjector.kext" not in paths and "BrcmBluetoothInjector.kext" not in paths, f"{tag}: no legacy Bluetooth injector")

check((ROOT / "EFI/BOOT/BOOTx64.efi").is_file(), "fallback bootloader exists")
# Preserve the source snapshot's current input/GPIO and USB behavior.
for file in (ROOT / "backup/EFI/OC/Kexts/VoodooI2C.kext").rglob("*"):
    if file.is_file():
        dest = ROOT / "EFI/OC/Kexts/VoodooI2C.kext" / file.relative_to(ROOT / "backup/EFI/OC/Kexts/VoodooI2C.kext")
        check(dest.is_file() and dest.read_bytes() == file.read_bytes(), f"input driver preserved: {file.name}")
for name in ["UTBDefault.kext/Contents/Info.plist"]:
    check((ROOT / "EFI/OC/Kexts" / name).read_bytes() == (ROOT / "backup/EFI/OC/Kexts" / name).read_bytes(), f"baseline component preserved: {name}")
new_binary = ROOT / "vendor/iris-xe/build/NootedGreen.kext/Contents/MacOS/NootedGreen"
check(new_binary.is_file() and new_binary.read_bytes() == (ROOT / "EFI/OC/Kexts/NootedGreen.kext/Contents/MacOS/NootedGreen").read_bytes(), "EFI contains the newly built NootedGreen")
usb_map = plistlib.loads((ROOT / "EFI/OC/Kexts/P1Gen5USBMap.kext/Contents/Info.plist").read_bytes())
pch = usb_map["IOKitPersonalities"]["P1 PCH 51ED"]
ports = pch["IOProviderMergeProperties"]["ports"]
check(len(ports) == 15, "all observed PCH ports retained within 15-port limit")
check(sorted(int.from_bytes(v["port"], "little") for v in ports.values()) == list(range(1, 16)), "PCH port IDs exact and unique")
check(ports["HS10"]["UsbConnector"] == 255, "Intel Bluetooth HS10 internal")
check(pch["IOPCIPrimaryMatch"] == "0x51ed8086", "USB map matches actual PCH controller")
check("IOProviderMergeProperties" not in usb_map["IOKitPersonalities"]["P1 Thunderbolt 1138"], "Thunderbolt enumeration retained")
manifest = {str(f.relative_to(ROOT / "EFI")): hashlib.sha256(f.read_bytes()).hexdigest()
            for f in sorted((ROOT / "EFI").rglob("*")) if f.is_file()}
(ROOT / "reports/efi-sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
result = dict(checks=checks, errors=errors, passed=not errors,
              ocvalidate="not available in local tools; not run", boot_tested=False,
              hardware_feature_parity_verified=False)
(ROOT / "reports/validation.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, ensure_ascii=False, indent=2))
sys.exit(bool(errors))
