# Building and Booting XNU

This note focuses on one question only: can the latest publicly available Apple XNU/Darwin sources be built and booted in an x86_64 QEMU environment?

Short answer:

- Building the kernel from the public source tree looks plausible on a macOS-based Apple toolchain.
- Booting a kernel into a working Darwin system is a separate problem.
- I found no evidence that the public Apple sources provide a complete standalone Darwin OS image today.
- I found no realistic, documented Linux-hosted build path for the current public XNU tree.

## Facts

- Apple publishes the current XNU source tree in `apple-oss-distributions/xnu`.
- The latest public tag visible on that repository is `xnu-12377.101.15`.
- Apple’s Open Source releases page now directs developers to GitHub-hosted release pages for operating-system source code.
- The current XNU README documents a `make`-based build flow and explicitly expects a `macOS` SDK path via `SDKROOT`.
- The README also says XNU runs on `x86_64` and `ARM64`.
- The build system derives the kernel version from the SDK or KDK by reading `System.kext/Info.plist`.
- A 2014 Yosemite-era walkthrough shows the older build path required OS X Yosemite, Xcode 6.1, `dtrace`, `AvailabilityVersions`, and additional header/install steps for `Libsystem` and `libsyscall`.
- A later Habr article notes that Darwin used to be installable as a standalone system, but that is no longer the case.

## Historical Build Path

The Yosemite-era recipe is useful because it shows how Apple kernel builds were originally composed from multiple public components.

Historical steps, as documented in 2014:

1. Install OS X Yosemite and Xcode 6.1.
2. Accept the Xcode license.
3. Download source tarballs for `dtrace`, `AvailabilityVersions`, and `xnu`.
4. Build and install CTF tools from `dtrace`.
5. Install `AvailabilityVersions`.
6. Build XNU with `make SDKROOT=macosx ARCH_CONFIGS=X86_64 KERNEL_CONFIGS=RELEASE`.
7. If adding system calls, also install `Libsystem` headers and build `Libsyscall`.

What that tells us:

- Historical Apple kernel builds were not "just compile xnu.c".
- They depended on Apple SDK structure and helper tools.
- Kernel source alone was never the whole environment.

## Current Public Build Dependencies

From the current public XNU README and versioning docs, the build surface still expects:

- A macOS SDK or KDK path passed through `SDKROOT`.
- Apple-style SDK layout, because the versioning logic reads `System/Library/Extensions/System.kext/Info.plist`.
- A `make`-driven build environment.
- Architecture selection such as `ARCH_CONFIGS=X86_64`.
- Kernel configuration selection such as `KERNEL_CONFIGS=DEVELOPMENT` or `RELEASE`.

What is not documented as part of a supported public Linux build:

- A Linux-hosted SDK/toolchain setup.
- Replacement Apple SDK shims.
- A fully documented non-Apple bootstrap path.

## Linux Host vs macOS/Xcode

### What is supported by the public documentation

- The official docs assume an Apple-style SDK/KDK and Apple build environment.
- The historical build recipe explicitly required Xcode and macOS.
- The current public documentation does not describe a Linux-hosted workflow.

### Practical conclusion

- For the first successful build, macOS with Apple command-line tools is the realistic path.
- A Linux host is not impossible in theory, but it would be an engineering experiment, not the documented route.
- If EvOS wants to minimize unknowns, treat Linux cross-building as a later porting task rather than the initial path.

## What Is Needed To Boot A Kernel In QEMU

Building XNU is not the same as booting Darwin.

### Kernel build requirements

- XNU source tree.
- Apple SDK/KDK-compatible environment.
- Host toolchain capable of the XNU make system.
- In older public recipes, supporting projects such as `dtrace`, `AvailabilityVersions`, `Libsystem`, and `Libsyscall`.

### Bootloader requirements

- An EFI or Darwin-compatible boot chain.
- A loader that can hand off to the kernel with the right flags and device assumptions.
- For historical Darwin experiments this usually means some Apple-like bootloader path rather than a generic raw-kernel boot.

### Root filesystem requirements

- A Darwin-compatible root volume image.
- The kernel image is not enough; the boot process expects a filesystem with the right directory structure and boot configuration.
- In practice this usually means a prepared image rather than an empty disk.

### Userland requirements

- A minimal Darwin userland.
- `launchd` or an equivalent init path.
- Core libraries and base utilities sufficient to bring the system to a shell or login prompt.
- Drivers and basic networking tools if the goal is more than a console boot.

## Bootability Assessment

### Facts

- XNU is real, current, and public.
- XNU is a kernel, not a complete OS image.
- Apple’s public release site points to source releases, not a standalone Darwin desktop download.

### Blockers

- No official complete standalone Darwin distribution is exposed through the current public Apple release flow.
- No official x86_64 QEMU boot recipe for the latest public XNU tree was found.
- Missing bootloader, rootfs, and userland pieces remain the hard part.

### Hypotheses

- A current XNU tree may still be buildable on macOS with the documented SDK-based flow.
- A bootable Darwin guest in QEMU would likely require a community boot chain and a reconstructed root filesystem.
- The most realistic path is to reuse or study an existing community artifact such as PureDarwin, then compare its boot chain against a fresh XNU build.

## Bottom Line

- Kernel buildability is plausible.
- Booting a real Darwin environment is still the problem.
- Linux-first build work is not the realistic starting point.
- A fresh XNU boot study should separate the kernel compile from the boot chain reconstruction.

## Sources

- [Apple XNU repository](https://github.com/apple-oss-distributions/xnu)
- [Apple Open Source releases](https://opensource.apple.com/releases/)
- [Historical Yosemite build post](https://shantonu.blogspot.com/2014/10/building-xnu-for-os-x-1010-yosemite.html)
- [Habr article on macOS XNU source release](https://habr.com/ru/companies/pvs-studio/articles/549460/)
