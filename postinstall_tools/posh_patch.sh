#!/bin/bash
# Frees the per-command-buffer POSH block in the Tahoe Metal driver of WhateverXe Graphics 0.4.0. It patches the installed file, because the patched
# Apple executable is not something this fork publishes: install Graphics 0.4.0 first, then run this. Without it WindowServer grows by 96 KiB per
# command buffer composited on Intel (5.6 MiB/s with the screen saver on two displays, on an ANV15-52 with Raptor Lake-P).
#
# Two NOPs replace the jne at 0x7ed87 in -[MTLIGAccelCommandBuffer dealloc]. Idea from JulioNectar's Metal bundle v18 (Hackintosh-XPS13Plus-IrisXe-Tahoe
# commit 06986480) and iqsanfm (issue #12 there): only the offset and the bytes, no code. The executable is then signed ad hoc at bundle level, without
# --deep: the nested dylibs and CodeResources stay as they are. It loads under the same AMFI relaxation the package needs.
#
#   bash tools/posh_patch.sh state                  read only: hash, bytes, signature, backups
#   bash tools/posh_patch.sh dryrun                 patch and sign a copy, check the expected hashes; nothing installed changes
#   sudo POSH_GO=1 bash tools/posh_patch.sh patch   back up to ~/posh-before/<date>, patch a copy, check it, swap it in
#   bash tools/posh_patch.sh verify                 after the patch: bytes, hash, signature
#   sudo POSH_GO=1 bash tools/posh_patch.sh restore the last backup, or POSH_BACKUP_DIR=...
#
# A file other than the Graphics 0.4.0 one is refused: the offset belongs to that file. Reboot after patch or restore: WindowServer loads the bundle at
# start, and on some systems a logout does not restart it. POSH_BUNDLE and POSH_BACKUP point the commands at a copy, for trying them out.
set -euo pipefail
BUNDLE=${POSH_BUNDLE:-/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle}
REL=Contents/MacOS/AppleIntelTGLGraphicsMTLDriver
BIN=$BUNDLE/$REL
STOCK=1e5e4f5bd76ff567a102125dfa3c74a255934d45c753a88aedcbfac7dab53c6c            # Graphics 0.4.0, Tahoe payload
PATCHED_UNSIGNED=a7dc59a91629572a072a0f8eeee2ca11205890b69c1f9f9fa7b2cd4f59efab53 # the two bytes, old signature
PATCHED_SIGNED=b24816e801f5c76d6ea0d2a9645d3fef3d1cd912e14060d6f4446780f413b422   # after the ad hoc signature
OFF=519559                 # 0x7ed87
CTX_OFF=519554             # 0x7ed82: cmpb [r14+rax],0 ; jne +0x0d ; call operator delete
CTX_STOCK=41803c0600750de87afa0100
CTX_PATCHED=41803c06009090e87afa0100
OWNER_HOME=$(eval echo ~"${SUDO_USER:-$USER}")
BK_ROOT=${POSH_BACKUP:-$OWNER_HOME/posh-before}

