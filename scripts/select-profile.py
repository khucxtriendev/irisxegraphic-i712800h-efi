#!/usr/bin/env python3
"""Select a config inside this package only. Does not touch a mounted ESP."""
import argparse
import hashlib
import os
import plistlib
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("profile", choices=["baseline", "thinkpad", "sensors-trial", "decode-trial", "install-trial"])
args = parser.parse_args()
source = root / "profiles" / f"config-{args.profile}.plist"
data = source.read_bytes()
plistlib.loads(data)
dest = root / "EFI/OC/config.plist"
temp = dest.with_name("config.plist.new")
with temp.open("wb") as f:
    f.write(data)
    f.flush()
    os.fsync(f.fileno())
os.replace(temp, dest)
print(f"Package config: {args.profile}; SHA-256 {hashlib.sha256(data).hexdigest()}")
print("Only this package changed. Run scripts/validate.py before copying EFI.")
