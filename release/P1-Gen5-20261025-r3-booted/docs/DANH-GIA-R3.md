# Cập nhật từ EFI boot được

Bản đang dùng là R3-booted: giữ nguyên EFI USB người dùng đã báo vào macOS thành công. Các lựa chọn "không thêm khóa thiếu index/flags 05" bên dưới mô tả R3 thử nghiệm trước đó, không mô tả snapshot hiện tại. Giữ cấu hình boot được để làm baseline, không tự loại khóa chỉ dựa vào lý thuyết. Thành công của cả cấu hình chưa chứng minh tác dụng của từng khóa hoặc nguyên nhân gốc. Báo cáo chi tiết ở `reports/boot-confirmation.json`.

---

## Đánh giá lịch sử của R3 thử nghiệm

# Đánh giá giả thuyết và phạm vi R3

## Có căn cứ để thử

EDID trong `evidence/panel.edid` được đối chiếu với `IODisplayEDID` trong AppleDisplay đã thu trên máy: BOE, product 0x0AE0, NE160QDM-NY1, 256 byte, hai block có checksum 0. EDID chứa timing 2560×1600 khoảng 60 Hz ở base block và khoảng 165 Hz ở DisplayID extension. Không sửa timing hay tự tạo EDID theo tên màn hình; có timing trong EDID không chứng minh driver chạy được 165 Hz.

R3 chỉ thêm DATA `AAPL00,override-no-connect` cho màn hình index 0 dưới IGPU. Không thêm `AAPL,override-no-connect` không có index: chưa xác định consumer cho khóa đó trong stack này. Cú pháp có index được tài liệu WhateverGreen mô tả; việc driver TGL hiện tại nhận và dùng đủ EDID vẫn cần xác nhận ở runtime.

Mã `hwInitializeCState` chọn nhánh fallback khi không có `ngreen-dmc`; nhánh này gọi original rồi cấu hình AUX, tránh nhánh ADL-P có firmware/context/power/timing writes. NVRAM/Delete đã có boot-args để cấu hình mới thay giá trị cũ khi boot OpenCore. Đây là hành vi nhánh mã, không phải đảm bảo an toàn tuyệt đối trên ThinkPad.

## Những khẳng định chưa đúng hoặc chưa chứng minh

EDID cung cấp danh tính/timing; nó không thay thế toàn bộ DPCD, link training, lane/power sequencing qua AUX và không chữa GPU hang. Vì vậy chưa thể khẳng định màn hình luôn Online, hết AUX timeout, hoặc boot thành công 100%. Log trước đó còn accelerator stamp timeout và một panic IO80211Family riêng.

`framebuffer-con0-type=02000000` tương ứng LVDS/eDP trong enum của driver. Nhưng NootedGreen đã đặt connector 0 thành type 0x2 trong `getOSInformation`, flags 0x18. Không tìm thấy bộ đọc `framebuffer-con0-*` trong source build này, WhateverGreen không bật đồng thời; thêm các khóa đó không chứng minh connector thực sự đổi.

`flags=05000000` không phải định nghĩa eDP chuẩn: 0x05 không có bit AlwaysConnected 0x08. R3 giữ flags 0x18 đang có bit này. Chưa có căn cứ thay bằng 0x05.

Nhận định "ngreen-dmc=adlp đang ghi combo-PHY Dell gây lệch điện áp" chưa được chứng minh. Đoạn gọi `setSignalLevelsADLP` trong chính nguồn R2 đã được comment-out. Bỏ cờ vẫn thay đổi đường DMC/context registers và là phép thử hợp lý, nhưng không được mô tả là đã xác nhận lỗi điện áp.

## Cần xác nhận sau boot

1. Boot-args thực tế không còn ngreen-dmc=adlp và log chọn fallback (nếu buffer ghi được).
2. Registry IGPU có override 256 byte đúng hash, display dùng đúng EDID, panel built-in/Online và có hình ổn định. Việc chỉ thấy property trong registry chưa chứng minh driver đã dùng nó.
3. GPU stamp, AUX/EDID errors và WindowServer offline so với lần boot trước; lưu ý hai giờ log có thể chứa nhiều lần boot, phải phân biệt timestamp.
4. Thử hiển thị trước ở 60 Hz nếu chọn được; chỉ xác nhận 165 Hz sau khi đo trạng thái thật.
5. Nếu R3 vào được, cần thử riêng EDID/DMC khi muốn kết luận thành phần nào là nguyên nhân; thành công khi đổi cả hai chưa phân biệt được.

## Nguồn

- Source build R2, đã đối chiếu SHA-256 với `reports/build-release.json`; các trích đoạn và số dòng ở `evidence/`.
- [NootedGreen README: lựa chọn DMC](https://github.com/sgiammori/NootedGreen/blob/main/README.md).
- [WhateverGreen Sample.dsl: cú pháp override có index](https://github.com/acidanthera/WhateverGreen/blob/master/Manual/Sample.dsl).
- [WhateverGreen kern_fb.hpp: LVDS/eDP và connector flags](https://github.com/acidanthera/WhateverGreen/blob/master/WhateverGreen/kern_fb.hpp).
- [Linux DRM helpers: AUX, EDID và DPCD](https://kernel.org/doc/html/latest/gpu/drm-kms-helpers.html).
