# HƯỚNG DẪN CẤU HÌNH ÁNH XẠ BÀN PHÍM THINKPAD (WINDOWS-STYLE & PRTSC CHỤP ẢNH) TRÊN MACOS

Tài liệu chi tiết về giải pháp chuyển đổi trải nghiệm gõ phím trên ThinkPad P1 Gen 5 (hoặc các dòng ThinkPad / Laptop PC) khi chạy macOS Sequoia / Sonoma sang chuẩn **thói quen Windows**, giữ nguyên tính năng đặc thù của macOS và gán nút chụp ảnh màn hình tiện lợi.

> [!IMPORTANT]
> **Đặc điểm giải pháp:**
> * **100% Native:** Tận dụng trực tiếp dịch vụ HID lõi của macOS (`/usr/bin/hidutil`) và cơ chế `LaunchAgent` của hệ thống.
> * **KHÔNG DÙNG APP NGOÀI:** Hoàn toàn không cài đặt hay phụ thuộc vào các tiện ích bên thứ ba như Karabiner-Elements, AltTab hay BetterTouchTool.
> * **0% Tiêu thụ tài nguyên:** Không tốn bất kỳ tiến trình nền hay RAM nào chạy ngầm, không gây delay gõ phím.
> * **Tự động kích hoạt:** Tự nạp chuẩn xác sau mỗi lần mở máy hoặc khởi động lại.

---

## 1. Bảng Ánh Xạ Phím Chi Tiết (Key Mapping Table)

Dưới đây là chi tiết kỹ thuật các phím vật lý trên bàn phím ThinkPad được hoán đổi sang nhân macOS:

| Vị trí phím vật lý trên ThinkPad | Mã HID gốc (Src) | Mã HID ánh xạ (Dst) | macOS nhận diện | Tác dụng & Trải nghiệm thực tế |
| :--- | :--- | :--- | :--- | :--- |
| **Left Ctrl** *(Phím góc ngoài cùng bên trái)* | `0x7000000E0`<br>`(30064771296)` | `0x7000000E3`<br>`(30064771299)` | **Left Command (`⌘`)** | **Chuẩn phím tắt Windows:** Bấm ngón út trái bình thường để thao tác `Ctrl + C` (Copy), `Ctrl + V` (Paste), `Ctrl + A` (Chọn tất cả), `Ctrl + Z` (Undo), `Ctrl + S` (Save), `Ctrl + T` (Tab mới), `Ctrl + W` (Đóng tab), `Ctrl + F` (Tìm kiếm)... |
| **Left Alt** *(Nằm giữa phím Win và phím Space)* | `0x7000000E2`<br>`(30064771298)` | `0x7000000E3`<br>`(30064771299)` | **Left Command (`⌘`)** | **Chuẩn Alt + Tab:** Bấm `Alt + Tab` để mở trình chuyển đổi cửa sổ ứng dụng (App Switcher gốc của macOS) mượt mà như Windows. |
| **Left Windows** *(Nằm giữa Ctrl và Alt)* | `0x7000000E3`<br>`(30064771299)` | `0x7000000E0`<br>`(30064771296)` | **Left Control (`⌃`)** | **Thay thế nút Control gốc của macOS:** Dùng khi cần các phím tắt chuyên biệt của macOS hoặc Terminal (ví dụ: `Ctrl + C` để ngắt lệnh Terminal, `Ctrl + L` xoá màn hình, chuyển Space...). |
| **Right Alt** *(Nằm ngay bên phải phím Space)* | `0x7000000E6`<br>`(30064771302)` | `0x7000000E6`<br>`(30064771302)` | **Option (`⌥`)** | **GIỮ NGUYÊN 100%:** Đóng vai trò phím Option chuẩn của macOS, dùng để gõ ký tự đặc biệt, phím tắt đồ họa, lập trình trong VS Code / JetBrains / Terminal. |
| **PrtSc** *(PrintScreen)* | `0x700000046`<br>`(30064771142)` | `0x700000068`<br>`(30064771176)` | **F13** | **Chụp màn hình vùng chọn vào Clipboard:** Xem cơ chế chi tiết ở Mục 2. Bấm `PrtSc` -> quét vùng màn hình -> bấm `Ctrl + V` là dán ảnh ngay lập tức! |
| **Insert** | — | — | — | Giữ nguyên mặc định theo yêu cầu. |

---

## 2. Cơ Chế Chụp Màn Hình Bằng PrtSc & Dán Ctrl+V Hoạt Động Ra Sao?

Trên macOS, phím tắt mặc định để chụp màn hình vùng chọn lưu thẳng vào bộ nhớ đệm (Clipboard) là tổ hợp rất dài: `Control + Shift + Command + 4` (`^⇧⌘4`).

