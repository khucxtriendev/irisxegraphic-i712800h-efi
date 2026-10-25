#!/usr/bin/env python3
"""Package already-built local artifacts; never writes an installed EFI/driver."""
import datetime
import hashlib
import json
import re
import shutil
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]
name = sys.argv[1] if len(sys.argv) > 1 else "P1-Gen5-20261025-r2"
if not re.fullmatch(r"P1-Gen5-[A-Za-z0-9_-]+", name):
    raise SystemExit("Use a release name such as P1-Gen5-20261025-r2.")
out = ROOT / "release" / name
archive = out.with_suffix(".zip")
if out.exists() or archive.exists():
    raise SystemExit(f"Release already exists; kept unchanged. Use a new name: {name}-r2")
validation = json.loads((ROOT / "reports/validation.json").read_text())
if not validation["passed"]:
    raise SystemExit("Validation failed; do not package.")
build = json.loads((ROOT / "reports/build-release.json").read_text())
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
for rel, expected in {**build["sources"], **build["artifacts"]}.items():
    if digest(ROOT / rel) != expected:
        raise SystemExit(f"Source/artifact changed since recorded build: {rel}")
for rel, expected in json.loads((ROOT / "reports/efi-sha256.json").read_text()).items():
    if digest(ROOT / "EFI" / rel) != expected:
        raise SystemExit(f"EFI changed since validation: {rel}")

out.mkdir(parents=True)
shutil.copytree(ROOT / "EFI", out / "EFI")
shutil.copytree(ROOT / "build/userland", out / "Graphics")
shutil.copytree(ROOT / "docs", out / "docs")
shutil.copytree(ROOT / "bin", out / "bin")
shutil.copytree(ROOT / "source-review", out / "source-review")
for file in ["FEATURES.md", "CHANGELOG.md", "MACHINE.json"]:
    shutil.copy2(ROOT / file, out / file)
(out / "scripts").mkdir()
for file in ["install-graphics.command", "collect.command", "cai-dat-nhanh.sh", "cai_dat_nhanh.py"]:
    shutil.copy2(ROOT / "scripts" / file, out / "scripts" / file)
(out / "reports").mkdir()
for file in ["validation.json", "build-release.json", "efi-sha256.json", "peripheral-evidence.json",
             "usb-port-map.json", "build-nootedgreen.log", "build-userland.log", "scanout-mmio-r2.json", "install-checks.log"]:
    shutil.copy2(ROOT / "reports" / file, out / "reports" / file)
(out / "Licenses").mkdir()
shutil.copytree(ROOT / "vendor/iris-xe/licenses", out / "Licenses/third-party")
for file in ["LICENSE", "NOTICE.md"]:
    shutil.copy2(ROOT / "vendor/iris-xe" / file, out / "Licenses" / file)
hal = Path("/Users/kxt/Downloads/SimpleHDA-HAL-1.0.0.pkg")
if hal.exists():
    (out / "Optional").mkdir()
    shutil.copy2(hal, out / "Optional" / hal.name)
    (out / "Optional/README.txt").write_text(
        "Gói HAL tùy chọn có sẵn trong Downloads của máy tại lúc đóng gói. Không tự cài. "
        "SimpleHDA có thể dùng IOAudio khi không có HAL.\nSHA256: " + digest(hal) + "\n")

(out / "README.md").write_text(
    f"# {name}\n\nEFI và thư viện đồ họa cho ThinkPad P1 Gen 5, macOS 25G241 / TGL 16.0.32.\n\n"
    "Đã build và kiểm tra tĩnh; chưa boot xác nhận. Chưa kết luận hết mất số Dock.\n\n"
    "1. Đọc [hướng dẫn cài đặt](docs/CAI-DAT.md) hoặc `HUONG-DAN-P1-Gen5.docx`.\n"
    "2. Dùng `EFI/` ở gốc phân vùng boot USB đã chuẩn bị, giữ USB cũ để quay lại.\n"
    "3. Để áp dụng libxedrv mới trên stack TGL đã cài, tự chạy `bash scripts/install-graphics.command`. "
    "Script kiểm tra phiên bản/chữ ký và sao lưu trước khi thay; chép EFI không thay thư viện trong /Library.\n"
    "4. Boot USB mới rồi thử âm thanh layout 11, Bluetooth, touchpad và đồ họa; "
    "chạy `bash scripts/collect.command` để thu kết quả.\n\n"
    "Nếu muốn cập nhật đồng thời hai driver đồ họa vào EFI đang có trên /Volumes/1401, "
    "dùng `bash scripts/cai-dat-nhanh.sh --check` rồi `bash scripts/cai-dat-nhanh.sh`. "
    "Script giữ config.plist và kext ngoại vi hiện có; xem hướng dẫn để áp dụng cấu hình ngoại vi mới.\n\n"
    "Chi tiết: [âm thanh/Bluetooth/touchpad](docs/AM-THANH-BLUETOOTH-TOUCHPAD.md), "
    "[tính năng](FEATURES.md), [thay đổi](CHANGELOG.md). "
    "Nguồn đã sửa và công cụ build nằm tại `~/Documents/gen5_igpu_driver/vendor/iris-xe/` "
    "và `scripts/` của thư mục nguồn; gói này không chứa toàn bộ source tree. "
    "Nguồn gốc upstream: https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe .\n\n"
    "`SHA256SUMS.json` ghi hash từng file; `reports/` ghi kiểm tra, nguồn/target build. "
    "`ocvalidate` chưa có sẵn để chạy. Map cổng ngoài chưa hoàn tất thử vật lý.\n")

# A portable Word document without an external Python package dependency.
sections = [ROOT / "docs/CAI-DAT.md", ROOT / "docs/AM-THANH-BLUETOOTH-TOUCHPAD.md", ROOT / "CHANGELOG.md"]
paragraphs = []
for section in sections:
    for line in section.read_text().splitlines():
        heading = line.startswith("#")
        line = line.lstrip("# ") if heading else line
        line = line.replace("**", "").replace("`", "")
        properties = '<w:pPr><w:spacing w:before="180" w:after="100"/></w:pPr>' if heading else ''
        bold = '<w:rPr><w:b/></w:rPr>' if heading else ''
        paragraphs.append(f'<w:p>{properties}<w:r>{bold}<w:t xml:space="preserve">{escape(line)}</w:t></w:r></w:p>')
document = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
            '<w:body>' + ''.join(paragraphs) + '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
            '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr></w:body></w:document>')
with zipfile.ZipFile(out / "HUONG-DAN-P1-Gen5.docx", "w", zipfile.ZIP_DEFLATED) as word:
    word.writestr('[Content_Types].xml', '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>')
    word.writestr('_rels/.rels', '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>')
    word.writestr('word/document.xml', document)
manifest = {str(p.relative_to(out)): digest(p) for p in sorted(out.rglob('*')) if p.is_file()}
(out / 'SHA256SUMS.json').write_text(json.dumps(manifest, indent=2) + '\n')
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as zipped:
    for p in sorted(out.rglob('*')):
        if p.is_file():
            zipped.write(p, p.relative_to(out.parent))
result = {'created_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'folder': str(out), 'zip': str(archive), 'zip_sha256': digest(archive),
          'files_in_manifest': len(manifest), 'boot_tested': False}
(ROOT / 'reports/package-release.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, ensure_ascii=False, indent=2))
