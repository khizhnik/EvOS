# OSX-KVM as Bootstrap Infrastructure

This note evaluates `kholia/OSX-KVM` strictly as infrastructure for EvOS research, not as part of EvOS itself.

## Findings

### What OSX-KVM provides

#### macOS VM creation

- It documents how to create a macOS virtual machine on QEMU/KVM.
- The repository README explicitly describes it as a way to run macOS on QEMU/KVM.
- It supports recent macOS releases, including Monterey, Ventura, and Sonoma.
- It provides boot scripts for interactive, headless, and libvirt-based use.

#### QEMU/KVM configuration

- The repo includes shell scripts and configuration files for QEMU/KVM-based macOS boots.
- The README advertises a CLI-first installation flow.
- It also includes libvirt/virt-manager support as an optional path.

#### OVMF/UEFI setup

- The repository includes OVMF firmware images and notes for UEFI-based booting.
- The documented setup uses OpenCore as the boot chain, not a bare kernel handoff.

#### Host requirements

- The README says the host should be a modern Linux distribution, for example Ubuntu 24.04 LTS or later.
- It requires QEMU 8.2.2 or newer.
- It requires Intel VT-x or AMD SVM.
- It requires SSE4.1 for macOS Sierra and newer.
- It requires AVX2 for macOS Ventura and newer.
- The repo metadata says a Mac system is not required.

#### Storage, networking, display support

- The README and scripts cover local VM disks, APFS formatting inside the guest, headless operation, VNC/SSH support discussions, and libvirt integration.
- The repository includes networking-related examples and bridge configuration files.
- Display operation is centered on the macOS VM itself; the headless script exists for non-graphical or remote workflows.

#### Automation and reproducibility

- The README says the repository blobs and resources are re-derivable and that instructions are included.
- It provides scripts such as `OpenCore-Boot.sh`, `boot-macOS-headless.sh`, and supporting fetch/install helpers.
- This makes it more useful as bootstrap infrastructure than as a one-off manual guide.

### Current status

- Active and widely used.
- The repository is public, large, and still receiving updates in 2026.
- The repository description and README indicate that support and support policy are now oriented toward paid/commercial help, but the technical material remains public.

## Relevance To EvOS

- High as bootstrap infrastructure.
- It gives EvOS a practical way to obtain a macOS environment on Linux-hosted hardware without requiring a physical Mac.
- That macOS environment can be used for Xcode, Command Line Tools, SDK, KDK, and Apple build-flow experimentation.
- It does not make EvOS itself less Darwin/XNU dependent; it only changes where the Apple toolchain work can be done.

## Gaps Closed

| Gap | Before OSX-KVM | After OSX-KVM | Status |
|---|---|---|---|
| Mac host availability | A physical Mac was the obvious path for Apple toolchains. | A Linux host can now run a macOS VM. | Partially closed |
| Xcode access | Required a real Mac or another existing macOS system. | A macOS VM can host Xcode/CLT workflows. | Partially closed |
| SDK access | Apple SDK workflows were Mac-hosted by default. | The VM can provide a macOS environment where SDK downloads and installs can happen. | Partially closed |
| Testing Apple build flows | Hard to reproduce off Apple hardware. | QEMU/KVM plus macOS gives a reproducible host for Apple build experiments. | Largely closed for host-side testing |
| Studying filesystem layout | Required access to a macOS environment. | The VM can be used to inspect `/System`, `/Library`, `/Users`, and other layout conventions. | Closed enough for research |
| Studying launchd/libSystem/userland | Needed a macOS execution environment. | The VM can run Apple userland for behavior study. | Closed enough for research |
| Creating build artifacts | Depended on a Mac host or a preexisting macOS machine. | The VM can be used to produce Apple-target artifacts for later EvOS experiments. | Partially closed |

## Gaps Remaining

