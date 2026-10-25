# Số thông báo Dock — đã xác nhận trên máy

NoCopy với descriptor nhiều mip trước đây không đi qua nhánh managed copy. Dữ liệu nguồn chỉ có mip 0, nên cần tạo texture riêng và sinh các mip khác trước khi trả về. Cơ chế sửa dựa trên [libxedrv v19 / issue #10](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe/issues/10).

Phép thử GPU riêng xác nhận A8/R8/BGRA chuỗi 7 mip đọc đúng mip 0/3/6 sau vá; trước vá trả dữ liệu 0. Ảnh CoreAnimation mô phỏng vẫn trắng cả trước và sau, nên phép thử đó không tự chứng minh đã sửa badge. Bằng chứng hình ảnh thực tế là lựa chọn “digits visible” của P1 và xác nhận của người dùng sau cài/restart.

Nguồn, kiểm tra biên/stride/offset, quyền sở hữu callback và xử lý lỗi queue/encoder/command được giữ trong `Source/DockMipFix/`. Thử A8→RGBA đơn mip của người dùng được giữ; phần sửa nhiều mip giữ nguyên format yêu cầu. `XE_MIP_NATIVO=1` tắt phần sửa nhiều mip trong tiến trình được đặt biến đó, phục vụ đối chứng khi cần; không đặt biến toàn hệ thống trong gói.

Máy đã có bundle đúng hash và số hiển thị được. Chỉ chép EFI không cập nhật libxedrv. Xem CAI-DAT.md để triển khai lại; không tự áp dụng lại khi chỉ lưu bản R3 này.
