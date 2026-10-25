# Sử dụng R3 có bản sửa số Dock

Máy hiện tại đã boot được bằng EFI R3 và người dùng xác nhận thấy số thông báo. Bundle Graphics trong gói khớp bundle đang cài; không cần cài lại để chốt phiên bản.

## Khi sao chép hoặc khôi phục gói về sau

1. Giữ USB boot đã hoạt động và sao lưu EFI đích. Chép trọn `EFI/` vào gốc phân vùng boot USB thử, có `EFI/BOOT/BOOTx64.efi` và `EFI/OC/config.plist`.
2. Stack đích cần macOS 25G241 và TGL 16.0.32. Bản sửa số Dock nằm trong `Graphics/AppleIntelTGLGraphicsMTLDriver.bundle`, không nằm trong EFI.
3. Từ thư mục gói, chạy `bash scripts/install-graphics.command --check`, sau đó `bash scripts/install-graphics.command` khi cần áp dụng Graphics. Script kiểm tra phiên bản/chữ ký, sao lưu bundle ở `Backups/graphics-...`, stage rồi thay bằng rename; yêu cầu mật khẩu quản trị trong Terminal. Không tự restart.
4. Restart bằng EFI R3 để WindowServer nạp dylib mới. Không cần Reset NVRAM để áp dụng phần sửa Dock.
5. Chạy `bash scripts/verify-mip-fix.command` để xem badge P1, lưu lựa chọn và log; hoặc `bash scripts/collect.command` để thu trạng thái chung.

`cai-dat-nhanh.sh` cập nhật kext và Metal bundle nhưng giữ config.plist. Nó không áp dụng cấu hình EDID/DMC cho một EFI khác; muốn đúng cấu hình R3 thì dùng trọn thư mục EFI trong gói.

## Thành phần được giữ nguyên

EFI R3-booted, NootedGreen, driver ngoại vi, ACPI, shader compiler và cấu hình BIOS không đổi trong lượt sửa Dock. Giữ các khóa EDID, connector và LegacyOverwrite đúng snapshot boot được; chưa quy kết một khóa riêng lẻ là nguyên nhân sửa boot.

## Phục hồi

Khi cần quay lại Graphics trước một lần cài, lấy đúng Metal bundle trong backup mà bộ cài tạo. Ví dụ từ thư mục gói:

```bash
sudo ditto "Backups/graphics-YYYYMMDD-HHMMSS/AppleIntelTGLGraphicsMTLDriver.bundle" "/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle"
```

Thay đúng tên backup thật rồi restart. Backup trước lần cài bản vá đầu tiên hiện nằm ở gói `P1-Dock-MipFix-20261025/Backups/graphics-20261025-221405`; không chép backup đang dùng vào gói release. Bản R3 `-before-dockfix` cũng được giữ riêng để đối chiếu. Không cần đổi EFI đang boot được để khôi phục Graphics.
