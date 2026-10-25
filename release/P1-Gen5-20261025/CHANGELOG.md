# Thay đổi — 25/10/2026

- Build lại NootedGreen từ nguồn trong vendor sau khi sửa ánh xạ GGTT, bảo vệ cache/slot và reset. Thay binary mới vào EFI/.
- Build libxedrv và Metal bundle: kiểm tra biên IOSurface/NoCopy, hỗ trợ fallback offset 0 khi native trả nil, xử lý quyền sở hữu bộ nhớ/callback/ngoại lệ. Chưa kết luận đã hết mất số Dock.
- Build shader compiler kèm bundle, xác minh chữ ký ad-hoc các thành phần mới.
- Âm thanh ALC287: layout 11 nhất quán ở DeviceProperties HDAS và alcid; giữ thứ tự Lilu/AppleALC/SimpleHDA cho Tahoe.
- Bluetooth Intel: giữ bộ ba firmware/patcher/BlueToolFixup, NVRAM DATA và thay cache cũ bằng Delete/Add.
- Thêm P1Gen5USBMap: giữ 15 port PCH, HS06/08/10 internal theo topology của máy; TB giữ enumeration. Connector ngoài chưa hoàn tất đo.
- Touchpad Synaptics I2C/GPIO: giữ driver đã khớp và GPIO INTC1055/pin 332; một VoodooInput, giữ PS2/TrackPoint.
- Cập nhật validator để xác nhận binary build mới, layout, Bluetooth, USB map, phụ thuộc và không xung đột injector.
- Bổ sung hướng dẫn áp dụng hai phần EFI/userland, script cập nhật Metal bundle/libxedrv có kiểm tra/backup, thu log ngoại vi và tài liệu Word.
- Đóng gói release riêng với manifest SHA-256 và ZIP; giữ các artifact trước build trong build/previous-before-hardware/.

Không ghi vào EFI đang boot, không cài vào /Library hay /System, không đổi NVRAM hoặc khởi động lại trong quá trình build. Chưa boot-test; ocvalidate chưa có sẵn để chạy. Mức xác nhận được giữ rõ trong FEATURES.md và reports/.
