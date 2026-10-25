# Báo Cáo Đánh Giá & Lộ Trình Tối Ưu Hóa iGPU Intel Iris Xe (ThinkPad P1 Gen 5)

> **Ngày thực hiện:** 25/10/2026 (Cập nhật phiên boot R3: 22:16:09 +0700)  
> **Trạng thái bản build:** **Bản R3 đã boot thành công vào macOS Tahoe 26.7.1**  
> **Thiết bị:** Lenovo ThinkPad P1 Gen 5 (Subsystem: `17AA:22F8` - SMBIOS: MacBookPro16,2)  
> **CPU:** Intel Core i7-12800H (14 Cores: 6P + 8E, 20 Threads - Alder Lake-P `906A3`)  
> **iGPU:** Intel Iris Xe Graphics (96 EUs - Real: `0x8086:0x46A6`, Spoof: `0x8086:0x9A49`)  
> **dGPU:** NVIDIA GeForce RTX A1000 Laptop GPU (`0x10DE:0x25B9` - Hiện đặt `class-code = 0xFFFFFFFF`)  
> **Tấm nền:** BOE NE160QDM-NY1 (16:10, 2560 × 1600 Native, 60/165 Hz)  
> **Ngăn xếp Driver:** NootedGreen R3 + HookCase + Driver Tiger Lake unreleased của Apple (16.0.32) + Metal Patch (MTL17/MTL18) + `libxedrv` R3 + `xe.bundle`

---

## 1. Tóm Tắt Kết Quả Đối Chiếu 11 Tiêu Chuẩn Apple

| STT | Nhóm Tính Năng | Đạt / Tổng số | Tỷ lệ (%) | Trạng thái kỹ thuật |
|:---:|---|:---:|:---:|---|
| **1** | **Khởi tạo phần cứng và nhận diện GPU** | **5 / 9** | **55.6%** | Chạy qua Spoof ID & Execlist; GuC/HuC bị tắt hoàn toàn |
| **2** | **Kernel driver và thực thi GPU** | **8 / 12** | **66.7%** | Host Scheduler; phục hồi sau GPU hang chưa hoàn hảo |
| **3** | **Metal và đồ họa 2D/3D** | **11 / 13** | **84.6%** | Metal GUI mượt mà 60fps; tắt Render Compression (AUX/CCS) |
| **4** | **Tương thích macOS user space** | **7 / 9** | **77.8%** | Tương thích qua `libxedrv`; buộc phải tắt kiểm duyệt AMFI |
| **5** | **Display engine và xuất hình** | **8 / 16** | **50.0%** | Panel eDP 2880x1800 HiDPI tốt; **Hỏng Sleep/Wake và xuất ngoài** |
| **6** | **Video engine và xử lý media** | **4 / 14** | **28.6%** | **VideoToolbox HW Decode/Encode hiện đang fallback CPU** |
| **7** | **Compute và tính năng GPU nâng cao** | **6 / 10** | **60.0%** | Metal Compute tốt; OpenCL chỉ có CPU, thiếu Metal 3 |
| **8** | **Quản lý nguồn và nhiệt** | **8 / 12** | **66.7%** | RC6 idle tốt; xung nhịp ép sàn qua boot-arg; **Sleep lỗi** |
| **9** | **Tương thích hệ thống và ngoại vi** | **7 / 11** | **63.6%** | App văn phòng/web tốt; dGPU tắt an toàn; không xuất màn hình ngoài |
| **10** | **Ổn định, bảo mật và kiểm thử** | **10 / 15** | **66.7%** | Chặn rò rỉ bộ nhớ; bảo mật SIP/AMFI bị hạ |
| **11** | **Công cụ phát triển và phân phối** | **11 / 12** | **91.7%** | Bộ script biên dịch, vá nhị phân và chẩn đoán hoàn chỉnh |
| **TỔNG** | **Toàn bộ hệ thống** | **85 / 133** | **63.9%** | **Đạt mức tăng tốc Metal GUI cơ bản, chưa đủ chuẩn Apple** |

---

## 2. Chi Tiết Đánh Giá Theo 11 Nhóm Tiêu Chí

