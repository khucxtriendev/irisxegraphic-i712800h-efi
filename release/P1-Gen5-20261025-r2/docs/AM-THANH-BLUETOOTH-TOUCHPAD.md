# Âm thanh, Bluetooth và touchpad trong bộ P1

Các quyết định dưới đây dựa trên phần cứng của chính máy; dữ liệu IORegistry được đọc trong phiên EFI cũ để nhận dạng thiết bị. Việc nhận dạng không phải kết quả kiểm thử bản EFI mới.

## Âm thanh: layout 11

- Controller thật **8086:51C8**, ACPI `/_SB/PC00/HDAS`, PCI `00:1f.3`; không spoof controller thành ID của Dell.
- Codec **ALC287** được đối chiếu từ INF Windows với subsystem Lenovo `17AA:22F8`; chưa có live codec dump xác nhận toàn bộ pin/amp.
- `DeviceProperties/Add/PciRoot(0x0)/Pci(0x1F,0x3)/layout-id` là DATA `0B000000`. `alcid=11` nhất quán, không giữ alcid khác.
- Nạp **Lilu 1.7.3 → AppleALC 1.9.8 → SimpleHDA 1.0.0**, cùng `keepsyms=1` và `-alcbeta` trên Darwin 25. SimpleHDA phục hồi stack AppleHDA cho Tahoe; không dùng AudShim dành cho SoundWire của Dell.
- Layout 11 có trong nguồn ALC287 của AppleALC. Sự tồn tại của layout không chứng minh mọi đường loa/mic/amp của P1 đã khớp; cần thử từng đường sau boot.
- Gói HAL tùy chọn được chép vào `Optional/SimpleHDA-HAL-1.0.0.pkg`. Nó không tự được cài. Theo upstream, khi không có HAL, SimpleHDA vẫn dùng đường IOAudio thông thường.

Nguồn: [SimpleHDA](https://github.com/laobamac/SimpleHDA/blob/main/README.en.md), [ALC287 layouts](https://github.com/acidanthera/AppleALC/blob/master/Resources/ALC287/Info.plist), [controller 51C8 trong AppleALC](https://github.com/acidanthera/AppleALC/blob/master/Resources/Controllers.plist).

## Bluetooth: Intel AX211

- USB **8087:0033**, firmware đã nhận tên `ibt-0040-0041.sfi` trong phiên cũ.
- Nạp **IntelBluetoothFirmware 2.5.1, IntelBTPatcher 2.5.1, BlueToolFixup 2.7.3**, sau Lilu; không bật IntelBluetoothInjector/BrcmBluetoothInjector đời cũ.
- NVRAM: `bluetoothExternalDongleFailed` là DATA `00`; `bluetoothInternalControllerInfo` là DATA 14 byte zero. Cả hai có trong Delete và Add để thay giá trị cũ khi boot.
- Thiết bị Bluetooth thực nằm tại `14a00000`, port số **10** của controller **8086:51ED**. `P1Gen5USBMap.kext` đặt `HS10/UsbConnector=255` (internal).
- Map giữ đủ **12 port USB2 + 3 port USB3 = 15**, không bỏ cổng để nhường Bluetooth. Cũng đánh dấu internal cho Goodix ở HS06 và camera ở HS08 theo topology đã đọc.
- Các cổng ngoài chưa được cắm thử USB2/USB3 và xác minh companion; connector type ngoài còn tạm. Controller Thunderbolt **8086:1138** giữ enumeration, không áp một map USB-C chưa đo. Vì vậy không gọi đây là map hoàn chỉnh của tất cả cổng vật lý.
- Tắt UTBDefault trong cấu hình mới để không có hai injector cạnh tranh. `XhciPortLimit` giữ false. Không xóa thiết bị đã pair hay file preferences Bluetooth.

Nguồn: [IntelBluetoothFirmware FAQ](https://openintelwireless.github.io/IntelBluetoothFirmware/FAQ.html), [BlueToolFixup và NVRAM](https://github.com/acidanthera/BrcmPatchRAM#bluetoolfixupkext), [USBToolBox](https://github.com/USBToolBox/kext).

## Touchpad: Synaptics I2C Precision

- ACPI **SYNA801D / TPD0**, HID vendor **06CB**, product **CEC9**, I2C address `0x2C`.
- IORegistry hiện có `VoodooI2CPrecisionTouchpadHIDEventDriver`, **5 transducer**, mode **GPIO**, pin **332**. GPIO controller **INTC1055** đang được `VoodooGPIOTigerLakeLP` nhận.
- Giữ nguyên bản VoodooI2C **2.9.1**, VoodooI2CHID và bản GPIO đã được tùy chỉnh cho máy. Không thay GPIO bằng bản upstream khác chỉ vì cùng tên kext.
- Nạp đúng phụ thuộc VoodooI2CServices, GPIO, VoodooI2C, VoodooInput và VoodooI2CHID. Chỉ một VoodooInput ở nhánh I2C được bật; bản trùng trong PS2 tắt.
- Giữ VoodooPS2Controller **2.3.8**, keyboard/mouse/trackpad plugins để bảo toàn bàn phím và đường TrackPoint. Không tắt PS2Trackpad máy móc: nó có thể phục vụ pass-through TrackPoint.
- Không ép polling hay đổi GPIO pin của một thiết bị đã nhận đúng trong phiên hiện tại. Cần kiểm thử gesture và TrackPoint sau boot bản mới.

Nguồn: [VoodooI2C installation và interrupt mode](https://github.com/VoodooI2C/VoodooI2C/blob/master/Documentation/Installation.md). Chi tiết phần cứng được lưu trong `reports/peripheral-evidence.json` và `reports/usb-port-map.json`.