1. Lệnh gốc của macOS (`hidutil`) chỉ có khả năng map **1 phím $\rightarrow$ 1 phím**, không thể map trực tiếp 1 phím cứng thành cả cụm 4 phím cùng lúc.
2. Do đó, giải pháp chuẩn nhất là ánh xạ phím cứng **PrtSc** thành phím **`F13`** (mã HID `0x700000068`). Phím `F13` là phím chức năng mở rộng chính thống của Apple nhưng không tồn tại trên bàn phím PC, nên hoàn toàn không bị xung đột với bất kỳ phím nào khác.
3. Sau đó, trong cấu hình phím tắt hệ thống macOS (`com.apple.symbolichotkeys.plist`), mục **Hotkey 31** (*Copy picture of selected area to the clipboard*) được gán trực tiếp cho phím **`F13`** (Keycode 105, Modifier flags = 0).
4. **Quy trình sử dụng:**
   * Bạn chỉ cần bấm nút **PrtSc** 1 lần.
   * Con trỏ chuột chuyển ngay thành hồng tâm toạ độ.
   * Quét chọn vùng màn hình cần chụp $\rightarrow$ Ảnh tự động lưu vào Clipboard.
   * Bấm **Ctrl + V** (ngón út phím Ctrl góc trái) là dán thẳng ảnh vào Zalo, Messenger, Telegram, Word, Photoshop...

---

## 3. Cách Cài Đặt (Khi Cài Lại Máy Hoặc Chuyển Sang Máy Khác)

Bộ cài đặt tự động đã được đóng gói sẵn trong thư mục này.

### Cách 1: Chạy Script tự động 1-Click (Khuyên dùng)
Mở ứng dụng **Terminal** và chạy lệnh:
```bash
bash /Volumes/1401/Keyboard_Remap/install.sh
```
Script sẽ tự động:
1. Copy file `com.local.hidutilKeyMapping.plist` vào thư mục `~/Library/LaunchAgents/`.
2. Kích hoạt LaunchAgent tự chạy cùng hệ thống.
3. Áp dụng ngay lập tức cấu hình phím (dùng được luôn không cần khởi động lại).
4. Cấu hình Symbolic Hotkey 31 cho phím `PrtSc` (F13).

---

### Cách 2: Cài đặt thủ công bằng tay (Manual)

Nếu muốn tự làm từng bước bằng lệnh:

1. **Sao chép LaunchAgent:**
   ```bash
   cp /Volumes/1401/Keyboard_Remap/com.local.hidutilKeyMapping.plist ~/Library/LaunchAgents/
   launchctl load ~/Library/LaunchAgents/com.local.hidutilKeyMapping.plist
   ```

2. **Kích hoạt ánh xạ phím ngay lập tức:**
   ```bash
   /usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771296,"HIDKeyboardModifierMappingDst":30064771299},{"HIDKeyboardModifierMappingSrc":30064771298,"HIDKeyboardModifierMappingDst":30064771299},{"HIDKeyboardModifierMappingSrc":30064771299,"HIDKeyboardModifierMappingDst":30064771296},{"HIDKeyboardModifierMappingSrc":30064771142,"HIDKeyboardModifierMappingDst":30064771176}]}'
   ```

3. **Cấu hình Hotkey 31 cho PrtSc (F13):**
   ```bash
   /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:31:enabled true" ~/Library/Preferences/com.apple.symbolichotkeys.plist
   /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:31:value:type standard" ~/Library/Preferences/com.apple.symbolichotkeys.plist
   /usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:31:value:parameters" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true
   /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters array" ~/Library/Preferences/com.apple.symbolichotkeys.plist
   /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:0 integer 65535" ~/Library/Preferences/com.apple.symbolichotkeys.plist
   /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:1 integer 105" ~/Library/Preferences/com.apple.symbolichotkeys.plist
   /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:31:value:parameters:2 integer 8388608" ~/Library/Preferences/com.apple.symbolichotkeys.plist
   killall cfprefsd
   ```

---

## 4. Cách Kiểm Tra Trạng Thái Hoạt Động

Mở Terminal và gõ:
```bash
hidutil property --get "UserKeyMapping"
```
Kết quả hiển thị dạng:
```
(
    {
        HIDKeyboardModifierMappingDst = 30064771299;
        HIDKeyboardModifierMappingSrc = 30064771296;
    },
    {
        HIDKeyboardModifierMappingDst = 30064771299;
        HIDKeyboardModifierMappingSrc = 30064771298;
    },
    {
        HIDKeyboardModifierMappingDst = 30064771296;
        HIDKeyboardModifierMappingSrc = 30064771299;
    },
    {
        HIDKeyboardModifierMappingDst = 30064771176;
        HIDKeyboardModifierMappingSrc = 30064771142;
    }
)
```
Nếu có đầy đủ 4 cặp mã trên là hệ thống đang hoạt động chuẩn xác 100%.

---

## 5. Cách Gỡ Bỏ (Khôi Phục Bàn Phím Về Mặc Định Ban Đầu)

Nếu sau này muốn đưa toàn bộ bàn phím về lại mặc định ban đầu của macOS:

Chỉ cần chạy script:
```bash
bash /Volumes/1401/Keyboard_Remap/uninstall.sh
```
Toàn bộ phím và phím tắt chụp ảnh sẽ lập tức được trả về trạng thái xuất xưởng của hệ điều hành.