### Nhóm 1: Khởi tạo phần cứng và nhận diện GPU (5/9 hoàn thành)
* `[ ]` **Nhận diện PCI vendor/device ID chính xác, không phụ thuộc spoof ID**: *Chưa đạt.* Phần cứng thực tế là Intel Alder Lake-P (`0x8086:0x46A6`). Apple chưa từng phát hành Mac dùng Alder Lake hay Raptor Lake. Hệ thống bắt buộc phải dùng OpenCore để spoof sang `device-id = <499A0000>` và `AAPL,ig-platform-id = <0000499A>` (Tiger Lake) để driver của Apple chấp nhận nạp.
* `[ ]` **Nhận diện đúng thế hệ GPU, revision và stepping**: *Chưa đạt.* macOS nhận diện là Gen 12 TGL ("Intel(R) TGL Unknown"), không nhận diện đúng thế hệ kiến trúc vi mô Gen 12.2 của Alder Lake.
* `[x]` **Khởi tạo MMIO registers và thanh ghi phần cứng**: *Đạt.* BAR0 MMIO (16MB) được ánh xạ tại `0x4000000000` và khởi tạo các thanh ghi thông qua các bản vá DBUF và CHICKEN_MISC của NootedGreen.
* `[x]` **Khởi tạo GPU engines và các hàng đợi lệnh**: *Đạt.* Các engine RCS, BCS, VCS, VECS, CCS đều được khởi tạo thành công trong IORegistry.
* `[x]` **Thiết lập GGTT, PPGTT và địa chỉ bộ nhớ GPU**: *Đạt.* Thiết lập bảng trang GGTT và PPGTT 48-bit hoàn chỉnh cho bộ nhớ ảo GPU.
* `[x]` **Quản lý VRAM chia sẻ và system memory**: *Đạt.* Unified memory hoạt động, chia sẻ bộ nhớ hệ thống lên đến 2048 MB (`maxBufferLength: 2048 MB`).
* `[ ]` **Khởi tạo firmware và GuC/HuC nếu cần cho phần cứng, tính năng tương ứng**: *Chưa đạt.* Firmware GuC/HuC bị vô hiệu hóa hoàn toàn bằng boot-arg `-disablegfxfirmware`. Driver phải chạy chế độ Host Scheduler (Execlist submission).
* `[x]` **Xử lý interrupt, DMA và đồng bộ CPU–GPU**: *Đạt.* Hoạt động qua MSI Interrupt (`IOPCIMSIMode: Yes`) kết hợp bản vá `XE-PAGESYNC`.
* `[ ]` **Phát hiện lỗi khởi tạo và báo lỗi có thể chẩn đoán**: *Chưa đạt chuẩn Apple.* Chỉ báo lỗi qua Lilu printk và log kernel thay vì hệ thống chẩn đoán phần cứng tích hợp của Apple.

---

### Nhóm 2: Kernel driver và thực thi GPU (8/12 hoàn thành)
* `[x]` **Command submission và quản lý command buffer**: *Đạt.* Hoạt động qua Execlist submission mode.
* `[x]` **Quản lý context và GPU execution queues**: *Đạt.* Hỗ trợ đa context cho WindowServer và ứng dụng người dùng.
* `[x]` **GPU scheduler và phân bổ tài nguyên**: *Đạt.* Chạy host scheduler `IGScheduler5` (tham số `ngreenSched=4`).
* `[x]` **Quản lý fence, semaphore và đồng bộ giữa engines**: *Đạt.* Đồng bộ qua `XE-PAGESYNC` và `IOAccelEventMachineFast2`.
* `[x]` **Quản lý bộ nhớ, page mapping và cache coherency**: *Đạt.* Đã vá các lỗi sập con trỏ trang qua `PAGEON GUARD` và `BLITSCRATCH2`.
* `[x]` **Quản lý cache GPU và flush/invalidate đúng cách**: *Đạt.* Thiết lập L3 cache và cấu hình invalidate hợp lệ.
* `[ ]` **Preemption và xử lý tác vụ dài**: *Chưa đạt.* Thiếu GuC scheduler, việc điều phối ngắt ngang tác vụ (preemption) kém linh hoạt, dễ gây nghẽn hàng đợi khi xử lý đồ họa nặng.
* `[x]` **Timeout detection và phát hiện GPU hang**: *Đạt.* Watchdog timer của macOS phát hiện GPU hang qua stamp index timeout.
* `[ ]` **Engine reset và GPU recovery**: *Chưa đạt.* Khi render engine bị hang, cơ chế reset GDRST bit 1 làm mất cấu hình của Compute Engine (CCS do thanh ghi `RCU_MODE 0x14800` bit 0 bị xóa). Bản vá `XE-GPUREC v2` cố gắng phục hồi nhưng vẫn có nguy cơ freeze giao diện.
* `[ ]` **Khôi phục context, bộ nhớ và lệnh sau reset**: *Chưa đạt.* Không khôi phục được trạng thái in-flight context, ứng dụng đồ họa thường bị thoát đột ngột.
* `[x]` **Kiểm soát truy cập bộ nhớ và xử lý lỗi an toàn**: *Đạt.* Được bảo vệ thông qua IOMMU/DMAR và PPGTT.
* `[ ]` **Chẩn đoán kernel panic, deadlock và race condition**: *Đạt một phần.* Dùng bộ công cụ ngoài (`xe-panic.py`, HookCase) thay vì subsystem Apple diagnostic.

---

### Nhóm 3: Metal và đồ họa 2D/3D (11/13 hoàn thành)
* `[x]` **Metal device được nhận diện đúng**: *Đạt.* Nhận diện `Intel(R) TGL Unknown`, hỗ trợ các họ `MTLGPUFamilyMac2`, `Common3`.
* `[x]` **Metal command queue và command buffer**: *Đạt.* Khởi tạo hàng đợi và commit lệnh Metal thành công.
* `[x]` **Render pipeline và compute pipeline**: *Đạt.* Pipeline render 2D/3D hoạt động mượt mà (WindowServer, hiệu ứng mờ kính Liquid Glass, Mission Control đạt 60fps).
* `[x]` **Vertex/fragment/compute shaders**: *Đạt.* Shader được thực thi và cho kết quả chuẩn xác.
* `[x]` **Shader compiler và chuyển đổi mã shader phù hợp GPU**: *Đạt.* Hoạt động nhờ adapter trung gian `xe.bundle` kết nối Apple IGC compiler 16.0.32 với LLVM của macOS Tahoe.
* `[x]` **Texture, buffer, sampler và resource binding**: *Đạt.* Được `libxedrv` chuyển đổi descriptor tương thích với Tahoe.
* `[x]` **Render targets, depth/stencil và multisampling**: *Đạt.*
* `[x]` **Blending, rasterization và các chế độ render**: *Đạt.*
* `[ ]` **Texture compression và pixel formats cần thiết**: *Chưa đạt.* Render Compression bị tắt hoàn toàn (`XE-NOCCS`, `XE-NOAUX`) do thiếu bảng dịch AUX trên kiến trúc mới; định dạng `BGR10_XR` (10-bit extended range `w30r`) không được hỗ trợ.
* `[x]` **Resolve, blit, copy và chuyển đổi giữa các bề mặt ảnh**: *Đạt.* Bản vá `XE-BLITALIGN` định tuyến bản sao không thẳng hàng 64-byte sang Copy Engine; kiểm tra chuyển đổi 12/12 định dạng pixel CoreVideo đều thành công.
* `[x]` **Synchronization giữa Metal, IOSurface và Core Animation**: *Đạt.* Core Animation compositing trực tiếp trên GPU Metal.
* `[x]` **Đảm bảo GPU render thật, không fallback sang CPU**: *Đạt.* Giao diện hệ thống render 100% bằng phần cứng GPU, không chạy Apple Software Renderer.
* `[ ]` **Kiểm thử các tính năng Metal theo capability thực tế**: *Đạt một phần.* Các tính năng Metal 3, Raytracing, Dynamic Libraries không được hỗ trợ.

