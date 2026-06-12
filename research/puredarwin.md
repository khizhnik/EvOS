# PureDarwin

## Project Overview

PureDarwin is a community effort to turn Apple's Darwin sources into a more usable, bootable operating system. The project sits closest to the original Darwin/OpenDarwin idea of "Darwin as a standalone OS", rather than just a source drop.

## Current Status

- Active, but niche.
- The main repository is public and still receiving updates in 2026.
- The repo description says the project aims to provide "a useful bootable ISO/VM of some recent version of Darwin".
- The latest public release on GitHub is `17.4`, published on 2026-01-27.
- That release notes it is a re-upload of a 2018 artifact, which is the key signal: the project is alive, but its bootable image path is old and not a fresh from-source modern Darwin build.

## Strengths

- It is the closest public experiment to a standalone Darwin machine.
- It keeps the x86_64/QEMU use case explicit instead of theoretical.
- It documents the missing pieces clearly enough to show where the hard work is.
- It provides a real boot artifact, not just kernel source.

## Risks

- Apple has closed a large part of the old "bootable Darwin" surface area.
- The project depends on obsolete or partially reconstructed components.
- The current bootable image is a re-uploaded historical beta, not a newly maintained release line.
- A lot of the work is likely to be around packaging, drivers, and userland reconstruction rather than kernel innovation.

## Relevance To EvOS

- High, if EvOS wants to test whether a Darwin-like boot chain is still practical on x86_64 QEMU.
- Medium, if EvOS mainly wants OpenStep/GNUstep semantics and only wants Darwin as a reference.
- Low, if the goal is a clean long-term platform rather than a historical reconstruction effort.

## What Is Realistically Bootable On x86_64 QEMU Today

- The PureDarwin 17.4 beta VM image is the only public Darwin-flavored x86_64 QEMU path I found that is explicitly documented as bootable.
- It is not a modern, complete OS in the product sense.
- It is best treated as an experiment platform and a source of lessons, not as the final target.

## Sources

- [PureDarwin/PureDarwin](https://github.com/PureDarwin/PureDarwin)
- [PureDarwin releases](https://github.com/PureDarwin/PureDarwin/releases/tag/17.4)
- [PureDarwin organization](https://github.com/PureDarwin)
