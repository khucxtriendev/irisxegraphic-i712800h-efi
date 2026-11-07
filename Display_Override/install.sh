#!/usr/bin/env bash

# ==============================================================================
# Script Cài đặt Display Override HiDPI cho Màn hình BOE (VendorID: 9e5, ProductID: ae0)
# ==============================================================================

set -e

# Kiểm tra quyền root (sudo)
if [ "$EUID" -ne 0 ]; then
    echo "❌ Lỗi: Bạn cần chạy script này với quyền root (sudo)."
    echo "👉 Hãy chạy: sudo bash $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/Library/Displays/Contents/Resources/Overrides"
VENDOR_DIR="$TARGET_DIR/DisplayVendorID-9e5"

echo "=========================================================="
echo "  BẮT ĐẦU CÀI ĐẶT BỘ DISPLAY OVERRIDE (BOE 0x9e5 - 0xae0) "
echo "=========================================================="

# 1. Tạo thư mục đích trong /Library/Displays/...
echo "==> [1/3] Đang tạo thư mục hệ thống..."
mkdir -p "$VENDOR_DIR"

# 2. Sao chép file cấu hình và icon
echo "==> [2/3] Đang sao chép file cấu hình Display Override..."
if [ -f "$SCRIPT_DIR/DisplayVendorID-9e5/DisplayProductID-ae0" ]; then
    cp -v "$SCRIPT_DIR/DisplayVendorID-9e5/DisplayProductID-ae0" "$VENDOR_DIR/"
else
    echo "❌ Không tìm thấy file DisplayProductID-ae0!"
    exit 1
fi

if [ -f "$SCRIPT_DIR/DisplayVendorID-9e5/DisplayProductID-ae0.icns" ]; then
    cp -v "$SCRIPT_DIR/DisplayVendorID-9e5/DisplayProductID-ae0.icns" "$VENDOR_DIR/"
fi

# Sao chép Icons.plist nếu có
if [ -f "$SCRIPT_DIR/Icons.plist" ]; then
    if [ ! -f "$TARGET_DIR/Icons.plist" ]; then
        echo "==> Đang sao chép Icons.plist..."
        cp -v "$SCRIPT_DIR/Icons.plist" "$TARGET_DIR/"
    else
        echo "ℹ️  Icons.plist đã tồn tại trên máy, tạo bản backup .bak..."
        cp -v "$TARGET_DIR/Icons.plist" "$TARGET_DIR/Icons.plist.bak"
        cp -v "$SCRIPT_DIR/Icons.plist" "$TARGET_DIR/"
    fi
fi

# 3. Phân quyền chuẩn macOS
echo "==> [3/3] Phân quyền root:wheel và thiết lập quyền đọc ghi..."
chown -R root:wheel "$VENDOR_DIR"
chmod 755 "$VENDOR_DIR"
chmod 644 "$VENDOR_DIR"/*

if [ -f "$TARGET_DIR/Icons.plist" ]; then
    chown root:wheel "$TARGET_DIR/Icons.plist"
    chmod 644 "$TARGET_DIR/Icons.plist"
fi

echo "=========================================================="
echo "✅ CÀI ĐẶT THÀNH CÔNG!"
echo "👉 Hãy khởi động lại máy (sudo reboot) để macOS nạp cấu hình mới."
echo "=========================================================="