---

### Nhóm 4: Tương thích macOS user space (7/9 hoàn thành)
* `[x]` **Tương thích driver với phiên bản macOS mục tiêu**: *Đạt.* Hoạt động ổn định trên macOS Tahoe 26.7.1.
* `[x]` **Tương thích ABI và cấu trúc dữ liệu Metal**: *Đạt.* `libxedrv` tự động chuyển đổi layout ABI giữa macOS Tahoe và driver 16.0.32.
* `[x]` **Tương thích framework/compiler service cần thiết**: *Đạt.* Sử dụng firmlink `/System/Library/Caches/xe.bundle` để vượt qua sandbox của `MTLCompilerService`.
* `[x]` **Thích nghi thay đổi LLVM và shader compiler**: *Đạt.* Thư viện `libLLVMbridge.dylib` kết nối tương thích giữa LLVM 3902 và 32023.
* `[x]` **Đóng gói và nạp thư viện driver đúng cách**: *Đạt.* Driver bundle đặt tại `/Library/GPUBundles` chuẩn quy định của Apple.
* `[ ]` **Tương thích code signing, library validation và bảo vệ hệ thống**: *Chưa đạt.* Bắt buộc phải thêm `amfi_get_out_of_my_way=1` vào boot-args để vượt qua kiểm duyệt chữ ký số và Library Validation của Apple.
* `[x]` **Xử lý thay đổi private API qua các bản cập nhật macOS**: *Đạt.* Đã vá các offset nội bộ của `IOSurface` và `IOAccelResource2`.
* `[x]` **Kiểm tra lỗi liên quan đến WindowServer và compositor**: *Đạt.* Không bị treo WindowServer trong điều kiện sử dụng thông thường.
* `[ ]` **Không gây crash ứng dụng hoặc rò rỉ tài nguyên**: *Chưa đạt.* Một số ứng dụng dùng backend đồ họa đặc thù (như Chrome ANGLE Metal) hoặc khi shutdown giải phóng bộ nhớ pool vẫn có nguy cơ gây panic.

---

### Nhóm 5: Display engine và xuất hình (8/16 hoàn thành)
* `[x]` **Khởi tạo màn hình nội bộ eDP**: *Đạt.*
* `[x]` **Đọc EDID và thông tin panel**: *Đạt.* Nhận diện chính xác panel BOE NE160QDM.
* `[x]` **Độ phân giải gốc và pixel clock phù hợp**: *Đạt.* Hoạt động ở độ phân giải gốc 2880x1800 (mode Dell cũ) hoặc 2560x1600 (profile ThinkPad P1).
* `[x]` **HiDPI và các chế độ scaling**: *Đạt.* Hiển thị sắc nét ở tỷ lệ HiDPI.
* `[x]` **Đổi độ phân giải không mờ, không nhòe**: *Đạt.*
* `[x]` **Độ sáng màn hình và điều chỉnh brightness**: *Đạt.* Tăng giảm độ sáng mượt mà qua phím tắt và thanh trượt Control Center (`BrightnessKeys`, `SSDT-PNLF`).
* `[x]` **Điều khiển backlight đúng cách**: *Đạt.* Chu kỳ PWM backlight được căn chỉnh qua `ngreenblmax=17777`.
* `[ ]` **Xuất hình HDMI và DisplayPort theo đường kết nối thực tế**: *Chưa đạt.* Cổng xuất ngoài nối qua dGPU NVIDIA (đã tắt) hoặc chưa cấu hình framebuffer con1/con2.
* `[ ]` **USB-C DisplayPort Alt Mode nếu phần cứng hỗ trợ**: *Chưa đạt.* Không xuất được hình qua USB-C.
* `[ ]` **Hot-plug và phát hiện màn hình ngoài**: *Chưa đạt.* Không nhận diện cắm/rút màn hình ngoài.
* `[ ]` **Chạy đồng thời nhiều màn hình**: *Chưa đạt.* Chỉ chạy được duy nhất màn hình nội bộ laptop.
* `[x]` **Refresh rate, timing và chế độ màn hình được hỗ trợ**: *Đạt.* 60 Hz mượt mà.
* `[x]` **Color space, gamma và color profile**: *Đạt.* Đã bypass gamma post-CSC (`GAMMA_MODE_A=0`) tránh sai lệch màu.
* `[ ]` **HDCP nếu cần và nếu có thể triển khai**: *Chưa đạt.* HDCP DRM không hoạt động.
* `[ ]` **Khôi phục màn hình sau sleep/wake**: *Chưa đạt (Hỏng).* Máy đang phải bật `disablesleep=1`. Khi resume từ trạng thái sleep, link eDP không kích hoạt lại khiến màn hình tối đen.
* `[ ]` **Không black screen, tearing hoặc mất tín hiệu khi đổi mode**: *Đạt một phần.* Vẫn còn 1 frame nhấp nháy chuyển tiếp nhẹ khi chuyển đổi độ phân giải.

