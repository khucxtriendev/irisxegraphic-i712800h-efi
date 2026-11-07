# OpenCore EFI for Lenovo ThinkPad P1 Gen 5
### Intel Core i7-12800H | Intel Iris Xe Graphics (96 EU) | macOS Sequoia 15.x & Tahoe

[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.3-blue.svg)](https://github.com/acidanthera/OpenCorePkg)
[![macOS](https://img.shields.io/badge/macOS-Sequoia%2015.x%20%7C%20Tahoe-green.svg)](https://www.apple.com/macos/)
[![WhateverXe](https://img.shields.io/badge/WhateverXe-Patched%206--bpc-orange.svg)](https://github.com/khucxtriendev/WhateverXe)

A production-ready OpenCore EFI configuration tailored specifically for the **Lenovo ThinkPad P1 Gen 5 (Type 21DDS88B00)**. This EFI successfully enables full **Intel Iris Xe Graphics (QE/CI with Metal 3D)** hardware acceleration on the internal **16.0" 2560x1600 (WQXGA)** eDP display without black screens or vertical slicing artifacts.

---

## 1. Hardware Specifications

| Component | Detailed Specification |
| :--- | :--- |
| **Model** | Lenovo ThinkPad P1 Gen 5 (Type `21DDS88B00`) |
| **Processor (CPU)** | Intel Core i7-12800H (Alder Lake-H, 14 Cores / 20 Threads: 6 P-Cores up to 4.8 GHz + 8 E-Cores up to 3.7 GHz, 24MB L3 Cache, Display 13) |
| **Integrated GPU (iGPU)** | Intel Iris Xe Graphics (`8086:46A6`, 96 Execution Units) — **Fully accelerated QE/CI Metal 3D** |
| **Discrete GPU (dGPU)** | NVIDIA RTX A1000 Laptop (`10DE:25B9`, 4GB GDDR6) — *Isolated and powered off to save battery and prevent heat* |
| **Internal Panel** | 16.0" 16:10 WQXGA (2560 x 1600), BOE `NE160QDM-NY1` / `LEN41B0` (eDP, 6-bpc GOP initialization) |
| **RAM** | 32GB (2 x 16GB) DDR5 4800MHz |
| **Storage** | NVMe SSD M.2 PCIe 4.0 x4 |
| **Audio** | Realtek ALC245 (`layout-id=11` via AppleALC) with Dolby Atmos stereo speakers |
| **Wireless & Bluetooth** | Intel Wi-Fi 6E AX211 160MHz (`AirportItlwm`) & Bluetooth 5.2 (`IntelBluetoothFirmware` + `IntelBTPatcher`) |
| **Input Devices** | Backlit ThinkPad Keyboard, TrackPoint + Precision Touchpad (`VoodooPS2Controller` + `VoodooI2C`) |
| **Power Management** | `HybridPM.kext` (XE-PM) + `CpuTopologyRebuild.kext` + `YogaSMC.kext` |

---

## 2. Feature Status

- [x] **Hardware Graphics Acceleration (QE/CI & Metal 3D):** Fully functional at native 2560x1600 @ 60Hz.
- [x] **Display Backlight Brightness Control:** Smooth brightness slider via `SSDT-PNLF` and `BrightnessKeys.kext`.
- [x] **Hybrid CPU Power Management:** `HybridPM.kext` combined with `-hpm` dynamically scales P-cores and E-cores, enabling proper C-states to keep the laptop cool and responsive.
- [x] **Audio:** Internal stereo speakers, 3.5mm headphone combo jack, and internal microphone.
- [x] **Wi-Fi & Bluetooth:** Full connectivity across 2.4GHz / 5GHz / 6GHz networks and Bluetooth peripherals.
- [x] **Keyboard & Trackpad:** Native ThinkPad keyboard shortcuts, TrackPoint navigation, and multi-touch gestures.
- [x] **Battery & Power Monitoring:** ACPI battery status and percentage readout via `SMCBatteryManager.kext` + `ECEnabler.kext`.
- [x] **Sleep & Wake:** Proper display clock restoration upon waking from sleep.
- [ ] **NVIDIA RTX A1000 dGPU:** Unsupported on modern macOS; power-down isolation drops internal temperature by 20°C–30°C.
- [ ] **Windows Hello IR Camera:** Unsupported by macOS.

---

## 3. Upstream Credits & Acknowledgments

This configuration builds upon pioneering work by the Hackintosh community:

* **[khucxtriendev/WhateverXe](https://github.com/khucxtriendev/WhateverXe):** WhateverXe fork patched specifically for Lenovo ThinkPad UEFI GOP 6-bpc (`0x8a200106`), eDP panel preservation during Type-C unreadiness, and physical register verification preventing `tryCloseGate()` black screens.
* **[b00t0x/WhateverXe](https://github.com/b00t0x/WhateverXe) & [b00t0x/WhateverXe-Graphics](https://github.com/b00t0x/WhateverXe-Graphics):** Foundational Intel Xe graphics adaptation layer on macOS.
* **[Thatisjigen/WhateverXe](https://github.com/Thatisjigen/WhateverXe) & [Thatisjigen/acer-nitro-anv15-52-macos](https://github.com/Thatisjigen/acer-nitro-anv15-52-macos):** Display 13 eDP research and implementations for mobile Alder Lake / Raptor Lake architectures.
* **[JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe):** Trailblazing Intel Iris Xe Metal driver adaptation for modern macOS, including:
  - `xefix.m` / `libxedrv`: Synchronizing compute vs render order and eliminating WindowServer backdrop blur rectangle artifacts.
  - `posh_patch`: Resolving the command buffer memory leak (5.6 MB/s).
  - `XE-PM` (`HybridPM.kext`): Intelligent frequency scaling for hybrid P/E core architectures.
* **[Acidanthera](https://github.com/acidanthera):** OpenCorePkg, Lilu, VirtualSMC, AppleALC, RestrictEvents, AMFIPass, etc.
* **[OpenIntelWireless](https://github.com/OpenIntelWireless):** AirportItlwm and IntelBluetoothFirmware.

---

## 4. Installation via USB Partition `1401`

The bootable USB partition is standardized with the volume label **`1401`** (formatted as FAT32).

### Preparing the USB Drive:
1. Format a USB drive partition with **FAT32** (MBR or GPT).
2. Set the volume label to: **`1401`**.
3. Copy the folders from this repository to the USB:
   * The `EFI/` directory (containing `BOOT/` and `OC/`) ➔ Place in the USB root.
   * The `postinstall_tools/` directory ➔ Place in the USB root.

```
USB 1401/
├── EFI/
│   ├── BOOT/
│   │   └── BOOTx64.efi
│   └── OC/
│       ├── config.plist
│       ├── ACPI/
│       ├── Drivers/
│       └── Kexts/
└── postinstall_tools/
    ├── install_iris_xe.sh
    ├── impostor.dylib
    ├── posh_patch.sh
    └── whateverxe_thinkpad_p1_gen5.patch
```

### Booting and Installing macOS:
1. Insert the USB drive into the ThinkPad P1 Gen 5.
2. Power on the laptop and immediately press **F12** to enter the BIOS Boot Menu.
3. Select the `1401` USB device to launch the OpenCore picker.
4. Select the macOS Sequoia installer and proceed with the installation.

---

## 5. Post-Installation: Installing Drivers into `/Library` (Enabling Metal 3D)

> [!IMPORTANT]
> **Why is installing into `/Library` mandatory?**
> The WhateverXe kernel extension in the EFI only provides a 2D GOP framebuffer scanout to illuminate the screen. Without the Intel Metal driver bundle installed in `/Library/GPUBundles`, macOS falls back to software rendering on the CPU (Apple llvmpipe).
> Running software rendering on a 2560x1600 display consumes 50%–100% of the 14-core CPU, causing **extreme UI lag and high temperatures (80°C–95°C)**. Installing the driver into `/Library` activates the 96-EU GPU for Metal 3D, delivering smooth 60 FPS animations and cool CPU temperatures.

### Option 1: Automated 1-Step Installation (Recommended)

Once you reach the macOS Desktop, ensure the `1401` USB is plugged in, open **Terminal**, and execute:

```bash
sudo bash /Volumes/1401/postinstall_tools/install_iris_xe.sh
```

*(Tip: You can type `sudo bash ` with a trailing space, then drag and drop `install_iris_xe.sh` from Finder directly into Terminal and press Enter).*

**What this script automates:**
1. Verifies or automatically downloads `WhateverXe-Graphics-0.4.0.pkg` from GitHub and installs it into `/Library/GPUBundles` and `/Library/Extensions`.
2. Injects JulioNectar's `impostor.dylib` (`xefix`) bridge and ad-hoc codesigns it.
3. Sets correct ownership and permissions (`root:wheel`, `755`).
4. Rebuilds the Auxiliary Kernel Collection (`kmutil install --volume-root / --update-all`).

---

### Option 2: Manual Installation Steps

If you prefer executing each step manually:

1. **Install the WhateverXe Graphics package:**
   ```bash
   sudo installer -pkg /Volumes/1401/postinstall_tools/WhateverXe-Graphics-0.4.0.pkg -target /
   ```
2. **Inject the JulioNectar Metal bridge:**
   ```bash
   sudo cp -f /Volumes/1401/postinstall_tools/impostor.dylib /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   sudo chmod 755 /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   sudo codesign -f -s - -i impostor /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   ```
3. **Set permissions:**
   ```bash
   sudo chown -R root:wheel /Library/GPUBundles /Library/Extensions
   sudo chmod -R 755 /Library/GPUBundles /Library/Extensions
   ```
4. **Rebuild the Kernel Cache:**
   ```bash
   sudo kmutil install --volume-root / --update-all
   ```
5. **Restart the machine:**
   ```bash
   sudo reboot
   ```

---

## 6. Post-Install Verification

After rebooting, open **Terminal** and run:
```bash
system_profiler SPDisplaysDataType | grep -E "Chipset Model|Metal"
```

* **Expected Output:**
  ```text
  Chipset Model: Intel Iris Xe Graphics
  Metal Support: Metal 3 (or Metal 2)
  ```
* Open **Activity Monitor**: `WindowServer` utilization should drop to a steady 1%–3%.
* Window resizing, Dock magnification, and 4K video playback will run at a fluid **60 FPS**, with CPU temperatures idling comfortably around 45°C–55°C.
