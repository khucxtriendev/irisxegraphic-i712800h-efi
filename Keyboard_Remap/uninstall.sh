#!/bin/bash
# ==============================================================================
# Script Gỡ Bỏ Ánh Xạ Phím - Khôi Phục Mặc Định Gốc Cho macOS
# ==============================================================================

set -e

PLIST_NAME="com.local.hidutilKeyMapping.plist"
USER_LAUNCHAGENTS="$HOME/Library/LaunchAgents"
TARGET_PLIST="$USER_LAUNCHAGENTS/$PLIST_NAME"

echo "--------------------------------------------------------"
echo " ĐANG GỠ BỎ KEYMAPPING - KHÔI PHỤC MẶC ĐỊNH MACOS"
echo "--------------------------------------------------------"

UID_NUM=$(id -u)

# 1. Hủy LaunchAgent
if [ -f "$TARGET_PLIST" ]; then
    echo "[1/3] Hủy đăng ký LaunchAgent..."
    launchctl bootout "gui/$UID_NUM/com.local.hidutilKeyMapping" 2>/dev/null || true
    launchctl unload "$TARGET_PLIST" 2>/dev/null || true
    rm -f "$TARGET_PLIST"
fi

# 2. Xóa cấu hình hidutil tức thì
echo "[2/3] Khôi phục toàn bộ phím bàn phím về mặc định xuất xưởng..."
/usr/bin/hidutil property --set '{"UserKeyMapping":[]}' >/dev/null

# 3. Khôi phục phím tắt chụp ảnh 31 về mặc định (^⇧⌘4)
echo "[3/3] Khôi phục phím tắt chụp màn hình về Ctrl+Shift+Cmd+4..."
PLIST_HOTKEYS="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

/usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:31:value:parameters" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters array" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:0 integer 52" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:1 integer 21" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:2 integer 1441792" "$PLIST_HOTKEYS" 2>/dev/null || true

killall cfprefsd 2>/dev/null || true

echo "--------------------------------------------------------"
echo " [THÀNH CÔNG] ĐÃ KHÔI PHỤC TOÀN BỘ PHÍM VỀ MẶC ĐỊNH!"
echo "--------------------------------------------------------"