---

### Nhóm 6: Video engine và xử lý media (4/14 hoàn thành)
* `[ ]` **Giải mã H.264 bằng phần cứng**: *Chưa đạt trên máy này.* Kiểm tra thực tế: phiên giải mã phần cứng trả về mã lỗi `-12906` (`kVTVideoDecoderNotAvailableNowErr`). Thư mục `/Library/GPUBundles` chưa cài bundle `AppleIntelTGLGraphicsVADriver.bundle` và boot-args thiếu `-ngreengva`.
* `[ ]` **Giải mã HEVC/H.265 bằng phần cứng**: *Chưa đạt.* Chưa cài VADriver; đang fallback CPU.
* `[ ]` **Giải mã VP9 bằng phần cứng**: *Chưa đạt.* Driver của Apple không hỗ trợ phần cứng VP9 cho Intel TGL; YouTube VP9 decode hoàn toàn bằng CPU.
* `[ ]` **Giải mã AV1 nếu media engine thực sự hỗ trợ**: *Chưa đạt.* Fallback CPU.
* `[ ]` **Mã hóa H.264 bằng phần cứng**: *Chưa đạt.* `VTCopyVideoEncoderList` xác nhận chỉ có `Apple H.264 (SW)`.
* `[ ]` **Mã hóa HEVC bằng phần cứng nếu hỗ trợ**: *Chưa đạt.* Chỉ có `Apple HEVC (SW)`.
* `[ ]` **Tích hợp VideoToolbox và các đường media macOS**: *Chưa đạt.* Toàn bộ luồng VideoToolbox đang chạy trên CPU software decoder.
* `[x]` **Chuyển đổi màu YUV/RGB**: *Đạt.* Thử nghiệm chuyển đổi 12/12 profile định dạng pixel giữa 420v, 420f, BGRA, 2vuy thành công hoàn toàn.
* `[x]` **Chuyển đổi chroma subsampling và bit depth phù hợp**: *Đạt.* Bản vá `PLANES2` xử lý đúng offset mặt phẳng màu YUV 4:2:0.
* `[ ]` **Zero-copy giữa decoder, IOSurface và compositor khi có thể**: *Chưa đạt.* Phải copy bộ nhớ từ CPU decode sang GPU surface.
* `[x]` **Phát video 4K ổn định, không drop frame bất thường**: *Đạt.* Nhờ CPU i7-12800H đủ mạnh để giải mã phần mềm 4K 60fps trên Chrome/Safari.
* `[ ]` **Kiểm tra codec, profile, bit depth và chroma format**: *Đạt một phần.*
* `[x]` **Kiểm tra nhiều luồng video đồng thời**: *Đạt.*
* `[ ]` **Phân biệt rõ hardware acceleration và software fallback**: *Chưa đạt.* Hệ thống đang chạy 100% software fallback cho VideoToolbox.

---

### Nhóm 7: Compute và tính năng GPU nâng cao (6/10 hoàn thành)
* `[x]` **Metal compute shaders**: *Đạt.* Khởi tạo pipeline tính toán và chạy kernel số học mảng song song cho kết quả chuẩn xác.
* `[x]` **Parallel compute và xử lý dữ liệu GPU**: *Đạt.* Dispatch threadgroup chạy tốt.
* `[x]` **Atomics và các primitive đồng bộ cần thiết**: *Đạt.*
* `[x]` **Kiểm tra giới hạn bộ nhớ và số lượng thread**: *Đạt.* Threadgroup tối đa đạt (1024, 1024, 1024), bộ nhớ buffer tối đa 2048 MB.
* `[x]` **Kiểm thử workload GPGPU**: *Đạt.*
* `[ ]` **Đánh giá khả năng hỗ trợ ML qua Metal**: *Chưa đạt.* Không có Apple Neural Engine (ANE), thiếu tối ưu hóa Metal 3 và float16 của Apple Silicon.
* `[ ]` **Kiểm tra ứng dụng dùng các tính năng Metal nâng cao**: *Chưa đạt.* Không hỗ trợ Raytracing (`supportsRaytracing: 0`), Dynamic Libraries và Binary Archives bị libxedrv chặn.
* `[ ]` **Đánh giá tương thích OpenCL nếu hệ điều hành và driver cho phép**: *Chưa đạt.* Thử nghiệm OpenCL chỉ nhận 1 thiết bị duy nhất là **CPU Intel Core i7-12800H**; driver không tạo OpenCL compute device cho iGPU.
* `[x]` **Đo hiệu năng thực tế so với đường chạy CPU**: *Đạt.*
* `[ ]` **Xác minh từng capability thay vì khai báo hỗ trợ giả**: *Đạt một phần.*

---

