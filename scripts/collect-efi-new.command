#!/bin/bash
# Read-only collection from the user's Terminal. No driver/config/NVRAM changes.
set -u
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_report="$task_root/reports/efi-new-investigation/runtime-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$task_report"
task_collect() {
    local name="$1"
    shift
    "$@" >"$task_report/$name.txt" 2>&1
    local result=$?
    printf '%s exit=%s\n' "$name" "$result" >>"$task_report/commands.txt"
}
task_collect os /usr/bin/sw_vers
task_collect boottime /usr/sbin/sysctl kern.boottime
task_collect boot-args /usr/sbin/nvram boot-args
task_collect loaded-kexts /usr/bin/kmutil showloaded --list-only
task_collect graphics-registry /usr/sbin/ioreg -lw0 -r -c IntelAccelerator
task_collect framebuffer-registry /usr/sbin/ioreg -lw0 -r -c AppleIntelFramebuffer
echo "Đang đọc log lần boot lỗi 19:50–20:06 ngày 25/10/2026..."
task_collect failed-boot-log /usr/bin/log show \
    --start '2026-10-25 19:50:00' --end '2026-10-25 20:06:00' \
    --style compact --info --debug --predicate \
    'process == "kernel" OR process == "WindowServer" OR process == "amfid" OR process == "loginwindow" OR (process == "launchd" AND (eventMessage CONTAINS[c] "WindowServer" OR eventMessage CONTAINS[c] "loginwindow"))'
task_collect current-graphics-log /usr/bin/log show --last 15m --style compact --info \
    --predicate 'process == "WindowServer" OR (process == "kernel" AND (eventMessage CONTAINS[c] "ngreen" OR eventMessage CONTAINS[c] "XeNG" OR eventMessage CONTAINS[c] "graphics"))'
for task_log in /private/tmp/xedrv-WindowServer.log /private/tmp/xedrv-DockHelper.log; do
    if [[ -r "$task_log" ]]; then cp "$task_log" "$task_report/"; fi
done
printf '\nĐã lưu: %s\n' "$task_report"
echo "Không cài/thay driver, không sửa EFI/NVRAM và không khởi động lại."
