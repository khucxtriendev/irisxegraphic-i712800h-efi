# LatSOF-Audio — Sound Open Firmware (SOF) DMIC microphone driver for macOS

**Bring Intel Smart Sound Technology (SST / cAVS) digital microphones (DMIC) to macOS — as a real, native IOAudio input device.**

This is a single macOS kernel extension (kext) that implements, entirely in-kernel:

- an HDA controller companion for the Intel cAVS 1.8 DSP (Comet Lake),
- the **Sound Open Firmware (SOF)** boot pipeline: ROM handshake → CL (clean loader) DMA transfer → firmware bring-up → IPC round-trip,
- SOF topology parsing (8 widgets verified) and DMIC capture via the DSP's HDAS DMA engine,
- a native `IOAudioEngine` (`LatSOFKernelAudioEngine`, device name `imic`) that macOS treats as the **default system microphone** — Voice Memos, QuickTime, browsers, and every Core Audio app just work,
- a UserClient "lab console" (sysctl-driven experiment knobs) plus a fully automatic production boot path.

Verified working:
- **Lenovo XiaoXin 13 / Dell Latitude 3410** (Comet Lake `8086:02c8`, Realtek ALC257, cAVS 1.8) on macOS Sequoia 15.
- **Lenovo ThinkPad P1 Gen 5 / T14 Gen 3** (Alder Lake-P `8086:51c8`, Realtek ALC257/ALC287, cAVS 2.5) on macOS Sequoia 15.
- **Acer Nitro V 15 ANV15-52** (Raptor Lake-P `8086:51ca`, Realtek ALC245, cAVS 2.5) on macOS Sequoia 15.

The architecture and debugging methodology generalize across Intel cAVS platforms (CML / TGL / ADL / RPL) — see [docs/ADAPTING.md](docs/ADAPTING.md).

> Why this exists: on Comet Lake laptops, AppleHDA only drives the Realtek codec's analog path. The on-die DSP that owns the PDM digital microphones is **never initialized by macOS at all** — the DMICs are physically wired to the DSP, not to the codec, so no AppleHDA layout patch or DeviceProperties injection can ever bring them up. Linux solved this years ago with SOF; this project ports that capability into a macOS kext.

## The five-layer onion (what actually blocks DMIC on macOS)

Reproducing this on another machine means peeling all five layers, in roughly this order:

1. **VT-d silently kills DSP-side DMA.** The DSP master's PCIe fetches have no mapping in the macOS VT-d domain and are dropped with *zero* error bits set. Fix: OpenCore `Kernel → Quirks → DisableIoMapper = true` (cost ≈ 0 on hackintosh).
2. **BDL address truncation.** With VT-d off, `IODMACommand` with 32-bit address bits force-remaps >4 GB physical pages into a bogus <4 GB bus address (`bdlBus ≠ bdlPhys`) → the ROM/loader reads garbage descriptors. Fix: use 64-bit BDL addressing (`abits=64`), matching what Linux does on CML.
3. **Never hijack the HDA command ring while AppleHDA is alive.** An early design let the kext answer codec verbs on the CORB/RIRB ring ("hdaInit=3"). Once SOF firmware stays resident, this desyncs AppleHDA's codec command channel (58 in-flight verbs swallowed) and AppleHDA's playback StartIO deadlocks forever on a controller lock — full system freeze when any app plays audio. Production mode uses `hdaInit=0` and touches nothing AppleHDA owns.
4. **Productization.** Boot-time auto-load: the retry engine synthesizes a production parameter string, defers DSP init off the matching thread, and arms itself — microphone is ready ~3.5 s after boot with zero user action. Fuses: boot-arg `latsof-auto=0` (persistent) or `sysctl kern.latsof_lab="auto=0"` (runtime).
5. **TCC.** After all of the above, apps still record silence if macOS privacy (TCC) hasn't granted them microphone access. Engine logs are the giveaway: audio flows, app gets nothing. Grant via System Settings, or note that TCC is evaluated **at app launch** — fully quit (Cmd+Q) and relaunch.

The full forensic debugging story — spindump deadlock evidence, the DPIB read-only watershed, the "one boot = 8 experiments" budget, A/B boot matrices — is in [docs/JOURNEY.md](docs/JOURNEY.md).

## Architecture

```
                     macOS kernel
┌──────────────────────────────────────────────────────────┐
│  LatSOFAudio.kext                                        │
│                                                          │
│  IOAudioEngine (imic) ← LatSOFKernelAudio (default dIn)  │
│        │ capture: cycle-wheel DMIC DMA, jackPoll engine  │
│        ▼                                                 │
│  LatSOFAudioDevice                                       │
│   ├─ HDA controller regs (PCI 0x1f.3, cAVS 1.8)          │
│   ├─ SOF firmware: .incbin → CL loader → ROM handshake   │
│   ├─ IPC mailbox (ROUND-TRIP verified, topology parse)   │
│   ├─ HDAS DMA capture streams (64-bit BDL)               │
│   ├─ Product auto-load (defer → ARMED → engine)          │
│   └─ UserClient lab console (sysctl experiment knobs)    │
└──────────────────────────────────────────────────────────┘
        │ PCI / HDAS                    │ I2C (codec vol)
        ▼                               ▼
   Intel cAVS DSP ── SOF fw (sof-cml.ri, not bundled) ── DMIC PDM ×2
   (AppleHDA keeps the ALC257 analog codec: speakers + headset — untouched)
```

Key design point: **coexistence**. AppleHDA keeps full ownership of the codec (speakers/headset). This kext only drives the DSP/DMIC side, shares the controller carefully (power-state awareness, borrowed-stream guards, idle gating of all AFG/I2C polling), and exposes an emergency kill-switch so a bad load can never take playback down with it.

## Requirements