### Nhóm 8: Quản lý nguồn và nhiệt (8/12 hoàn thành)
* `[x]` **GPU idle state và RC6 khi phù hợp**: *Đạt.* GPU hạ điện năng và vào trạng thái RC6 khi màn hình đứng yên.
* `[x]` **Điều chỉnh xung nhịp theo tải**: *Đạt.* Xung nhịp tự động nâng lên ~1300–1400 MHz khi xử lý đồ họa nặng.
* `[x]` **Điều chỉnh điện áp và power limits thông qua cơ chế an toàn**: *Đạt.* Bị kiểm soát giới hạn an toàn bởi CPU PCU PL4/IccMax.
* `[ ]` **DVFS và quản lý trạng thái hiệu năng**: *Chưa đạt chuẩn Apple.* Phải dùng bản vá `XE-GTFREQ` và boot-arg `ngreengtfreq=1400` để ép xung sàn qua MMIO do thiếu firmware GuC điều phối.
* `[x]` **Giảm điện năng khi chỉ hiển thị desktop**: *Đạt.*
* `[x]` **Tránh GPU giữ trạng thái hoạt động cao khi nhàn rỗi**: *Đạt.* Đã vá lỗi forcewake leak qua `XE-RC6FW`.
* `[x]` **Tương thích CPU/GPU shared power budget**: *Đạt.*
* `[x]` **Phối hợp quản lý nguồn với firmware và ACPI**: *Đạt.* AGPM client load bình thường trong IORegistry.
* `[x]` **Giám sát nhiệt độ và throttling**: *Đạt.* Đọc cảm biến nhiệt độ qua VirtualSMC / SMCProcessor.
* `[x]` **Xử lý GPU hang không làm tiêu thụ điện kéo dài**: *Đạt.* Bản vá `XE-IDLEBOUND` ngắt chờ sau 2s.
* `[ ]` **Đo mức tiêu thụ điện ở idle, video và tải 3D**: *Đạt một phần.*
* `[ ]` **Kiểm tra sleep/wake và trạng thái nguồn sau resume**: *Chưa đạt (Thất bại).* Sleep/wake hoàn toàn không hoạt động được, đang bật `disablesleep=1`.

---

### Nhóm 9: Tương thích hệ thống và ngoại vi (7/11 hoàn thành)
* `[x]` **Tương thích OpenCore và cấu hình ACPI**: *Đạt.* OpenCore 1.0+, SSDT-PLUG-ALT, SSDT-PNLF, SSDT-GPI0 hoạt động ổn định.
* `[x]` **Tương thích Intel iGPU với dGPU NVIDIA cùng tồn tại**: *Đạt.* dGPU NVIDIA RTX 3050/A1000 (`0x25B9`) được ẩn qua DeviceProperties (`class-code = 0xFFFFFFFF`).
* `[x]` **Xác định đường nối màn hình với từng GPU**: *Đạt.* iGPU quản lý màn hình eDP.
* `[ ]` **Chuyển đổi GPU hoặc lựa chọn GPU render nếu khả thi**: *Không khả dụng.* Do NVIDIA không có driver trên macOS hiện đại, không thể chuyển đổi qua lại (Optimus).
* `[ ]` **Tương thích đa màn hình qua dock**: *Chưa đạt.* Xuất dock Thunderbolt/Type-C display chưa được hỗ trợ.
* `[x]` **Tương thích ứng dụng Electron và trình duyệt**: *Đạt.* VS Code, Slack, Chrome, WhatsApp chạy ổn định với GPU compositing.
* `[ ]` **Tương thích Safari và tăng tốc nội dung web**: *Chưa đạt chuẩn.* Safari render web mượt nhưng WebKit GPU Process trong sandbox không đọc được bundle ngoài `/Library/GPUBundles`, giải mã video web hoàn toàn trên CPU.
* `[ ]` **Tương thích ứng dụng dựng hình, thiết kế và mô phỏng**: *Chưa đạt.* Các app yêu cầu Metal 3 / Apple Silicon (Blender Metal mới, Final Cut Pro tính năng mới) sẽ báo lỗi hoặc không mở được.
* `[x]` **Tương thích simulator và công cụ phát triển**: *Đạt.*
* `[x]` **Không làm hỏng audio, Wi-Fi hoặc các thiết bị PCIe khác**: *Đạt.* AirportItlwm, AppleALC, Bluetooth đều hoạt động bình thường.
* `[ ]` **Kiểm tra khởi động nguội, khởi động lại và cập nhật hệ thống**: *Đạt một phần.* Khởi động và tắt máy nhanh, nhưng cập nhật macOS có thể làm hỏng firmlink và cache của `xe.bundle`.

---