| Gap | Why OSX-KVM does not solve it |
|---|---|
| Booting standalone Darwin | OSX-KVM boots macOS through OpenCore and Apple boot flow; it does not produce a standalone Darwin system image from public XNU sources. |
| Darwin-compatible root filesystem | The VM gives you a macOS guest, not a reconstructed standalone Darwin rootfs. |
| Replacing Apple SDK/KDK dependencies | It relocates the dependency into a VM, but does not eliminate Apple toolchain and SDK requirements. |
| Linux-hosted native Darwin builds | It is a macOS VM, not a native Linux Darwin toolchain. |
| Package management | No package system for standalone Darwin is created by this project. |
| Self-hosting | The VM can host Apple tools, but EvOS self-hosting remains a separate long-term task. |
| Licensing/distribution constraints | The repo still depends on Apple-provided installation media and software terms; it does not remove legal or redistribution constraints. |

## Risks

- It is bootstrap infrastructure, not an architectural substitute.
- It can encourage overfitting EvOS to a macOS VM workflow instead of solving the real standalone boot problem.
- It depends on Apple installation media, OpenCore, and a specific QEMU/KVM environment.
- It improves experimentation speed, but does not reduce the engineering depth of the Darwin/XNU path.
- It does not answer whether a fresh XNU build can boot independently.

## Does It Make A First Fresh XNU Build Realistic?

Yes, as a practical bootstrap path.

What changes:

- EvOS no longer needs a physical Mac to begin Apple toolchain experiments.
- A Linux workstation can host a macOS VM for Xcode, CLT, SDK, and possibly KDK-driven work.
- That makes the first compilation experiments much more realistic.

What does not change:

- The kernel build still depends on Apple SDK/KDK assumptions unless proven otherwise.
- The boot chain problem remains separate from the build problem.
- A successful macOS VM does not prove a standalone Darwin guest can boot.

### Host setup required

- Modern Linux host.
- QEMU 8.2.2 or newer.
- KVM support enabled in hardware and the kernel.
- CPU support for VT-x or SVM.
- SSE4.1, and AVX2 if targeting newer macOS releases like Ventura or Sonoma.
- Enough storage and RAM for a macOS VM and toolchain.

### First target to use

- A recent supported macOS release already documented by the project, with Sonoma or Ventura as the practical modern target.
- For an XNU-build-first experiment, the exact guest OS version should be chosen by the requirements of the current Apple XNU source tree and its documented SDK/KDK assumptions, not by image aesthetics.

### Xcode / SDK / KDK assumptions

- OSX-KVM itself does not ship Apple SDKs or KDKs.
- It provides the macOS environment in which those Apple components can be installed and used.
- The build path is still Apple-toolchain-centric unless EvOS later proves a Linux-native replacement path.

### First minimal success criterion

Build the latest public XNU source in the macOS VM far enough to produce a kernel artifact using the documented Apple-style build flow.

Success should mean:

- The toolchain works end to end inside the VM.
- The necessary SDK/KDK assumptions are satisfied.
- The build produces the expected kernel outputs.
- No claim is made yet about standalone Darwin bootability.

## What It Helps Build

### It helps build XNU?

- Indirectly, yes.
- It provides a macOS host environment where current Apple build flows can be tested more realistically than on a bare Linux host.

### It helps build Darwin?

- Only partially.
- It helps with the Apple toolchain side of Darwin research, but not with the standalone bootable OS side.

### Precise answer

- OSX-KVM helps build and study the Apple-hosted side of the problem.
- It does not itself build Darwin as an independently bootable operating system.

## Recommended First Experiment

1. Boot a macOS VM using the documented OSX-KVM path on a Linux host.
2. Install Apple Command Line Tools and Xcode or the minimum required Apple build toolchain inside the VM.
3. Verify that the current public XNU source tree can at least start a documented build with the expected SDK/KDK assumptions.
4. Stop at kernel artifact production and record the exact dependencies and failure modes.
5. Do not attempt to conclude anything about standalone Darwin bootability from this experiment alone.

## Open Questions

- Which exact macOS guest version is the least painful for the latest public XNU tree?
- Is KDK actually required for the current source tree, or is an SDK enough for the first build?
- How much of the Apple build flow can be repeated inside the VM without host-specific quirks?
- Can the VM be used to stage artifacts for a later Darwin root filesystem reconstruction effort?

## Sources

- [OSX-KVM repository](https://github.com/kholia/OSX-KVM)
- [OSX-KVM README and repository metadata](https://github.com/kholia/OSX-KVM)
