# Kiểm tra “EFI new” — 25/10/2026

Đối tượng lỗi do người dùng xác nhận: `/Volumes/1401/EFI new`. Bản đang dùng để vào được macOS là `/Volumes/1401/EFI`. Chưa sửa USB, driver hệ thống hoặc NVRAM trong lượt kiểm tra này.

## Kết quả đã xác minh

- 156 file của bản build `Documents/gen5_igpu_driver/EFI` đều có mặt và khớp SHA-256 trên `EFI new` (bỏ `.DS_Store`). Không có tham chiếu đang bật trỏ tới kext, AML hoặc UEFI driver bị thiếu.
- `config.plist` đọc được và qua `plutil -lint`; 33 kiểm tra thứ tự phụ thuộc kext, checksum AML và xung đột patcher không báo lỗi. Chưa chạy `ocvalidate`; các kiểm tra này không chứng minh boot thành công.
- NootedGreen trên USB đúng R2, SHA-256 `6b99b13c5ca22f7314e960a3bb6a95b8d4421c0728c06c436515fcd73ea0bb5d`; chữ ký ad-hoc qua kiểm tra. WhateverGreen có file nhưng không được bật đồng thời.
- Ba binary trong Metal bundle đang cài ở `/Library/GPUBundles` khớp bản build: AppleIntelTGLGraphicsMTLDriver, libigdmd.dylib, libxedrv.dylib. Metal bundle và shader compiler `/System/Library/Caches/xe.bundle` qua kiểm tra chữ ký. Chưa thấy bằng chứng thiếu hoặc lệch các thư viện này.
- TGL accelerator, framebuffer và HookCase có trong `/Library/Extensions`. Đọc trực tiếp `AuxiliaryKernelExtensions.kc` xác nhận cả ba có trong kernel collection (xem `auxiliary-collection.txt`). Đây là bằng chứng đăng ký vào collection, chưa phải xác nhận chúng đã khởi động thành công trong lần boot lỗi.
- `codesign` báo accelerator bị sửa chữ ký và framebuffer không có chữ ký. Đây là các kext Apple đã patch đang có từ trước, không phải NootedGreen R2 hoặc Metal bundle mới. Không tự ký lại hoặc rebuild kernel collection khi chưa có log từ chối nạp. Cấu hình SIP/AMFI và tình trạng nạp thực tế cần xem cùng nhau.

## Hai đường đồ họa khác nhau

EFI cũ đang có boot-args `nvfb=1 nvaccel=1 ...`, WhateverGreen + AMFIPass bật, cấu hình chặn IONDRVSupport; không có NootedGreen. EFI mới spoof Intel 9A49, bật NootedGreen và đặt thuộc tính ẩn NVIDIA. NVRAM đọc trong phiên hiện tại khớp boot-args EFI cũ. **Không suy từ các boot-args này rằng NVIDIA đang tăng tốc:** log runtime mới thu xác nhận EFI cũ hiện xuất hình bằng `IGPU@2/IONDRVFramebuffer`, `accel=0`, `isAcc=NO`; kết nối framebuffer NVIDIA không mở được. Danh sách kext đang nạp không có NootedGreen, TGL accelerator/framebuffer hoặc driver NVIDIA. Vì vậy việc EFI cũ vào được chỉ xác nhận đường firmware framebuffer còn hoạt động.

Đã đối chiếu thêm `EFI igpu 5.zip` trên USB: OpenCore/BOOT binary, phần thiết lập iGPU và Booter quirks giống EFI mới. NootedGreen khác, đồng thời bản mới thêm audio layout 11 và USB map. Không có cơ sở đổi ngẫu nhiên Booter quirks theo EFI NVIDIA để sửa Intel.

## Lỗi thực tế đã tìm được

`Kernel-2026-10-25-200427.panic`: lúc 20:04:27 +0700, uptime khoảng 441,8 giây, boot-args khớp tiền tố cấu hình Intel mới. Panic `waitq ... lock timeout`; stack thread gặp lỗi đi qua `IO80211Family`, `IO80211Glue`, `IO80211SkywalkInterface`.

Đây là một lỗi cần điều tra ở luồng Wi-Fi/IPC. Stack này **không chứng minh AirportItlwm là nguyên nhân gốc**, không loại trừ hỏng bộ nhớ từ thành phần khác và không chứng minh panic gây màn hình đen từ đầu. AirportItlwm của EFI cũ và mới có cùng SHA-256.

## Điểm nghi vấn trong mã scanout

Trong `kern_gen11.cpp`, `p1InitRangeAllocator` đặt chỗ phần giao với bank 16–160 MiB. Nếu đặt chỗ thất bại, nó đánh dấu lỗi và trả false từ hàm khởi tạo allocator. Trong `p1_scanout.hpp`, alias còn có thể bị từ chối do layout, PTE hoặc giới hạn vùng nhớ. Khi `redirect` trả false, caller giữ SURF gốc, kể cả địa chỉ ngoài aperture.

Mã trước thay đổi mô tả remap aperture là cần thiết cho scanout trên ADL/RPL. Vì vậy nhánh từ chối trên có thể dẫn tới mất hình, dù tránh ghi GGTT khi chưa bảo đảm quyền sở hữu. **Chưa có log runtime xác nhận nhánh nào đã chạy**; không được coi đây là nguyên nhân đã kết luận hoặc hoàn tác bảo vệ vùng nhớ một cách mù quáng.

