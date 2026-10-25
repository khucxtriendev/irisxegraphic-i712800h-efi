# Đối chiếu EFI old / NullMoth với Intel hiện tại

Đã đọc `/Volumes/1401/EFI old/OC/config.plist`: bật nvfb/nvaccel, AMFIPass + WhateverGreen, không spoof Intel 9A49 và không ẩn NVIDIA. EFI Intel hiện tại bật NootedGreen, spoof 9A49 và ẩn NVIDIA. Kext/Metal plugin NullMoth cài trong macOS, không nằm trong EFI; hiện các file đó được giữ ở `~/Desktop/NVIDIA_Backup_20261022`, không còn ở `/Library/Extensions` và `/Library/GPUBundles`. Vì vậy không coi việc chỉ boot lại EFI old hiện nay là tái lập đúng trạng thái NVIDIA trước đây.

Người dùng xác nhận số Dock hiển thị khi dùng NVIDIA. Báo cáo lịch sử `BAO-CAO.md` cũng ghi nhận NVRM/NVAccel active và WindowServer chạy qua NVMTL ở thời điểm dùng stack NVIDIA. Log lúc 20:09 ngày 25/10 thuộc giai đoạn đã bỏ driver NVIDIA và dùng firmware framebuffer; không được dùng log đó phủ nhận tăng tốc NVIDIA ở thời điểm trước.

[NullMoth PR #274](https://github.com/nullmoth/nvidia-macos-driver/pull/274) sửa số badge bằng cách điền mip còn thiếu sau upload mip 0. [PR #271](https://github.com/nullmoth/nvidia-macos-driver/pull/271) sửa ánh xạ kênh A8 render target, là vấn đề khác.

[Intel issue #10](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe/issues/10) xác nhận cùng triệu chứng và đã sửa ở [libxedrv v19, commit 125f089](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe/commit/125f089fcc90520cd5565dee19f26c968f3d5c59). Điểm vào Intel là NoCopy với nhiều mip, khác đường upload thông thường. CoreAnimation chỉ cung cấp dữ liệu mip 0, nên phải tạo managed snapshot và sinh mip còn lại trước khi trả texture.

Bản cục bộ trước sửa chỉ nhận `mipmapLevelCount == 1`; thử trước đó có tự gọi generateMipmaps nên không tái hiện trường hợp lỗi. Bản sửa hiện mở đường NoCopy nhiều mip cho ảnh 8-bit đọc, giữ format của texture nhiều mip, kiểm tra span/offset/stride, giữ deallocator và xử lý lỗi tạo queue/encoder/command. Thử A8→RGBA đơn mip của người dùng vẫn được giữ để không gộp thay đổi ngoài mục tiêu. Không chép shader hoặc kext NVIDIA sang Intel.

Chưa cài bản sửa khi viết báo cáo này. Cần phép thử `test-mip-fix.command` trong Terminal và kiểm tra Dock thật sau khi WindowServer nạp bundle mới. EFI R3 không thay đổi.
