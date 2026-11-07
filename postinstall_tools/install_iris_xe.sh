#!/bin/bash
# ==============================================================================
# Script Cài Đặt Metal 3D Graphics Driver Cho Intel Iris Xe Trên macOS
# Lenovo ThinkPad P1 Gen 5 - Intel Core i7-12800H (Alder Lake-H)
# ==============================================================================

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Lỗi: Bạn cần chạy lệnh này với quyền root (sudo)!"
    echo "    Cách chạy: sudo bash \"$0\""
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_PATH="$SCRIPT_DIR/WhateverXe-Graphics-0.4.0.pkg"
IMPOSTOR_SRC="$SCRIPT_DIR/impostor.dylib"
TARGET_BUNDLE="/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle"

echo "=========================================================="
echo " 1. Kiểm tra bộ cài WhateverXe-Graphics-0.4.0.pkg..."
echo "=========================================================="
if [ ! -f "$PKG_PATH" ]; then
    echo "[*] Chưa có sẵn gói cài đặt trên phân vùng USB."
    echo "[*] Đang tải WhateverXe-Graphics-0.4.0.pkg từ GitHub..."
    curl -L --progress-bar -o "$PKG_PATH" "https://github.com/b00t0x/WhateverXe-Graphics/releases/download/v0.4.0/WhateverXe-Graphics-0.4.0.pkg"
    echo "[+] Tải gói cài đặt thành công!"
fi

echo ""
echo "=========================================================="
echo " 2. Cài đặt WhateverXe Graphics Driver vào /Library..."
echo "=========================================================="
installer -pkg "$PKG_PATH" -target /
echo "[+] Đã cài đặt WhateverXe Graphics vào hệ thống thành công!"

echo ""
echo "=========================================================="
echo " 3. Nạp cầu nối Metal Bridge (impostor.dylib - JulioNectar)..."
echo "=========================================================="
if [ -f "$IMPOSTOR_SRC" ] && [ -d "$TARGET_BUNDLE/Contents/MacOS" ]; then
    echo "[*] Nạp impostor.dylib vào $TARGET_BUNDLE..."
    cp -f "$IMPOSTOR_SRC" "$TARGET_BUNDLE/Contents/MacOS/impostor.dylib"
    chmod 755 "$TARGET_BUNDLE/Contents/MacOS/impostor.dylib"
    codesign -f -s - -i impostor "$TARGET_BUNDLE/Contents/MacOS/impostor.dylib" 2>/dev/null || true
    echo "[+] Đã nạp impostor.dylib và ký chữ ký số ad-hoc thành công!"
else
    echo "[!] Cảnh báo: Không tìm thấy $IMPOSTOR_SRC hoặc $TARGET_BUNDLE"
fi

echo ""
echo "=========================================================="
echo " 4. Phân quyền hệ thống chuẩn root:wheel..."
echo "=========================================================="
chown -R root:wheel /Library/GPUBundles /Library/Extensions 2>/dev/null || true
chmod -R 755 /Library/GPUBundles /Library/Extensions 2>/dev/null || true

echo ""
echo "=========================================================="
echo " 5. Làm mới AuxKC (Auxiliary Kernel Cache)..."
echo "=========================================================="
kmutil install --volume-root / --update-all || true

echo ""
echo "=========================================================="
echo " [THÀNH CÔNG] ĐÃ HOÀN TẤT CÀI ĐẶT DRIVER ĐỒ HỌA INTEL IRIS XE!"
echo " Hãy khởi động lại máy để tận hưởng Metal 3D và giao diện 60 FPS!"
echo "=========================================================="