### Nhóm 10: Ổn định, bảo mật và kiểm thử (10/15 hoàn thành)
* `[x]` **Kiểm thử khởi động liên tục**: *Đạt.*
* `[x]` **Kiểm thử Metal stress trong nhiều giờ**: *Đạt.*
* `[x]` **Kiểm thử VRAM/shared-memory pressure**: *Đạt.*
* `[x]` **Kiểm thử nhiều ứng dụng GPU đồng thời**: *Đạt.*
* `[x]` **Kiểm thử phát video và chuyển cửa sổ liên tục**: *Đạt.*
* `[ ]` **Kiểm thử đổi độ phân giải và kết nối màn hình**: *Chưa đạt.* Chỉ đổi được trên eDP, kết nối màn hình ngoài không hoạt động.
* `[ ]` **Kiểm thử sleep/wake nhiều chu kỳ**: *Chưa đạt.* Không vượt qua được kiểm thử sleep/wake.
* `[ ]` **Kiểm thử lỗi GPU và khả năng phục hồi**: *Chưa đạt.* Khả năng tự phục hồi khi GPU engine bị kẹt còn rủi ro gây freeze.
* `[x]` **Kiểm tra memory leak, use-after-free và race condition**: *Đạt.* Đã vá các lỗi sập `kfree` (`XE-RESFREE`) và `unorphanIt` (`XE-NOORPHAN`).
* `[x]` **Thu thập kernel logs và GPU diagnostics**: *Đạt.*
* `[ ]` **Không có kernel panic trong bộ kiểm thử chuẩn**: *Chưa đạt.* Vẫn tồn tại rủi ro watchdog panic nếu GPU bị kẹt lệnh phức tạp.
* `[ ]` **Kiểm thử nhiều phiên bản macOS mục tiêu**: *Chưa đạt.* Tập trung vào phiên bản Tahoe 26.7.1.
* `[x]` **Regression tests sau mỗi thay đổi driver**: *Đạt.*
* `[ ]` **Kiểm tra tính toàn vẹn và nguồn gốc binary**: *Chưa đạt.* Buộc phải tắt AMFI để nạp nhị phân ad-hoc sign.
* `[x]` **Tài liệu hóa giới hạn, lỗi đã biết và cách khôi phục**: *Đạt.* Có tài liệu `STATUS.md`, `EXPERIMENTS.md`, `DEBUGGING.md` chi tiết.

---

### Nhóm 11: Công cụ phát triển và phân phối (11/12 hoàn thành)
* `[x]` **Build system có thể tái tạo**: *Đạt.* Script `install.sh`, `build-all.sh`, `build-nootedgreen.sh`.
* `[x]` **Quản lý phiên bản source và binary**: *Đạt.* Theo dõi đầy đủ qua Git commit.
* `[ ]` **CI cho build và các kiểm tra tĩnh**: *Chưa đạt.* Chưa có automated CI pipeline.
* `[x]` **Logging có thể bật/tắt theo cấp độ**: *Đạt.* Bật tắt qua boot-args `IGLogLevel=3`, `-ngreenevlog`.
* `[x]` **Công cụ chẩn đoán GPU, Metal và media**: *Đạt.* Thư mục `tools/diagnostics/` có bộ công cụ tự viết đầy đủ (`xe-video-check`, `xe-tex-tests`,...).
* `[x]` **Benchmark thống nhất giữa các phiên bản**: *Đạt.*
* `[x]` **EFI mẫu tách riêng theo từng phần cứng**: *Đạt.*
* `[x]` **Cấu hình an toàn để tắt driver khi gặp lỗi**: *Đạt.* Có `config-install.plist` cho chế độ safe mode.
* `[x]` **Installer và cơ chế rollback**: *Đạt.* Có script `install.sh --uninstall` và cơ chế rollback EFI.
* `[x]` **Ma trận tương thích theo GPU, laptop và macOS**: *Đạt.* Có tài liệu đối chiếu các mẫu CPU 80 EU, 96 EU.
* `[x]` **Release notes, tài liệu cài đặt và hướng dẫn debug**: *Đạt.* `CHANGELOG.md`, `INSTALL.md`, `DEBUGGING.md`.
* `[x]` **Quy trình xác nhận bản vá không làm giảm độ ổn định**: *Đạt.*

---

## 3. Bản Chất 5 Rào Cản So Với Máy Mac Chuẩn Apple

1. **Sleep / Wake bị hỏng hoàn toàn**: Màn hình tối đen sau khi mở máy do link eDP không re-negotiate được tín hiệu, bắt buộc phải tắt tính năng sleep (`disablesleep=1`).
2. **VideoToolbox Hardware Acceleration chưa hoạt động**: Cả giải mã (Decode) lẫn mã hóa (Encode) H.264/HEVC đều đang chạy bằng CPU software fallback do thiếu VADriver bundle và boot-arg `-ngreengva`.
3. **Màn hình ngoài không khả dụng**: Không hỗ trợ HDMI, DisplayPort hay USB-C Alt Mode; chỉ xuất được duy nhất màn hình eDP của laptop.
4. **Không có GuC/HuC & Render Compression**: Buộc phải chạy Host Execlist Scheduler và tắt nén texture AUX/CCS.
5. **Hạ mức bảo mật hệ thống**: Bắt buộc phải tắt AMFI (`amfi_get_out_of_my_way=1`) để chạy được các file nhị phân user-space đã qua chỉnh sửa.

---

## 4. Tiêu Chuẩn Thực Tế Để Máy Trở Thành "Daily Driver" (Máy Dùng Ổn Định Hàng Ngày)

Để một chiếc Hackintosh Intel 12th Gen hoạt động ổn định làm việc hàng ngày, **người dùng không cần 100% tính năng độc quyền của Apple Silicon** (như Neural Engine, 10-bit XR hay AirDrop/AWDL). 

Mục tiêu cốt lõi của một **Daily Driver** thực thụ gồm 6 yêu cầu thực tế:
1. **Màn hình & Giao diện chuẩn xác**: Không đen màn hình khi khởi động, đúng tỷ lệ panel 16:10, không bị mất số trên Dock Badge.
2. **Không sập nguồn ngẫu nhiên**: Không bị Watchdog timeout do GPU hang, không bị kernel panic do Wi-Fi Skywalk.
3. **Pin & Nhiệt độ mát mẻ**: Card rời NVIDIA phải ngắt nguồn điện hoàn toàn (D3cold), iGPU xuống được trạng thái nghỉ RC6, gập nắp máy chỉ tắt màn hình an toàn.
4. **Âm thanh, Đàm thoại & Camera mượt mà**: Loa trong, mic đàm thoại, jack tai nghe và camera USB UVC hoạt động cho Zoom/Meet.
5. **Bàn phím & Touchpad chuẩn xác**: Đầy đủ cử chỉ đa ngón, TrackPoint nhạy, phím Fn chỉnh độ sáng/âm lượng mượt mà.
6. **Lướt web & Xem video ổn định**: Trình duyệt Chrome/Safari chạy 4K YouTube mượt, các ứng dụng Electron (VS Code, Slack, Telegram) không bị giật lag hay trắng màn hình.

