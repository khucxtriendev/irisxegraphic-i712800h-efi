# Dùng bản build P1 Gen 5

Bộ này dành cho ThinkPad P1 Gen 5 đang chạy macOS 26.7.1, build **25G241**, với stack Tiger Lake **16.0.32** đã được cài theo repo Iris Xe. Đây là bản build mới, đã kiểm tra tĩnh và kiểm tra logic CPU; chưa được boot xác nhận trên máy.

## Thành phần cần áp dụng

1. **`EFI/`** chứa NootedGreen mới cùng cấu hình âm thanh, Bluetooth và touchpad.
2. **`Graphics/AppleIntelTGLGraphicsMTLDriver.bundle`** trong gói release chứa libxedrv mới. Nếu đang ở thư mục nguồn, cùng thành phần nằm tại `build/userland/`.

Chỉ chép EFI sẽ áp dụng kext/cấu hình nhưng **không cập nhật libxedrv**, vì thư viện này được nạp từ `/Library/GPUBundles`, ngoài phân vùng EFI.

## Cài nhanh hai driver đồ họa vào EFI 1401

Nếu giữ EFI hiện có trên USB `1401` và chỉ cần cập nhật đồng bộ NootedGreen + Metal/libxedrv, chạy:

```bash
bash scripts/cai-dat-nhanh.sh --check
bash scripts/cai-dat-nhanh.sh
```

Lệnh đầu chỉ kiểm tra. Lệnh sau yêu cầu quyền quản trị khi bạn tự chạy. Script kiểm tra danh tính EFI, NootedGreen đang bật, đích macOS/Metal, hash kext và chữ ký; sao lưu cả hai bundle, stage trên từng filesystem, rồi thay bằng rename. Nếu bước sau thất bại thì phục hồi cả hai thành phần; backup/nhật ký ở `Backups/quick-.../`. Script nhắc Restart, không tự restart.

Script này **giữ nguyên config.plist và các driver ngoại vi** trên 1401. Vì vậy nó không thay thế bước chép trọn EFI mới nếu bạn muốn áp dụng cấu hình âm thanh/layout 11, Bluetooth và USB map mới. Nó không ghi thư viện rời vào `/Library/GPUBundles/` sai chỗ: libxedrv nằm bên trong Metal bundle đúng đường dẫn.

## Phạm vi hai sửa đổi R2

Ảnh NoCopy 2D một mip/một array đủ điều kiện được upload managed trước khi gọi native, kể cả offset 0. Giữ kiểm tra biên, pitch, format, depth/sample; không copy texture có ShaderWrite hoặc RenderTarget. Đây là snapshot tại thời điểm upload: CPU sửa vùng nguồn sau đó không tự cập nhật bản sao. Chưa có phép thử Dock/GPU xác nhận mọi texture chữ số thuộc đường này hoặc đảm bảo hết mất số 100%.

Cache scanout không còn đọc lại 6.144 PTE đích trên hit. PTE nguồn hiện tại vẫn được đối chiếu với bản đã lưu RAM để phát hiện cùng VA nhưng đổi backing. IO giả đếm 40.580 → 16.004 lần đọc ở native, 45.280 → 20.704 ở HiDPI; không phải số đo ms hoặc FPS. Không tuyên bố toàn hàm có zero MMIO hay panel đã chạy 165 Hz.

## Chuẩn bị boot

Giữ USB đang boot được để quay lại. Chép thư mục `EFI/` của bản release vào **gốc phân vùng boot FAT32 của USB thử đã chuẩn bị**, sao cho có `EFI/BOOT/BOOTx64.efi` và `EFI/OC/config.plist`. Không đặt thành `EFI/EFI/`. Bộ này không tự format, phân vùng, ghi USB hay sửa EFI đang chạy.

Trong bản nguồn, EFI mới cũng nằm trực tiếp tại `~/Documents/gen5_igpu_driver/EFI/`. Không lấy lại EFI cũ trong `backup/` hoặc `build/previous-before-hardware/`.

## Cập nhật thư viện đồ họa

Chạy **thủ công**, sau khi đã chuẩn bị EFI mới:

```bash
bash scripts/install-graphics.command
```

