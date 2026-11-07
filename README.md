# OpenCore EFI for Lenovo ThinkPad P1 Gen 5
### Intel Core i7-12800H | Dual-GPU: Intel Iris Xe + NVIDIA RTX A1000 | macOS Sequoia 15.x & Tahoe

[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.3-blue.svg)](https://github.com/acidanthera/OpenCorePkg)
[![macOS](https://img.shields.io/badge/macOS-Sequoia%2015.x%20%7C%20Tahoe-green.svg)](https://www.apple.com/macos/)
[![WhateverXe](https://img.shields.io/badge/WhateverXe-Patched%206--bpc-orange.svg)](https://github.com/khucxtriendev/WhateverXe)
[![Release](https://img.shields.io/badge/Release-EFI%20v1.0%20(ZIP)-purple.svg)](https://github.com/khucxtriendev/irisxegraphic-i712800h-efi/releases)

A production-grade OpenCore EFI configuration tailored specifically for the **Lenovo ThinkPad P1 Gen 5 (Type 21DDS88B00)**. 

This build achieves an extraordinary milestone: **Simultaneous Dual-GPU Multi-Monitor Acceleration on modern macOS**:
1. **Internal Panel (2560x1600 WQXGA):** Driven by **Intel Iris Xe Graphics (96 EU)** with QE/CI Metal 2 / Metal 3 acceleration via our patched [WhateverXe](https://github.com/khucxtriendev/WhateverXe).
2. **External Display (HDMI):** Directly wired to and driven by **NVIDIA RTX A1000 Laptop (Ampere)** with Metal 3 acceleration via [NullMoth's nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver).

Both displays work concurrently with fluid hardware acceleration!

---

## 1. Hardware Specifications

| Component | Detailed Specification |
| :--- | :--- |
| **Model** | Lenovo ThinkPad P1 Gen 5 (Type `21DDS88B00`) |
| **Processor (CPU)** | Intel Core i7-12800H (Alder Lake-H, 14 Cores / 20 Threads: 6 P-Cores up to 4.8 GHz + 8 E-Cores up to 3.7 GHz, 24MB L3 Cache, Display 13) |
| **Integrated GPU (iGPU)** | Intel Iris Xe Graphics (`8086:46A6`, 96 EU) — **Internal 2560x1600 eDP display with Metal 2 / Metal 3** |
| **Discrete GPU (dGPU)** | NVIDIA RTX A1000 Laptop (`10DE:25B9`, 4GB GDDR6 Ampere) — **External HDMI display with Metal 3** |
| **Internal Panel** | 16.0" 16:10 WQXGA (2560 x 1600), BOE `NE160QDM-NY1` / `LEN41B0` (eDP, 6-bpc GOP initialization) |
| **RAM** | 32GB (2 x 16GB) DDR5 4800MHz |
| **Storage** | NVMe SSD M.2 PCIe 4.0 x4 |
| **Audio** | Realtek ALC245 (`layout-id=11` via AppleALC) + Dolby Atmos stereo speakers |
| **Wireless & Bluetooth** | Intel Wi-Fi 6E AX211 160MHz (`AirportItlwm`) & Bluetooth 5.2 (`IntelBluetoothFirmware` + `IntelBTPatcher`) |
| **Input Devices** | Backlit ThinkPad Keyboard, TrackPoint + Precision Touchpad (`VoodooPS2Controller` + `VoodooI2C`) |
| **Power Management** | `HybridPM.kext` (XE-PM) + `CpuTopologyRebuild.kext` + `YogaSMC.kext` |

---

## 2. Feature Status

- [x] **Dual-GPU Multi-Monitor Acceleration:**
  - Internal 16.0" 2560x1600 display running on Intel Iris Xe (Metal 2 / Metal 3).
  - External HDMI monitor running directly on NVIDIA RTX A1000 (Metal 3).
- [x] **Display Backlight Brightness Control:** Smooth brightness slider for the internal panel via `SSDT-PNLF` and `BrightnessKeys.kext`.
- [x] **Hybrid CPU Power Management:** `HybridPM.kext` combined with `-hpm` dynamically scales P-cores and E-cores, enabling proper C-states to keep the laptop cool.
- [x] **Audio:** Internal stereo speakers, 3.5mm headphone jack, and internal microphone.
- [x] **Wi-Fi & Bluetooth:** Connectivity across 2.4GHz / 5GHz / 6GHz networks and Bluetooth peripherals.
- [x] **Keyboard & Trackpad:** ThinkPad keyboard shortcuts, TrackPoint navigation, and multi-touch gestures.
- [x] **Battery & Power Monitoring:** ACPI battery percentage readout via `SMCBatteryManager.kext` + `ECEnabler.kext`.
- [x] **Sleep & Wake:** Display clock and HDMI link restoration upon wake.
- [ ] **Windows Hello IR Camera:** Unsupported by macOS.

---

## 3. Upstream Credits & Acknowledgments

This achievement is built upon the incredible work of the open-source community:

* **[khucxtriendev/WhateverXe](https://github.com/khucxtriendev/WhateverXe):** WhateverXe fork patched for Lenovo ThinkPad UEFI GOP 6-bpc (`0x8a200106`), eDP panel preservation during Type-C unreadiness, and physical register verification preventing `tryCloseGate()` black screens.
* **[nullmoth/1401](https://github.com/nullmoth/1401) & [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver):** The breakthrough NVIDIA modern macOS driver and installer app enabling NVIDIA Ampere/Turing dGPUs on macOS with Metal 3.
* **[b00t0x/WhateverXe](https://github.com/b00t0x/WhateverXe) & [b00t0x/WhateverXe-Graphics](https://github.com/b00t0x/WhateverXe-Graphics):** Foundational Intel Xe graphics adaptation layer on macOS.
* **[Thatisjigen/WhateverXe](https://github.com/Thatisjigen/WhateverXe) & [Thatisjigen/acer-nitro-anv15-52-macos](https://github.com/Thatisjigen/acer-nitro-anv15-52-macos):** Display 13 eDP research and implementations for mobile Alder Lake / Raptor Lake architectures.
* **[JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe):** Pioneer of Intel Iris Xe Metal driver adaptation on macOS Tahoe/Sequoia:
  - `xefix.m` / `libxedrv`: Synchronizing compute vs render order and eliminating WindowServer backdrop blur rectangle artifacts.
  - `posh_patch`: Resolving the command buffer memory leak.
  - `XE-PM` (`HybridPM.kext`): Intelligent frequency scaling for hybrid P/E core architectures.
* **[Acidanthera](https://github.com/acidanthera):** OpenCorePkg, Lilu, VirtualSMC, AppleALC, RestrictEvents, AMFIPass, etc.
* **[OpenIntelWireless](https://github.com/OpenIntelWireless):** AirportItlwm and IntelBluetoothFirmware.

---

## 4. Complete Step-by-Step Installation Procedure

To achieve a fully functional dual-GPU setup, follow these four phases in order:

### Phase 1: Prepare the USB Installer via NullMoth 1401
1. Download the **1401 installer tool** from [nullmoth/1401](https://github.com/nullmoth/1401).
2. Use the 1401 application to create a bootable macOS USB installer.
3. The USB partition will be formatted as FAT32 with the volume label **`1401`**.

### Phase 2: Fresh macOS Installation
1. Boot the ThinkPad P1 Gen 5 by pressing **F12** at startup and selecting the `1401` USB drive.
2. Complete the standard macOS installation (Sequoia 15.x / Tahoe) onto your internal NVMe SSD.
3. Once at the macOS Desktop, complete the initial post-install environment setup prompted by 1401.

### Phase 3: Install NullMoth NVIDIA Driver (External HDMI Display)
1. Download the latest driver package from [NullMoth NVIDIA macOS Driver Releases](https://github.com/nullmoth/nvidia-macos-driver/releases).
2. Install the package in macOS to deploy the NVIDIA kernel extensions (`NVRM.kext`, `NVAccel.kext`, etc.) and the Metal user-space bundle (`/Library/GPUBundles/NVMTLDriver.bundle`).
3. Connect an external HDMI monitor — it will light up powered by the NVIDIA RTX A1000 with Metal 3 acceleration!

### Phase 4: Deploy This ThinkPad P1 Gen 5 EFI & Post-Install (Intel Iris Xe)
1. Download **`EFI-ThinkPad-P1-Gen5-IrisXe-Nvidia-v1.0.zip`** from this repository's [Releases](https://github.com/khucxtriendev/irisxegraphic-i712800h-efi/releases).
2. Extract and copy the **`EFI`** directory to the EFI partition of your USB drive or internal SSD.
3. Copy the **`postinstall_tools`** folder from this repo onto the root of the USB (volume `1401`).
4. In macOS Terminal, execute the automated Intel graphics setup script:
   ```bash
   sudo bash /Volumes/1401/postinstall_tools/install_iris_xe.sh
   ```
   *This script installs WhateverXe Graphics, injects JulioNectar's `impostor.dylib` (`xefix`), sets `root:wheel` permissions, and rebuilds the AuxKC kernel cache.*
5. Restart your laptop:
   ```bash
   sudo reboot
   ```

---

## 5. Verification

After rebooting, open **Terminal** and verify both GPUs:

```bash
system_profiler SPDisplaysDataType
```

* **Expected Result:**
  * **Intel Iris Xe Graphics:** Driving the internal 16.0" 2560x1600 eDP panel (`Metal Support: Metal 2` or `Metal 3`).
  * **NVIDIA RTX A1000 Laptop:** Driving the external HDMI monitor (`Metal Support: Metal 3`).
* Both displays run simultaneously with fluid 60 FPS hardware acceleration, smooth window movement, and balanced thermal performance!

---

## 6. Pre-Packaged Release

For immediate deployment, download the ready-to-use EFI archive from GitHub Releases:
* 📦 **[Download EFI-ThinkPad-P1-Gen5-IrisXe-Nvidia-v1.0.zip](https://github.com/khucxtriendev/irisxegraphic-i712800h-efi/releases)**
