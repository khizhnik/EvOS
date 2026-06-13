# XNU / Darwin Toolchain Findings

## Findings

- The article demonstrates a Linux-hosted cross-compilation setup using `osxcross` on Ubuntu.
- It successfully builds a trivial application for a macOS target and verifies that binary on a real macOS system.
- It also builds a library from source for the same target and then links an application against that library.
- The setup depends on an Apple macOS SDK, but the SDK itself is supplied as a packaged tarball rather than being built locally on macOS.
- The toolchain uses Linux host tooling plus Apple-targeted cross tools, including Apple-ABI-aware linking behavior.
- The article does not build XNU, launchd, libSystem, or a Darwin root filesystem.
- The article does not boot Darwin.

## What Exactly Was Achieved

### Cross-compiling applications

- Yes.
- The article builds a simple `Hello World` program for a macOS target.

### Cross-compiling libraries

- Yes.
- The article builds `libusb` for the macOS target so the application can link against it.

### Building Darwin binaries

- Partially.
- It builds macOS-target Mach-O binaries, which are ABI-relevant for Darwin/macOS, but this is not the same as constructing a complete Darwin system component stack.

### Building Darwin userland

- No.
- Nothing in the article shows a Darwin userland such as `launchd`, BSD utilities, or a login environment being assembled.

### Building XNU

- No.
- The article is about application and library cross-compilation, not kernel work.

### Booting Darwin

- No.
- There is no bootloader, root filesystem, or guest boot flow in the article.

## Relevance To EvOS

- Useful as a toolchain enabler, not as a system-image solution.
- The main value is proving that macOS-target software can be built on Linux with a cross toolchain.
- That matters if EvOS wants a Linux-hosted build farm or wants to avoid doing every Apple-target build on a Mac.
- It does not solve the hard Darwin-specific parts of EvOS: kernel boot, system bootstrap, or root filesystem composition.

## Open Questions

- Can the same Linux-hosted toolchain build the Apple open-source pieces EvOS actually needs, such as `launchd` or `libSystem`?
- Can the build artifacts be made compatible with a Darwin root filesystem without manual path rewriting?
- How much of the Apple SDK can be legally and practically packaged for repeatable builds?
- Can the toolchain be extended to support XNU-related build steps, or does XNU still require a macOS host?
- Is the cross toolchain sufficient for a mostly userland-oriented EvOS prototype, even if it cannot handle the kernel path?

## Next Research Steps

1. Test whether the Linux-hosted `osxcross` approach can build small Apple open-source userland components.
2. Check which Darwin projects hard-require Apple build tools versus only requiring a compatible SDK and linker.
3. Compare `osxcross` output against the expectations of `launchd`, `libSystem`, and base utilities.
4. Map whether a cross-built userland could be staged into a Darwin-compatible root filesystem image.
5. Keep the kernel path separate until toolchain viability for userland is proven.

## Sources

- [Habr article: Cross-compiling for macOS with OSXCross](https://habr.com/ru/articles/875290/)
- [osxcross repository](https://github.com/tpoechtrager/osxcross)
- [Virtual Hackintosh system](https://github.com/kholia/OSX-KVM)