## Dữ liệu còn thiếu và bước tiếp

Phiên công cụ không đọc được unified log (`log: Cannot run while sandboxed`), còn `kmutil showloaded` không lấy được danh sách đang nạp. Đã tạo `scripts/collect-efi-new.command` để người dùng chạy trong Terminal khi vẫn ở EFI cũ. Script chỉ đọc, lấy log kernel/WindowServer/amfid/loginwindow trong khoảng lần boot lỗi 19:50–20:06, trạng thái nạp hiện tại và registry đồ họa. Không cài driver, sửa EFI/NVRAM hoặc restart. `bash -n` đã qua.

Chưa xác nhận sửa được boot. Cần log lần boot lỗi để phân biệt: driver bị từ chối nạp, accelerator không khởi tạo, scanout alias bị từ chối, WindowServer không khởi động hoặc treo sau khởi động. Không cần thử boot lại để lấy các log đã lưu này.

## Cập nhật từ log người dùng chạy lúc 20:22

Đã đọc `runtime-20261025-202224`. Cả tám lệnh thu dữ liệu trả exit 0. `failed-boot-log.txt` chứa hai điểm khởi động kernel trong khoảng được thu; không gộp tất cả thành một lần boot. `loaded-kexts.txt` và `current-graphics-log.txt` thuộc EFI cũ lúc 20:09 trở đi, không dùng chúng để kết luận danh sách kext nạp trong EFI mới.

Các bằng chứng trực tiếp trong chuỗi log 19:52:

| Thời gian | Bằng chứng |
| --- | --- |
| 19:52:29.703 | AppleMobileFileIntegrity xác nhận signature enforcement đã bị tắt bằng boot-arg. |
| 19:52:50.678–50.829 | HookCase khởi động; TGL accelerator probe thấy Intel 9A49; TGL framebuffer thực thi mã khởi tạo. Việc file kext bị sửa/không ký không đồng nghĩa nó đã bị chặn trong lần này. |
| 19:52:50.830 | `FBMemMgr_Init: Insufficient stolen memory`. Chưa có số đo DVMT thực; không tự quy lỗi cho thiết lập BIOS hoặc bank alias từ riêng dòng này. |
| 19:53:18.735–22.737 | `IOAccelEventMachine2::waitForStamp`: IntelAccelerator không hoàn thành stamp 3, gpu_stamp vẫn là 2. |
| 19:53:26.170–28.687 | `Unsupported DDI`, DDI0 AUX timeout, FB0 đọc EDID lỗi `0xe00002d6`, sau đó `Display resources already allocated - bailing out`. |
| 19:54:53.452 | Chính WindowServer PID 201 ghi `libxedrv ... carregada em WindowServer ... entries=1 pd=1 rhm=1 layout=1 lab=0`. **Thư viện đã được nạp trong lần lỗi**, không chỉ có file trên đĩa. |
| 19:55:07–32 | WindowServer tiếp tục đánh dấu màn hình chính offline; các display Intel được dựng không có trạng thái built-in hợp lệ trong phần log này. |

Các sự kiện đã trích kèm số dòng trong `failed-boot-key-events.txt`. Đường xuất hình bị lỗi nằm ở tầng Intel accelerator/framebuffer/nhận diện màn hình; không có bằng chứng cho giả thuyết không tìm thấy libxedrv. GPU stamp timeout và lỗi AUX/EDID là các lỗi thực tế, nhưng chưa xác định lỗi nào là nguyên nhân đầu tiên, lỗi nào là hệ quả. `Insufficient stolen memory` không phải căn cứ đủ để đổi DVMT hay cắt bớt bảo vệ GGTT.

Unified log không có `P1-SCANOUT`, `P1-SURF`, `XeNG` hoặc log Lilu. **Thiếu log không chứng minh NootedGreen không nạp**: chưa có danh sách kext hoặc buffer chẩn đoán NootedGreen của đúng lần boot lỗi. Do đó chưa xác nhận hoặc loại được giả thuyết allocator/scanout đã nêu. Không coi `IOVersatile`/các lỗi phụ thuộc không liên quan trực tiếp là chứng cứ Metal library bị thiếu.

Đối chiếu thêm driver cũ: `/Users/kxt/xe-build/build/NootedGreen.kext` khớp SHA-256 driver trong `EFI igpu 5.zip` (`08fd9e5d...1cccf91`). Ngoài scanout, nguồn vendor mới có thêm thay đổi forcewake/RC6, GPU reset recovery, topology và blit so với cây `xe-build`; chưa có bằng chứng quy lỗi cho một thay đổi riêng. Import mới duy nhất so với binary cũ là `_memset`, và kernel đang có xuất symbol này. Chữ ký NootedGreen cũ và R2 đều dùng page size 4096; không quy các thông báo page shift 14 chung trong log cho kext R2.

Kết luận hiện tại: đã xác định giai đoạn lỗi và xác nhận user-space shim nạp được; **chưa có bản sửa boot đã được chứng minh**. Giữ nguyên USB và driver hệ thống. Cần xác nhận người dùng đang dùng panel laptop hay cổng màn hình ngoài, tình trạng BIOS Hybrid/Discrete, và trạng thái khởi tạo thực tế của NootedGreen trước khi chọn thay đổi kernel/config tiếp theo.
