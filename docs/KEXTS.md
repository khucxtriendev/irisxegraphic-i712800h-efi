# Kext Reference & Version Inventory
### OpenCore EFI for Lenovo ThinkPad P1 Gen 5 (macOS Sequoia 15.x & Tahoe)

This document catalogs all 35 Kernel Extensions (Kexts) and sub-plugins included in this OpenCore EFI, their exact version strings, bundle identifiers, and their active status in `config.plist`.

---

## 1. Quick Summary Table

| # | Kext Name | Version | Bundle Identifier | Status | Primary Purpose |
| :- | :--- | :--- | :--- | :--- | :--- |
| **1** | **`Lilu.kext`** | `1.7.2` | `as.vit9696.Lilu` | ✅ **Enabled** | Master patch engine for kernel and user-space kexts |
| **2** | **`HybridPM.kext`** | `1.0.0` | `org.anv1552.HybridPM` | ✅ **Enabled** | XE-PM CPU power management for Alder Lake 6P + 8E cores |
| **3** | **`WhateverXe.kext`** | `0.7.0` | `org.b00t0x.WhateverXe` | ✅ **Enabled** | Patched Intel Iris Xe Display 13 driver (ThinkPad 6-bpc GOP) |
| **4** | **`AMFIPass.kext`** | `1.4.1` | `com.dhinakg.AMFIPass` | ✅ **Enabled** | Bypasses AMFI checks for unsigned Metal graphics bundles |
| **5** | **`AppleALC.kext`** | `1.9.9` | `as.vit9696.AppleALC` | ✅ **Enabled** | High-definition audio patching (`alcid=11` for ALC287 `10EC:0287`) |
| **6** | **`BrightnessKeys.kext`** | `1.0.4` | `as.acidanthera.BrightnessKeys` | ✅ **Enabled** | Handles ACPI brightness hotkeys (Fn+F5/F6) |
| **7** | **`CpuTopologyRebuild.kext`** | `2.0.2` | `org.b00t0x.CpuTopologyRebuild` | ✅ **Enabled** | Reconstructs asymmetric CPU core topology for Thread Director |
| **8** | **`ECEnabler.kext`** | `1.0.6` | `com.1Revenger1.ECEnabler` | ✅ **Enabled** | Enables reading non-standard Embedded Controller fields |
| **9** | **`NVMeFix.kext`** | `1.1.4` | `org.acidanthera.NVMeFix` | ✅ **Enabled** | Fixes NVMe APST power states and thermal stability |
| **10** | **`RestrictEvents.kext`** | `1.1.7` | `as.vit9696.RestrictEvents` | ✅ **Enabled** | Handles Software Updates (sbvmm), CPU brand string & PCI block |
| **11** | **`VirtualSMC.kext`** | `1.3.9` | `as.vit9696.VirtualSMC` | ✅ **Enabled** | Advanced Apple System Management Controller (SMC) emulation |
| **12** | **`SMCBatteryManager.kext`** | `1.3.9` | `ru.usrsse2.SMCBatteryManager` | ✅ **Enabled** | ACPI battery status and percentage readout |
| **13** | **`SMCLightSensor.kext`** | `1.3.9` | `ru.usrsse2.SMCLightSensor` | ✅ **Enabled** | Ambient Light Sensor (ALS) support for VirtualSMC |
| **14** | **`SMCProcessor.kext`** | `1.3.9` | `as.vit9696.SMCProcessor` | ✅ **Enabled** | Monitors CPU core temperatures and package power |
| **15** | **`SMCSuperIO.kext`** | `1.3.9` | `ru.joedm.SMCSuperIO` | ✅ **Enabled** | Hardware monitoring for motherboard fans and I/O chips |
| **16** | **`SMCNvidiaGPU.kext`** | `1.6` | `org.nullmoth.SMCNvidiaGPU` | ✅ **Enabled** | VirtualSMC sensor plugin for NVIDIA RTX A1000 dGPU |
| **17** | **`YogaSMC.kext`** | `1.5.3` | `org.zhen.YogaSMC` | ✅ **Enabled** | ThinkPad specific features: fan profiles, charge thresholds |
| **18** | **`AirportItlwm.kext`** | `2.4.0` | `com.zxystd.AirportItlwm` | ✅ **Enabled** | Native Apple Wi-Fi emulation for Intel AX211 160MHz |
| **19** | **`itlwm.kext`** | `2.3.0` | `com.zxystd.itlwm` | ⚪ *Disabled* | Standalone Wi-Fi driver (fallback when using HeliPort) |
| **20** | **`IntelBluetoothFirmware.kext`** | `2.5.1` | `com.zxystd.IntelBluetoothFirmware` | ✅ **Enabled** | Uploads firmware into Intel AX211 Bluetooth controller |
| **21** | **`IntelBTPatcher.kext`** | `2.5.1` | `com.zxystd.IntelBTPatcher` | ✅ **Enabled** | Patches Bluetooth subsystem for Intel controllers |
| **22** | **`BlueToolFixup.kext`** | `2.7.3` | `as.acidanthera.BlueToolFixup` | ✅ **Enabled** | Fixes Bluetooth daemons on macOS Monterey, Sequoia & Tahoe |
| **23** | **`USBToolBox.kext`** | `1.2.0` | `com.dhinakg.USBToolBox.kext` | ✅ **Enabled** | Core USB driver wrapper for custom port maps |
| **24** | **`UTBMap.kext`** | `1.1` | `com.dhinakg.USBToolBox.map` | ✅ **Enabled** | Hardware USB port map specifically mapped for ThinkPad P1 Gen 5 |
| **25** | **`XHCI-unsupported.kext`** | `0.9.2` | `org.rehabman.injector.XHCI.unsupported` | ✅ **Enabled** | Injects unsupported Intel 600-series PCH USB controller IDs |
| **26** | **`VoodooI2C.kext`** | `2.9.1` | `com.alexandred.VoodooI2C` | ✅ **Enabled** | Core Intel I2C bus controller driver |
| **27** | ↳ `VoodooI2CServices.kext` | `1.0` | `com.alexandred.VoodooI2CServices` | ✅ **Enabled** | Core I2C helper services plugin |
| **28** | ↳ `VoodooGPIO.kext` | `1.2` | `org.coolstar.VoodooGPIO` | ✅ **Enabled** | Intel GPIO pinning and interrupt handling |
| **29** | ↳ `VoodooInput.kext` (I2C) | `1.1.7` | `me.kishorprins.VoodooInput` | ✅ **Enabled** | Multi-touch gesture engine for Precision Touchpad |
| **30** | **`VoodooI2CHID.kext`** | `1.0` | `com.alexandred.VoodooI2CHID` | ✅ **Enabled** | I2C Human Interface Device (HID) satellite for Touchpad |
| **31** | **`VoodooPS2Controller.kext`** | `2.3.8` | `as.acidanthera.voodoo.driver.PS2Controller` | ✅ **Enabled** | Core PS/2 bus controller driver |
| **32** | ↳ `VoodooPS2Keyboard.kext` | `2.3.8` | `as.acidanthera.voodoo.driver.PS2Keyboard` | ✅ **Enabled** | Drives the physical ThinkPad keyboard |
| **33** | ↳ `VoodooPS2Mouse.kext` | `2.3.8` | `as.acidanthera.voodoo.driver.PS2Mouse` | ✅ **Enabled** | Drives the iconic red TrackPoint nub & click buttons |
| **34** | ↳ `VoodooInput.kext` (PS2) | `1.1.7` | `me.kishorprins.VoodooInput` | ⚪ *Disabled* | Disabled to avoid duplicate collision with VoodooI2C's engine |
| **35** | ↳ `VoodooPS2Trackpad.kext` | `2.3.8` | `as.acidanthera.voodoo.driver.PS2Trackpad` | ⚪ *Disabled* | Disabled because touchpad is exclusively handled over I2C |

