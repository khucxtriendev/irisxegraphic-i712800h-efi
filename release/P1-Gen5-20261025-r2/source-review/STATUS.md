# Rà soát mã nguồn đồ họa — 25/10/2026

Đã sửa mã nguồn trong `~/Documents/gen5_igpu_driver/vendor/iris-xe/` và **đã build NootedGreen + libxedrv vào bộ EFI/release mới** theo yêu cầu tiếp theo. Chữ ký các artifact mới đã kiểm tra. Chưa cài lên hệ thống hay EFI đang boot, chưa kiểm tra hiển thị thực tế. Chưa có cơ sở kết luận cả bốn lỗi đã hết trên máy. Xem `../reports/build-release.json` và `../docs/CAI-DAT.md`.

| Vấn đề | Thay đổi đã có trong mã | Mức xác minh |
| --- | --- | --- |
| Nháy góc trên/menu bar | Bank alias bắt đầu tại 16 MiB; không ghi các PTE thấp tại 0 và 0x18000. Thêm hook đặt chỗ qua bộ cấp phát trước khi dùng bank. | Qua kiểm tra CPU về biên và điều kiện đặt chỗ; chưa boot xác minh hook và hình ảnh. |
| Nháy góc dưới | Bỏ giới hạn 4000 trang; tính số trang từ kích thước, stride, định dạng và tiling. Mỗi slot 6144 trang, tối đa 6016 trang dữ liệu, phần còn lại lặp PTE cuối hợp lệ, tối thiểu 128 trang đệm. Từ chối dữ liệu thiếu hoặc vượt slot. | Qua kiểm tra CPU với native và HiDPI; chưa đo FIFO/prefetch hoặc xác nhận hết nháy. |
| Nháy chuột/hover | Sáu slot với chỉ số cố định; không dịch metadata. Bảo vệ slot đang quét, chờ quét và vừa được arm; cache so PTE nguồn hiện tại với bản PTE đã lưu trong RAM; không đọc PTE đích, vô hiệu hóa sau reset/resume. | Cache hit không ghi PTE trong mô phỏng; vẫn đọc MMIO và có thể thay slot khi cache đầy. Chưa đo độ trễ thực tế. |
| Mất số thông báo Dock | R2 chủ động copy managed cho ảnh 2D đủ điều kiện ở cả offset 0/aligned, không chờ native trả nil. Giữ kiểm tra biên/định dạng, loại GPU-writable/render target, xử lý callback và ngoại lệ. | Qua kiểm tra CPU: native giả trả object hợp lệ nhưng wrapper vẫn chọn managed upload, đúng dữ liệu alpha và callback một lần. **Chưa có phép kiểm tra GPU/Dock thực tế; không khẳng định sắc nét hoặc hết lỗi 100%.** |

## Giới hạn đã làm rõ

- 4096 trang tương đương 16 MiB, không phải yêu cầu căn chỉnh mọi surface tới 4096 trang. Bộ đệm nhỏ hơn được điền phần alias còn lại, không đọc sang IOSurface bên cạnh để cố đủ 4096 trang. Không quét tới PTE invalid vì vùng hợp lệ kế bên có thể thuộc đối tượng khác.
- 6 × 24 MiB là 144 MiB **không gian địa chỉ GGTT**, từ 16 tới 160 MiB. Không chỉ kiểm tra aperture 256 MiB rồi giả định vùng này thuộc quyền sử dụng: hook đặt chỗ phần giao của các range allocator với bank. Nếu không có hook/đặt chỗ, aperture thiếu hoặc PTE không hợp lệ thì giữ SURF gốc.
- Layout hỗ trợ trong helper: packed RGB không nén, linear hoặc X-tiled, không rotation/offset. Layout khác giữ đường native; không đoán định dạng hay cắt bớt surface lớn để vừa slot.
- Các khoảng GGTT thấp không bị helper ghi đè không đồng nghĩa đã chứng minh toàn bộ nguyên nhân nháy góc trên. Tương tự, 128 trang đệm không chứng minh hết underrun FIFO. Không có cam kết “không bao giờ evict”, “zero MMIO” hoặc hết nháy chuột từ kiểm tra CPU.
- Offset 0 là giá trị hợp lệ. R2 chủ động copy ảnh NoCopy 2D đủ điều kiện như yêu cầu; bản sao là snapshot, không tự phản ánh lần CPU sửa dữ liệu nguồn về sau. Không áp cho ShaderWrite/render target. Nếu managed allocation không thành công thì giữ đường native/gated fallback; khi native trả nil mà quyền sở hữu chưa rõ thì không đoán để đọc bộ nhớ.
- R2 bỏ 24.576 lần đọc MMIO của slot đích trên mỗi hit (readPte thực hiện 4 lần đọc 32 bit khi ổn định). Hit native: 40.580 → 16.004; HiDPI: 45.280 → 20.704 lần đọc. Đó là số lời gọi đếm bằng IO giả, không phải phép đo ms/FPS. PTE nguồn vẫn phải đọc: cùng VA/layout không chứng minh backing chưa tái sử dụng. Để loại cả đọc nguồn cần theo dõi generation/lifetime mapping thật, hiện chưa có.
- Không có số đo chứng minh 12 ms → 0.001 ms hay panel chạy 165 Hz. CPU sanitizer không xác nhận đồng bộ GPU, lifetime của surface đang quét, hoặc hoạt động của hook trong kernel.