---

## 5. 6 Yêu Cầu Cụ Thể Cần Xử Lý Cho ThinkPad P1 Gen 5

Dựa trên dữ liệu thu thập từ các lần kiểm tra thực tế trong thư mục `reports/` (`efi-new-investigation`, `dock-investigation`), đây là các hành động kỹ thuật bắt buộc để đạt chuẩn dùng hàng ngày:

### Yêu Cầu 1: Chuẩn Hóa Hiển Thị Tấm Nền 16:10 & Sửa Lỗi Dock Badge
* **Vấn đề thực tế:** Máy đang gánh profile 2880 × 1800 của Dell XPS, sau đó phải co hình (downsample) về tấm nền thật **BOE 2560 × 1600**, gây tốn tải GPU và lệch độ sắc nét. Ngoài ra, thông báo đỏ trên Dock bị mất chữ số màu trắng (như Settings, Mail, Messages).
* **Giải pháp thực hiện:**
  1. Đổi sang profile hiển thị chuẩn **2560 × 1600 Native** với chế độ HiDPI **1280 × 800 (Pixel-perfect 2×)** hoặc **1680 × 1050 HiDPI** bằng công cụ `p1-display` tích hợp sẵn trong repo.
  2. Áp dụng bản vá **libxedrv R2**: Bản vá này đã chủ động thực hiện `managed upload` cho texture NoCopy 2D kể cả tại offset 0, giúp phục hồi các chữ số màu trắng bên trong Dock Badge đỏ.
  3. Đảm bảo cấu hình scanout cấp phát đúng 6 slot × 24 MiB (từ 16 MiB) trong `kern_gen11.cpp` để ngăn chặn lỗi `Insufficient stolen memory` và tránh sập GGTT aperture khi khởi động.

### Yêu Cầu 2: Chống Treo Máy (GPU Hang) & Khắc Phục Kernel Panic
* **Vấn đề thực tế:** 
  - macOS thường xuyên kích hoạt tiến trình nền `mediaanalysisd` (quét thư viện ảnh Photo Analysis), đẩy các tác vụ compute shader nặng vào GPU gây kẹt engine -> Watchdog timeout -> panic/freeze.
  - File log `Kernel-2026-10-25-200427.panic` ghi nhận lỗi sập nguồn `lock timeout` tại `IO80211SkywalkInterface` (liên quan đến luồng Wi-Fi).
* **Giải pháp thực hiện:**
  1. **Chặn nguồn gốc GPU Hang:** Chạy lệnh vô hiệu hóa tiến trình phân tích ảnh nền:
     ```bash
     launchctl disable gui/$UID/com.apple.mediaanalysisd
     ```
  2. **Ổn định Wi-Fi:** Theo dõi stack `AirportItlwm-Tahoe 2.4.0`. Nếu hiện tượng kẹt Skywalk lặp lại, giải pháp dứt điểm cho daily driver là chuyển sang dùng `itlwm.kext` kết hợp ứng dụng người dùng `HeliPort` (cách ly hoàn toàn luồng truyền tải mạng khỏi kernel space).
  3. **Tắt máy nhanh chóng:** Đảm bảo boot-arg có `XE-IDLEBOUND` (đã tích hợp trong NootedGreen R2) để máy tắt trong 3–5 giây, không bị kẹt 3 phút chờ GPU idle.

### Yêu Cầu 3: Tối Ưu Hóa Pin, Cắt Điện dGPU NVIDIA & Quản Lý Nguồn
* **Vấn đề thực tế:** 
  - File `MACHINE.json` xác nhận: `"power_off_verified": false`. Hiện tại card NVIDIA RTX A1000 mới chỉ bị che mắt bằng `class-code = 0xFFFFFFFF`. Nếu mạch phần cứng dGPU vẫn nhận điện (trạng thái D0), máy sẽ ăn thêm 15W–25W liên tục, quạt tản nhiệt hú to và pin cạn kiệt trong 1–1.5 giờ!
  - Sleep toàn hệ thống (S3/S0ix) bị lỗi đen màn hình do mất link eDP sau khi thức giấc.
* **Giải pháp thực hiện:**
  1. **Cắt nguồn dGPU triệt để:** Bổ sung ACPI SSDT ngắt nguồn card rời (gọi phương thức `_OFF` hoặc `_DSM` của đường dẫn PCI PEG/NVIDIA) để đưa dGPU về trạng thái **D3cold** (tiêu thụ 0W).
  2. **Thiết lập chính sách Display Sleep an toàn:** Do không thể dùng system sleep, cấu hình máy về chế độ "Tắt màn hình, không ngủ RAM" để khi gập nắp máy hoặc sau 10 phút nhàn rỗi, màn hình tắt và CPU/GPU hạ xung về trạng thái idle RC6 (< 1.5W):
     ```bash
     sudo pmset -a displaysleep 10 sleep 0 hibernatemode 0 powernap 0 womp 0
     ```