die() { echo "ERROR: $*" >&2; exit 1; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
ctx() { xxd -s "$CTX_OFF" -l 12 -p "$1"; }
classify() {
  local s; s=$(sha "$1")
  if [ "$s" = "$STOCK" ]; then echo "stock 0.4.0, leak present"
  elif [ "$s" = "$PATCHED_SIGNED" ]; then echo "patched, signed ad hoc"
  elif [ "$(ctx "$1")" = "$CTX_PATCHED" ]; then echo "patched, unexpected hash"
  else echo "unknown file"; fi
}
allowed() {   # the real location needs root and the confirmation; a copy only the confirmation
  [ "${POSH_GO:-}" = 1 ] || die "confirm with POSH_GO=1"
  [ -n "${POSH_BUNDLE:-}" ] || [ "$(id -u)" = 0 ] || die "needs sudo"
}
build_patched() {   # <work folder>: leaves the patched, signed bundle in <work folder>/b
  local w=$1
  ditto "$BUNDLE" "$w/b"
  [ "$(sha "$w/b/$REL")" = "$STOCK" ] || die "the installed file is not the Graphics 0.4.0 one: $(classify "$w/b/$REL")"
  [ "$(ctx "$w/b/$REL")" = "$CTX_STOCK" ] || die "unexpected bytes at $CTX_OFF"
  printf '\x90\x90' | dd of="$w/b/$REL" bs=1 seek="$OFF" conv=notrunc 2>/dev/null
  [ "$(sha "$w/b/$REL")" = "$PATCHED_UNSIGNED" ] || die "unexpected hash after the patch"
  codesign -f -s - "$w/b" 2>&1 | grep -v "replacing existing signature" || true
  codesign -v --deep --strict "$w/b" || die "the ad hoc signature is not valid"
  [ "$(ctx "$w/b/$REL")" = "$CTX_PATCHED" ] || die "the signature changed the bytes"
  [ "$(sha "$w/b/$REL")" = "$PATCHED_SIGNED" ] || die "unexpected hash after the signature: $(sha "$w/b/$REL")"
}
hashes() { for f in AppleIntelTGLGraphicsMTLDriver impostor.dylib descriptor.dylib libigdmd.dylib; do printf '  %s  %s\n' "$(sha "$1/Contents/MacOS/$f")" "$f"; done; }

[ -f "$BIN" ] || [ "${1:-state}" = restore ] || die "no bundle at $BUNDLE: install WhateverXe Graphics 0.4.0 first"
case "${1:-state}" in
  state)
    echo "bundle: $BUNDLE"
    echo "file:   $(sha "$BIN")  $(classify "$BIN")"
    echo "bytes at $CTX_OFF: $(ctx "$BIN")   (stock $CTX_STOCK, patched $CTX_PATCHED)"
    if [ -d "$BK_ROOT" ]; then echo "backup: $(ls -1d "$BK_ROOT"/* 2>/dev/null | tail -1)"; else echo "backup: none in $BK_ROOT"; fi ;;
  dryrun)
    W=$(mktemp -d "${TMPDIR:-/tmp}/posh-dryrun.XXXXXX"); echo "folder: $W"
    build_patched "$W"; hashes "$W/b"; echo "dry run passed; nothing changed in $BUNDLE" ;;
  patch)
    allowed
    [ "$(sha "$BIN")" = "$STOCK" ] || die "not patching: $(classify "$BIN")"
    BK=$BK_ROOT/$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$BK"; ditto "$BUNDLE" "$BK/AppleIntelTGLGraphicsMTLDriver.bundle"
    [ "$(sha "$BK/AppleIntelTGLGraphicsMTLDriver.bundle/$REL")" = "$STOCK" ] || die "the backup does not match"
    W=$(mktemp -d "${TMPDIR:-/tmp}/posh-patch.XXXXXX"); build_patched "$W"
    mv "$BUNDLE" "$BUNDLE.posh-old"; ditto "$W/b" "$BUNDLE.posh-new"; mv "$BUNDLE.posh-new" "$BUNDLE"
    if [ "$(id -u)" = 0 ]; then chown -R root:wheel "$BUNDLE"; chmod -R go-w "$BUNDLE"; fi
    if ! codesign -v --deep --strict "$BUNDLE"; then mv -f "$BUNDLE" "$BUNDLE.posh-bad"; mv "$BUNDLE.posh-old" "$BUNDLE"; die "signature not valid after the copy: original put back"; fi
    rm -rf "$BUNDLE.posh-old" "$W"
    echo "Done: $(classify "$BIN"). Backup in $BK. Reboot, then: bash tools/posh_patch.sh verify" ;;
  verify)
    echo "file: $(sha "$BIN")  $(classify "$BIN")"
    codesign -v --deep --strict "$BUNDLE" && echo "signature: valid"
    [ "$(ctx "$BIN")" = "$CTX_PATCHED" ] && echo "VERIFY OK" || die "the file is not patched" ;;
  restore)
    allowed
    SRC=${POSH_BACKUP_DIR:-$(ls -1d "$BK_ROOT"/* 2>/dev/null | tail -1)}
    [ -n "$SRC" ] && [ -d "$SRC/AppleIntelTGLGraphicsMTLDriver.bundle" ] || die "no backup in $BK_ROOT"
    [ "$(sha "$SRC/AppleIntelTGLGraphicsMTLDriver.bundle/$REL")" = "$STOCK" ] || die "the backup is not the Graphics 0.4.0 file"
    mv "$BUNDLE" "$BUNDLE.posh-old"; ditto "$SRC/AppleIntelTGLGraphicsMTLDriver.bundle" "$BUNDLE.posh-new"; mv "$BUNDLE.posh-new" "$BUNDLE"
    if [ "$(id -u)" = 0 ]; then chown -R root:wheel "$BUNDLE"; fi
    codesign -v --deep --strict "$BUNDLE" || die "the backup's signature is not valid (original in $BUNDLE.posh-old)"
    rm -rf "$BUNDLE.posh-old"; echo "Restored: $(classify "$BIN"). Reboot." ;;
  *) die "usage: posh_patch.sh state|dryrun|patch|verify|restore" ;;
esac
