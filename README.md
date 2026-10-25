# ThinkPad P1 Gen 5 — EFI và Stack Iris Xe macOS Tahoe

> **Trạng thái:** **Bản build R3 đã boot thành công và đang hoạt động trên hệ thống** (Xác nhận boot: 22:16 +0700, 25/10/2026).  
> **Hệ điều hành:** macOS Tahoe 26.7.1 (Build **25G241** / Darwin 25.6.0).  
> **Stack đồ họa:** NootedGreen R3 + Apple Tiger Lake **16.0.32** + Metal Bundle MTL18 + `libxedrv` R3 + `xe.bundle`.  
> **Phần cứng thực tế:** Lenovo ThinkPad P1 Gen 5 (Subsystem: `17AA:22F8`, SMBIOS: MacBookPro16,2), CPU Intel Core i7-12800H (14 Cores: 6P + 8E, 20 Threads), 32 GB DDR5 4800 MHz, Intel Iris Xe Graphics 96 EU (Native `0x46A6` spoof `0x9A49`), NVIDIA RTX A1000 đã ẩn (`class-code = 0xFFFFFFFF`), tấm nền BOE NE160QDM-NY1 (2560 × 1600 Native 16:10).

---

## 1. Kết Quả Xác Minh Thực Tế Sau Khi Boot R3

Báo cáo trích xuất từ phiên chẩn đoán trực tiếp (`reports/runtime-20261025-232920`):

| Phần cứng / Tính năng | Trạng thái thực tế | Bằng chứng từ log runtime |
|---|:---:|---|
| **Metal GPU 2D/3D** | **HOẠT ĐỘNG (PASS)** | Giao diện WindowServer 60fps, Liquid Glass mượt mà. Test compute shader dispatch 256 vector GPU readback thành công (`metal.txt`). |
| **Âm thanh (Realtek ALC287)** | **HOẠT ĐỘNG** | Nhận diện loa trong `内建输出 / 内置扬声器` 2 kênh 48kHz làm thiết bị âm thanh mặc định (`IOAudioEngine.txt`, `peripherals.txt`). |
| **Camera** | **HOẠT ĐỘNG (Native)** | Nhận diện trực tiếp `Integrated Camera` qua giao thức USB UVC chuẩn (`174F:1812`), dùng tốt cho Zoom / FaceTime / Meet. |
| **Bluetooth (Intel AX211)** | **HOẠT ĐỘNG** | Chip Intel `8087:0033` nạp firmware v12490 (State: On), tự động quét và nhận danh sách thiết bị đã ghép đôi (AirPods 4 ANC). |
| **Wi-Fi (Intel AX211)** | **HOẠT ĐỘNG** | Hoạt động qua AirportItlwm-Tahoe 2.4.0 trên cổng PCI `8086:51F0`. |
| **Bàn phím & Touchpad** | **HOẠT ĐỘNG** | Touchpad Synaptics `SYNA801D` (`06CB:CEC9`) chạy ngắt GPIO pin 332 qua VoodooI2C; TrackPoint và phím cứng qua VoodooPS2. |
| **Độ sáng màn hình** | **HOẠT ĐỘNG** | Điều chỉnh mượt mà qua cụm phím Fn và thanh trượt Control Center (`BrightnessKeys` + `SSDT-PNLF`). |
| **Sleep / Wake** | ⚠️ **Cần khóa System Sleep** | Wake màn hình eDP chưa tự bật lại tín hiệu (màn hình đen). **Bắt buộc dùng Display Sleep**. |
| **VideoToolbox HW Decode** | ⚠️ **CPU Fallback** | Đang fallback giải mã CPU mượt mà; chưa bật VA plugin phần cứng. |

---

## 2. Thiết Lập Bắt Buộc Để Máy Dùng Ổn Định Hàng Ngày (Daily Driver)

Chạy 2 lệnh sau trong Terminal để triệt tiêu hoàn toàn các nguy cơ crash máy ngẫu nhiên:

### A. Khóa System Sleep (Chống đen màn hình khi gập nắp)
Vì iGPU chưa hỗ trợ bật lại link eDP khi thức giấc từ chế độ ngủ sâu (S3/S0ix), chuyển hệ thống sang chế độ **Display Sleep** (khi gập nắp hoặc để yên, máy chỉ tắt màn hình và đưa CPU/GPU về idle RC6 tiết kiệm điện, không bao giờ bị đen màn hình):
```bash
sudo pmset -a displaysleep 10 sleep 0 hibernatemode 0 powernap 0 womp 0
```

