# OpenCore EFI for Lenovo ThinkPad P1 Gen 5
### Intel Core i7-12800H | Dual-GPU: Intel Iris Xe + NVIDIA RTX A1000 | macOS Sequoia 15.x & Tahoe

<p align="center">
  <img src="stats.webp" alt="ThinkPad P1 Gen 5 Dual-GPU macOS Stats" width="100%">
</p>

[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.3-blue.svg)](https://github.com/acidanthera/OpenCorePkg)
[![macOS](https://img.shields.io/badge/macOS-Sequoia%2015.x%20%7C%20Tahoe-green.svg)](https://www.apple.com/macos/)
[![WhateverXe](https://img.shields.io/badge/WhateverXe-Patched%206--bpc-orange.svg)](https://github.com/khucxtriendev/WhateverXe)
[![Microphone](https://img.shields.io/badge/DMIC-LatSOFAudio%20Working-success.svg)](LatSOF-Audio%20patched/)
[![Display](https://img.shields.io/badge/Display-HiDPI%20Override-informational.svg)](Display_Override/)
[![Keyboard](https://img.shields.io/badge/Keyboard-Native%20Remap-brightgreen.svg)](Keyboard_Remap/)
[![Kexts](https://img.shields.io/badge/Kexts-36%20Inventory-teal.svg)](docs/KEXTS.md)
[![Power Management](https://img.shields.io/badge/Power-XE--PM%20Guide-success.svg)](docs/XE-PM-GUIDE.md)
[![Release](https://img.shields.io/badge/Release-EFI%20v1.0.1%20(ZIP)-purple.svg)](https://github.com/khucxtriendev/irisxegraphic-i712800h-efi/releases/tag/v1.0.1)

### 📚 Documentation & Technical Guides:
* 📦 [**Kext Reference & Version Inventory**](docs/KEXTS.md): Full breakdown of all 36 kernel extensions, versions, bundle IDs, and input device coordination (`VoodooPS2` + `VoodooI2C`).
* ⚡ [**XE-PM & Hybrid Power Management Guide**](docs/XE-PM-GUIDE.md): Architectural deep-dive into Alder Lake HWP frequency scaling, thermal profiles, and live `sysctl` commands.
* 🎙️ [**LatSOF-Audio DMIC Guide**](LatSOF-Audio%20patched/HUONG_DAN_CAI_DAT.md): Native Intel Smart Sound (cAVS 2.5) digital microphone driver and volume setup.
* 🖥️ [**Display Override & HiDPI Guide**](Display_Override/HUONG_DAN_CAI_DAT.md): BOE panel EDID patch, sharp text vector rendering, and accessibility font tuning.
* ⌨️ [**Keyboard Remap Guide**](Keyboard_Remap/HUONG_DAN_SU_DUNG.md): 100% native Windows-style shortcuts (`Ctrl+C/V/Z`, `Alt+Tab`) and one-click `PrtSc` screenshot to clipboard.

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
| **Internal Panel** | 16.0" 16:10 WQXGA (2560 x 1600), BOE `NE160QDM-NY1` / `LEN41B0` (eDP, 6-bpc GOP initialization, HiDPI Retina override & sharp vector font tuning) |
| **RAM** | 32GB (2 x 16GB) DDR5 4800MHz |
| **Storage** | NVMe SSD M.2 PCIe 4.0 x4 |
| **Audio** | Realtek ALC287 (`10EC:0287`, layout-id `11` via AppleALC) + Dolby Atmos stereo speakers + **Intel SST/cAVS 2.5 DMIC array via `LatSOFAudio.kext`** |
| **Wireless & Bluetooth** | Intel Wi-Fi 6E AX211 160MHz (`AirportItlwm`) & Bluetooth 5.2 (`IntelBluetoothFirmware` + `IntelBTPatcher`) |
| **Input Devices** | Backlit ThinkPad Keyboard (with native Windows-style remap & `PrtSc` to clipboard), TrackPoint + Precision Touchpad (`VoodooPS2Controller` + `VoodooI2C`) |
| **Power Management** | `HybridPM.kext` (XE-PM) + `CpuTopologyRebuild.kext` + `YogaSMC.kext` |

---

## 2. Feature Status & Apple Ecosystem Matrix

### 🛠️ Hardware Functionality Checklist:
- [x] **Dual-GPU Multi-Monitor Acceleration:**
  - Internal 16.0" 2560x1600 display running on Intel Iris Xe (Metal 2 / Metal 3).
  - External HDMI monitor running directly on NVIDIA RTX A1000 (Metal 3).
- [x] **Display Backlight Brightness Control:** Smooth brightness slider for the internal panel via `SSDT-PNLF` and `BrightnessKeys.kext`.
- [x] **Display Override & Ultra-Sharp Text Rendering:** Native Retina HiDPI profiles (`Display_Override/`) and Accessibility vector outline font smoothing override eliminating GPU downsampling blur.
- [x] **Hybrid CPU Power Management:** `HybridPM.kext` (XE-PM) dynamically scales P-cores and E-cores, enabling C8/C10 deep sleep states (40°C–50°C idle).
- [x] **Audio Speakers & Headphone Jack:** Realtek ALC287 codec (`alcid=11`) driving internal stereo speakers and 3.5mm audio jack.
- [x] **Internal Digital Microphone:** ✅ **Working** (Fully functional via patched `LatSOFAudio.kext` driving the Intel Smart Sound Technology cAVS 2.5 DMIC digital microphone array as a native macOS `IOAudio` device with hardware gain calibration).
- [x] **Wi-Fi & Bluetooth:** Intel Wi-Fi 6E AX211 (`AirportItlwm`) connecting to 2.4GHz / 5GHz / 6GHz networks, Bluetooth 5.2 connecting to mice, keyboards, and headphones.
- [x] **Keyboard, TrackPoint & Precision Trackpad:** Backlit ThinkPad keyboard with native Windows-style key remap and `PrtSc` screenshot (`Keyboard_Remap/`), red TrackPoint nub with physical click buttons, and multi-touch gestures on the glass trackpad.
- [x] **Battery & Power Monitoring:** Live percentage readout, charging metrics, and cycle counts via `SMCBatteryManager` + `ECEnabler`.
- [x] **Webcam:** Integrated 1080p FHD USB UVC webcam works out of the box with FaceTime, Zoom, and Photo Booth.
- [ ] **Sleep & Wake:** ⚠️ **Currently NOT working / WIP** (Dual-GPU multi-head sleep requires further work synchronizing NVIDIA GSP firmware re-initialization and Intel Display 13 MBUS/DDB power wells upon wake).
- [ ] **Windows Hello IR Camera & Touch ID:** Unsupported by macOS (macOS requires Apple TrueDepth and Secure Enclave T2/Apple Silicon hardware).

### 🍎 Apple Ecosystem & Continuity Services:

| Feature | Status | Notes & Workarounds |
| :--- | :--- | :--- |
| **iMessage & FaceTime** | ✅ **Working** | Requires generating and entering your own unique MLB, ROM, and Serial Number in `PlatformInfo -> Generic`. |
| **iCloud Drive & App Store** | ✅ **Working** | Full sync for Notes, Reminders, Photos, and App Store purchases. |
| **Handoff** | ✅ **Working** | Seamlessly continue browsing tabs and open apps from iPhone/iPad to ThinkPad. |
| **Universal Clipboard** | ✅ **Working** | Copy text or images on your iPhone and paste them directly on macOS. |
| **Continuity Camera & Mic** | ✅ **Working** | Supported natively. Internal DMIC now functions independently via `LatSOFAudio.kext`, with iPhone Continuity available as a studio-grade alternative. |
| **AirDrop** | **Working** | Intel Wi-Fi (`ForbiddenItlwm`) 
| **Universal Control** | ⚠️ **Unsupported** | Depends on Apple AWDL protocol, which is unavailable on Intel Wi-Fi. |
| **Sidecar** | ⚠️ **Untested / Limited** | Requires Apple T2 hardware or native Apple QuickSync H.265 encoder. |
| **DRM (Apple TV+, Netflix 4K)** | ⚠️ **Partial** | Netflix/YouTube 1080p works in Chrome/Brave (Widevine). Safari FairPlay 4K streaming is limited on non-native GPUs. |

> 🎙️ **Internal Digital Microphone Fully Working (`LatSOFAudio.kext`):**
> The laptop's dual digital microphones (Intel cAVS 2.5 DMIC) are driven natively via our patched **`LatSOFAudio.kext`**. You no longer need external audio adapters or workarounds! See [Section 6 - Phase 6](#phase-6-internal-digital-microphone-setup-latsofaudiokext) for volume calibration and TCC permission steps.

> 📦 **Complete Kext Inventory & Version Guide:**
> For the complete inventory of all 35 kernel extensions included in this EFI, exact version numbers, bundle IDs, and why `VoodooPS2` & `VoodooI2C` are coordinated, refer to the [**Kext Reference & Version Inventory**](docs/KEXTS.md).

---

## 3. CPU Power Management: How to Use XE-PM (HybridPM)

Intel 12th Gen Alder Lake-H (`i7-12800H`) features a hybrid architecture combining **6 Performance cores (12 threads)** and **8 Efficient cores (8 threads)**. Because macOS Apple XCPM scheduler predates hybrid architectures, it natively misclassifies E-cores, ignores Intel Thread Director, and causes P-cores to run at elevated frequencies while keeping idle power consumption high (30W–45W at idle, 80°C–90°C).

This EFI employs **XE-PM** (originally discovered and developed by [JulioNectar](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe), and ported into the standalone Lilu plugin `HybridPM.kext` by [Thatisjigen](https://github.com/Thatisjigen/HybridPM)) alongside `CpuTopologyRebuild.kext` to correct hybrid scheduling, HWP multiplier scaling (78.7 MHz mismatch), and deep C-states (C8/C10).

> 📖 **Comprehensive Technical Guide:**
> For an exhaustive architectural explanation, live `sysctl` runtime commands without rebooting, and custom power profiles, please see our dedicated [**XE-PM & Hybrid CPU Power Management Guide**](docs/XE-PM-GUIDE.md).
>
> 🔗 **Original Upstream Documentation:**
> * [JulioNectar XE-PM Guide: Full CPU Turbo & Lower Idle Power](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe#new-full-cpu-turbo-and-lower-idle-power--ngreenpm-26-oct)
> * [Thatisjigen HybridPM Upstream Documentation](https://github.com/Thatisjigen/HybridPM#what-it-does)

### Active HybridPM Parameters in `config.plist`:
* **`-hpm`**: Activates the HybridPM Lilu plugin.
* **`-hpmbeta`**: Relaxes OS checks to allow running on newer macOS versions (Sequoia 15.x and Tahoe).
* **`hpmd3=1`**: Enforces package D3 state behavior for driverless PCI devices, drastically lowering idle draw.
* **`hpmepp=128`**: Sets the Energy Performance Preference (EPP) register to `128` (a balanced sweet-spot between performance and battery thermal efficiency, where `0` = maximum performance and `255` = maximum power saving).
* **`hpmpl1=45`**: Configures the sustained Power Limit 1 (PL1) ceiling to `45W`, matching the native TDP of the Intel Core i7-12800H.
* **`ctrsmt=full`**: Instructs `CpuTopologyRebuild.kext` to build an asymmetric core topology mapping so macOS correctly schedules background tasks to E-cores and high-priority threads to P-cores.

### Live Dynamic Power Tuning (No Reboot Required):
You can switch power modes instantly in Terminal:
```bash
# Maximum Performance (EPP 0):
sudo sysctl -w debug.hybridpm.epp=0

# Balanced / Daily Workflow (EPP 128 - Default):
sudo sysctl -w debug.hybridpm.epp=128

# Maximum Battery / Whisper Quiet (EPP 192):
sudo sysctl -w debug.hybridpm.epp=192
```

---

## 4. Comprehensive Boot-Args Analysis

Below is the complete breakdown of the boot arguments utilized in `config.plist`:

```text
-v debug=0x100 keepsyms=1 -allow3d -disablegfxfirmware -igfxdvmt ctrsmt=full amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 revblock=pci,gmux revpatch=sbvmm,cpuname revcpu=1 -wex-reset-recover -wex-scanout-coherent -wex-hidpi-dbuf alcid=11 -hpm -hpmbeta hpmd3=1 hpmepp=128 hpmpl1=45 nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth nvfbhidpi=1
```

### Breakdown by Subsystem:

| Argument | Category | Purpose |
| :--- | :--- | :--- |
| `-v` | Diagnostic | Enables verbose boot mode for hardware logging and troubleshooting. |
| `debug=0x100` | Kernel | Prevents automatic reboot upon kernel panic, allowing inspection of the panic log. |
| `keepsyms=1` | Kernel | Retains kernel debug symbols in panic backtraces. |
| `-allow3d` | WhateverXe | Enables 3D hardware acceleration for Intel Xe integrated graphics. |
| `-disablegfxfirmware` | WhateverXe | Prevents loading Apple's incompatible proprietary GPU firmware on Alder Lake Xe. |
| `-igfxdvmt` | WhateverXe | Enables DVMT stolen memory patching for Intel Xe. |
| `-wex-reset-recover` | WhateverXe | Saves and restores render engine MOCS/L3 cache tables across GPU hang resets. |
| `-wex-scanout-coherent`| WhateverXe | Treats flipped display surfaces as displayable for coherent MOCS caching. |
| `-wex-hidpi-dbuf` | WhateverXe | Allocates 96 DBUF blocks for cursor and primary planes, preventing HiDPI scaling glitches. |
| `amfi_get_out_of_my_way=0x1` | Security | AMFIPass parameter bypassing AMFI code-signing checks for third-party graphics bundles. |
| `amfi=0x80` | Security | Relaxes AMFI signature enforcement for unapproved user-space drivers. |
| `ipc_control_port_options=0` | Kernel | Relaxes mach port IPC restrictions required for custom Metal bundles. |
| `ctrsmt=full` | CPU Topology | Configures full asymmetric SMT topology for Alder Lake 6P + 8E cores. |
| `revblock=pci,gmux` | RestrictEvents | Blocks GMUX and PCI validation checks. |
| `revpatch=sbvmm,cpuname` | RestrictEvents | Enables Software Update VMM patching and CPU brand string override. |
| `revcpu=1` | RestrictEvents | Enables custom CPU topology display in macOS System Settings. |
| `-hpm` | XE-PM | Activates JulioNectar's Hybrid CPU Power Management plugin. |
| `-hpmbeta` | XE-PM | Permits XE-PM execution on macOS Sequoia and Tahoe. |
| `hpmd3=1` | XE-PM | Enables package D3 low-power states. |
| `hpmepp=128` | XE-PM | Sets balanced Energy Performance Preference (EPP). |
| `hpmpl1=45` | XE-PM | Configures 45W long-term TDP power limit for i7-12800H. |
| `nvfb=1` | NullMoth | Enables NullMoth NVIDIA Framebuffer (NVRMFB) driver. |
| `nvaccel=1` | NullMoth | Enables NullMoth NVIDIA Hardware Acceleration (NVAccel). |
| `nvfbheads=4` | NullMoth | Configures 4 display heads for the NVIDIA RTX A1000. |
| `-nvkmsnosmooth` | NullMoth | Disables KMS smooth-stepping transitions on NVIDIA display ports. |
| `nvfbhidpi=1` | NullMoth | Enables HiDPI scaling support on displays attached to the NVIDIA card. |
| `alcid=11` | Audio | Sets AppleALC layout ID 11 for Realtek ALC287 (`10EC:0287`). Test `alcid=13` or `21` for mic/combo troubleshooting. |

---

## 5. Sleep & Wake: Current Limitations & Workaround

> [!WARNING]
> **Sleep & Wake is currently in development and NOT yet functional on this dual-GPU setup.**
> Attempting to sleep the machine can lead to black screens, kernel panics on wake, or disconnected HDMI links.

### Why Sleep/Wake Fails on Dual-GPU Hackintosh:
1. **NVIDIA GSP Firmware Wake:** The NVIDIA Ampere architecture relies on GSP (GPU System Processor) firmware. When waking from S3/Modern Standby, the GSP firmware must be completely cold-booted and reloaded by `NVRM.kext`. Modern macOS lacks native handling for discrete NVIDIA sleep/wake cycles.
2. **Display 13 Pipe Desynchronization:** WhateverXe must reprogram MBUS, Pipe DDB, and clock gates upon wake. When two independent GPU drivers (Intel + NVIDIA) attempt to wake simultaneously, display handoff can stall.

### Recommended System Settings to Prevent Sleep:
To prevent unexpected panics while sleeping, configure macOS power management in Terminal:

```bash
sudo pmset -a disablesleep 1
sudo pmset -a sleep 0
sudo pmset -a displaysleep 15
sudo pmset -a hibernatemode 0
```
*(This allows the display to turn off after 15 minutes of inactivity while keeping the system awake and stable).*

---

## 6. Complete Step-by-Step Installation Procedure

To achieve a fully functional dual-GPU setup, follow these phases in order:

### Phase 0: Lenovo ThinkPad BIOS Configuration (Crucial: Hybrid Graphics)
Before booting the installer, press **F1** or **Enter** at the Lenovo splash screen to enter the UEFI BIOS Setup and configure the following options:

* ⚠️ **Config -> Display -> Graphics Device:** Set to **`Hybrid Graphics`** *(MANDATORY)*
  * **DO NOT** select *Discrete Graphics only*: This disables the Intel Iris Xe GPU at the ACPI/PCIe level, preventing the internal 2560x1600 eDP screen from initializing.
  * **DO NOT** select *Integrated Graphics only*: This cuts power to the NVIDIA RTX A1000, disabling external HDMI video output.
  * **Hybrid Graphics** keeps both GPUs accessible so WhateverXe drives the internal panel and NullMoth drives the external HDMI monitor.
* **Security -> Secure Boot:** `Disabled`
* **Security -> Intel Total Memory Encryption (TME):** `Disabled`
* **Startup -> Fast Boot:** `Disabled`
* **Security -> Virtualization -> Intel Virtualization Technology (VT-x):** `Enabled`
* **Security -> Virtualization -> Intel VT-d:** `Enabled`
* **Config -> Thunderbolt 4 / USB4:** Leave at factory defaults (on 12th Gen ThinkPad P1 Gen 5, Thunderbolt 4 is integrated directly into the Intel SoC, so legacy "BIOS Assist Mode" is either not present or already disabled by default).

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
2. Install the package inside macOS to deploy the NVIDIA kernel extensions (`NVRM.kext`, `NVAccel.kext`) and the Metal user-space bundle (`/Library/GPUBundles/NVMTLDriver.bundle`).
3. ⚡ **Configure NVIDIA to "Armed-Only" Mode (Crucial Power & CPU Optimization):**
   When using the laptop on battery or solely with the internal laptop display, background macOS applications could unnecessarily route Metal commands across the PCIe bus to the NVIDIA dGPU, spiking CPU usage and draining battery.
   To lock the NVIDIA driver into "Armed-Only" mode (only activating when an external display is connected), run this command in Terminal:
   ```bash
   sudo sh -c 'echo "!*" > /Library/GPUBundles/nvmtl-allow.txt'
   ```
4. ⚠️ **HDMI External Monitor Connection Note (Cold-Plug Required):**
   * If you wish to use the discrete card and external monitor, **plug in the HDMI cable BEFORE powering on or booting into macOS**.
   * On modern macOS Hackintosh systems with discrete NVIDIA Ampere cards, HDMI display heads must be initialized during early boot. Hotplugging HDMI *after* macOS has already booted may fail to wake the display output until a reboot with the cable plugged in.

---

### Phase 4: Install Intel Iris Xe Graphics Post-Install
To enable 3D Metal hardware acceleration on the internal 16.0" 2560x1600 eDP screen, install the WhateverXe graphics bundle and JulioNectar's `impostor.dylib` bridge.

You can choose either the automated script or the manual terminal method:

#### Option A: Automated Script (Recommended)
1. Ensure the `postinstall_tools` folder from this repo is placed on your USB drive (volume `1401`).
2. Open Terminal and run:
   ```bash
   sudo bash /Volumes/1401/postinstall_tools/install_iris_xe.sh
   ```
   *This automated script downloads and installs `WhateverXe-Graphics-0.4.0.pkg`, injects `impostor.dylib` into `/Library/GPUBundles`, applies `root:wheel` permissions, and rebuilds the AuxKC kernel cache.*

#### Option B: Manual Installation
If you prefer executing the steps manually:
1. Download and install [WhateverXe-Graphics-0.4.0.pkg](https://github.com/b00t0x/WhateverXe-Graphics/releases/download/v0.4.0/WhateverXe-Graphics-0.4.0.pkg):
   ```bash
   sudo installer -pkg WhateverXe-Graphics-0.4.0.pkg -target /
   ```
2. Copy JulioNectar's `impostor.dylib` into the Intel Metal graphics bundle:
   ```bash
   sudo cp postinstall_tools/impostor.dylib /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   sudo chmod 755 /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   sudo codesign -f -s - -i impostor /Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents/MacOS/impostor.dylib
   ```
3. Set proper system permissions:
   ```bash
   sudo chown -R root:wheel /Library/GPUBundles /Library/Extensions
   sudo chmod -R 755 /Library/GPUBundles /Library/Extensions
   ```
4. Rebuild the Auxiliary Kernel Collection (AuxKC):
   ```bash
   sudo kmutil install --volume-root / --update-all
   ```

---

### Phase 5: Deploy This EFI to Internal SSD & Final Reboot
Now that both NVIDIA and Intel drivers are properly installed in `/Library`, deploy this OpenCore EFI to your internal NVMe SSD so the laptop can boot standalone:

1. Download **`EFI-ThinkPad-P1-Gen5-v1.0.0.zip`** from [Releases](https://github.com/khucxtriendev/irisxegraphic-i712800h-efi/releases/tag/v1.0.0) (or grab the `EFI` folder from this repo).
2. Mount the EFI partition (ESP) of your internal SSD using **MountEFI** or Terminal:
   ```bash
   # Identify your internal SSD EFI disk identifier (e.g. disk0s1):
   diskutil list
   sudo diskutil mount /dev/disk0s1
   ```
3. Copy the **`EFI`** folder into the root of the mounted EFI volume (`/Volumes/EFI/`).
4. Safely unmount the EFI volume and remove the USB installer drive:
   ```bash
   diskutil unmount /Volumes/EFI
   ```
5. *(Optional)* If using an external monitor, plug in the HDMI cable now.
6. Reboot your ThinkPad:
   ```bash
   sudo reboot
   ```

---

### Phase 6: Internal Digital Microphone Setup (`LatSOFAudio.kext`)

The ThinkPad P1 Gen 5 uses an **Intel Smart Sound Technology (SST / cAVS 2.5)** digital microphone (DMIC) array (`8086:51c8`). In modern Intel laptops, the DMIC microphones are wired directly to the on-die Intel DSP—not to the Realtek analog codec pins. Traditional AppleALC patches cannot initialize these DSP lines.

We resolve this by integrating **`LatSOFAudio.kext`**, which implements the Sound Open Firmware (SOF) pipeline in-kernel and exposes a native `IOAudioEngine` (`imic`) recognized by macOS as a native system microphone.

#### 1. Automated Installation
Run the automated installer script from the `LatSOF-Audio patched` directory:
```bash
sudo bash "LatSOF-Audio patched/scripts/install.sh"
sudo reboot
```
> [!WARNING]
> Do NOT attempt to run `kmutil unload` dynamically while `coreaudiod` is active. Doing so can cause kernel deadlocks. Always reboot to let macOS cleanly rebuild AuxKC.

#### 2. Input Volume Calibration (Crucial)
On Windows, Lenovo uses Dynamic Speech AGC with a default pre-amp boost of ~+28 dB. In macOS:
1. Navigate to **System Settings -> Sound -> Input**.
2. Select **Internal Microphone**.
3. Set **Input Volume** slider to **85% – 95%** for crisp, clear audio capture.
*(Optional: Add `latsof_gain=28` to `boot-args` in `config.plist` to enforce hardware pre-amp gain by default).*

#### 3. Microphone Permissions for Applications (TCC Bypass)
Due to custom graphics injection (WhateverXe / NullMoth), standard macOS TCC permission popups may occasionally be suppressed in background:
* **Option A (GUI):** Open `/Applications/1401.app` -> under *MICROPHONE AND CAMERA*, click **"Allow an app..."** and choose your app (e.g., Google Chrome, Discord, Zoom), then restart the app (`Cmd+Q`).
* **Option B (Terminal):**
  ```bash
  /Applications/1401.app/Contents/Resources/nullmoth-tcc-grant "/Applications/Google Chrome.app"
  ```

---

### Phase 7: Display Override & Ultra-Sharp Text Rendering (HiDPI & Font Smoothing)

The ThinkPad P1 Gen 5 panel is a 16.0" 16:10 WQXGA panel (`2560x1600` / `2880x1800` BOE `0x9e5:0x0ae0`). When running without proper scaling, fonts can appear blurred due to GPU downsampling artifacts. We provide a 2-stage fix: native HiDPI Display Override and CoreGraphics font smoothing / vector glyph scaling override.

#### 1. Install BOE Display Override (HiDPI & EDID Patch)
The `Display_Override/` folder injects a custom EDID and resolution mapping into `/Library/Displays/Contents/Resources/Overrides/` (resides in local `/Library`, so **SIP does NOT need to be disabled** and updates persist):
```bash
sudo bash Display_Override/install.sh
```

#### 2. System Accessibility & CoreGraphics Font Smoothing Configuration
Run the following commands in Terminal to eliminate downsampling blur and enforce razor-sharp font rendering:

```bash
# 1. Disable blurry font halo and enable CoreGraphics sharp font rendering pipeline:
defaults write -g AppleFontSmoothing -int 0
defaults write -g CGFontRenderingFontSmoothingDisabled -bool false

# 2. Configure Accessibility to grant larger physical pixel budget for vector font glyphs:
defaults write com.apple.universalaccess FontSizeCategory -dict global "L"
defaults write com.apple.universalaccess UIPreferredContentSizeCategoryName "UICTContentSizeCategoryXL"
defaults write com.apple.universalaccess customFonts -bool true

# 3. Refresh preferences cache (or log out / reboot):
killall cfprefsd
```

> [!TIP]
> **👉 Tại sao cấu hình này lại làm nét chữ vượt trội? (Why this makes text razor-sharp):**
> * **Trước khi cấu hình:** Ở kích thước mặc định (nhỏ), mỗi con chữ chỉ được vẽ bởi một vài pixel li ti. Khi bị nén và co giãn qua thuật toán GPU downsampling (từ 2880 xuống 2560 hoặc tỷ lệ không nguyên số), nét chữ bị vỡ và hòa lẫn vào nền gây ra hiện tượng mờ tịt (fuzzy/blurry text).
> * **Sau khi cấu hình Trợ năng (Accessibility `FontSizeCategory = L` / `UIPreferredContentSizeCategoryName = UICTContentSizeCategoryXL` & `customFonts = True`):** Mỗi ký tự được cấp nhiều pixel vật lý hơn trên ma trận màn hình để dựng vector outline $\rightarrow$ nét chữ trở nên dày dặn, sắc cạnh và loại bỏ triệt để hiệu ứng mờ nhòe do GPU downsampling!
> * **Hai thông số Font Smoothing kết hợp:**
>   * `AppleFontSmoothing = 0`: Tắt bỏ hoàn toàn lớp quầng xám làm dày/nhòe font mặc định của macOS.
>   * `CGFontRenderingFontSmoothingDisabled = False`: Bật lại đường ống dựng font sắc nét góc cạnh nguyên bản của CoreGraphics.

---

### Phase 8: ThinkPad Native Keyboard Remapping (Windows-Style & PrtSc Screenshot)

ThinkPad users accustomed to Windows key layouts often struggle with macOS's swapped `Ctrl` / `Cmd` positions and awkward 4-key screenshot shortcuts (`Ctrl+Shift+Cmd+4`). 

Our `Keyboard_Remap/` package provides a **100% native solution** using macOS's internal `hidutil` service and a user `LaunchAgent`.
* **Zero 3rd-party bloat:** No background apps (Karabiner-Elements, AltTab, or BetterTouchTool) required.
* **0% CPU / RAM overhead:** Runs directly inside the macOS HID kernel layer without input latency.

#### Keyboard Remap Matrix:

| ThinkPad Physical Key | Mapped macOS Key | Experience & Benefits |
| :--- | :--- | :--- |
| **Left Ctrl** *(Bottom-left corner)* | **Left Command (`⌘`)** | **Windows-Standard Shortcuts:** Natural muscle memory for `Ctrl+C`, `Ctrl+V`, `Ctrl+A`, `Ctrl+Z`, `Ctrl+S`, `Ctrl+T`, `Ctrl+W`... |
| **Left Alt** *(Between Win and Space)* | **Left Command (`⌘`)** | **Standard Alt+Tab:** Seamless app switching using the native macOS App Switcher just like Windows. |
| **Left Windows** *(Between Ctrl and Alt)* | **Left Control (`⌃`)** | **Native macOS Control:** Used for Terminal shortcuts (`Ctrl+C` interrupt, `Ctrl+L` clear) and macOS-specific commands. |
| **Right Alt** *(Right of Space)* | **Option (`⌥`)** | **100% Preserved:** Kept intact for code navigation, IDE shortcuts, and special characters. |
| **PrtSc** *(PrintScreen)* | **F13 $\rightarrow$ Hotkey 31** | **Crop-to-Clipboard Screenshot:** Press `PrtSc` $\rightarrow$ crosshair cursor appears $\rightarrow$ drag-select area $\rightarrow$ hit `Ctrl+V` to paste image straight into Telegram, Zalo, Messenger, Word! |

#### 1-Click Installation:
```bash
bash Keyboard_Remap/install.sh
```
*(Takes effect immediately without needing a reboot; automatically loads on every login).*

To revert back to factory default macOS keys anytime:
```bash
bash Keyboard_Remap/uninstall.sh
```

---

## 7. Verification

After completing the installation and rebooting, verify all subsystems:

### 1. Dual-GPU Multi-Monitor Acceleration:
```bash
system_profiler SPDisplaysDataType
```
* **Intel Iris Xe Graphics:** Driving the internal 16.0" 2560x1600 eDP panel (`Metal Support: Metal 2` or `Metal 3`).
* **NVIDIA RTX A1000 Laptop:** Driving the external HDMI monitor (`Metal Support: Metal 3`).

### 2. Internal Digital Microphone (`LatSOFAudio`):
```bash
ioreg -r -c LatSOFAudioDevice -l | grep -E "Status|FW-Ready|PM-Gating|Topology"
```
* Expected: `"Status" = "OK"`, `"FW-Ready" = "OK"`, `"Topology" = "8 OK, 0 FAIL"`.

### 3. Display Override & HiDPI:
```bash
ioreg -lw0 -r -c "IODisplayConnect" | grep "DisplayProductID"
```
* Expected: `DisplayProductID = 2784` (`0xae0`) and `DisplayVendorID = 2533` (`0x9e5`).

### 4. Native Keyboard Remapping:
```bash
hidutil property --get "UserKeyMapping"
```
* Displays active mapping dictionary entries for HID codes `30064771296`, `30064771298`, `30064771299`, and `30064771142`.

---

## 8. Upstream Credits & Acknowledgments

* **[khucxtriendev/WhateverXe](https://github.com/khucxtriendev/WhateverXe):** WhateverXe fork patched for Lenovo ThinkPad UEFI GOP 6-bpc (`0x8a200106`), eDP panel preservation during Type-C unreadiness, and physical register verification preventing `tryCloseGate()` black screens.
* **[nullmoth/1401](https://github.com/nullmoth/1401) & [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver):** The breakthrough NVIDIA modern macOS driver and installer app enabling NVIDIA Ampere/Turing dGPUs on macOS with Metal 3.
* **[pokipoi/LatSOF-Audio](https://github.com/pokipoi/LatSOF-Audio):** Breakthrough Sound Open Firmware (SOF) companion driver bringing native Intel SST/cAVS digital DMIC microphones to macOS as a real `IOAudio` device.
* **[b00t0x/WhateverXe](https://github.com/b00t0x/WhateverXe) & [b00t0x/WhateverXe-Graphics](https://github.com/b00t0x/WhateverXe-Graphics):** Foundational Intel Xe graphics adaptation layer on macOS.
* **[Thatisjigen/WhateverXe](https://github.com/Thatisjigen/WhateverXe) & [Thatisjigen/HybridPM](https://github.com/Thatisjigen/HybridPM):** Display 13 eDP research, upstream WhateverXe mobile tree, and standalone `HybridPM.kext` port for hybrid Intel power management.
* **[JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe):** Pioneer of Intel Iris Xe Metal driver adaptation, `impostor.dylib` (`xefix`), and original XE-PM hybrid core power management discovery on macOS Tahoe/Sequoia.
* **[Acidanthera](https://github.com/acidanthera):** OpenCorePkg, Lilu, VirtualSMC, AppleALC, RestrictEvents, AMFIPass, etc.
* **[retropinapple](https://github.com/retropineaple/ForbiddenItlwm):** ForbiddenItlwm for Airdrop.

---

## 9. Pre-Packaged Release

For immediate deployment, download the ready-to-use EFI archive from GitHub Releases:
* 📦 **[Download EFI-ThinkPad-P1-Gen5-v1.0.1.zip](https://github.com/khucxtriendev/irisxegraphic-i712800h-efi/releases/download/v1.0.1/EFI-ThinkPad-P1-Gen5-v1.0.1.zip)**
