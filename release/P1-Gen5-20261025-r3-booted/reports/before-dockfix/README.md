# R3-booted — bản R3 chính đang dùng

Đây là bản chụp nguyên trạng `/Volumes/1401/EFI` ngay sau khi người dùng báo đã boot vào macOS thành công. EFI trong gói khớp từng byte với USB tại thời điểm chụp. Boot-args NVRAM hiện tại cũng khớp cấu hình USB. Đây là bằng chứng một lần boot theo người dùng; chưa tự xác minh thiết bị firmware đã boot hoặc các tính năng khác.

Giữ nguyên cả hai khóa EDID 256 byte, connector enable/type/flags `01/02/05`, `NVRAM/LegacyOverwrite=true`, và boot-args không có `ngreen-dmc=adlp` như EFI thực tế. Không suy ra một khóa riêng lẻ đã chữa lỗi; chưa chứng minh `flags=05` cần thiết hoặc được driver sử dụng.

Binary EFI và Graphics giống R2/R3 thử nghiệm. Dùng bản này làm baseline cho các thay đổi tiếp theo. R3 thử nghiệm cũ vẫn được giữ nguyên bên cạnh và tại `reports/trial-r3` trong gói cho phần báo cáo lịch sử.

**Đã có báo cáo boot thành công; chưa xác nhận Metal/tăng tốc GPU, số Dock, 165 Hz, sleep/wake hoặc độ ổn định qua nhiều lần khởi động.**

Để sao lưu/khôi phục, giữ nguyên thư mục `EFI/` và đặt ở gốc phân vùng boot của USB thử. Không cần chép lại EFI vào USB đang chạy chỉ để dùng cùng bản này: nó đã khớp. Không cần cài lại Metal/libxedrv chỉ để chốt snapshot. Xem `docs/CAI-DAT.md` khi áp dụng cho USB khác.

`reports/boot-confirmation.json` ghi mức xác nhận; `reports/efi-sha256.json` ghi hash chính xác của USB. `SHA256SUMS.json` ghi toàn bộ file của gói. Giữ bản R3 này riêng và chỉ đổi một thành phần mỗi lần khi điều tra tiếp.
