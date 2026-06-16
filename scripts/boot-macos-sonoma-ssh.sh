#!/usr/bin/env bash

set -euo pipefail

# Bootstrap-only launcher for the installed macOS VM.
# This keeps the VM off the LAN and exposes only localhost:10022 on the Linux host
# so Codex and CLI tools can reach the guest over SSH.
# Bridge/tap networking is intentionally deferred.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OSX_KVM_DIR="$REPO_ROOT/external/OSX-KVM"

cd "$OSX_KVM_DIR"

MY_OPTIONS="+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check"

ALLOCATED_RAM="4096" # MiB
CPU_SOCKETS="1"
CPU_CORES="2"
CPU_THREADS="4"
OVMF_CODE_FILE="${OVMF_CODE_FILE:-./OVMF_CODE_4M.fd}"
OVMF_VARS_FILE="${OVMF_VARS_FILE:-./OVMF_VARS-1920x1080.fd}"

if [[ ! -f "$OVMF_CODE_FILE" ]]; then
  echo "Missing OVMF code image: $OVMF_CODE_FILE" >&2
  exit 1
fi

if [[ ! -f "$OVMF_VARS_FILE" ]]; then
  echo "Missing OVMF vars image: $OVMF_VARS_FILE" >&2
  echo "Set OVMF_VARS_FILE to the writable firmware vars file used by your installed VM." >&2
  exit 1
fi

args=(
  -enable-kvm -m "$ALLOCATED_RAM" -cpu Skylake-Client,-hle,-rtm,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$MY_OPTIONS"
  -machine q35
  -device qemu-xhci,id=xhci
  -device usb-kbd,bus=xhci.0 -device usb-tablet,bus=xhci.0
  -smp "$CPU_THREADS",cores="$CPU_CORES",sockets="$CPU_SOCKETS"
  -device usb-ehci,id=ehci
  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE_FILE"
  -drive if=pflash,format=raw,file="$OVMF_VARS_FILE"
  -smbios type=2
  -device ich9-intel-hda -device hda-duplex
  -device ich9-ahci,id=sata
  -drive id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file="./OpenCore/OpenCore.qcow2"
  -device ide-hd,bus=sata.2,drive=OpenCoreBoot
  -device ide-hd,bus=sata.3,drive=InstallMedia
  -drive id=InstallMedia,if=none,file="./BaseSystem.img",format=raw
  -drive id=MacHDD,if=none,file="./mac_hdd_ng.img",format=qcow2
  -device ide-hd,bus=sata.4,drive=MacHDD
  # Bootstrap-only networking:
  # - user-mode networking keeps the guest isolated from the LAN
  # - hostfwd exposes only localhost:10022 on the Linux host
  # - SSH access is intended for Codex/CLI workflows after Remote Login is enabled
  # - tap/bridge/qemu-bridge-helper are intentionally deferred
  -netdev user,id=net0,hostfwd=tcp::10022-:22 -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27
  -monitor stdio
  -device vmware-svga
)

exec qemu-system-x86_64 "${args[@]}"
