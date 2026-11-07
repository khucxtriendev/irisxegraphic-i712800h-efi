# HƯỚNG DẪN CÀI ĐẶT VÀ SỬ DỤNG LatSOFAudio (DMIC INTEL SEVER)

Tài liệu hướng dẫn chi tiết cách cài đặt driver microphone kỹ thuật số (**Intel Smart Sound Technology / cAVS 2.5 DMIC**) trên macOS Sequoia (15.x), Sonoma (14.x) cho các dòng laptop Intel Core thế hệ 12 (Alder Lake-P: ThinkPad P1 Gen 5, T14 Gen 3, v.v.) và thế hệ 13 (Raptor Lake-P).

---

## 1. Yêu cầu hệ thống

* **Nền tảng phần cứng:** Intel Core thế hệ 12/13 (Alder Lake / Raptor Lake) có Device ID âm thanh cAVS: `0x51c8` hoặc `0x51ca`.
* **Cấu hình OpenCore:**
  * `Kernel -> Quirks -> DisableIoMapper = true` (hoặc cấu hình VT-d đúng).
  * Đang sử dụng **AppleALC.kext** và **Lilu.kext** bình thường cho loa ngoài (Speakers) và jack tai nghe (Headphone).
* **Firmware:** File `sof-adl.ri` đã được biên dịch nhúng trực tiếp vào nhân của `LatSOFAudio.kext`.

---

## 2. Cách cài đặt

### Cách 1: Cài đặt tự động qua Script (Khuyên dùng - Nhanh & An toàn nhất)

Bản vá kext đã được biên dịch sẵn tại thư mục `kext/LatSOFAudio.kext`. Bạn chỉ cần mở **Terminal** và chạy:

```bash
sudo bash /Volumes/1401/LatSOF-Audio/scripts/install.sh
```

Sau khi script báo `[THÀNH CÔNG]`, hãy khởi động lại máy để hệ thống nạp kernel collection mới:
```bash
sudo reboot
```

> [!WARNING]
> **Tuyệt đối KHÔNG chạy lệnh `kmutil unload` trực tiếp** khi macOS đang chạy bình thường. Khi daemon âm thanh `coreaudiod` đang giữ driver, việc ép unload nóng sẽ gây ra lỗi kernel deadlock (treo cứng máy). Luôn áp dụng bản vá bằng cách copy vào `/Library/Extensions/` rồi chạy `sudo reboot`.

---

### Cách 2: Nạp kext qua OpenCore (EFI)

1. Sao chép thư mục `kext/LatSOFAudio.kext` vào phân vùng EFI của bạn tại đường dẫn:
   `EFI/OC/Kexts/LatSOFAudio.kext`
2. Mở file `EFI/OC/config.plist` bằng ProperTree hoặc OpenCore Configurator.
3. Thêm `LatSOFAudio.kext` vào mục `Kernel -> Add` (lưu ý đặt nằm **sau** `Lilu.kext` và `AppleALC.kext`).
4. Khởi động lại máy.

---

## 3. Các bước cấu hình sau khi cài đặt (RẤT QUAN TRỌNG)

### Bước 1: Cân chỉnh âm lượng Microphone

Trên Windows, driver Lenovo áp dụng thuật toán Dynamic Speech AGC tự động kích âm lượng mic lên khoảng **+28 dB**. Trên macOS, bạn cần kéo thanh âm lượng hệ thống để đạt mức to rõ tương đương:

1. Vào **Cài đặt hệ thống (System Settings) > Âm thanh (Sound) > Đầu vào (Input)**.
2. Chọn thiết bị **Internal Microphone** (Microphone tích hợp).
3. Kéo thanh trượt **Âm lượng đầu vào (Input Volume)** lên mức **85% – 95%**.
4. *(Tùy chọn nâng cao)*: Bạn có thể thêm boot-arg `latsof_gain=28` vào OpenCore `config.plist` để hệ thống mặc định mức pre-amp phần cứng tối ưu.

---

### Bước 2: Cấp quyền Microphone cho ứng dụng (Chrome, Discord, Web...)

> [!IMPORTANT]
> **Hiện tượng:** Mở web ghi âm hoặc ứng dụng (Google Chrome, Discord, Zoom...) báo *"Không tìm thấy microphone"* hoặc ghi âm không có tiếng.
> 
> **Nguyên nhân:** Do máy Hackintosh sử dụng bản vá đồ họa WhateverXe / Nullmoth, các hộp thoại popup xin quyền bảo mật TCC của macOS có thể bị chặn hiển thị ngầm, khiến ứng dụng không bao giờ được cấp quyền dùng mic.

**Cách khắc phục:**

* **Cách A (Dùng giao diện đồ họa):**
  1. Mở ứng dụng **`1401.app`** (nằm trong thư mục `/Applications/` hoặc trên thanh menu).
  2. Bấm vào nút **"Allow an app..."** ở mục *MICROPHONE AND CAMERA*.
  3. Chọn ứng dụng cần dùng (ví dụ: Google Chrome, Discord).
  4. Thoát hẳn ứng dụng (bấm **Cmd + Q**) rồi mở lại.

* **Cách B (Dùng lệnh Terminal nhanh):**
  ```bash
  /Applications/1401.app/Contents/Resources/nullmoth-tcc-grant "/Applications/Google Chrome.app"
  ```
  *(Thay thế bằng đường dẫn của Discord hoặc app khác nếu cần)*.

---

## 4. Kiểm tra trạng thái hoạt động

Sau khi khởi động lại máy, bạn có thể kiểm tra xem DSP và kext đã nạp thành công chưa bằng lệnh:

```bash
ioreg -r -c LatSOFAudioDevice -l | grep -E "Status|FW-Ready|PM-Gating|Topology"
```

**Kết quả chuẩn:**
* `"Status" = "OK"`
* `"FW-Ready" = "OK"`
* `"Topology" = "8 OK, 0 FAIL"`
* `"PM-Gating" = "linux: ..."` (Xác nhận cơ chế chống nghẽn DMI L1 đang hoạt động).

---

## 5. Tự biên dịch lại kext (Dành cho nhà phát triển)

Nếu bạn sửa đổi mã nguồn trong thư mục `kext/`:

```bash
cd /Volumes/1401/LatSOF-Audio/kext
make clean && make
```
File kext đầu ra sẽ nằm tại `kext/LatSOFAudio.kext`. Chạy lại `scripts/install.sh` để cập nhật.
