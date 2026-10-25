# Đối chiếu tính năng với dự án Dell

**Đã build EFI mới ngày 25/10/2026; chưa có tính năng nào của bản mới được xác nhận sau reboot.** “Giữ” dưới đây nghĩa là cấu hình/driver tương ứng đã được bảo toàn hoặc đã đóng gói, không đồng nghĩa phép thử thực tế đã đạt. Bản R2 đã đổi đường ảnh 2D sang managed upload trước native; kết quả hiển thị số Dock vẫn chưa được boot xác nhận. Tăng tốc Intel đang hiện diện trong IORegistry của phiên hiện tại; phiên agent không thực thi được kiểm tra đồ họa qua WindowServer.

| Tính năng repo gốc | Phần triển khai cho P1 Gen 5 | Trạng thái và phép kiểm tra còn thiếu |
| --- | --- | --- |
| Metal, Dock, cửa sổ, Liquid Glass | NootedGreen + libxedrv build lại từ nguồn đã sửa: bank 6 slot có đặt chỗ, bảo vệ live slot, stride/layout và padding có biên; chủ động managed upload ảnh 2D kể cả offset 0, so PTE nguồn với bản lưu RAM thay vòng đọc PTE đích | Cần boot, chạy `p1-metal`, cuộn/kéo cửa sổ và mở ứng dụng thực tế |
| Độ phân giải gốc và HiDPI | Profile đúng 2560 × 1600; công cụ chọn chính xác 1440 × 900 hoặc 1280 × 800 HiDPI | Cấu hình lưu đang là 1440 × 900, hệ số 2×; chưa đổi mode bằng công cụ mới |
| GPU clock, RC6 | Giữ cơ chế driver; đặt `ngreengtfreq=1400` theo thông số i7-12800H, thay mặc định yêu cầu 1500 MHz của Dell | Cần đo idle/tải, tần số và nhiệt trên P1; yêu cầu xung không phải xung đo được |
| CPU đủ luồng | CPUID trực tiếp: i7-12800H; hệ thống trả 20 luồng; giữ CpuTopologyRebuild, CPUID tương thích và ProvideCurrentCpuInfo | Tên CPU mới cần reboot; số core do macOS báo có thể khác 14 do topology giả lập |
| Cảm biến CPU | Có SMCProcessor và profile `sensors-trial` với `lilucpu=16` | Chưa bật mặc định; cần kiểm tra service và nhiệt độ hợp lệ, đồng thời kiểm tra các plugin Lilu khác |
| HEIC/YUV, hình nền, ảnh | Giữ thư viện/stack đang cài; kext upstream mới có trong bản thử thứ hai | Cần mở ảnh thực và kiểm tra màu/artefact |
| Icon, thumbnail, Finder | Giữ stack Intel, không ép định dạng Apple-silicon-only | Cần kiểm thử thực tế sau reboot |
| H.264/HEVC hardware decode | Đã build VA plugin từ stock 16.0.32; các bước vá xác nhận byte gốc, chữ ký đạt; có profile thử `-ngreengva` | Chưa cài plugin vào hệ thống hoặc xác nhận decode, **không tính là đã đạt** |
| Safari/Chrome/YouTube | Giữ tương thích stack hiện có | Cần phát video và đo; không hứa VP9/AV1 hardware decode hay Safari hardware decode |
| Screen recording | Không đổi cơ chế của macOS | Chưa ghi thử; cần quyền macOS của ứng dụng ghi |
| Touchscreen và gesture | Giữ nguồn `xe-toque` trong vendor | Chưa xác nhận có phần cứng cảm ứng; không giả định tấm nền P1 có tính năng Dell |
| Touchpad, bàn phím, TrackPoint | Giữ VoodooI2C/GPIO đã khớp SYNA801D (06CB:CEC9), GPIO pin 332; chỉ bật một VoodooInput; giữ PS2 cho TrackPoint | Cần thử đa ngón, TrackPoint, phím Fn và sử dụng kéo dài |
| Brightness | Giữ BrightnessKeys và cờ hiện tại; không dùng hằng PWM Dell | Cần đo PWM và thử slider/phím; chưa áp `17777`, chưa cài daemon ghi MMIO |
| Shutdown/restart | Có cơ chế driver đang dùng; EFI thử nguồn mới chứa sửa lỗi upstream | Cần shutdown và restart thực; không hứa tốc độ của Dell |
| Logo boot | Giữ `Resolution=Max`, `gfxrst=1` | Cần nhìn trong quá trình boot; chưa ép timing/panel Dell |
| Loa trong | ALC287: Lilu → AppleALC → SimpleHDA; layout 11 ở HDAS 00:1f.3 và alcid=11, keepsyms=1 | Chưa phát thử; có thể cần pin/layout/amp fix riêng. Không dùng AudShim của Dell |
| Micro, tai nghe, jack switching | Cùng audio profile, cần kiểm tra từng đường | Mic số DSP có thể cần giải pháp khác; không đồng nhất kết quả loa với micro |
| Wi-Fi | Giữ AirportItlwm-Tahoe 2.4.0 cho AX211 | Cần test kết nối/reconnect; không có AWDL/AirDrop; giới hạn WPA3-only/PMF theo upstream |
| Bluetooth | IntelBluetoothFirmware + IntelBTPatcher + BlueToolFixup; NVRAM DATA và HS10 internal trong map PCH 8086:51ED | Cần test ghép đôi, reconnect, âm thanh và cold boot |
| Haptic touchpad | Giữ nguồn Dell tham khảo | Chưa có bằng chứng P1 dùng cùng thiết bị haptic; không cài công cụ điều khiển Dell |
| Vân tay cho sudo | Nhận Goodix **27C6:6594**; nguồn libfprint/PAM có trong vendor | libfprint development liệt kê model này, nên có hướng chuyển; chưa build phụ thuộc, chưa thử cảm biến/PAM. Không có Touch ID/Secure Enclave |
| Nút nguồn khóa màn hình | Giữ nguồn `xe-pblock` tham khảo | Chưa đối chiếu sự kiện Lenovo hoặc cài agent; cần kiểm thử riêng |
| Display sleep/đóng nắp | Giữ thiết lập hiện có, không cài daemon Dell | Cần kiểm tra đèn nền tắt/bật và mở nắp; sleep toàn hệ thống chưa được chứng minh |
| NVMe, pin, USB | Giữ ECEnabler, YogaSMC, SMCBatteryManager; map PCH giữ 15 port, internal HS06/08/10; TB giữ enumeration | Cần kiểm tra dung lượng/sạc và từng cổng vật lý; NVMeFix vẫn tắt như baseline để tránh thêm biến số chưa kiểm thử |
| Camera | Máy có USB UVC **174F:1812**, khác camera IPU6 của Dell | Có đường dùng camera native; chưa chụp thử, không tự mở camera để kiểm tra |
| Màn hình ngoài/HDMI/Thunderbolt | Không giả định tuyến xuất hình giống Dell; NVIDIA đang bị ẩn | Cần xác định cổng nối iGPU hay dGPU rồi thử màn hình; ẩn dGPU không chứng minh đã tắt nguồn card |

