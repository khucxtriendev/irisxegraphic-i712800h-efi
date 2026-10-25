# R3 — đã xác nhận boot và hiện số thông báo Dock

EFI giữ nguyên bản trên USB 1401 đã boot được. Graphics đã cập nhật libxedrv sửa NoCopy nhiều mip theo upstream v19. Người dùng xác nhận đã thấy chữ số thông báo; ứng dụng P1 cũng ghi nhận “digits visible”. Metal bundle trong gói khớp toàn bộ bundle đang cài trên máy.

- EFI: giữ nguyên 156 file của R3-booted, EDID và DMC fallback như trước.
- Dock: tạo managed texture từ dữ liệu mip 0, sinh các mip còn lại trước khi trả texture; giữ kiểm tra biên và deallocator.
- Nguồn sửa: `Source/DockMipFix/`; bằng chứng: `reports/dock-fix-confirmation.json` và `reports/dock-fix/`.
- Chưa xác nhận 165 Hz, sleep/wake hoặc mọi tính năng GPU. Một lần boot và việc thấy số Dock không chứng minh tất cả tính năng đã hoàn thiện.

**Máy hiện tại đã cài đúng bản vá, không cần cài lại hoặc chép lại EFI USB.** Khi triển khai lại từ gói: chép `EFI/` lên USB thử, cài Metal bundle bằng `bash scripts/install-graphics.command`, rồi restart bằng EFI R3. Chỉ chép EFI không áp dụng phần sửa số Dock nằm trong macOS.

Xem [hướng dẫn](docs/CAI-DAT.md), [sửa số Dock](docs/SUA-SO-DOCK.md), và tài liệu Word. `SHA256SUMS.json` ghi hash gói mới. Bản R3 trước sửa được giữ riêng với hậu tố `-before-dockfix`; báo cáo cũ trong `reports/before-dockfix` là lịch sử, không phải trạng thái hiện tại.
