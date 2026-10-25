#!/usr/bin/env python3
"""Package a config-only R3 from the verified, immutable R2 ZIP. No installation."""
import copy
import datetime
import hashlib
import json
import plistlib
import re
import shutil
import struct
import subprocess
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

DEST = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent
SOURCE = Path('/Users/kxt/Documents/gen5_igpu_driver')
NAME = 'P1-Gen5-20261025-r3'
R2 = 'P1-Gen5-20261025-r2'
ZIP = SOURCE / 'release' / (R2 + '.zip')
R2_SHA = 'c5e7f02808cc5c066fbe13e99e620d89a7ccad3e2c528174535d9bc11541855f'
EDID_SHA = '088bd08b9b569f571462bcaf28eff70b920bb79cf60479daabc3a3e14cd4fd01'
APPLE = '7C436110-AB2A-4BBB-A880-FE41995C9F82'
IGPU = 'PciRoot(0x0)/Pci(0x2,0x0)'
PROP = 'AAPL00,override-no-connect'
OUT = DEST / NAME
ARCHIVE = DEST / (NAME + '.zip')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def main():
    require(not OUT.exists() and not ARCHIVE.exists(), 'R3 already exists; refusing to overwrite.')
    require(digest(ZIP.read_bytes()) == R2_SHA, 'R2 ZIP SHA-256 differs from verified release.')
    edid = (SOURCE / 'evidence/panel.edid').read_bytes()
    require(digest(edid) == EDID_SHA and len(edid) == 256, 'Unexpected panel EDID.')
    require(edid[:8] == bytes.fromhex('00ffffffffffff00'), 'Bad EDID header.')
    require(edid[126] == 1 and all(sum(edid[i:i+128]) % 256 == 0 for i in (0, 128)), 'Bad EDID blocks.')
    captured = (SOURCE / 'evidence/AppleDisplay.txt').read_text()
    match = re.search(r'"IODisplayEDID"\s*=\s*<([0-9a-fA-F]+)>', captured)
    require(match is not None and bytes.fromhex(match[1]) == edid, 'EDID differs from captured AppleDisplay.')
    require(b'NE160QDM-NY1' in edid and edid[8:12] == bytes.fromhex('09e5e00a'), 'Wrong panel identity.')
    dtd = edid[54:72]
    hact = dtd[2] | ((dtd[4] >> 4) << 8)
    hblank = dtd[3] | ((dtd[4] & 15) << 8)
    vact = dtd[5] | ((dtd[7] >> 4) << 8)
    vblank = dtd[6] | ((dtd[7] & 15) << 8)
    base_hz = int.from_bytes(dtd[:2], 'little') * 10000 / ((hact+hblank) * (vact+vblank))
    require(edid[128:131] == bytes.fromhex('701379') and edid[133:136] == bytes.fromhex('030114'), 'Unexpected DisplayID timing layout.')
    timing = edid[136:156]
    pclk = (int.from_bytes(timing[:3], 'little') + 1) * 10000
    ext_hact, ext_hblank, ext_vact, ext_vblank = [int.from_bytes(timing[i:i+2], 'little') + 1 for i in [4, 6, 12, 14]]
    ext_hz = pclk / ((ext_hact+ext_hblank) * (ext_vact+ext_vblank))
    require((hact, vact, ext_hact, ext_vact) == (2560, 1600, 2560, 1600) and abs(base_hz-60) < .1 and abs(ext_hz-165) < .1, 'Unexpected panel timing.')
    with zipfile.ZipFile(ZIP) as z:
        require(z.testzip() is None, 'R2 ZIP CRC error.')
        original_manifest = json.loads(z.read(R2 + '/SHA256SUMS.json'))
        for rel, expected in original_manifest.items():
            require(digest(z.read(R2 + '/' + rel)) == expected, 'R2 manifest mismatch: ' + rel)
        base_bytes = z.read(R2 + '/EFI/OC/config.plist')
        OUT.mkdir()
        for member in z.infolist():
            path = Path(member.filename)
            require(path.parts[0] == R2 and '..' not in path.parts and not path.is_absolute(), 'Unsafe ZIP path.')
            if member.is_dir() or path.name == '.DS_Store':
                continue
            target = OUT.joinpath(*path.parts[1:])
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(z.read(member))
            mode = (member.external_attr >> 16) & 0o777
            if mode:
                target.chmod(mode)
    base = plistlib.loads(base_bytes)
    candidate = copy.deepcopy(base)
    candidate['DeviceProperties']['Add'][IGPU][PROP] = edid
    args = candidate['NVRAM']['Add'][APPLE]['boot-args'].split()
    removed = [a for a in args if a.split('=', 1)[0] == 'ngreen-dmc']
    require(removed == ['ngreen-dmc=adlp'], 'Unexpected original DMC argument.')
    candidate['NVRAM']['Add'][APPLE]['boot-args'] = ' '.join(a for a in args if a not in removed)
    require('boot-args' in candidate['NVRAM']['Delete'][APPLE], 'Must replace stale NVRAM boot-args.')
    config_path = OUT / 'EFI/OC/config.plist'
    config_path.write_bytes(plistlib.dumps(candidate, sort_keys=False))
    # Only these two semantic changes are allowed relative to the tested R2 package.
    reverted = copy.deepcopy(candidate)
    del reverted['DeviceProperties']['Add'][IGPU][PROP]
    reverted['NVRAM']['Add'][APPLE]['boot-args'] = base['NVRAM']['Add'][APPLE]['boot-args']
    require(reverted == base, 'Unexpected config change beyond EDID + DMC argument.')
    require(candidate['DeviceProperties']['Add'][IGPU]['force-online'] == bytes.fromhex('01000000'), 'force-online changed.')
    require(not any(k.startswith('framebuffer-con0-') for k in candidate['DeviceProperties']['Add'][IGPU]), 'Unexpected connector override.')
    evidence = OUT / 'evidence'
    evidence.mkdir()
    (evidence / 'panel.edid').write_bytes(edid)
    write_json(evidence / 'edid-decoded.json', {'manufacturer': 'BOE', 'product_id': '0x0ae0', 'panel': 'NE160QDM-NY1',
        'bytes': len(edid), 'sha256': EDID_SHA, 'block_checksums': [0, 0],
        'base_detailed_timing': {'width': hact, 'height': vact, 'refresh_hz': base_hz},
        'displayid_detailed_timing': {'width': ext_hact, 'height': ext_vact, 'refresh_hz': ext_hz},
        'runtime_165hz_verified': False})
    shutil.copy2(SOURCE / 'evidence/AppleDisplay.txt', evidence / 'AppleDisplay-captured.txt')
    driver = SOURCE / 'vendor/iris-xe/src/NootedGreen'
    build = json.loads((OUT / 'reports/build-release.json').read_text())
    for name in ['kern_gen11.cpp', 'kern_gen11.hpp']:
        p = driver / name
        rel = str(p.relative_to(SOURCE))
        require(digest(p.read_bytes()) == build['sources'][rel], 'Driver source differs from R2 build: ' + name)
    lines = (driver / 'kern_gen11.cpp').read_text().splitlines()
    excerpt = []
    for start, end in [(4399, 4480), (4698, 4717), (4773, 4788)]:
        excerpt.extend(f'{i+1}: {lines[i]}' for i in range(start-1, end))
    (evidence / 'driver-source-excerpts.txt').write_text('\n'.join(excerpt) + '\n')
    header = (driver / 'kern_gen11.hpp').read_text().splitlines()
    (evidence / 'connector-flags-source.txt').write_text('\n'.join(f'{i+1}: {header[i]}' for i in range(1095, 1125)) + '\n')
    (evidence / 'config-r2-original.plist').write_bytes(base_bytes)
    shutil.copy2(Path(__file__), OUT / 'scripts/build-r3.py')
    report = OUT / 'reports'
    for name in ['validation.json', 'efi-sha256.json']:
        (report / name).rename(report / ('r2-' + name))
    write_json(report / 'r2-SHA256SUMS.json', original_manifest)
    (OUT / 'SHA256SUMS.json').unlink()
    write_json(report / 'config-r3-changes.json', {
        'base_config_sha256': digest(base_bytes), 'r3_config_sha256': digest(config_path.read_bytes()),
        'changes': [{'path': 'DeviceProperties/Add/' + IGPU + '/' + PROP,
                     'before': None, 'after': {'type': 'DATA', 'bytes': 256, 'sha256': EDID_SHA}},
                    {'path': 'NVRAM/Add/' + APPLE + '/boot-args', 'removed_tokens': removed}],
        'connector_type_in_driver': '0x2 (LVDS/eDP)', 'connector_flags_in_driver': '0x18',
        'connector_properties_added': False, 'unindexed_edid_property_added': False,
        'nvram_delete_boot_args_present': True, 'binaries_rebuilt': False})
    # Reuse the signed R2 drivers. R3 is a configuration experiment, not a new binary build.
    for folder in ['EFI', 'Graphics']:
        for p in (OUT / folder).rglob('*'):
            if p.is_file() and p != config_path:
                rel = p.relative_to(OUT).as_posix()
                require(digest(p.read_bytes()) == original_manifest[rel], 'Driver payload changed: ' + rel)
    machine_path = OUT / 'MACHINE.json'
    machine = json.loads(machine_path.read_text())
    machine['r3_display_trial'] = {'edid_property': PROP, 'edid_bytes': 256, 'edid_sha256': EDID_SHA,
                                   'dmc_argument': 'removed; default fallback', 'boot_verified': False}
    write_json(machine_path, machine)
    # The inherited two-driver updater preserves config, so reject a target that lacks R3 config.
    quick = OUT / 'scripts/cai_dat_nhanh.py'
    text = quick.read_text()
    needle = '    graphics = ROOT / ("Graphics"'
    require(text.count(needle) == 1, 'Unexpected R2 updater layout.')
    guard = '''    igpu_path = "PciRoot(0x0)/Pci(0x2,0x0)"
    apple_guid = "7C436110-AB2A-4BBB-A880-FE41995C9F82"
    target_edid = installed["DeviceProperties"]["Add"].get(igpu_path, {}).get("AAPL00,override-no-connect")
    expected_edid = candidate["DeviceProperties"]["Add"][igpu_path]["AAPL00,override-no-connect"]
    target_args = installed["NVRAM"]["Add"][apple_guid]["boot-args"].split()
    if target_edid != expected_edid or any(a.split("=", 1)[0] == "ngreen-dmc" for a in target_args):
        raise SystemExit("Chưa có cấu hình R3 trên EFI đích. Chép trọn EFI R3 lên USB thử theo docs/CAI-DAT.md; trình cập nhật hai driver không áp dụng EDID/boot-args.")
'''
    quick.write_text(text.replace(needle, guard + needle))
    collect = OUT / 'scripts/collect.command'
    text = collect.read_text()
    needle = 'capture bluetooth-nvram'
    extra = '''capture r3-framebuffer ioreg -lw0 -r -c AppleIntelFramebuffer
capture r3-igpu ioreg -lw0 -r -n IGPU
capture r3-display-log /usr/bin/log show --last 2h --style compact --predicate '(process == "kernel" AND (eventMessage CONTAINS[c] "AUX" OR eventMessage CONTAINS[c] "EDID" OR eventMessage CONTAINS[c] "ngreen" OR eventMessage CONTAINS[c] "waitForStamp")) OR (process == "WindowServer" AND (eventMessage CONTAINS[c] "offline" OR eventMessage CONTAINS[c] "libxedrv"))'
'''
    require(text.count(needle) == 1, 'Unexpected collector layout.')
    collect.write_text(text.replace(needle, extra + needle))
    readme = f'''# {NAME}

R3 thử nghiệm EDID + DMC fallback cho ThinkPad P1 Gen 5, BOE NE160QDM-NY1.
Đích: macOS 25G241, stack TGL 16.0.32 đã cài trên máy.

- Nạp EDID gốc 256 byte tại `DeviceProperties/Add/{IGPU}/{PROP}`.
- Bỏ `ngreen-dmc=adlp`; driver dùng nhánh mặc định fallback.
- Giữ cấu hình eDP sẵn trong NootedGreen: type 0x2, flags 0x18.
- Dùng lại toàn bộ binary EFI/Graphics của R2; thay đổi chính nằm trong config.plist.

**Chưa boot xác nhận. EDID không đảm bảo Online 100%, không sửa mọi lỗi AUX/link training, GPU stamp timeout hoặc panic Wi-Fi. Lỗi số Dock vẫn cần kiểm tra trên màn hình thật.**

Đọc [hướng dẫn áp dụng R3](docs/CAI-DAT.md) và [đánh giá kỹ thuật](docs/DANH-GIA-R3.md).
Chép trọn `EFI/` vào gốc USB thử riêng, giữ USB cũ đang boot được. Chỉ chạy trình cập nhật hai driver sẽ không áp dụng cấu hình R3.
Nếu Metal bundle R2 đã cài và còn khớp, không cần cài lại để thử thay đổi R3.

`evidence/panel.edid` khớp byte-for-byte bản AppleDisplay đã thu trên máy.
`evidence/config-r2-original.plist` là cấu hình R2 để đối chiếu; không phải EFI cũ đang boot được.
`reports/r2-*` và `reports/build-release.json` là bằng chứng R2 lưu lại; `reports/validation.json` và `reports/config-r3-changes.json` dành riêng R3.
`SHA256SUMS.json` ghi hash các file của gói. Xem `scripts/build-r3.py` để tái tạo từ ZIP R2 đã xác minh và bằng chứng nguồn; đầu vào nguồn vẫn ở `~/Documents/gen5_igpu_driver`.
'''
    (OUT / 'README.md').write_text(readme)
    assessment = '''# Đánh giá giả thuyết và phạm vi R3

## Có căn cứ để thử

EDID trong `evidence/panel.edid` được đối chiếu với `IODisplayEDID` trong AppleDisplay đã thu trên máy: BOE, product 0x0AE0, NE160QDM-NY1, 256 byte, hai block có checksum 0. EDID chứa timing 2560×1600 khoảng 60 Hz ở base block và khoảng 165 Hz ở DisplayID extension. Không sửa timing hay tự tạo EDID theo tên màn hình; có timing trong EDID không chứng minh driver chạy được 165 Hz.

R3 chỉ thêm DATA `AAPL00,override-no-connect` cho màn hình index 0 dưới IGPU. Không thêm `AAPL,override-no-connect` không có index: chưa xác định consumer cho khóa đó trong stack này. Cú pháp có index được tài liệu WhateverGreen mô tả; việc driver TGL hiện tại nhận và dùng đủ EDID vẫn cần xác nhận ở runtime.

Mã `hwInitializeCState` chọn nhánh fallback khi không có `ngreen-dmc`; nhánh này gọi original rồi cấu hình AUX, tránh nhánh ADL-P có firmware/context/power/timing writes. NVRAM/Delete đã có boot-args để cấu hình mới thay giá trị cũ khi boot OpenCore. Đây là hành vi nhánh mã, không phải đảm bảo an toàn tuyệt đối trên ThinkPad.

## Những khẳng định chưa đúng hoặc chưa chứng minh

EDID cung cấp danh tính/timing; nó không thay thế toàn bộ DPCD, link training, lane/power sequencing qua AUX và không chữa GPU hang. Vì vậy chưa thể khẳng định màn hình luôn Online, hết AUX timeout, hoặc boot thành công 100%. Log trước đó còn accelerator stamp timeout và một panic IO80211Family riêng.

`framebuffer-con0-type=02000000` tương ứng LVDS/eDP trong enum của driver. Nhưng NootedGreen đã đặt connector 0 thành type 0x2 trong `getOSInformation`, flags 0x18. Không tìm thấy bộ đọc `framebuffer-con0-*` trong source build này, WhateverGreen không bật đồng thời; thêm các khóa đó không chứng minh connector thực sự đổi.

`flags=05000000` không phải định nghĩa eDP chuẩn: 0x05 không có bit AlwaysConnected 0x08. R3 giữ flags 0x18 đang có bit này. Chưa có căn cứ thay bằng 0x05.

Nhận định "ngreen-dmc=adlp đang ghi combo-PHY Dell gây lệch điện áp" chưa được chứng minh. Đoạn gọi `setSignalLevelsADLP` trong chính nguồn R2 đã được comment-out. Bỏ cờ vẫn thay đổi đường DMC/context registers và là phép thử hợp lý, nhưng không được mô tả là đã xác nhận lỗi điện áp.

## Cần xác nhận sau boot

1. Boot-args thực tế không còn ngreen-dmc=adlp và log chọn fallback (nếu buffer ghi được).
2. Registry IGPU có override 256 byte đúng hash, display dùng đúng EDID, panel built-in/Online và có hình ổn định. Việc chỉ thấy property trong registry chưa chứng minh driver đã dùng nó.
3. GPU stamp, AUX/EDID errors và WindowServer offline so với lần boot trước; lưu ý hai giờ log có thể chứa nhiều lần boot, phải phân biệt timestamp.
4. Thử hiển thị trước ở 60 Hz nếu chọn được; chỉ xác nhận 165 Hz sau khi đo trạng thái thật.
5. Nếu R3 vào được, cần thử riêng EDID/DMC khi muốn kết luận thành phần nào là nguyên nhân; thành công khi đổi cả hai chưa phân biệt được.

## Nguồn

- Source build R2, đã đối chiếu SHA-256 với `reports/build-release.json`; các trích đoạn và số dòng ở `evidence/`.
- [NootedGreen README: lựa chọn DMC](https://github.com/sgiammori/NootedGreen/blob/main/README.md).
- [WhateverGreen Sample.dsl: cú pháp override có index](https://github.com/acidanthera/WhateverGreen/blob/master/Manual/Sample.dsl).
- [WhateverGreen kern_fb.hpp: LVDS/eDP và connector flags](https://github.com/acidanthera/WhateverGreen/blob/master/WhateverGreen/kern_fb.hpp).
- [Linux DRM helpers: AUX, EDID và DPCD](https://kernel.org/doc/html/latest/gpu/drm-kms-helpers.html).
'''
    (OUT / 'docs/DANH-GIA-R3.md').write_text(assessment)
    install = '''# Áp dụng R3 — EDID + DMC fallback

Đây là cấu hình thử nghiệm trên nền binary R2, chưa boot xác nhận. Máy cần stack Tiger Lake 16.0.32, macOS build 25G241 đang dùng. R3 không cài lại macOS.

## Chuẩn bị và áp dụng

1. Giữ USB EFI cũ đã vào được macOS. Chuẩn bị USB thử riêng và sao lưu EFI trên USB thử trước khi thay.
2. Chép trọn thư mục `EFI/` của R3 vào gốc phân vùng boot FAT32 của USB thử, sao cho có `EFI/BOOT/BOOTx64.efi` và `EFI/OC/config.plist`. Thư mục tên `EFI new` chỉ để lưu, không phải đường boot fallback chuẩn. Không để lồng `EFI/EFI/`.
3. Metal/libxedrv R3 giống hệt R2. Log lần lỗi trước đã xác nhận thư viện R2 được WindowServer nạp; không cần cài lại thư viện chỉ để thử EDID/DMC. Nếu bộ R2 chưa có, xem bước cài Metal bên dưới.
4. Restart rồi F12 chọn USB thử. Không đổi BIOS và không Reset NVRAM đồng thời trong phép thử đầu; config đã có NVRAM/Delete cho boot-args.
5. Nếu vào được, kiểm tra màn hình laptop, độ phân giải, độ ổn định và thu log bằng `bash scripts/collect.command` từ thư mục gói. Script chỉ đọc và lưu báo cáo; chạy ở Terminal để log không bị giới hạn sandbox của công cụ.
6. Nếu lại đen màn hình, quay về USB EFI cũ rồi chạy cùng collector càng sớm càng tốt. Log hai giờ gần nhất được lấy để có thể chứa lần boot lỗi; phân biệt các boot theo timestamp.

**Trình `cai-dat-nhanh.sh` chỉ thay hai driver, giữ nguyên config.plist: không áp dụng EDID/DMC R3.** Trong R3, script sẽ từ chối nếu config đích chưa có EDID R3 hoặc còn cờ ngreen-dmc. Cách áp dụng R3 là chép trọn EFI lên USB thử.

## Metal bundle khi chưa có R2

Chỉ khi cần cập nhật thư viện, chạy thủ công từ thư mục gói:

```bash
bash scripts/install-graphics.command --check
bash scripts/install-graphics.command
```

Script kiểm tra phiên bản/chữ ký, sao lưu Metal bundle rồi thay trọn bundle chứa libxedrv. Chép EFI không tự cập nhật thư viện trong /Library. Shader compiler đi kèm không được script này ghi vào /System. Không có bước cài nào đã được tự chạy khi đóng gói R3.

## Xác nhận kết quả

Kiểm tra EDID override xuất hiện dưới IGPU và panel Online; boot-args thực tế không còn `ngreen-dmc=adlp`; xem AUX/EDID/GPU stamp và WindowServer trong báo cáo. Có EDID không đảm bảo link training thành công. Đừng coi 165 Hz hoặc số Dock đã hoạt động chỉ vì máy vào được desktop. Thử cả âm thanh, Bluetooth, touchpad và USB như hướng dẫn ngoại vi kèm theo.

## Quay lại

Boot USB cũ đã xác nhận hoạt động. Cấu hình R2 tại `evidence/config-r2-original.plist` chỉ phục vụ đối chiếu vì chính EFI R2 từng bị mất hình. Không dùng nó thay cho bản EFI cũ đang vào được macOS.

Nếu đã tự thay Metal và cần phục hồi, lấy đúng backup script tạo, ví dụ:

```bash
sudo ditto "Backups/graphics-YYYYMMDD-HHMMSS/AppleIntelTGLGraphicsMTLDriver.bundle" "/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle"
```

Thay đúng đường dẫn backup thật rồi boot EFI cũ. Không tự xóa dữ liệu Bluetooth hoặc reset toàn bộ NVRAM để thử R3.
'''
    (OUT / 'docs/CAI-DAT.md').write_text(install)
    changelog = OUT / 'CHANGELOG.md'
    changelog.write_text('''# Thay đổi R3 — 25/10/2026

- Thêm EDID BOE NE160QDM-NY1 gốc 256 byte vào AAPL00,override-no-connect.
- Bỏ ngreen-dmc=adlp; giữ NVRAM/Delete boot-args, chọn fallback mặc định.
- Giữ eDP type 0x2/flags 0x18 trong driver, không thêm override flags 0x05.
- Binary EFI/Graphics giữ nguyên R2; không build lại hoặc tự cài driver.
- Cập nhật hướng dẫn, Word, đánh giá kỹ thuật, bằng chứng EDID, collector và guard cho trình cập nhật hai driver.
- Chưa boot xác nhận, chưa bảo đảm Online/165 Hz hoặc hết lỗi số Dock.

---

''' + changelog.read_text())
    features = OUT / 'FEATURES.md'
    features.write_text('''# Phạm vi R3

R3 chỉ đổi cấu hình EDID/DMC. Các mức xác nhận ngoại vi/đồ họa dưới đây được kế thừa từ R2, không phải kết quả boot R3. Chưa xác nhận boot, 165 Hz hoặc hết mất số Dock. Xem docs/DANH-GIA-R3.md.

''' + features.read_text())
    # Regenerate the Word guide so it agrees with R3 instructions.
    paragraphs = []
    for section in ['README.md', 'docs/CAI-DAT.md', 'docs/DANH-GIA-R3.md', 'docs/AM-THANH-BLUETOOTH-TOUCHPAD.md']:
        for line in (OUT / section).read_text().splitlines():
            line = line.replace('**', '').replace('`', '').lstrip('# ')
            paragraphs.append('<w:p><w:r><w:t xml:space="preserve">' + escape(line) + '</w:t></w:r></w:p>')
    with zipfile.ZipFile(OUT / 'HUONG-DAN-P1-Gen5.docx', 'w', zipfile.ZIP_DEFLATED) as word:
        word.writestr('[Content_Types].xml', '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>')
        word.writestr('_rels/.rels', '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>')
        word.writestr('word/document.xml', '<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + ''.join(paragraphs) + '</w:body></w:document>')
    # Structural checks for the actual packaged configuration and its referenced payload.
    checks = []
    def check(ok, label):
        require(ok, label)
        checks.append(label)
    active = [e for e in candidate['Kernel']['Add'] if e['Enabled']]
    paths = [e['BundlePath'] for e in active]
    check('NootedGreen.kext' in paths and 'WhateverGreen.kext' not in paths, 'NootedGreen enabled without WhateverGreen conflict')
    check(len(paths) == len(set(paths)), 'No duplicate enabled kexts')
    ids = []
    dependencies = []
    for entry in active:
        folder = OUT / 'EFI/OC/Kexts' / entry['BundlePath']
        for key in ['PlistPath', 'ExecutablePath']:
            if entry[key]:
                check((folder / entry[key]).is_file(), 'Referenced file: ' + entry['BundlePath'] + '/' + entry[key])
        info = plistlib.loads((folder / entry['PlistPath']).read_bytes())
        ids.append(info.get('CFBundleIdentifier'))
        dependencies.append(info.get('OSBundleLibraries', {}))
    for i, deps in enumerate(dependencies):
        for dependency in deps:
            if dependency in ids:
                check(ids.index(dependency) < i, 'Kext dependency order: ' + ids[i] + ' after ' + dependency)
    for entry in candidate['ACPI']['Add']:
        if entry['Enabled']:
            p = OUT / 'EFI/OC/ACPI' / entry['Path']
            b = p.read_bytes()
            check(b[:4] == b'SSDT' and struct.unpack_from('<I', b, 4)[0] == len(b) and sum(b) % 256 == 0, 'AML header/size/checksum: ' + entry['Path'])
    for entries, folder in [(candidate['UEFI']['Drivers'], 'Drivers'), (candidate['Misc']['Tools'], 'Tools')]:
        for entry in entries:
            if entry['Enabled']:
                check((OUT / 'EFI/OC' / folder / entry['Path']).is_file(), 'Referenced UEFI ' + folder + ': ' + entry['Path'])
    check(candidate['PlatformInfo'] == base['PlatformInfo'], 'PlatformInfo identity preserved')
    check(candidate['Kernel'] == base['Kernel'], 'Kernel configuration preserved')
    check(candidate['ACPI'] == base['ACPI'], 'ThinkPad ACPI preserved')
    check(candidate['DeviceProperties']['Add'][IGPU][PROP] == edid, 'Original 256-byte EDID in config')
    check(not any(a.startswith('ngreen-dmc=') for a in candidate['NVRAM']['Add'][APPLE]['boot-args'].split()), 'No ngreen-dmc argument')
    check('boot-args' in candidate['NVRAM']['Delete'][APPLE], 'Stale boot-args deletion configured')
    subprocess.run(['/usr/bin/plutil', '-lint', str(config_path)], check=True)
    for p in ['EFI/OC/Kexts/NootedGreen.kext', 'Graphics/AppleIntelTGLGraphicsMTLDriver.bundle', 'Graphics/xe.bundle']:
        subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(OUT / p)], check=True)
        checks.append('codesign --verify --deep --strict: ' + p)
    subprocess.run(['/bin/bash', '-n', str(collect)], check=True)
    compile(quick.read_text(), str(quick), 'exec')
    compile(Path(__file__).read_text(), str(Path(__file__)), 'exec')
    checks.extend(['Collector bash syntax', 'Quick updater Python syntax', 'R3 packaging Python syntax'])
    write_json(report / 'efi-sha256.json', {p.relative_to(OUT / 'EFI').as_posix(): digest(p.read_bytes()) for p in sorted((OUT / 'EFI').rglob('*')) if p.is_file()})
    write_json(report / 'validation.json', {'release': NAME, 'passed': True, 'checks': checks,
        'r2_zip_sha256': R2_SHA, 'r2_manifest_verified': True, 'edid_sha256': EDID_SHA,
        'edid_captured_data_match': True, 'edid_checksums': [0, 0], 'config_changes_only': True,
        'efi_graphics_binaries_match_r2': True, 'ocvalidate': 'not available locally; not run',
        'boot_tested': False, 'panel_online_verified': False, 'hz_165_verified': False,
        'dock_badge_fix_verified': False, 'installed_to_boot_efi': False, 'installed_to_system': False,
        'created_at': datetime.datetime.now(datetime.timezone.utc).isoformat()})
    manifest = {p.relative_to(OUT).as_posix(): digest(p.read_bytes()) for p in sorted(OUT.rglob('*')) if p.is_file()}
    write_json(OUT / 'SHA256SUMS.json', manifest)
    with zipfile.ZipFile(ARCHIVE, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file():
                z.write(p, p.relative_to(DEST))
    with zipfile.ZipFile(ARCHIVE) as z:
        require(z.testzip() is None, 'R3 ZIP CRC failure.')
        for rel, expected in manifest.items():
            require(digest(z.read(NAME + '/' + rel)) == expected, 'R3 ZIP manifest mismatch: ' + rel)
    sha = digest(ARCHIVE.read_bytes())
    (DEST / (NAME + '.zip.sha256')).write_text(sha + '  ' + ARCHIVE.name + '\n')
    (DEST / 'LATEST-R3.txt').write_text(NAME + '\n' + sha + '  ' + ARCHIVE.name + '\n')
    print(json.dumps({'release': str(OUT), 'zip': str(ARCHIVE), 'sha256': sha,
                      'files': len(manifest), 'checks': len(checks), 'boot_tested': False}, indent=2))


if __name__ == '__main__':
    main()
