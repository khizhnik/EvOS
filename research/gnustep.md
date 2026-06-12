# GNUstep

## Project Overview

GNUstep is an Objective-C framework and application ecosystem that implements the OpenStep/Cocoa programming model on non-Apple platforms. It is the most relevant userland technology in the EvOS stack because it gives you the NeXT/OpenStep mental model without requiring macOS itself.

## Current Status

- Alive and actively maintained.
- The official GNUstep site is current and points to GitHub repositories, downloads, docs, and developer resources.
- The GNUstep GitHub organization shows active repository updates in 2026.
- Recent releases are still being published:
  - `tools-make` 2.9.3 in 2025-02
  - `libs-base` 1.31.1 in 2025-02
  - `libs-gui` 0.32.0 in 2025-02
  - `libs-back` 0.32.0 in 2025-02
  - `libobjc2` 2.3 in 2025-09

## Strengths

- It is the clearest living OpenStep-compatible ecosystem.
- It has real applications, not just framework code.
- It is portable across Unix-like systems and Windows.
- It aligns well with EvOS's interest in workstation-style UI and old NeXT ideas.
- The project is active enough to be a practical dependency rather than just a historical reference.

## Risks

- Cocoa compatibility is partial, not complete.
- Some APIs and behaviors are still approximations of Apple's frameworks.
- Tooling and backend quality vary by platform.
- Objective-C remains the center of gravity, so Swift-first plans are a poor fit.

## Relevance To EvOS

- Very high.
- GNUstep is the best current candidate for an OpenStep-like userland and desktop layer.
- It can serve both as an application framework and as the user-facing identity of the project.

## What Is Realistically Bootable On x86_64 QEMU Today

- GNUstep itself is not an operating system, so "bootable" is not the right unit.
- As a desktop stack, it is realistic on top of an already bootable host or guest.
- For EvOS, GNUstep is the most realistic way to get productive quickly, even if the kernel experiment remains separate.

## Sources

- [GNUstep official site](https://www.gnustep.org/)
- [GNUstep organization](https://github.com/gnustep/)
- [GNUstep libobjc2 release 2.3](https://github.com/gnustep/libobjc2/releases/tag/v2.3)
- [GNUstep Base release 1.31.1](https://github.com/gnustep/libs-base/releases/tag/base-1_31_1)
- [GNUstep GUI release 0.32.0](https://github.com/gnustep/libs-gui/releases/tag/gui-0_32_0)
- [GNUstep Back release 0.32.0](https://github.com/gnustep/libs-back/releases/tag/back-0_32_0)
- [GNUstep Make release 2.9.3](https://github.com/gnustep/tools-make/releases/tag/make-2_9_3)
