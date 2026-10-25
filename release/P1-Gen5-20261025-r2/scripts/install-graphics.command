#!/bin/bash
# Manual installation only. The build never calls this script.
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -d "$task_root/Graphics/AppleIntelTGLGraphicsMTLDriver.bundle" ]]; then
    task_graphics="$task_root/Graphics"
else
    task_graphics="$task_root/build/userland"
fi
task_source="$task_graphics/AppleIntelTGLGraphicsMTLDriver.bundle"
task_dest="/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle"
[[ "$(sw_vers -buildVersion)" == "25G241" ]] || { echo "Bản này dành cho macOS build 25G241." >&2; exit 1; }
[[ -d "$task_source" && -d "$task_dest" ]] || { echo "Thiếu Metal bundle nguồn hoặc stack TGL đang cài." >&2; exit 1; }
python3 - "$task_source" "$task_dest" <<'PY'
import plistlib, sys
from pathlib import Path
for bundle in map(Path, sys.argv[1:]):
    info = plistlib.loads((bundle / 'Contents/Info.plist').read_bytes())
    if (info.get('CFBundleIdentifier') != 'com.apple.driver.AppleIntelTGLGraphicsMTLDriver'
            or info.get('CFBundleShortVersionString') != '16.0.32'):
        raise SystemExit('Cần stack TGL 16.0.32 đúng bundle ID; dừng trước khi ghi.')
PY
codesign --verify --deep --strict "$task_source"
if [[ "${1:-}" == "--check" ]]; then echo "Preflight PASS; chưa ghi hoặc cài gì."; exit 0; fi
if [[ "$#" -ne 0 ]]; then echo "Usage: install-graphics.command [--check]" >&2; exit 1; fi
if [[ "$EUID" -ne 0 ]]; then exec sudo /bin/bash "$0"; fi
task_backup="$task_root/Backups/graphics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$task_backup"
ditto "$task_dest" "$task_backup/AppleIntelTGLGraphicsMTLDriver.bundle"
# Stage on the destination filesystem so replacement uses renames, not a merge
# that could retain files from a different patched bundle.
task_stage_root="$(mktemp -d /Library/GPUBundles/.p1-graphics.XXXXXX)"
task_stage="$task_stage_root/AppleIntelTGLGraphicsMTLDriver.bundle"
ditto "$task_source" "$task_stage"
codesign --verify --deep --strict "$task_stage"
task_restore() {
    trap - ERR
    if [[ -d "$task_stage_root/previous.bundle" ]]; then
        if [[ -e "$task_dest" ]]; then mv "$task_dest" "$task_stage_root/failed.bundle"; fi
        mv "$task_stage_root/previous.bundle" "$task_dest"
    fi
    echo "Cài thất bại; bundle cũ đã giữ/phục hồi. Backup: $task_backup; staging: $task_stage_root" >&2
    exit 1
}
trap task_restore ERR
mv "$task_dest" "$task_stage_root/previous.bundle"
mv "$task_stage" "$task_dest"
codesign --verify --deep --strict "$task_dest"
diff -qr "$task_source" "$task_dest" >/dev/null
trap - ERR
# Only the private directory returned by mktemp above is removed.
rm -rf "${task_stage_root:?}"
echo "Đã cập nhật trọn Metal bundle cùng libxedrv. Backup: $task_backup"
echo "Khởi động lại cùng EFI mới để áp dụng đồng bộ. Script không tự khởi động lại."
