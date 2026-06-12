# Darwin / XNU

## Project Overview

XNU is the kernel at the center of Darwin and Apple's operating systems. Darwin is the open-source core OS layer, while XNU is the hybrid kernel that combines Mach, BSD-derived pieces, and IOKit.

## Current Status

- Alive and actively maintained by Apple through the `apple-oss-distributions` GitHub organization.
- The XNU repository is public and updated in 2026.
- The repository README states that XNU runs on `x86_64` and `ARM64`.
- Apple still publishes open-source releases through its Open Source site, which now points developers to GitHub-hosted release pages.
- This is active source publishing, but not the same thing as a supported standalone Darwin desktop.

## Strengths

- This is the real kernel lineage behind macOS and related Apple platforms.
- Source availability remains current enough for research and code reading.
- The codebase is large, documented, and historically well understood.
- x86_64 support is present in the public tree, which matters for QEMU-based experiments.

## Risks

- The public sources are only one layer of the full Apple stack.
- Many user-facing and hardware-specific components are closed or distributed in other forms.
- A bootable standalone Darwin guest is not an Apple-supported product.
- The kernel is deep and stable, but the surrounding ecosystem is constrained by Apple's release model.

## Relevance To EvOS

- Very high as a research reference for kernel, boot, and userland compatibility boundaries.
- Medium as a possible source base for a historical reconstruction experiment.
- Low as a direct path to a modern, maintainable desktop unless you are prepared to rebuild a lot of missing infrastructure.

## What Is Realistically Bootable On x86_64 QEMU Today

- XNU by itself is not a bootable OS.
- Apple publishes the kernel source, but not a turnkey x86_64 QEMU guest image.
- If EvOS wants a Darwin-based guest, the practical boot target is the existing PureDarwin artifact, not a fresh XNU checkout.

## Sources

- [XNU repository](https://github.com/apple-oss-distributions/xnu)
- [Apple Open Source releases](https://opensource.apple.com/releases/)
- [Apple OSS distribution-macOS repository](https://github.com/apple-oss-distributions/distribution-macOS)