---

## 2. Detailed Breakdown by Subsystem

### 🖥️ A. Graphics & Display Pipeline
* **`WhateverXe.kext` (v0.7.0 patched):**
  * Built from our patched fork [khucxtriendev/WhateverXe](https://github.com/khucxtriendev/WhateverXe).
  * Forces 6-bpc GOP color depth initialization (`0x8a200106`) for the BOE `NE160QDM-NY1` eDP panel.
  * Preserves eDP panel routing when Type-C PHY is unready, and prevents `tryCloseGate()` race condition black screens.
* **`AMFIPass.kext` (v1.4.1):**
  * Relaxes AppleMobileFileIntegrity checks without requiring full SIP disabling, allowing `/Library/GPUBundles` (both Intel Metal and NVIDIA Metal bundles) to load securely.
* **`BrightnessKeys.kext` (v1.0.4):**
  * Intercepts Lenovo ThinkPad ACPI brightness notifications (Fn+F5, Fn+F6) and translates them into native macOS CoreDisplay brightness events.

### ⚡ B. CPU Power Management & Scheduling
* **`HybridPM.kext` (v1.0.0 — XE-PM):**
  * Discovered by JulioNectar and ported by Thatisjigen.
  * Corrects the 78.7 MHz HWP multiplier mismatch on Alder Lake P-cores and unlocks deep C-states (C8/C10). Drops idle power consumption from 35W+ down to 3W–6W.
* **`CpuTopologyRebuild.kext` (v2.0.2):**
  * Resolves macOS scheduler conflicts on hybrid architecture (6 P-cores + 8 E-cores). Ensures macOS schedules high-priority threads to P-cores and background tasks to E-cores.

### ⌨️ C. Input Devices: Why Both `VoodooPS2` and `VoodooI2C` are Used
Laptop ThinkPad hardware separates inputs across two physical buses:
1. **Physical Keyboard & TrackPoint Nub:**
   * Wired via legacy **PS/2** lines.
   * `VoodooPS2Controller.kext` -> `VoodooPS2Keyboard.kext` handles typing and Fn hotkeys.
   * `VoodooPS2Controller.kext` -> `VoodooPS2Mouse.kext` handles the red TrackPoint nub and the three dedicated physical mouse buttons above the trackpad.
2. **Glass Precision Touchpad:**
   * Wired via high-speed **I2C** bus.
   * `VoodooI2C.kext` + `VoodooI2CHID.kext` provides multi-touch gestures (2-finger scroll, 3-finger Mission Control, pinch-to-zoom).
3. **Collision Prevention:**
   * To prevent dual drivers from contending for the same touchpad, **`VoodooPS2Trackpad.kext`** and `VoodooPS2Controller`'s internal **`VoodooInput.kext`** are deliberately set to `<false/>` in `config.plist`.

### 📶 D. Wireless, Bluetooth & Audio
* **`AirportItlwm.kext` (v2.4.0):**
  * Emulates a native Apple AirPort card for the Intel Wi-Fi 6E AX211 chipset, enabling seamless Wi-Fi connectivity and menu-bar control without needing external apps.
* **`IntelBluetoothFirmware.kext` + `IntelBTPatcher.kext` (v2.5.1) & `BlueToolFixup.kext` (v2.7.3):**
  * Injects Intel Bluetooth firmware into the AX211 controller at boot, fixes HCI packet structures, and patches `bluetoothd` on macOS Sequoia / Tahoe.
* **`AppleALC.kext` (v1.9.9):**
  * Patches AppleHDA dynamically for Realtek ALC287 (`10EC:0287`) with default layout ID 11 (`alcid=11`), enabling dual stereo speakers and 3.5mm combo jack. Alternative candidate layouts for microphone testing: `13`, `21`, `66`.

### 🔌 E. Hardware Monitoring, Sensors & USB
* **`VirtualSMC.kext` (v1.3.9) Ecosystem:**
  * `SMCProcessor.kext`: Live CPU core temps and wattages.
  * `SMCBatteryManager.kext`: Battery percentage, health, and charge cycle metrics.
  * `SMCLightSensor.kext`: Ambient light sensor support.
  * `SMCSuperIO.kext`: Motherboard fan speed readouts.
  * `SMCNvidiaGPU.kext` (v1.6 by NullMoth): Reads NVIDIA RTX A1000 dGPU temperature and clock states into macOS.
* **`YogaSMC.kext` (v1.5.3):**
  * Integrates ThinkPad-specific ACPI features: battery charge thresholds (battery conservation mode) and fan curves.
* **`USBToolBox.kext` (v1.2.0) & `UTBMap.kext` (v1.1):**
  * Complete USB port mapping for the ThinkPad P1 Gen 5, ensuring all Type-A, Type-C (Thunderbolt 4), SD card reader, and internal webcam/Bluetooth ports operate within the macOS 15-port limit.

---

## 3. Technical Clarifications & Common Questions

### 1. Realtek Audio Codec Verification (ALC287 vs ALC245)
* **Hardware Reality:** The Lenovo ThinkPad P1 Gen 5 (Type `21DDS88B00`) features a **Realtek ALC287** audio codec (`10EC:0287`), not ALC245.
* **Why does `layout-id=11` work for speakers?**
  * In the upstream `AppleALC` pinconfig database, layout 11 is shared between ALC245, ALC257, and ALC287 Lenovo configurations.
  * While layout 11 successfully maps the stereo amplifier output for the speakers, its input nodes for the microphone / combo jack may differ from your hardware wiring.
* **Alternative candidate layouts to test:**
  * You can test alternative layouts by passing `alcid=N` in `boot-args` without modifying `config.plist`:
    - `alcid=13`
    - `alcid=21`
    - `alcid=66`

### 2. Is `CPUFriend.kext` Necessary on Alder Lake?
* **No, `CPUFriend.kext` is superseded by XE-PM (`HybridPM.kext`).**
* `CPUFriend` was designed for older monolithic Intel architectures (Comet Lake, Coffee Lake) to inject static `FrequencyVectors` into `X86PlatformPlugin`. It has no awareness of asymmetric P-cores and E-cores.
* `HybridPM.kext` operates at a much deeper level: it hooks XCPM in kernel space, rewrites MSR `0x1FC`, dynamically converts 78.7 MHz HWP requests, and manages EPP (`hpmepp=N`). Running `CPUFriend` alongside `HybridPM` is either redundant or risks overriding dynamic HWP frequencies.

### 3. A/B Testing: `CpuTopologyRebuild.kext`
* `CpuTopologyRebuild.kext` + `ctrsmt=full` reorganizes Alder Lake's 14 cores (6P + 8E) into asymmetric processor sets for macOS.
* However, as noted by author `b00t0x`, on certain macOS versions, the Apple XNU scheduler can occasionally schedule priority threads to E-cores, leading to slightly lower multi-core benchmark scores, or cause occasional boot hangs in verbose mode.
* **Recommended A/B Testing Procedure:**
  1. Benchmark your system with `CpuTopologyRebuild.kext` enabled and `ctrsmt=full` in `boot-args`.
  2. Disable `CpuTopologyRebuild.kext` in OpenCore and remove `ctrsmt=full`, relying purely on `HybridPM.kext` for power scaling.
  3. Compare single-core/multi-core Geekbench scores, idle package power, and boot stability to determine which profile is optimal for your workflow.

### 4. ACPI Power Management: `SSDT-PLUG-ALT.aml`
* Alder Lake does not use the legacy `_PR.CPU0` ACPI processor scope; instead, cores are defined under `_SB.PR00`.
* This EFI **already includes `SSDT-PLUG-ALT.aml`** in `EFI/OC/ACPI/` to ensure native XCPM CPU power management hooks attach correctly at boot.

### 5. Why Ethernet Kexts (`IntelMausi` / `RealtekRTL8111`) are Excluded
* The ThinkPad P1 Gen 5 chassis **does not possess an onboard RJ-45 Ethernet port**. It relies entirely on the integrated Intel Wi-Fi 6E AX211 card (handled by `AirportItlwm.kext`) or external USB-C/Thunderbolt Ethernet adapters.
* Including unused Ethernet drivers would only clutter the kernel extension cache and increase boot times.

### 6. `ECEnabler.kext` vs `YogaSMC.kext`
* **`ECEnabler.kext` (Mandatory):** Allows reading 16-bit and 32-bit fields from the Embedded Controller. Without this, `SMCBatteryManager` cannot read battery percentages or charging status.
* **`YogaSMC.kext` (Sensors & Thermal Profiles):** On 12th Gen Alder Lake ThinkPads, Lenovo updated the EC thermal architecture. Users should verify in **Stats** whether fan RPM readouts update in real time; if fan RPM is static at 0 and conservation mode is unused, `YogaSMC` can be disabled to eliminate background ACPI polling overhead.
