# OpenCore EFI for Lenovo ThinkPad P1 Gen 5
### Intel Core i7-12800H | Intel Iris Xe Graphics (96 EU) | macOS Sequoia 15.x & Tahoe

[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.3-blue.svg)](https://github.com/acidanthera/OpenCorePkg)
[![macOS](https://img.shields.io/badge/macOS-Sequoia%2015.x%20%7C%20Tahoe-green.svg)](https://www.apple.com/macos/)
[![WhateverXe](https://img.shields.io/badge/WhateverXe-Patched%206--bpc-orange.svg)](https://github.com/khucxtriendev/WhateverXe)

Kho lưu trữ cấu hình OpenCore EFI hoàn chỉnh dành riêng cho **Lenovo ThinkPad P1 Gen 5 (Type 21DDS88B00)**, kích hoạt thành công tăng tốc phần cứng **Intel Iris Xe Graphics (QE/CI Metal 3D)** trên màn hình độ phân giải cao **2560 x 1600 (WQXGA)** mà không bị đen màn hình hay sọc sọc hiển thị.

---

## 1. Thông Số Phần Cứng (Hardware Specifications)

| Thành phần | Chi tiết cấu hình |
| :--- | :--- |
| **Model máy** | Lenovo ThinkPad P1 Gen 5 (Type `21DDS88B00`) |
| **Vi xử lý (CPU)** | Intel Core i7-12800H (Alder Lake-H, 14 Cores / 20 Threads: 6 P-Cores up to 4.8 GHz + 8 E-Cores up to 3.7 GHz, 24MB L3 Cache, Display 13) |
| **Đồ hoạ tích hợp (iGPU)** | Intel Iris Xe Graphics (`8086:46A6`, 96 Execution Units) — **Đã kích hoạt full QE/CI Metal 3D** |
| **Đồ hoạ rời (dGPU)** | NVIDIA RTX A1000 Laptop (`10DE:25B9`, 4GB GDDR6) — *Đã vô hiệu hoá để tiết kiệm pin và chống nóng* |
| **Màn hình trong** | 16.0" 16:10 WQXGA (2560 x 1600), tấm nền BOE `NE160QDM-NY1` / `LEN41B0` (eDP, khởi tạo GOP 6-bpc) |
| **Bộ nhớ RAM** | 32GB (2 x 16GB) DDR5 4800MHz |
| **Ổ cứng lưu trữ** | NVMe SSD M.2 PCIe 4.0 x4 |
| **Âm thanh (Audio)** | Realtek ALC245 (AppleALC `layout-id=11`) + Loa stereo Dolby Atmos |
| **Mạng không dây** | Intel Wi-Fi 6E AX211 160MHz (`AirportItlwm`) & Bluetooth 5.2 (`IntelBluetoothFirmware` + `IntelBTPatcher`) |
| **Thiết bị nhập liệu** | Bàn phím ThinkPad có đèn nền, TrackPoint + Touchpad đa điểm (`VoodooPS2Controller` + `VoodooI2C`) |
| **Quản lý nguồn** | `HybridPM.kext` (XE-PM) + `CpuTopologyRebuild.kext` + `YogaSMC.kext` |

---

## 2. Tình Trạng Tính Năng (Current Status)

- [x] **Tăng tốc đồ hoạ phần cứng (QE/CI & Metal 3D):** Hoạt động mượt mà ở độ phân giải gốc 2560x1600 @ 60Hz.
- [x] **Điều khiển độ sáng màn hình:** Hoạt động qua `SSDT-PNLF` và cụm phím tắt `BrightnessKeys.kext`.
- [x] **Quản lý xung nhịp CPU kiến trúc lai:** `HybridPM.kext` kết hợp `-hpm` giúp điều phối nhân P và nhân E, tự hạ C-states tiết kiệm điện và giữ máy mát mẻ.
- [x] **Âm thanh:** Loa trong, jack tai nghe 3.5mm và microphone hoạt động qua AppleALC.
- [x] **Wi-Fi & Bluetooth:** Nhận diện và kết nối tốt mạng 2.4GHz / 5GHz / 6GHz và các thiết bị Bluetooth.
- [x] **Bàn phím & Trackpad:** Phím bấm chuẩn ThinkPad, TrackPoint mượt, cảm ứng đa điểm cuộn mượt.
- [x] **Hiển thị phần trăm pin & sạc:** `SMCBatteryManager.kext` + `ECEnabler.kext`.
- [x] **Chế độ ngủ (Sleep & Wake):** Thức dậy giữ nguyên xung nhịp xuất hình.
- [ ] **NVIDIA RTX A1000 dGPU:** Không hỗ trợ trên macOS hiện đại; đã ngắt nguồn điện để giảm nhiệt độ máy 20-30°C.
- [ ] **Camera Windows Hello / IR:** Không hỗ trợ (macOS không hỗ trợ bảo mật khuôn mặt hồng ngoại ngoài FaceID của Apple).

---

## 3. Nguồn Gốc & Liên Kết Các Repository Đã Sử Dụng (Credits)

Dự án này là thành quả kế thừa và phát triển từ các công trình xuất sắc của cộng đồng Hackintosh:

* **[khucxtriendev/WhateverXe](https://github.com/khucxtriendev/WhateverXe):** Fork WhateverXe được vá đặc biệt để hỗ trợ UEFI GOP 6-bpc (`0x8a200106`) của ThinkPad P1 Gen 5 và đọc thanh ghi phần cứng tránh lỗi sập xung đen màn hình lúc WindowServer handoff.
* **[b00t0x/WhateverXe](https://github.com/b00t0x/WhateverXe) & [b00t0x/WhateverXe-Graphics](https://github.com/b00t0x/WhateverXe-Graphics):** Dự án nền tảng điều khiển đồ hoạ Intel Xe trên macOS.
* **[Thatisjigen/WhateverXe](https://github.com/Thatisjigen/WhateverXe) & [Thatisjigen/acer-nitro-anv15-52-macos](https://github.com/Thatisjigen/acer-nitro-anv15-52-macos):** Nhánh nghiên cứu xuất sắc hỗ trợ Display 13 eDP cho dòng vi xử lý Alder Lake / Raptor Lake di động.
* **[JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe):** Tác giả tiên phong dự án Intel Iris Xe Metal trên macOS Tahoe/Sequoia, sáng tạo ra các bản vá cốt lõi:
  - `xefix.m` / `libxedrv`: Đồng bộ thứ tự Compute/Render và khử lỗi vệt đen blur WindowServer.
  - `posh_patch`: Khắc phục lỗi rò rỉ bộ nhớ (leak 5.6 MB/s) của trình điều khiển Metal.
  - `XE-PM` (`HybridPM.kext`): Bộ điều khiển xung nhịp thông minh cho kiến trúc CPU lai Alder Lake.
* **[Acidanthera](https://github.com/acidanthera):** OpenCorePkg, Lilu, VirtualSMC, AppleALC, RestrictEvents, AMFIPass, v.v.
* **[OpenIntelWireless](https://github.com/OpenIntelWireless):** Bộ đôi `AirportItlwm` và `IntelBluetoothFirmware`.

---

## 4. Hướng Dẫn Cài Đặt Bằng Phân Vùng USB `1401`

Phân vùng USB khởi động được đặt tên nhãn là **`1401`** (định dạng FAT32). Đây là cấu trúc tiêu chuẩn để cài đặt và chạy các công cụ tự động.

### Chuẩn bị USB:
1. Định dạng một phân vùng USB chuẩn **FAT32** (hoặc Master Boot Record / GPT).
2. Đặt tên nhãn phân vùng (Volume Label) là: **`1401`**.
3. Sao chép các thư mục từ repository này vào USB:
   * Thư mục `EFI/` (chứa `BOOT/` và `OC/`) ➔ đặt ngay tại thư mục gốc của USB.
   * Thư mục `postinstall_tools/` ➔ đặt ngay tại thư mục gốc của USB.

```
USB 1401/
├── EFI/
│   ├── BOOT/
│   └── OC/
└── postinstall_tools/
    ├── install_iris_xe.sh
    ├── impostor.dylib
    ├── posh_patch.sh
    └── whateverxe_thinkpad_p1_gen5.patch
```

### Khởi động và cài đặt macOS:
1. Cắm USB vào cổng USB-A của ThinkPad P1 Gen 5.
2. Bật nguồn máy, nhấn liên tục phím **F12** để vào Boot Menu của BIOS.
3. Chọn ổ USB `1401` để vào menu OpenCore.
4. Chọn bộ cài macOS Sequoia và tiến hành cài đặt vào ổ cứng máy.

---

## 5. Hướng Dẫn Cài Đặt Vào `/Library` (Kích Hoạt Metal 3D)

> [!IMPORTANT]
> **Tại sao bắt buộc phải cài đặt vào `/Library`?**
> Kext WhateverXe ở EFI chỉ đảm nhận quét hình ảnh 2D cơ bản ra màn hình. Nếu chưa cài driver Metal vào `/Library/GPUBundles`, macOS sẽ buộc 14 nhân CPU phải vẽ từng khung hình (Software Rendering) ➔ **Máy sẽ rất lag và nóng ran (80°C - 95°C)**.
> Sau khi cài đặt bộ driver vào `/Library`, GPU 96 EU sẽ trực tiếp xử lý Metal 3D, giao diện mượt 60 FPS và máy mát rượi!

### Cách 1: Cài đặt tự động bằng 1 lệnh duy nhất (Khuyên dùng)

Sau khi đã boot vào màn hình Desktop của macOS, hãy cắm USB `1401` vào máy, mở ứng dụng **Terminal** và chạy lệnh sau:

```bash
sudo bash /Volumes/1401/postinstall_tools/install_iris_xe.sh
```

*(Mẹo: Bạn có thể gõ `sudo bash ` có dấu cách, rồi mở Finder kéo thả file `install_iris_xe.sh` từ USB vào cửa sổ Terminal rồi nhấn Enter).*

**Script này sẽ tự động:**
1. Tải và cài đặt gói driver `WhateverXe-Graphics-0.4.0.pkg` vào `/Library/GPUBundles` và `/Library/Extensions`.
2. Nạp cầu nối `impostor.dylib` (bản vá `xefix` của JulioNectar) và ký chữ ký số `codesign`.
3. Phân quyền chuẩn `root:wheel` cho toàn bộ thư mục driver.
4. Làm mới bộ đệm hạt nhân AuxKC (`kmutil install --update-all`).

---

### Cách 2: Cài đặt thủ công từng bước

Nếu bạn muốn tự tay thực hiện từng dòng lệnh:

1. **Cài đặt gói Graphics Package:**
   ```bash
   sudo installer -pkg /Volumes/1401/postinstall_tools/WhateverXe-Graphics-0.4.0.pkg -target /
   ```
2. **Nạp bản vá Metal Bridge của JulioNectar:**
   ```bash
   sudo cp -f /Volumes/1401/postinstall_tools/impostor.dylib /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   sudo chmod 755 /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   sudo codesign -f -s - -i impostor /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   ```
3. **Phân quyền chuẩn:**
   ```bash
   sudo chown -R root:wheel /Library/GPUBundles /Library/Extensions
   sudo chmod -R 755 /Library/GPUBundles /Library/Extensions
   ```
4. **Cập nhật Kernel Cache:**
   ```bash
   sudo kmutil install --volume-root / --update-all
   ```
5. **Khởi động lại máy:**
   ```bash
   sudo reboot
   ```

---

## 6. Kiểm Tra Sau Khi Cài Đặt Thành Công

Sau khi khởi động lại, mở **Terminal** và gõ lệnh:
```bash
system_profiler SPDisplaysDataType | grep -E "Chipset Model|Metal"
```

* **Kết quả chuẩn:**
  ```text
  Chipset Model: Intel Iris Xe Graphics
  Metal Support: Metal 3 (hoặc Metal 2)
  ```
* Mở **Activity Monitor**, bạn sẽ thấy `WindowServer` chỉ ăn 1-3% CPU.
* Toàn bộ thanh Dock, hiệu ứng phóng to thu nhỏ cửa sổ và video 4K chạy mượt mà 60 FPS, quạt máy êm và nhiệt độ duy trì mát mẻ 45°C - 55°C.
