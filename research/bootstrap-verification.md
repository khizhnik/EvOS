# Bootstrap Verification Plan

This note tracks the minimal checks needed before attempting any macOS installation or build work with OSX-KVM.

## Checklist

- Verify host CPU virtualization support.
- Verify QEMU version.
- Verify KVM availability.
- Verify OVMF packages.
- Verify OSX-KVM scripts are present.
- Verify whether Codex can run local shell commands.
- Verify whether Codex can interact with the macOS VM only through SSH or shared folders after the VM is installed.

## Control Path Assumption

Preferred future control path:

Linux host -> QEMU macOS VM -> SSH enabled inside macOS -> Codex executes commands via SSH from the Linux host

Do not assume direct control of the macOS GUI.

## Scope Boundaries

- Do not install macOS yet.
- Do not download large macOS images.
- Do not run QEMU installation steps yet.
- Use OSX-KVM only as external bootstrap infrastructure, not as EvOS source code.
