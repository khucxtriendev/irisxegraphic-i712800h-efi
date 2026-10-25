#!/usr/bin/env python3
"""Create a separate trial EFI using the NootedGreen built from the pinned source."""
import hashlib
import json
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "vendor/iris-xe/build/NootedGreen.kext"
binary = source / "Contents/MacOS/NootedGreen"
if not binary.is_file():
    raise SystemExit("Build vendor/iris-xe/build-nootedgreen.sh first.")
out = root / "build/EFI-upstream"
if out.exists():
    raise SystemExit(f"Already exists: {out}; choose a new output before rebuilding.")
shutil.copytree(root / "EFI", out)
shutil.rmtree(out / "OC/Kexts/NootedGreen.kext")
shutil.copytree(source, out / "OC/Kexts/NootedGreen.kext")
manifest = {str(f.relative_to(out)): hashlib.sha256(f.read_bytes()).hexdigest()
            for f in sorted(out.rglob("*")) if f.is_file()}
(root / "reports/upstream-efi-sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"Created {out}; copy as an EFI folder on a separate test USB.")
print("Only NootedGreen differs from the main candidate. Boot testing is still required.")
