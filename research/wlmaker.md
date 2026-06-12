# wlmaker

## Project Overview

wlmaker, or Wayland Maker, is a Wayland compositor inspired by Window Maker. It tries to recreate some of the NeXTSTEP/Window Maker visual and workflow ideas on top of modern Wayland.

## Current Status

- Alive and actively developed.
- The GitHub repository is public and updated in 2026.
- The latest release is `v0.8`, published on 2026-05-21.
- The project README still labels the compositor as "early access", which is the important signal: active, but not yet a finished desktop platform.

## Strengths

- Strong aesthetic fit for an EvOS project that cares about NeXTSTEP/Window Maker style.
- Modern Wayland base, so it fits today's Linux desktop stack.
- Active development and recent release activity.
- It already has Window Maker-inspired details like dock/clip behavior, workspaces, and theme support.

## Risks

- It is not a kernel or OS base, only a compositor.
- The README explicitly says it is still early access and only covers elementary compositor functionality.
- It lives in the Wayland ecosystem, which is useful on Linux but not directly helpful for a Darwin/XNU boot path.
- It may become a distraction if EvOS's core goal is a Darwin-like system image rather than a desktop skin.

## Relevance To EvOS

- High as a visual and interaction reference for a Window Maker-like desktop on a Linux host.
- Medium as a validation target for layout, dock, workspace, and theming ideas.
- Low as a foundation for a Darwin/XNU-centric guest OS.

## What Is Realistically Bootable On x86_64 QEMU Today

- wlmaker is not bootable because it is not an OS.
- It is useful after the guest or host OS is already up.
- If EvOS chooses a Linux-hosted development path, wlmaker is one of the better current compositors to study.

## Sources

- [wlmaker repository](https://github.com/phkaeser/wlmaker)
- [wlmaker v0.8 release](https://github.com/phkaeser/wlmaker/releases/tag/v0.8)
