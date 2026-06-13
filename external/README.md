# External Bootstrap Infrastructure

This directory holds third-party infrastructure that EvOS uses for bootstrap research.

## OSX-KVM

- Source: `https://github.com/kholia/OSX-KVM`
- Local path: `external/OSX-KVM`

OSX-KVM is included only to support bootstrap experiments and host-side research.

It is not part of the EvOS source tree.

It may help provide a macOS VM for:

- Xcode experiments
- Apple SDK access
- KDK research
- XNU build experiments

It does not solve standalone Darwin bootability.

Keep any changes to OSX-KVM isolated from EvOS code unless they are specifically about bootstrap integration or documentation.