- Intel platform with cAVS 1.8 / 2.5 DSP exposing DMIC:
  - Comet Lake (0x02c8)
  - Alder Lake-P (0x51c8)
  - Raptor Lake-P (0x51ca)
- OpenCore (or Clover) with `DisableIoMapper = true` or VT-d correctly mapped.
- macOS Sequoia (15.x), Sonoma (14.x), Ventura (13.x) with Xcode Command Line Tools (`xcode-select --install`).
- SOF firmware image matching your SoC from [sof-bin releases](https://github.com/thesofproject/sof-bin/releases):
  - Alder Lake: `sof-adl.ri`
  - Raptor Lake: `sof-rpl.ri`
  - Comet Lake: `sof-cml.ri`

## Build

```bash
git clone https://github.com/pokipoi/LatSOF-Audio.git
cd LatSOF-Audio/kext

# Place your matching firmware inside Firmware directory:
# (e.g. for Alder Lake)
cp ~/Downloads/sof-adl.ri LatSOFAudio/Firmware/

# Build the kext:
make clean && make      # → LatSOFAudio.kext (x86_64)
```

## Installation

### Method 1: Automated Script (/Library/Extensions)
The fastest and safest method on macOS 13+ (Sequoia / Sonoma / Ventura):
```bash
sudo bash scripts/install.sh
sudo reboot
```
> [!IMPORTANT]
> Do NOT use `kmutil unload` directly while `coreaudiod` is running to avoid kernel deadlocks. Always reboot to cleanly apply AuxKC updates.

### Method 2: OpenCore Kext Injection
1. Copy `kext/LatSOFAudio.kext` into your EFI partition at `EFI/OC/Kexts/`.
2. Add `LatSOFAudio.kext` into your `config.plist` under `Kernel -> Add` (place it **after** `AppleALC.kext` / `Lilu.kext`).
3. Ensure `Kernel -> Quirks -> DisableIoMapper = true`.
4. Reboot.

---

## Post-Install & Verification

1. **Verify DSP Status in Kernel:**
```bash
ioreg -r -c LatSOFAudioDevice -l | grep -E "Status|FW-Ready|PM-Gating|Topology"
# Expected output:
# "Status" = "OK"
# "FW-Ready" = "OK"
# "Topology" = "8 OK, 0 FAIL"
# "PM-Gating" = "linux: PCI48=... PCI44=... EM2=..."
```

2. **Adjusting Input Volume:**
- Go to **System Settings > Sound > Input** and adjust the **Input Volume** slider to **85% – 95%** for optimal speech volume.
- Optional boot-arg: `latsof_gain=28` (configures default pre-amp in dB; range 0..40).

3. **Granting Microphone Permissions on Hackintosh:**
On systems utilizing modified graphics drivers (such as WhateverXe / Nullmoth), native TCC authorization dialogs may be suppressed.
If applications like Google Chrome, Discord, or Zoom do not receive microphone input:
- Use `nullmoth-tcc-grant` or `1401.app`:
  ```bash
  /Applications/1401.app/Contents/Resources/nullmoth-tcc-grant "/Applications/Google Chrome.app"
  ```
- Fully restart the application (Cmd + Q and reopen).

---

## Hướng dẫn cài đặt (Tiếng Việt)

> Chi tiết từng bước vui lòng xem tài liệu đầy đủ tại: **[HUONG_DAN_CAI_DAT.md](HUONG_DAN_CAI_DAT.md)**

1. **Biên dịch kext:**
   ```bash
   cd LatSOF-Audio/kext
   make clean && make
   ```
2. **Cài đặt vào hệ thống:**
   ```bash
   sudo bash scripts/install.sh
   sudo reboot
   ```
3. **Cân chỉnh âm lượng:**
   * Sau khi khởi động lại, vào **Cài đặt hệ thống > Âm thanh > Đầu vào**, kéo thanh trượt **Âm lượng đầu vào** lên **85% - 95%** để đạt âm lượng to rõ ngang bằng Windows.
4. **Cấp quyền cho ứng dụng (nếu dùng WhateverXe):**
   * Nếu Chrome/Discord không nhận mic, mở `1401.app` chọn **"Allow an app..."** hoặc chạy:
     ```bash
     /Applications/1401.app/Contents/Resources/nullmoth-tcc-grant "/Applications/Google Chrome.app"
     ```
   * Thoát hẳn ứng dụng (Cmd + Q) rồi mở lại.

## Safety fuses

| Fuse | Scope | Effect |
|---|---|---|
| boot-arg `latsof-auto=0` | next boot | disable production auto-load entirely (kext stays parked) |
| `sudo sysctl -w kern.latsof_lab="auto=0"` | running system | same, without reboot |
| explicit lab string via `kern.latsof_lab` | one shot | override any production default for a single experiment |

## Documentation

- [docs/JOURNEY.md](docs/JOURNEY.md) — the complete debugging campaign: every wrong turn, the forensics that caught a kernel deadlock, and the winning data chain.
- [docs/ADAPTING.md](docs/ADAPTING.md) — porting guide for other laptops/SoCs/codecs, and which of the five layers apply where.

## License

MIT — see [LICENSE](LICENSE).
SOF firmware is fetched at build time from [sof-bin](https://github.com/thesofproject/sof-bin) (BSD-3-Clause / GPL-2.0 by Intel, NXP et al.) and is not redistributed here.

## Keywords / discovery

`hackintosh` `dmic` `digital microphone` `sound open firmware` `sof` `intel smart sound` `cavs` `cml` `comet lake` `alc257` `realtek` `kext` `applehda` `opencore` `ioaudio` `kernel extension` `macos sequoia` `lenovo xiaoxin 13` `hda` `dsp firmware` `ipc` `bdm` `corb rirb`
