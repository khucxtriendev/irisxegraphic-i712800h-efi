# P1-Gen5-20261025-r2

EFI và thư viện đồ họa cho ThinkPad P1 Gen 5, macOS 25G241 / TGL 16.0.32.

Đã build và kiểm tra tĩnh; chưa boot xác nhận. Chưa kết luận hết mất số Dock.

1. Đọc [hướng dẫn cài đặt](docs/CAI-DAT.md) hoặc `HUONG-DAN-P1-Gen5.docx`.
2. Dùng `EFI/` ở gốc phân vùng boot USB đã chuẩn bị, giữ USB cũ để quay lại.
3. Để áp dụng libxedrv mới trên stack TGL đã cài, tự chạy `bash scripts/install-graphics.command`. Script kiểm tra phiên bản/chữ ký và sao lưu trước khi thay; chép EFI không thay thư viện trong /Library.
4. Boot USB mới rồi thử âm thanh layout 11, Bluetooth, touchpad và đồ họa; chạy `bash scripts/collect.command` để thu kết quả.

Nếu muốn cập nhật đồng thời hai driver đồ họa vào EFI đang có trên /Volumes/1401, dùng `bash scripts/cai-dat-nhanh.sh --check` rồi `bash scripts/cai-dat-nhanh.sh`. Script giữ config.plist và kext ngoại vi hiện có; xem hướng dẫn để áp dụng cấu hình ngoại vi mới.

Chi tiết: [âm thanh/Bluetooth/touchpad](docs/AM-THANH-BLUETOOTH-TOUCHPAD.md), [tính năng](FEATURES.md), [thay đổi](CHANGELOG.md). Nguồn đã sửa và công cụ build nằm tại `~/Documents/gen5_igpu_driver/vendor/iris-xe/` và `scripts/` của thư mục nguồn; gói này không chứa toàn bộ source tree. Nguồn gốc upstream: https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe .

`SHA256SUMS.json` ghi hash từng file; `reports/` ghi kiểm tra, nguồn/target build. `ocvalidate` chưa có sẵn để chạy. Map cổng ngoài chưa hoàn tất thử vật lý.
