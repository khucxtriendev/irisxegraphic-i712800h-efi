#!/bin/bash
# Build only, using the upstream component commands. Never installs into /Library or /System.
# The stock input must be the 16.0.32 sle/ directory already downloaded on this machine.
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_stock="${1:?Usage: build-userland.sh /path/to/stock/sle}"
task_source="$task_root/vendor/iris-xe/macos"
task_output="$task_root/build/userland"
[[ -d "$task_stock/AppleIntelTGLGraphicsMTLDriver.bundle" ]] || { echo "Stock Metal bundle missing" >&2; exit 1; }
mkdir -p "$task_output"
clang -arch x86_64 -mmacosx-version-min=15.0 -dynamiclib -fno-objc-arc -O2 \
  -framework Foundation -framework Metal -framework IOSurface -lobjc \
  -install_name /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/libxedrv.dylib \
  -o "$task_output/libxedrv.dylib" "$task_source/src/libxedrv.m"
codesign -f -s - "$task_output/libxedrv.dylib"
python3 "$task_source/patch-mtl17.py" "$task_stock/AppleIntelTGLGraphicsMTLDriver.bundle" "$task_output/libxedrv.dylib" "$task_output"
# The stock helper still carries an old Apple certificate that may fail current trust checks.
# Sign copied embedded libraries inside-out, then refresh the enclosing bundle seal.
for task_library in "$task_output/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/"*.dylib; do
    codesign -f -s - "$task_library"
done
codesign -f -s - "$task_output/AppleIntelTGLGraphicsMTLDriver.bundle"
zsh "$task_source/build-shader-compiler.sh" "$task_stock" "$task_output"
echo "Built userland stack against this macOS compiler ABI: $task_output"
