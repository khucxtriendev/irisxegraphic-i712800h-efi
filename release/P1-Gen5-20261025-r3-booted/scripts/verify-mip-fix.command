#!/bin/bash
# Check installed payload, exercise this test app's real Dock badge, collect logs.
set -euo pipefail
umask 077
task_root="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$task_root" <<'PY'
import hashlib,json,sys
from pathlib import Path
root=Path(sys.argv[1]);expected=json.loads((root/'mip-fix-build.json').read_text())['bundle_hashes']['Contents/MacOS/libxedrv.dylib']
p=Path('/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/libxedrv.dylib')
if hashlib.sha256(p.read_bytes()).hexdigest()!=expected:raise SystemExit('Dylib đang cài chưa khớp bản vá này; dừng kiểm tra.')
PY
task_out="$task_root/reports/after-install-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$task_out"
nvram boot-args > "$task_out/boot-args.txt" 2>&1
sysctl -n kern.boottime > "$task_out/boottime.txt"
open -W -n "$task_root/P1BadgeCheck.app" --args "$task_out"
for task_process in WindowServer Dock DockHelper; do
    if [[ -r "/private/tmp/xedrv-$task_process.log" ]]; then
        cp "/private/tmp/xedrv-$task_process.log" "$task_out/$task_process.log"
    fi
done
echo "Đã lưu kết quả: $task_out"
echo 'Báo lại kết quả số trên biểu tượng P1 và System Settings. Không thay EFI hoặc driver.'
