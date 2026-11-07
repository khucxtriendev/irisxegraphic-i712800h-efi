# HƯỚNG DẪN CÀI ĐẶT BỘ DISPLAY OVERRIDE (HiDPI & EDID) CHO MÀN HÌNH BOE (0x9E5 / 0xAE0)

Tài liệu hướng dẫn chi tiết cách cài đặt bộ cấu hình Display Override cho màn hình trong (Color LCD / Internal Display) của máy laptop sử dụng tấm nền **BOE Technology** trên macOS Sequoia (15.x), Sonoma (14.x) và các phiên bản macOS trước đó.

---

## 1. Thông tin bộ Override

* **Nhà sản xuất (Vendor ID):** `0x09e5` (2533) – **BOE Technology**
* **Mã màn hình (Product ID):** `0x0ae0` (2784) – **BOE CQ (Color LCD)**
* **Tác dụng:**
  * **Patch EDID (256 bytes):** Giúp macOS nhận diện chính xác tấm nền máy tính xách tay chuẩn Retina Color LCD, kích hoạt thanh chỉnh độ sáng (Backlight slider) và kết nối với iGPU Intel Iris Xe.
  * **Kích hoạt các nấc phân giải HiDPI sắc nét:** Màn hình vật lý `2880 x 1800` sẽ được kích hoạt chế độ Retina HiDPI chuẩn Apple (giao diện hiển thị mịn màng ở nấc scale tương đương `1440 x 900`, `1600 x 1000`, `1680 x 1050`...).
  * **Icon hiển thị đẹp:** Kèm icon và preview độ phân giải hiển thị chuẩn MacBook trong **System Settings -> Displays**.

> [!NOTE]
> Thư mục đích cài đặt là `/Library/Displays/Contents/Resources/Overrides/` (nằm trong phân vùng dữ liệu cục bộ `/Library`), **KHÔNG PHẢI** `/System/Library/...` (Read-only System Volume). Do đó:
> * **KHÔNG CẦN TẮT SIP** (System Integrity Protection).
> * **KHÔNG BỊ MẤT** khi máy cập nhật các bản update macOS nhỏ (minor updates).

---

## 2. Cách cài đặt

### Cách 1: Cài đặt tự động bằng Script (Khuyên dùng - Nhanh nhất)

1. Cắm USB vào máy.
2. Mở ứng dụng **Terminal** và chạy lệnh:
   ```bash
   sudo bash /Volumes/1401/Display_Override/install.sh
   ```
3. Nhập mật khẩu máy tính của bạn khi được hỏi (mật khẩu không hiện ký tự trên màn hình).
4. Sau khi script báo `[CÀI ĐẶT THÀNH CÔNG]`, hãy khởi động lại máy để hệ thống áp dụng:
   ```bash
   sudo reboot
   ```

---

### Cách 2: Cài đặt thủ công bằng tay (Manual)

Nếu bạn muốn tự copy từng file, mở **Terminal** và thực hiện lần lượt các lệnh sau:

#### Bước 1: Tạo thư mục đích trong hệ thống
```bash
sudo mkdir -p /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5
```

#### Bước 2: Sao chép các file cấu hình từ USB vào hệ thống
```bash
# 1. Copy file cấu hình EDID và phân giải HiDPI
sudo cp -p /Volumes/1401/Display_Override/DisplayVendorID-9e5/DisplayProductID-ae0 /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/

# 2. Copy icon hiển thị màn hình
sudo cp -p /Volumes/1401/Display_Override/DisplayVendorID-9e5/DisplayProductID-ae0.icns /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/

# 3. Copy file cấu hình Icons chung
sudo cp -p /Volumes/1401/Display_Override/Icons.plist /Library/Displays/Contents/Resources/Overrides/
```

#### Bước 3: Phân quyền chuẩn cho macOS (Bắt buộc)
```bash
sudo chown -R root:wheel /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5
sudo chmod 755 /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5
sudo chmod 644 /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/*
sudo chown root:wheel /Library/Displays/Contents/Resources/Overrides/Icons.plist
sudo chmod 644 /Library/Displays/Contents/Resources/Overrides/Icons.plist
```

#### Bước 4: Khởi động lại máy
```bash
sudo reboot
```

---

## 3. Cách kiểm tra sau khi cài đặt

Sau khi máy khởi động lại xong:

1. Vào **System Settings** (Cài đặt hệ thống) -> **Displays** (Màn hình).
2. Bạn sẽ thấy biểu tượng màn hình chuẩn và các tùy chọn thu phóng sắc nét (Larger Text - Default - More Space) hoặc danh sách độ phân giải HiDPI.
3. Hoặc kiểm tra nhanh trong Terminal bằng lệnh:
   ```bash
   ioreg -lw0 -r -c "IODisplayConnect" | grep "DisplayProductID"
   ```
   Nếu thấy `DisplayProductID = 2784` (tức `0xae0`) và `DisplayVendorID = 2533` (tức `0x9e5`) là hệ thống đã nhận diện chính xác bộ override.

---

## 4. Cách gỡ bỏ (Khôi phục mặc định ban đầu)

Nếu bạn muốn gỡ bỏ hoàn toàn bộ override này để quay về trạng thái mặc định của macOS:

```bash
sudo rm -rf /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5
sudo reboot
```