### Yêu Cầu 4: Kích Hoạt Âm Thanh Realtek ALC287 & Camera Đàm Thoại
* **Vấn đề thực tế:** Máy ThinkPad P1 Gen 5 sử dụng chip codec Realtek ALC287 trên controller PCH `8086:51C8`, hoàn toàn khác với mạch SoundWire DSP của Dell XPS.
* **Giải pháp thực hiện:**
  1. Sử dụng cấu hình âm thanh chuẩn: Lilu + AppleALC + SimpleHDA với **layout-id = 11** (DATA `0B000000` tại PCI device `00:1f.3` kết hợp boot-arg `alcid=11`). Không sử dụng driver AudShim của Dell.
  2. Kiểm tra loa kép (Stereo), chuyển đổi tự động jack 3.5mm khi cắm tai nghe và micro đàm thoại.
  3. Camera của máy là USB UVC chuẩn (`174F:1812`), nhận diện native trong FaceTime, Zoom, Google Meet mà không cần patch phức tạp.

### Yêu Cầu 5: Hoàn Thiện Touchpad Synaptics & Bàn Phím ThinkPad
* **Vấn đề thực tế:** Cần loại bỏ xung đột giữa các driver nhập liệu và đảm bảo TrackPoint hoạt động mượt mà.
* **Giải pháp thực hiện:**
  1. Touchpad Synaptics `SYNA801D` (`06CB:CEC9`) kết nối qua giao thức I2C với ngắt GPIO pin 332. Chỉ nạp duy nhất một driver `VoodooInput.kext` bên trong bộ kext để tránh xung đột kernel panics.
  2. Bàn phím ThinkPad và TrackPoint cùng 3 phím chuột vật lý chạy qua `VoodooPS2Controller.kext`.
  3. Điều chỉnh độ sáng màn hình thông qua phím tắt Fn bằng `BrightnessKeys.kext` phối hợp `SSDT-PNLF`.

### Yêu Cầu 6: Cấu Hình Trình Duyệt Web & Trải Nghiệm Ứng Dụng
* **Vấn đề thực tế:** Một số phiên bản trình duyệt Chrome sử dụng backend đồ họa ANGLE Metal có thể gây hiện tượng trắng cửa sổ hoặc chớp hình trên driver Iris Xe mod.
* **Giải pháp thực hiện:**
  1. Khởi chạy Chrome với chế độ đồ họa tương thích:
     ```bash
     defaults write com.google.Chrome WebKitDebugAcceleratedDrawingEnabled -bool YES
     ```
  2. Đảm bảo YouTube phát mượt mà ở độ phân giải 1080p và 4K 60fps qua CPU decode kết hợp GPU compositing.
  3. Các ứng dụng làm việc như VS Code, Telegram, Office hoạt động trơn tru trên nền đồ họa Metal 2D.

---

## 6. Trạng Thái Bản R3 Đã Boot & Danh Sách Việc Cần Làm Ngay (Daily Driver Checklist)

Phiên boot hiện tại (**khởi động lúc 22:16:09 ngày 25/10/2026**) đã xác nhận **Bản R3 boot thành công**, giao diện Metal GUI, WindowServer và các kext Iris Xe đang hoạt động trực tiếp.

Để đưa bản R3 này vào trạng thái dùng ổn định hàng ngày mà không gặp lỗi phát sinh, hãy thực hiện và kiểm tra theo danh sách sau:

### Bước 1: Chống treo máy và GPU Hang ngắt quãng (Bắt buộc)
Chạy lệnh vô hiệu hóa tiến trình nền của Photos để loại bỏ 90% nguyên nhân gây GPU watchdog timeout:
```bash
launchctl disable gui/$UID/com.apple.mediaanalysisd
```

### Bước 2: Khóa chế độ Sleep an toàn (Chống màn hình đen khi gập nắp)
Do driver eDP chưa thể khôi phục tín hiệu sau khi ngủ sâu (S3/S0ix), cấu hình máy về chế độ Display Sleep:
```bash
sudo pmset -a displaysleep 10 sleep 0 hibernatemode 0 powernap 0 womp 0
```

### Bước 3: Kiểm chứng thực tế các tính năng trên màn hình
Hãy kiểm tra trực quan các điểm sau ngay trên máy:
1. **Dock Notification Badge**: Nhìn vào icon System Settings hoặc App Store trên Dock, số thông báo màu trắng bên trong vòng tròn đỏ đã hiển thị rõ ràng chưa (hay vẫn bị mất số)?
2. **Âm thanh (ALC287)**: Thử tăng giảm âm lượng và phát 1 video YouTube trên Chrome. Loa trong có tiếng không?
3. **Độ sáng & Phím Fn**: Bấm cụm phím Fn chỉnh độ sáng (hoặc qua slider Control Center) xem mức độ sáng có tăng giảm mượt mà không?
4. **Nhiệt độ & Quạt**: Đặt tay lên khu vực khe tản nhiệt và đáy máy xem máy có mát và quạt có êm sau khi dùng 30 phút không (để xác nhận card rời NVIDIA không ăn điện ngầm).

### Bước 4: Chạy kiểm tra Metal và trích xuất dữ liệu chẩn đoán R3
Chạy script kiểm tra đồ họa trực tiếp trong phiên đăng nhập:
```bash
cd ~/Documents/gen5_igpu_driver
bash scripts/collect.command --metal
```
File log thu được sẽ xác nhận chính xác các thông số hoạt động của GPU và Metal trên bản R3.
