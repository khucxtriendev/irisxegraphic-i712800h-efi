#!/usr/bin/env python3
"""Manual two-component graphics installation, with staging and rollback."""
import datetime
import hashlib
import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def tree_hash(folder):
    return {str(p.relative_to(folder)): ("symlink:" + os.readlink(p) if p.is_symlink()
            else hashlib.sha256(p.read_bytes()).hexdigest())
            for p in sorted(folder.rglob("*")) if p.is_file() or p.is_symlink()}


def verify_signature(folder):
    subprocess.run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(folder)], check=True)


def install_transaction(updates, backup, verify=verify_signature):
    """Stage every component before the first mutation; restore both on failure."""
    backup.mkdir(parents=True, exist_ok=False)
    stages = []
    journal = backup / "transaction.json"

    def record(state):
        journal.write_text(json.dumps({"state": state, "components": [
            {"name": tag, "destination": str(dest), "stage": str(stage)}
            for tag, source, dest, stage in stages]}, indent=2) + "\n")

    try:
        for tag, source, dest in updates:
            if not source.is_dir() or not dest.is_dir() or dest.is_symlink():
                raise RuntimeError(f"Thiếu bundle hoặc đích là symlink: {dest}")
            shutil.copytree(dest, backup / tag, symlinks=True)
            if tree_hash(dest) != tree_hash(backup / tag):
                raise RuntimeError(f"Backup không khớp: {tag}")
            stage = Path(tempfile.mkdtemp(prefix=".p1-stage-", dir=dest.parent))
            stages.append((tag, source, dest, stage))
            shutil.copytree(source, stage / "new", symlinks=True)
            verify(stage / "new")
            if tree_hash(source) != tree_hash(stage / "new"):
                raise RuntimeError(f"Bản stage không khớp: {tag}")
        record("staged")
        for tag, source, dest, stage in stages:
            # Detect edits made after the backup, before replacing this component.
            if tree_hash(dest) != tree_hash(backup / tag):
                raise RuntimeError(f"Bundle đích vừa bị thay đổi: {tag}")
            dest.rename(stage / "old")
            (stage / "new").rename(dest)
            verify(dest)
            if tree_hash(source) != tree_hash(dest):
                raise RuntimeError(f"Nội dung cài không khớp: {tag}")
        record("installed; restart required")
    except BaseException:
        failures = []
        for tag, source, dest, stage in reversed(stages):
            try:
                if (stage / "old").exists():
                    if dest.exists():
                        dest.rename(stage / "failed-new")
                    (stage / "old").rename(dest)
                    if tree_hash(dest) != tree_hash(backup / tag):
                        raise RuntimeError("Restored contents differ from backup")
            except Exception as error:
                failures.append(f"{tag}: {error}")
        record("rollback failed: " + "; ".join(failures) if failures else "rolled back; no components installed")
        if failures:
            raise RuntimeError(f"Cần phục hồi từ {backup}: {'; '.join(failures)}")
        raise
    else:
        for tag, source, dest, stage in stages:
            shutil.rmtree(stage)


def main():
    if sys.argv[1:] not in ([], ["--check"]):
        raise SystemExit("Usage: cai-dat-nhanh.sh [--check]")
    efi = Path("/Volumes/1401/EFI")
    config_path = efi / "OC/config.plist"
    installed = plistlib.loads(config_path.read_bytes())
    candidate = plistlib.loads((ROOT / "EFI/OC/config.plist").read_bytes())
    if installed["PlatformInfo"]["Generic"] != candidate["PlatformInfo"]["Generic"]:
        raise SystemExit("EFI trên 1401 có danh tính khác bộ này; dừng trước khi ghi.")
    active = [e["BundlePath"] for e in installed["Kernel"]["Add"] if e["Enabled"]]
    if "NootedGreen.kext" not in active or "WhateverGreen.kext" in active:
        raise SystemExit("Cấu hình đích phải bật NootedGreen và tắt WhateverGreen.")
    igpu_path = "PciRoot(0x0)/Pci(0x2,0x0)"
    apple_guid = "7C436110-AB2A-4BBB-A880-FE41995C9F82"
    target_edid = installed["DeviceProperties"]["Add"].get(igpu_path, {}).get("AAPL00,override-no-connect")
    expected_edid = candidate["DeviceProperties"]["Add"][igpu_path]["AAPL00,override-no-connect"]
    target_args = installed["NVRAM"]["Add"][apple_guid]["boot-args"].split()
    if target_edid != expected_edid or any(a.split("=", 1)[0] == "ngreen-dmc" for a in target_args):
        raise SystemExit("Chưa có cấu hình R3 trên EFI đích. Chép trọn EFI R3 lên USB thử theo docs/CAI-DAT.md; trình cập nhật hai driver không áp dụng EDID/boot-args.")
    graphics = ROOT / ("Graphics" if (ROOT / "Graphics").is_dir() else "build/userland")
    kext = ROOT / "EFI/OC/Kexts/NootedGreen.kext"
    metal = graphics / "AppleIntelTGLGraphicsMTLDriver.bundle"
    # Validate OS/driver versions and source Metal signature without installation.
    subprocess.run(["/bin/bash", str(ROOT / "scripts/install-graphics.command"), "--check"], check=True)
    verify_signature(kext)
    build = json.loads((ROOT / "reports/build-release.json").read_text())
    key = "EFI/OC/Kexts/NootedGreen.kext/Contents/MacOS/NootedGreen"
    if hashlib.sha256((ROOT / key).read_bytes()).hexdigest() != build["artifacts"][key]:
        raise SystemExit("Kext nguồn khác hash của bản build.")
    print("Sẽ cập nhật NootedGreen trên /Volumes/1401 và trọn Metal bundle/libxedrv trong /Library.", flush=True)
    print("Giữ nguyên config.plist, OpenCore, các kext ngoại vi và shader compiler đang cài.", flush=True)
    if sys.argv[1:] == ["--check"]:
        print("Preflight PASS; chưa ghi hoặc cài gì.")
        return
    if os.geteuid():
        os.execv("/usr/bin/sudo", ["sudo", sys.executable, str(Path(__file__).resolve())])
    backup = ROOT / "Backups" / ("quick-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f"))
    updates = [("NootedGreen.kext", kext, efi / "OC/Kexts/NootedGreen.kext"),
               ("Metal.bundle", metal, Path("/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle"))]
    install_transaction(updates, backup)
    print(f"Đã cài cả hai phần. Backup và nhật ký: {backup}")
    print("RESTART máy và boot /Volumes/1401 để áp dụng trọn bộ thay đổi đồ họa. Không tự khởi động lại.")


if __name__ == "__main__":
    try:
        main()
    except (Exception, KeyboardInterrupt) as error:
        raise SystemExit(f"DỪNG: {error}")
