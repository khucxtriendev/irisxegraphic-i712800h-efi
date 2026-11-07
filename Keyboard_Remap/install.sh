#!/bin/bash
# ==============================================================================
# Script Cài Đặt Ánh Xạ Phím ThinkPad Windows-Style & PrtSc Chụp Ảnh Cho macOS
# Không dùng app ngoài - 100% Native via hidutil & LaunchAgent
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.local.hidutilKeyMapping.plist"
USER_LAUNCHAGENTS="$HOME/Library/LaunchAgents"
TARGET_PLIST="$USER_LAUNCHAGENTS/$PLIST_NAME"

echo "--------------------------------------------------------"
echo " ĐANG CÀI ĐẶT BỘ KEYMAPPING CHO MACOS (NATIVE)"
echo "--------------------------------------------------------"

# 1. Tạo thư mục LaunchAgents nếu chưa có
mkdir -p "$USER_LAUNCHAGENTS"

# 2. Sao chép file LaunchAgent cấu hình hidutil
echo "[1/4] Sao chép LaunchAgent cấu hình phím..."
cp -f "$SCRIPT_DIR/$PLIST_NAME" "$TARGET_PLIST"
chmod 644 "$TARGET_PLIST"

# 3. Kích hoạt LaunchAgent
echo "[2/4] Kích hoạt LaunchAgent tự chạy khi mở máy..."
UID_NUM=$(id -u)
launchctl bootout "gui/$UID_NUM/com.local.hidutilKeyMapping" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$TARGET_PLIST" 2>/dev/null || launchctl load "$TARGET_PLIST" 2>/dev/null || true

# 4. Áp dụng ngay lập tức cấu hình phím vào nhân hệ thống
echo "[3/4] Áp dụng ánh xạ phím tức thì vào HID subsystem..."
/usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771296,"HIDKeyboardModifierMappingDst":30064771299},{"HIDKeyboardModifierMappingSrc":30064771298,"HIDKeyboardModifierMappingDst":30064771299},{"HIDKeyboardModifierMappingSrc":30064771299,"HIDKeyboardModifierMappingDst":30064771296},{"HIDKeyboardModifierMappingSrc":30064771142,"HIDKeyboardModifierMappingDst":30064771176}]}' >/dev/null

# 5. Cấu hình Symbolic Hotkey 31 (Chụp ảnh màn hình vùng chọn vào Clipboard -> Gán vào phím F13)
echo "[4/4] Cấu hình phím PrtSc (F13) chụp ảnh thẳng vào Clipboard..."
PLIST_HOTKEYS="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:31:enabled true" "$PLIST_HOTKEYS" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:enabled bool true" "$PLIST_HOTKEYS" 2>/dev/null || true

/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:31:value:type standard" "$PLIST_HOTKEYS" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:type string standard" "$PLIST_HOTKEYS" 2>/dev/null || true

/usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:31:value:parameters" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters array" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:0 integer 65535" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:1 integer 105" "$PLIST_HOTKEYS" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:2 integer 8388608" "$PLIST_HOTKEYS" 2>/dev/null || true

# Làm mới cache preferences
killall cfprefsd 2>/dev/null || true

echo "--------------------------------------------------------"
echo " [THÀNH CÔNG] ĐÃ CÀI ĐẶT VÀ KÍCH HOẠT XONG!"
echo "--------------------------------------------------------"
echo "Các phím đang hoạt động:"
echo "  * Left Ctrl      -> Left Command (Ctrl+C, Ctrl+V, Ctrl+A... như Windows)"
echo "  * Left Alt       -> Left Command (Alt+Tab chuyển app)"
echo "  * Left Win       -> Left Control (Phím Control gốc của macOS)"
echo "  * Right Alt      -> Giữ nguyên 100% làm Option (⌥)"
echo "  * Phím PrtSc     -> Gán F13 chụp ảnh vùng chọn lưu thẳng vào Clipboard"
echo "                      (Bấm PrtSc -> quét chuột -> bấm Ctrl+V để dán ảnh)"
echo "--------------------------------------------------------"