### B. Chặn lỗi GPU Hang do tiến trình quét ảnh ngầm
Tiến trình phân tích media nền của Apple thường xuyên đẩy shader compute nặng vào GPU gây kẹt engine -> treo máy:
```bash
launchctl disable gui/$UID/com.apple.mediaanalysisd
```

---

## 3. Cấu Trúc Bản Build & Các Thành Phần Đã Áp Dụng

```
/Users/kxt/Documents/gen5_igpu_driver/
├── EFI/                         # EFI đang áp dụng (NootedGreen R3 + Audio Layout 11 + ThinkPad ACPI/Kexts)
├── build/userland/              # Bundle Metal driver MTL18 + libxedrv R3 + xe.bundle
├── scripts/
│   ├── cai-dat-nhanh.sh         # Script cập nhật đồng bộ NootedGreen và Metal Bundle vào hệ thống
│   ├── install-graphics.command # Script cài đặt Metal bundle & libxedrv vào /Library/GPUBundles
│   ├── collect.command          # Thu thập log và chẩn đoán phần cứng (thêm flag --metal)
│   └── probe-dock.command       # Kiểm tra render badge thông báo Dock
├── reports/                     # Dữ liệu chẩn đoán, benchmark và log runtime thực tế
│   └── runtime-20261025-232920/ # Dữ liệu phiên boot R3 hiện tại
└── roadmap-igpu.md              # Báo cáo đánh giá chi tiết theo 11 nhóm tiêu chuẩn Apple
```

### Các bản vá cốt lõi đã nạp:
1. **NootedGreen R3**: 
   - Quản lý scanout aperture 6 slot × 24 MiB (từ 16 MiB), tính toán stride/layout động thay vì giới hạn 4000 trang cũ, ngăn chặn lỗi `Insufficient stolen memory`.
   - Lưu cache PTE vào RAM, loại bỏ đọc lại 6.144 PTE đích trên hit.
   - Hỗ trợ `XE-IDLEBOUND` giúp shutdown/restart chỉ mất 3–5 giây.
2. **libxedrv R3**:
   - Chủ động `managed upload` ảnh 2D ở cả offset 0 trước khi gọi native driver, giúp hiển thị lại các chữ số màu trắng trên Dock Badge thông báo.
   - Tương thích cấu trúc ABI của macOS Tahoe 26.7.1.
3. **Âm thanh ALC287**:
   - Sử dụng chuẩn `layout-id = 11` (DATA `0B000000`) tại device `00:1f.3` phối hợp AppleALC + SimpleHDA.

---

## 4. Hướng Dẫn Kiểm Tra & Bảo Trì

### Kiểm tra tình trạng hoạt động thực tế:
Chạy script kiểm tra trong Terminal:
```bash
cd ~/Documents/gen5_igpu_driver
bash scripts/collect.command --metal
```
Log sẽ tự động được lưu vào thư mục `reports/runtime-<timestamp>/`.

### Khôi phục khi gặp sự cố:
Nếu cần quay về bản dự phòng, các bản sao lưu an toàn được lưu tự động tại thư mục `Backups/`:
```bash
# Phục hồi Metal bundle cũ nếu cần
sudo ditto "Backups/graphics-YYYYMMDD-HHMMSS/AppleIntelTGLGraphicsMTLDriver.bundle" "/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle"
```

---

## 5. Tài Liệu Tham Khảo Kèm Theo

- [roadmap-igpu.md](roadmap-igpu.md): Bảng phân tích 11 nhóm tiêu chuẩn và 6 yêu cầu Daily Driver.
- [CHANGELOG.md](CHANGELOG.md): Lịch sử thay đổi chi tiết giữa các bản R1, R2 và R3.
- [docs/CAI-DAT.md](docs/CAI-DAT.md): Hướng dẫn cài đặt và nâng cấp driver.
- [docs/AM-THANH-BLUETOOTH-TOUCHPAD.md](docs/AM-THANH-BLUETOOTH-TOUCHPAD.md): Chi tiết cấu hình ngoại vi ThinkPad P1 Gen 5.
