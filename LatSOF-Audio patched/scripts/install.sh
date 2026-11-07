#!/bin/bash
set -e

echo "=========================================================="
echo "    CÀI ĐẶT BẢN VÁ LatSOFAudio (Alder Lake CoreMask 0x1)  "
echo "=========================================================="

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEXT_PATH="$DIR/../kext/LatSOFAudio.kext"

if [ ! -d "$KEXT_PATH" ]; then
    echo "[-] Error: LatSOFAudio.kext not found at $KEXT_PATH. Please run 'make' in kext/ first."
    exit 1
fi

echo "==> [1/2] Đồng bộ kext mới vào /Library/Extensions/..."
rm -rf /Library/Extensions/LatSOFAudio.kext
cp -R "$KEXT_PATH" /Library/Extensions/
chown -R root:wheel /Library/Extensions/LatSOFAudio.kext
chmod -R 755 /Library/Extensions/LatSOFAudio.kext

echo "==> [2/2] Yêu cầu macOS ghi nhận kext mới vào AuxKC..."
kmutil load -z -p /Library/Extensions/LatSOFAudio.kext || true

echo ""
echo "=========================================================="
echo " [THÀNH CÔNG] Đã ghi nhận bản vá LatSOFAudio vào hệ thống!"
echo " KHÔNG UNLOAD TRỰC TIẾP để tránh treo máy."
echo " Bây giờ bạn chỉ cần gõ lệnh sau để khởi động lại sạch sẽ:"
echo "     sudo reboot"
echo "=========================================================="
