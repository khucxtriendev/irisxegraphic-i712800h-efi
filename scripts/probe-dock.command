#!/bin/bash
# Read-only driver diagnosis. Run from the normal logged-in user's Terminal.
set -u
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_out="$task_root/reports/dock-investigation"
mkdir -p "$task_out"
sw_vers > "$task_out/user-os.txt"
sysctl -n kern.boottime > "$task_out/user-boottime.txt" 2>&1
shasum -a 256 /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/libxedrv.dylib > "$task_out/user-installed-sha256.txt" 2>&1
"$task_root/bin/p1-badge-probe" "$task_out/probe-user.json" > "$task_out/probe-user-run.log" 2>&1
task_result=$?
echo "$task_result" > "$task_out/probe-user.exit"
for task_process in WindowServer DockHelper; do
    if [[ -r "/private/tmp/xedrv-$task_process.log" ]]; then
        cp "/private/tmp/xedrv-$task_process.log" "$task_out/$task_process-after-probe.log"
    fi
done
cat "$task_out/probe-user-run.log"
echo "Đã lưu kết quả: $task_out"
echo "Không cài hoặc thay driver. Hãy báo lại đã chạy xong để đọc kết quả."
exit "$task_result"