Script kiểm tra build macOS, đúng bundle ID và phiên bản 16.0.32 của nguồn/đích, cùng chữ ký nguồn trước khi ghi. Nó thay **trọn Metal bundle đã build**, bao gồm libxedrv; không ghép thư viện mới với một bản vá Metal binary khác. Bundle mới được stage và kiểm tra trên cùng filesystem trước khi đổi bằng rename, sau đó xác minh chữ ký và đối chiếu nội dung. Bản sao đầy đủ của Metal bundle cũ được lưu tại `Backups/graphics-YYYYMMDD-HHMMSS/` trong bộ. Nếu lỗi trong bước thay/đối chiếu, script phục hồi bundle cũ đã được giữ trong staging. Backup đầy đủ vẫn còn để khôi phục sau reboot. Script yêu cầu quyền quản trị khi bạn tự chạy để cài; quá trình build không gọi script này.

Có thể kiểm tra trước mà không cài bằng `bash scripts/install-graphics.command --check`. Nếu sai phiên bản hoặc bundle ID thì script dừng trước khi ghi. Bản Metal đang cài có thể có hash khác vì đã được vá; do đó bộ cài thay trọn bundle mới đã xác minh, thay vì chỉ thay một dylib. Không chạy `vendor/iris-xe/install.sh` chỉ để thay một thư viện: đó là trình cài upstream với phạm vi thay đổi rộng hơn.

`Graphics/xe.bundle` là shader compiler đã build kèm để lưu đồng bộ artifact. Lượt sửa này không thay mã shader compiler; script trên không ghi compiler vào `/System`. Máy cài repo từ trước cần giữ compiler đang hoạt động. Không cần áp lại VA plugin để dùng cấu hình mặc định; giải mã phần cứng vẫn là profile riêng chưa bật.

Khởi động lại, chọn USB thử trong menu boot Lenovo. Cấu hình đã có `NVRAM/Delete` cho boot-args và hai biến Bluetooth nên **không bắt buộc Reset NVRAM mỗi lần**.

## Kiểm tra sau boot

| Phần | Việc cần kiểm tra |
| --- | --- |
| Đồ họa | 2560 × 1600, mode 1440 × 900 HiDPI, góc trên/dưới, hover Dock, đổi con trỏ, kéo cửa sổ và số thông báo Dock. Chưa kết luận số Dock đã hết lỗi. |
| Âm thanh | Loa trái/phải, điều chỉnh âm lượng, tai nghe, chuyển jack và từng micro. Layout 11 được đặt nhất quán ở boot-arg và DeviceProperties. |
| Bluetooth | Bật/tắt, tìm thiết bị, ghép chuột/tai nghe, reconnect sau khởi động lại và cold boot. Firmware nhận thiết bị chưa chứng minh ghép đôi/audio đã hoạt động. |
| Touchpad | Di chuột, click/tap, cuộn hai ngón, pinch, ba/bốn ngón, kéo thả; TrackPoint và ba nút riêng. |
| USB | Cắm USB2 và USB3 vào từng cổng vật lý, kiểm tra USB-C cả hai chiều và hub nếu dùng. Connector ngoài chưa được đo hoàn chỉnh. |

Thu log sau boot bằng Terminal trong phiên đăng nhập:

```bash
bash scripts/collect.command
```

Trong gói release, file nằm dưới `scripts/`; trong bản nguồn có thể dùng đường dẫn đầy đủ `~/Documents/gen5_igpu_driver/scripts/collect.command`. Thêm `--metal` để chạy phép tính Metal nhỏ. Công cụ không tự phát âm thanh, bật camera, ghép đôi Bluetooth hoặc đổi thiết lập nguồn điện.

## Quay lại

Nếu boot mới có vấn đề, chọn USB cũ trong menu firmware. `backup/EFI/` trong bản nguồn là bản chụp ban đầu; `build/previous-before-hardware/` giữ kext/config/userland trước lượt build mới.

Nếu đã tự cài thư viện mới, phục hồi Metal bundle từ backup script tạo rồi boot EFI cũ:

```bash
sudo ditto "Backups/graphics-YYYYMMDD-HHMMSS/AppleIntelTGLGraphicsMTLDriver.bundle" "/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle"
```

Thay đúng thời điểm thư mục backup thực tế. Không cần xóa dữ liệu Bluetooth hoặc reset toàn bộ NVRAM để quay lại.
