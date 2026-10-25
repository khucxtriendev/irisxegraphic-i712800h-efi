# R3 — cập nhật số thông báo Dock, 25/10/2026

- Tích hợp cơ chế libxedrv v19 cho NoCopy nhiều mip; giữ biên bộ nhớ, deallocator và fallback khi lỗi.
- Người dùng xác nhận số Dock hiển thị sau cài/restart; P1 ghi nhận “digits visible”.
- Thay Metal bundle và dylib rời trong Graphics; mã driver Metal chính không đổi ngoài chữ ký.
- Giữ nguyên toàn bộ EFI R3-booted. Cập nhật nguồn, hướng dẫn, Word, manifest và ZIP.
- Giữ bản R3 trước sửa ở hậu tố -before-dockfix. Không tự cài lại driver khi đóng gói.

---

# R3-booted — chốt EFI đã boot được

- Chụp nguyên trạng 156 file từ /Volumes/1401/EFI, đối chiếu hash trước/sau copy.
- Giữ nguyên config, gồm hai khóa EDID, connector flags 05 và LegacyOverwrite=true.
- Người dùng xác nhận vào được macOS; boot-args hiện tại khớp USB.
- Dùng làm R3 chính. Giữ R3 thử nghiệm cũ và báo cáo lịch sử để đối chiếu.
- Chưa xác nhận tăng tốc GPU, số Dock, 165 Hz hoặc nguyên nhân gốc.

---

# Thay đổi R3 — 25/10/2026

- Thêm EDID BOE NE160QDM-NY1 gốc 256 byte vào AAPL00,override-no-connect.
- Bỏ ngreen-dmc=adlp; giữ NVRAM/Delete boot-args, chọn fallback mặc định.
- Giữ eDP type 0x2/flags 0x18 trong driver, không thêm override flags 0x05.
- Binary EFI/Graphics giữ nguyên R2; không build lại hoặc tự cài driver.
- Cập nhật hướng dẫn, Word, đánh giá kỹ thuật, bằng chứng EDID, collector và guard cho trình cập nhật hai driver.
- Chưa boot xác nhận, chưa bảo đảm Online/165 Hz hoặc hết lỗi số Dock.

---

# Thay đổi — 25/10/2026

## R2

- Chủ động managed upload ảnh 2D ở offset 0/aligned/unaligned trước native, thay điều kiện chỉ recovery khi native nil. Giữ biên/format và loại GPU-writable/render target; ghi rõ snapshot semantics. Chưa boot xác nhận Dock.
- Cache PTE đã cài được lưu RAM: bỏ đọc PTE đích trên hit, vẫn xác minh PTE nguồn để phát hiện VA tái sử dụng. IO giả đếm native 40.580 → 16.004; HiDPI 45.280 → 20.704 lần đọc. Chưa đo thời gian/FPS thực tế.
- Thêm cai-dat-nhanh.sh để cài cùng NootedGreen vào EFI 1401 và Metal bundle/libxedrv, có staging, backup, rollback cả hai khi bước sau thất bại. Không tự chạy cài đặt/restart.
- Kiểm tra CPU có sanitizer và kiểm tra transaction trong thư mục tạm đã qua; cập nhật hướng dẫn và Word trong release R2.

## R1

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
