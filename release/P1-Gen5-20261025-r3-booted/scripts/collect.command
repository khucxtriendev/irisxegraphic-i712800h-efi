#!/bin/bash
set -u
umask 077
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_out="$task_root/reports/runtime-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$task_out"
capture() {
    task_name="$1"; shift
    "$@" >"$task_out/$task_name.txt" 2>&1
    echo "$?" >"$task_out/$task_name.exit"
}
capture os sw_vers
capture cpu "$task_root/bin/p1-hardware"
capture displays "$task_root/bin/p1-display"
capture peripherals system_profiler SPDisplaysDataType SPAudioDataType SPCameraDataType SPBluetoothDataType SPUSBDataType -detailLevel mini
capture kexts /usr/bin/kmutil showloaded
capture boot-args nvram boot-args
capture power pmset -g custom
for task_class in IntelAccelerator AppleDisplay AppleHDAController IOHDACodecDevice IOAudioEngine IntelBluetoothFirmware SMCProcessor VoodooGPIOTigerLakeLP VoodooI2CDeviceNub VoodooI2CHIDDevice VoodooI2CPrecisionTouchpadHIDEventDriver AppleUSBXHCIPCI; do
    capture "$task_class" ioreg -lw0 -r -d 2 -c "$task_class"
done
capture r3-framebuffer ioreg -lw0 -r -c AppleIntelFramebuffer
capture r3-igpu ioreg -lw0 -r -n IGPU
capture r3-display-log /usr/bin/log show --last 2h --style compact --predicate '(process == "kernel" AND (eventMessage CONTAINS[c] "AUX" OR eventMessage CONTAINS[c] "EDID" OR eventMessage CONTAINS[c] "ngreen" OR eventMessage CONTAINS[c] "waitForStamp")) OR (process == "WindowServer" AND (eventMessage CONTAINS[c] "offline" OR eventMessage CONTAINS[c] "libxedrv"))'
capture bluetooth-nvram nvram bluetoothExternalDongleFailed bluetoothInternalControllerInfo
if [[ "${1:-}" == "--metal" ]]; then
    capture metal "$task_root/bin/p1-metal"
fi
echo "Đã lưu kết quả: $task_out"
echo "Không thay đổi EFI, âm thanh, nguồn điện hoặc độ phân giải."