## Những giới hạn không thể biến thành “đã hỗ trợ” bằng đổi thông số

- Repo gốc không có sleep toàn hệ thống đáng tin cậy, AirDrop/AWDL, Touch ID native hoặc hardware encode ổn định. Bộ P1 không tuyên bố đã làm được các mục đó.
- 1440 × 900 HiDPI trên tấm nền 2560 × 1600 vẫn cần thu ảnh; sửa EFI không biến tấm nền thành 2880 × 1800.
- AudShim của Dell match controller `8086:51CA` và chuỗi SoundWire RT1316/RT714. P1 đang thấy `8086:51C8` cùng hồ sơ ALC287; đổi ID để ép AudShim nạp không tạo ra driver đúng phần cứng.
- Các công cụ haptic, touchscreen và sự kiện phím phụ thuộc thiết bị, firmware/ACPI. Chỉ áp dụng sau khi đối chiếu ID và hành vi trên P1.

## Điều kiện để chốt bản dùng hằng ngày

Boot được bản thử trên một USB riêng, có log runtime đầy đủ và thử các mục áp dụng trong bảng. Với các tính năng cần thư viện hệ thống mới (đặc biệt VA decode), kiểm tra đúng phiên bản driver rồi mới cài và đo. Chỉ nâng trạng thái của một tính năng khi có phép thử thực tế tương ứng; hiện yêu cầu đủ toàn bộ tính năng vẫn chưa hoàn thành.

Nguồn: [README upstream](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe), [STATUS upstream](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe/blob/main/docs/STATUS.md), [SimpleHDA](https://github.com/laobamac/SimpleHDA/blob/main/README.en.md), [libfprint supported devices — bản development](https://fprint.freedesktop.org/supported-devices.html). Mã AudShim/PAM đã chụp lại trong `vendor/iris-xe/tools/` để đối chiếu đúng snapshot.
