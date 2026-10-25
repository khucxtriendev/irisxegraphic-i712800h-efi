#!/usr/bin/env python3
"""Record source/artifact provenance after the local build and signature checks."""
import datetime
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
sources = {str(p.relative_to(ROOT)): digest(p)
           for folder in [ROOT / "vendor/iris-xe/src/NootedGreen", ROOT / "vendor/iris-xe/macos/src"]
           for p in sorted(folder.rglob("*")) if p.is_file()}
artifacts = ["EFI/OC/Kexts/NootedGreen.kext/Contents/MacOS/NootedGreen",
             "build/userland/libxedrv.dylib",
             "build/userland/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/AppleIntelTGLGraphicsMTLDriver",
             "build/userland/xe.bundle/Contents/MacOS/libIGIL-Metal.dylib"]
report = {"created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
          "target_os_build": "25G241", "target_driver_version": "16.0.32",
          "sources": sources, "artifacts": {p: digest(ROOT / p) for p in artifacts},
          "production_build": "success", "codesign_verify_new_components": "passed",
          "ocvalidate": "unavailable locally; shell DNS unavailable; not run",
          "boot_tested": False, "installed_to_boot_efi": False, "installed_to_system": False,
          "dock_badge_visual_fix_verified": False}
(ROOT / "reports/build-release.json").write_text(json.dumps(report, indent=2) + "\n")
manifest = {str(p.relative_to(ROOT)): digest(p)
            for folder in [ROOT / "build/userland", ROOT / "build/video-decode", ROOT / "vendor/iris-xe/build/HookCase.kext"]
            for p in sorted(folder.rglob("*")) if p.is_file()}
(ROOT / "reports/payload-sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
print("Recorded source and freshly built payload hashes.")