## Kiểm tra đã hoàn thành

- `check-cpu.sh`: hai chương trình kiểm tra CPU với AddressSanitizer và UndefinedBehaviorSanitizer, không tạo Metal device/command queue và không ghi GPU. Cả hai PASS; xem `cpu-checks.log`.
- `scanout-check.cpp`: giao range và tràn số, stride/native/HiDPI, layout không hỗ trợ, cache hit, PTE đổi khi VA tái sử dụng, hơn sáu surface, bảo vệ slot đang dùng, PTE thiếu, aperture/đặt chỗ thiếu và reset.
- `nocopy-check.m`: gọi trực tiếp hai wrapper NoCopy với thiết bị giả, chủ động copy ảnh offset 0/aligned/unaligned ngay cả khi native có thể trả object hợp lệ; passthrough GPU-writable, callback đồng bộ/muộn một lần, fallback khi copy thất bại, ngoại lệ allocation/upload và biên vùng nhớ. Trang nguồn được bảo vệ khi callback giải phóng để phát hiện đọc sau giải phóng. Không phải phép kiểm tra badge Dock.
- `clang++ -fsyntax-only` trên `kern_gen11.cpp`: PASS, còn cảnh báo có sẵn trong mã upstream; xem `kernel-syntax.log`.
- `clang -fsyntax-only` trên `libxedrv.m`: PASS; xem `shim-syntax.log`.
- Ở cuối giai đoạn sửa nguồn, trước khi người dùng yêu cầu build: 155 file EFI, 155 file EFI-upstream và 93 payload giữ nguyên hash, ghi trong `existing-artifacts-unchanged.json`. **Đây là kết quả lịch sử trước build**, không phải hash artifact mới. Hash mới ở `../reports/efi-sha256.json` và `../reports/payload-sha256.json`.

## Bằng chứng và thay đổi

Hook dùng symbol riêng `IGRangeAllocator::initWithRange(IGAddressRange, unsigned long long)`. Đã đối chiếu ABI x86_64 với disassembly của AppleIntelTGLGraphics đang có trên máy: cấu trúc hai số 64 bit, base IORangeAllocator tại offset 0; `IGStolenMemoryPool` cũng tạo IGRangeAllocator. Hash binary nằm trong `allocator-abi.json`, các đoạn disassembly trong `allocator-abi-excerpts.txt`. Đối chiếu thêm khai báo `allocateRange` trong `vendor/iris-xe/build/deps/MacKernelSDK/Headers/IOKit/IORangeAllocator.h`.

Đây là bằng chứng tĩnh, chưa xác nhận route runtime, khả năng khởi tạo khi giảm vùng cấp phát, hay tính tương thích với phiên bản AppleIntelTGLGraphics khác.

Mã trước sửa nằm trong `before/`; hash trước/sau trong `before-sha256.json` và `after-sha256.json`. `source-changes.patch` chứa đầy đủ thay đổi của sáu file nguồn. `kern_gen11.cpp` dùng helper mới `p1_scanout.hpp`; `libxedrv.m` dùng kiểm tra phạm vi trong `xe_image_span.h`.

Sau khi được yêu cầu build, `EFI/` đã được thay bằng NootedGreen mới và `build/userland/` đã được build lại. Binary trước lượt sửa nằm trong `../build/previous-before-hardware/`. Chép EFI áp dụng phần kernel; cần cập nhật riêng libxedrv theo hướng dẫn để áp dụng phần user space. Không tự cài đặt trong quá trình build.
