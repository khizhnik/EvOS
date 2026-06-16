# XNU Build Lab

See: [research/xnu-compatibility-fixes.md](research/xnu-compatibility-fixes.md)

This note records the first attempt to work with the latest public XNU sources from the macOS Sonoma VM hosted in OSX-KVM.

## Environment

- macOS version: `14.8.7`
- Darwin kernel version: `23.6.0`
- Reported XNU version: `xnu-10063.141.1.712.16~1/RELEASE_X86_64`
- Command Line Tools: installed
- `clang` version: `Apple clang version 16.0.0 (clang-1600.0.26.6)`
- `git`: works
- `make`: works
- SDK path: `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`
- SDK version: `15.2`
- `xcode-select -p`: `/Library/Developer/CommandLineTools`
- `/Applications/Xcode.app`: not present
- `xcrun --find migcom`: failed under CLT-only setup
- `xcrun --find iig`: failed under CLT-only setup

## Source Checkout

Status:

- Completed in this session.
- Checkout path: `~/Work/EvOS/xnu`
- Current branch: `main`
- Current commit: `f6217f891ac0bb64f3d375211650a4c1ff8ca1ea`
- Latest tags observed:
  - `xnu-12377.101.15`
  - `xnu-12377.81.4`
  - `xnu-12377.61.12`
  - `xnu-12377.41.6`
  - `xnu-12377.1.9`
  - `xnu-11417.140.69`
  - `xnu-11417.121.6`
  - `xnu-11417.101.15`
  - `xnu-11215.81.4`
  - `xnu-11215.61.5`
  - `xnu-11215.41.3`
  - `xnu-11215.1.10`
  - `xnu-10063.141.1`
  - `xnu-10063.121.3`
  - `xnu-10063.101.15`
  - `xnu-10002.81.5`
  - `xnu-10002.61.3`
  - `xnu-10002.41.9`
  - `xnu-10002.1.13`
  - `xnu-8796.141.3`

Assumption used:

- The newest public tag in the cloned repo was selected for inspection because it is the most recent public Apple XNU source snapshot visible in the repository tags.

## Official XNU Repository

- Repository: `https://github.com/apple-oss-distributions/xnu`
- Latest public tag observed on the official GitHub tags page: `xnu-12377.101.15`
- Latest public tag commit shown by GitHub: `5c306be`

## Xcode Compatibility Notes

- Apple’s public App Store page for Xcode currently shows the latest release as requiring macOS `26.2` or later.
- The same Apple page shows Xcode `15.4` as a stable historical release with macOS Sonoma `14.5` support.
- On this Sonoma `14.8.7` VM, that makes Xcode `15.4` the latest Sonoma-era stable release visible from official Apple history.
- The App Store page is at: `https://apps.apple.com/us/app/xcode/id497799835`

## Build Documentation Summary

The official XNU README documents the build entry point as:

```sh
make SDKROOT=<sdkroot> ARCH_CONFIGS=<arch> KERNEL_CONFIGS=<variant>
```

Relevant documented points:

- `SDKROOT` is the path to the macOS SDK on disk.
- `ARCH_CONFIGS` selects the target architecture, such as `X86_64`.
- `KERNEL_CONFIGS` selects the build variant, such as `DEVELOPMENT` or `RELEASE`.
- The README says the XNU version is derived from the SDK or KDK via `System.kext/Info.plist`.
- The README references `doc/building/xnu_version.md` for versioning details.
- `doc/building/xnu_version.md` confirms version derivation comes from the SDK or KDK `System.kext/Info.plist`.
- The first documented build shape used here was:

```sh
make SDKROOT=<sdkroot> ARCH_CONFIGS=<arch> KERNEL_CONFIGS=<variant>
```

## First Build Attempt

- Attempted exactly once with the public CLT SDK path and explicit x86_64 development build settings:

```sh
make SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" ARCH_CONFIGS=X86_64 KERNEL_CONFIGS=DEVELOPMENT
```

- Result: failed immediately during version discovery, before any meaningful compilation started.
- Error category: SDK versioning / build metadata resolution.

## Current Environment Status

- The VM remains CLT-only.
- Xcode is not installed.
- `mas` is not installed.
- The Apple Developer downloads page requires sign-in, so no direct CLI installation path was available in this session.

## First Blocker

- The build system could not derive an XNU version from the installed Command Line Tools SDK:

```text
xcrun: error: unable to lookup item 'PlatformPath' from command line tools installation
xcrun: error: unable to lookup item 'PlatformPath' in SDK '/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk'
xcrun: error: unable to find utility "migcom", not a developer tool or in PATH
xcrun: error: unable to find utility "iig", not a developer tool or in PATH
/Users/khizhnik/Work/EvOS/xnu/makedefs/MakeInc.kernel:299: *** Could not determine xnu version from SDK or KDK! Set RC_DARWIN_KERNEL_VERSION environment variable..  Stop.
make[1]: *** [build_setup_bootstrap_DEVELOPMENT^X86_64^NONE] Error 2
make: *** [all] Error 2
```

<a id="fix-f001"></a>
## Availability.pl

What it is:

- `availability.pl` is an Apple build-time helper script used by `bsd/sys/make_symbol_aliasing.sh`.
- That script pipes `availability.pl --ios` output into generated availability macros for `_symbol_aliasing.h`.

Where XNU invokes it:

- `bsd/sys/Makefile` defines `_symbol_aliasing.h` as part of `SETUP_GEN_LIST`.
- `bsd/sys/Makefile` marks `SETUP_GEN_LIST` as part of `do_build_setup`.
- `bsd/sys/make_symbol_aliasing.sh` requires:

```sh
AVAILABILITY_PL="${SDKROOT}/${DRIVERKITROOT}/usr/local/libexec/availability.pl"
```

What target needs it:

- The early `do_build_setup` phase, specifically `_symbol_aliasing.h`.
- The comment in `bsd/sys/Makefile` says these generated headers are needed early and are used by `iig` during `installhdrs` of `iokit/DriverKit`.

Where it exists:

- `/Applications/Xcode.app`: not found in the public Xcode tree inspected here.
- `/Library/Developer`: not found.
- XNU source tree: only references and the consumer script exist, not the tool itself.
- Apple open-source repos: no public copy was found in this research pass.
- KDK: not verified as a source of this file.

SDK relationship:

- The tool is treated as an SDK-provided artifact, not as something generated by XNU.
- The current public Xcode SDK symlink `MacOSX15.0.sdk -> MacOSX.sdk` does not contain `usr/local/libexec/availability.pl`.
- The internal SDK name `macosx.internal` is not available on this machine.

Older tag check:

- `xnu-10063.141.1` contains the same `bsd/sys/make_symbol_aliasing.sh` guard and therefore does not avoid this dependency.

## Dependency Matrix

| Component | Required | Why |
| --- | --- | --- |
| Command Line Tools | Yes | `clang`, `git`, `make`, and the public SDK are available here. |
| Full Xcode | Likely yes | `xcrun` could not resolve `PlatformPath` from CLT, and the build system expects platform-aware tool lookups plus `iig`. |
| KDK | Not proven mandatory yet | XNU docs say the version can come from an SDK or KDK. The first failure came from version discovery, not a KDK-specific step. |
| `migcom` | Yes, as a build tool lookup | `makedefs/MakeInc.cmd` calls `xcrun -sdk $(SDKROOT) -find migcom`. The CLT package contains `migcom`, but `xcrun` could not resolve it because platform lookup failed first. |
| `iig` | Yes, as a build tool lookup | `makedefs/MakeInc.cmd` calls `xcrun -sdk $(SDKROOT) -find iig`, and `iig` is absent from the CLT tree. |
| SDK `System.kext/Info.plist` | Yes for version discovery | XNU derives `RC_DARWIN_KERNEL_VERSION` from this file in the SDK or KDK. The public CLT SDK here does not provide it. |
| `availability.pl` | Yes for this build path | `bsd/sys/make_symbol_aliasing.sh` requires it from `SDKROOT/${DRIVERKITROOT}/usr/local/libexec`, and the default build’s `do_build_setup` depends on `_symbol_aliasing.h`. |

## Interpretation

- `PlatformPath` is an SDK platform lookup performed by `xcrun`.
- In this VM, `xcode-select -p` points at `/Library/Developer/CommandLineTools`, so the environment is CLT-only rather than full Xcode.
- `migcom` is present in the CLT package at `/Library/Developer/CommandLineTools/usr/libexec/migcom`, but `xcrun` still failed to resolve it because the platform lookup failed first.
- `iig` is absent from the CLT tree.
- XNU’s build system expects both tool lookups through `xcrun`, and it also expects an SDK or KDK that contains `System.kext/Info.plist` for kernel version derivation.
- `availability.pl` is not a kernel compiler tool; it is an SDK-supplied helper for generating availability alias headers during the early setup stage.

## Next Recommended Action

1. Find an Apple SDK variant that actually ships `usr/local/libexec/availability.pl`, likely an internal SDK rather than public CLT or the public macOS SDK.
2. Re-run only the environment checks for `availability.pl`, `_symbol_aliasing.h`, and the `do_build_setup` stage once such an SDK is available.
3. If no Apple-hosted SDK artifact is available, confirm whether this blocker is effectively tied to `macosx.internal` and not solvable by KDK or env vars alone.
4. Keep the kernel build attempt separate from any bootability work.

## availability.pl reverse engineering

### What it expects

`bsd/sys/make_symbol_aliasing.sh` is a two-argument helper:

```sh
Usage: $0 <sdk> <output>
```

It expects:

- `$1` to be the SDK root path passed in as `SDKROOT`
- `$2` to be the output file name, usually `_symbol_aliasing.h`
- `DRIVERKITROOT` to already be set in the environment by the build system

The script then resolves:

```sh
AVAILABILITY_PL="${SDKROOT}/${DRIVERKITROOT}/usr/local/libexec/availability.pl"
```

and aborts if that file is missing or not executable.

### What `availability.pl` produces

The script does not generate `availability.pl`; it calls it.

Input to `availability.pl`:

- `--ios`
- `--macosx`

Output from `availability.pl`:

- A list of availability version strings, one per line or token, which the shell loop parses into major/minor/revision components.

Output produced by `make_symbol_aliasing.sh`:

- A generated C header named `_symbol_aliasing.h`
- The file contains `__DARWIN_ALIAS_STARTING_IPHONE_*` and `__DARWIN_ALIAS_STARTING_MAC_*` macro definitions
- The file begins with a guard telling users to include `<sys/cdefs.h>` instead of the generated header directly

### Dependency graph

```text
availability.pl
  -> make_symbol_aliasing.sh (--ios, --macosx)
  -> generated _symbol_aliasing.h
  -> included by <sys/cdefs.h>
  -> exposed to many headers and translation units through cdefs.h
```

Downstream use in the source tree:

- [`bsd/sys/cdefs.h`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/bsd/sys/cdefs.h#L947) includes `<sys/_symbol_aliasing.h>`
- That makes the generated header reachable from a very broad part of the BSD and system header surface

Build-stage use:

- [`bsd/sys/Makefile`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/bsd/sys/Makefile#L345-L356) puts `_symbol_aliasing.h` in `SETUP_GEN_LIST`
- The comment says these generated headers are needed early and are used by `iig` during `installhdrs` of `iokit/DriverKit`

### What files consume it

Directly:

- `bsd/sys/cdefs.h`

Indirectly:

- Any source including standard Darwin/BSD headers that flow through `cdefs.h`
- DriverKit-related header generation paths that need the early setup outputs

### Which final binaries depend on it

This is mostly build-time header infrastructure, not a single binary artifact.

The generated header influences:

- kernel and libc-style header consumers
- DriverKit header generation
- any final object compiled with the availability alias macros in scope

It is not a stand-alone binary dependency in the usual sense.

### Is `_symbol_aliasing.h` kernel-critical?

Classification:

- **A. Kernel-critical as build infrastructure**

Reason:

- The file is required in `do_build_setup`
- The comment in `bsd/sys/Makefile` explicitly says it is needed early
- It is part of the default build setup, not just an optional post-build metadata step

It is **not** a runtime kernel binary dependency by itself.

### Can the output be reproduced independently?

Likely yes, with caveats.

What looks deterministic:

- The script’s logic is deterministic given the `availability.pl` output
- The generated header contents depend only on the version list returned by `availability.pl`

What it depends on:

- The SDK payload at `${SDKROOT}/${DRIVERKITROOT}/usr/local/libexec/availability.pl`
- The version values emitted for `--ios` and `--macosx`
- Therefore the output is likely SDK-version dependent and DriverKit-version dependent

What it does not appear to depend on:

- CPU architecture, directly

Prototype replacement strategy:

- Extract the version lists produced by `availability.pl --ios` and `--macosx`
- Generate the same macro block structure in a small replacement script
- Feed the result into `_symbol_aliasing.h`
- This would reproduce the generated header if and only if the version lists match the Apple script’s output

### Evidence from public searches

- Public Apple OSS and web searches in this pass did not surface a public standalone `availability.pl`
- I found no public evidence that XNU ships a replacement script
- I found no public example of developers bypassing the script by checking in a hand-generated `_symbol_aliasing.h`
- The absence of public hits suggests it is an Apple SDK helper, not a public open-source artifact

## availability.pl data source analysis

### Exact expected input format

`make_symbol_aliasing.sh` expects `availability.pl` to emit whitespace-delimited version tokens for two queries:

- `availability.pl --ios`
- `availability.pl --macosx`

The parser is simple:

```sh
for ver in $(${AVAILABILITY_PL} --ios) ; do
    set -- $(echo "$ver" | tr '.' ' ')
    ver_major=$1
    ver_minor=$2
    ver_rel=$3
    ...
done

for ver in $(${AVAILABILITY_PL} --macosx) ; do
    set -- $(echo "$ver" | tr '.' ' ')
    ver_major=$1
    ver_minor=$2
    ver_rel=$3
    ...
done
```

### Parser behavior

For each token:

- split on `.` into major, minor, revision
- if the revision field is absent:
  - iOS path: emit a macro
  - macOS path: treat revision as `0`

#### Example iOS token

Input token:

```text
14.8
```

Resulting output block:

```c
#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140800
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x)
#endif
```

#### Example macOS token

Input token:

```text
15.0
```

Resulting output block:

```c
#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 150000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x)
#endif
```

### Exact output shape

The generated `_symbol_aliasing.h` contains:

- license header
- include guard check for `_CDEFS_H_`
- repeated `#if / #define / #else / #define / #endif` blocks
- blank line between version blocks

### What the input data must look like

The output of `availability.pl --ios` and `availability.pl --macosx` must therefore be a list of version strings such as:

```text
10.0 10.1 10.2 ...
14.8
15.0
```

The script does not need JSON, plist, or structured records. It only needs version tokens.

### Local data source search

I searched the installed Xcode tree for equivalent version sources:

- `SDKSettings.json`
- `SDKSettings.plist`
- `AvailabilityVersions.h`
- `Availability.h`
- `AvailabilityInternal.h`
- SDK manifests and plist files

Findings:

- `AvailabilityVersions.h` exists in both the public macOS SDK and DriverKit SDK.
- `SDKSettings.json` and `SDKSettings.plist` exist in both SDKs.
- `availability.pl` itself does not appear in the public macOS SDK or public DriverKit SDK tree.
- The available headers contain version macros, but not the token list generator behavior of `availability.pl`.

### Can the data be reconstructed from the installed SDK?

Partially.

What is available locally:

- `AvailabilityVersions.h` contains the version macro table.
- `SDKSettings.json` / `.plist` identify SDK metadata.
- `xcrun --show-sdk-path` can resolve the active SDK path.

What is missing:

- the Apple script that enumerates the precise `--ios` and `--macosx` token sets used by `availability.pl`
- any documented schema tying those version tokens directly to the public SDK headers

Conclusion:

- A compatibility generator is feasible in principle.
- The exact token list is the missing piece.
- The generated header is deterministic once the token list is known.

### Proof of concept

Given hypothetical tokens:

```text
14.8
15.0
```

The fragment would be:

```c
#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140800
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x)
#endif

#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 150000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x)
#endif
```

### Answers

A. What exact data is missing?

- The Apple-generated version token lists returned by `availability.pl --ios` and `availability.pl --macosx`.

B. Does Xcode already contain that data elsewhere?

- It contains version metadata and availability headers, but not a public replacement for the script’s token enumeration.

C. Can `availability.pl` be replaced by a compatibility generator?

- Yes, likely, if the token lists can be reconstructed or copied from an Apple SDK that includes them.

D. What is the smallest experiment to validate this?

- Create a non-invasive local script that emits a tiny hard-coded token list and compare the generated `_symbol_aliasing.h` fragment against the structure expected by `bsd/sys/make_symbol_aliasing.sh`.
- No build is needed for this validation; only header generation comparison is required.

## availability.pl replacement feasibility

### Header parsing results

I parsed `AvailabilityVersions.h` from both SDK locations:

- `MacOSX.sdk/usr/include/AvailabilityVersions.h`
- `DriverKit.sdk/System/DriverKit/usr/include/AvailabilityVersions.h`

Observed version identifier sets:

- MacOS identifiers: 63 entries
- iOS identifiers: 81 entries
- The two SDK copies expose the same version tables

The relevant identifiers are already encoded as macro names:

- `__MAC_10_0`, `__MAC_10_1`, ... `__MAC_15_0`
- `__IPHONE_2_0`, `__IPHONE_2_1`, ... `__IPHONE_18_0`

### Comparison against the parser contract

`make_symbol_aliasing.sh` expects tokens like:

- `10.0`
- `10.10.3`
- `14.8`
- `15.0`

The header macro names can be mechanically converted into those tokens by:

- stripping the `__MAC_` or `__IPHONE_` prefix
- replacing underscores with dots

Examples:

- `__MAC_15_0` -> token `15.0`
- `__IPHONE_14_8` -> token `14.8`
- `__MAC_10_10_3` -> token `10.10.3`

### Can the token list be reconstructed automatically?

Yes, with high confidence.

Reasoning:

- The public SDKs already contain complete availability version tables.
- The parser in `make_symbol_aliasing.sh` only needs version tokens.
- The token list can be reconstructed mechanically from `AvailabilityVersions.h`.
- The same headers exist in both public macOS SDK and DriverKit SDK copies.

### Prototype compatibility generator design

Input:

- `AvailabilityVersions.h`

Output:

- a token stream equivalent to `availability.pl --ios`
- a token stream equivalent to `availability.pl --macosx`
- then the existing `make_symbol_aliasing.sh` macro generation logic, or an equivalent reimplementation

Suggested reconstruction algorithm:

1. Parse `AvailabilityVersions.h`.
2. Collect macro names starting with `__IPHONE_` and `__MAC_`.
3. Convert macro names into version tokens:
   - `__IPHONE_14_8` -> `14.8`
   - `__MAC_10_10_3` -> `10.10.3`
4. Sort by semantic version order if needed.
5. Feed the resulting token list into the existing shell macro logic.

### Concrete examples

Example 1:

```text
AvailabilityVersions.h entry: __IPHONE_14_8
generated token: 14.8
generated _symbol_aliasing.h macro:
#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140800
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x)
#endif
```

Example 2:

```text
AvailabilityVersions.h entry: __MAC_15_0
generated token: 15.0
generated _symbol_aliasing.h macro:
#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 150000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x)
#endif
```

Example 3:

```text
AvailabilityVersions.h entry: __MAC_10_10_3
generated token: 10.10.3
generated _symbol_aliasing.h macro:
#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101003
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x)
#endif
```

### Does the data already exist elsewhere in Xcode?

Yes, partially:

- `AvailabilityVersions.h` contains the version macro tables
- `SDKSettings.json` and `SDKSettings.plist` exist, but they do not appear to be the source of the token list
- `AvailabilityMacros.h` and `Availability.h` provide API-level availability macros, not the token enumerator output
- I did not find a public copy of `availability.pl` in the installed Xcode tree

### Confidence

**HIGH**

Reason:

- The required macro names are already present in the installed SDKs.
- The transformation from macro names to tokens is direct and mechanical.
- The shell generator logic is fully visible and deterministic.

### Smallest validation experiment

- Write a local throwaway parser that reads `AvailabilityVersions.h` and prints a handful of tokens.
- Compare those tokens against what `make_symbol_aliasing.sh` expects.
- No build or file modification is needed.

## availability.pl compatibility prototype

Prototype tool:

- [`research/availability_pl_compat_poc.py`](/home/khizhnik/Work/PROJECTS/EvOS/research/availability_pl_compat_poc.py)

What it does:

- reads `AvailabilityVersions.h` from the installed Xcode SDK trees
- extracts the `__MAC_*` and `__IPHONE_*` version identifiers
- converts them into the whitespace-delimited token streams expected by `bsd/sys/make_symbol_aliasing.sh`
- prints both token streams
- validates the token format against the shell parser contract
- prints sample `_symbol_aliasing.h` fragments for:
  - `__MAC_15_0`
  - `__MAC_10_10_3`
  - `__IPHONE_14_8`

Observed proof output:

- macOS token stream begins at `10.0` and ends at `15.0`
- iOS token stream begins at `2.0` and ends at `18.0`
- `DriverKit.sdk` and `MacOSX.sdk` produced matching token streams
- the prototype confirmed the parser contract is satisfied by whitespace-delimited version tokens

Concrete sample fragments:

```text
AvailabilityVersions.h entry: __MAC_15_0
generated token: 15.0
generated _symbol_aliasing.h macro:
#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 150000
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x)
#endif
```

```text
AvailabilityVersions.h entry: __MAC_10_10_3
generated token: 10.10.3
generated _symbol_aliasing.h macro:
#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101003
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x) x
#else
#define __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x)
#endif
```

```text
AvailabilityVersions.h entry: __IPHONE_14_8
generated token: 14.8
generated _symbol_aliasing.h macro:
#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= 140800
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x) x
#else
#define __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x)
#endif
```

Compatibility conclusion:

- `availability.pl` can be replaced by a compatibility generator for this use case
- the required input data already exists in the public SDK metadata
- the generator is deterministic and can be reproduced locally without modifying XNU

## availability.pl compatibility build-lab experiment

Temporary experiment performed:

- created a reversible SDK overlay at `/tmp/evos-sdk-overlay` in the macOS VM
- copied the public MacOSX SDK directory structure into the overlay by symlink
- installed a throwaway compatibility `availability.pl` at:
  - `/tmp/evos-sdk-overlay/usr/local/libexec/availability.pl`
- ran the XNU build from:
  - `/Users/khizhnik/Work/EvOS/xnu`
- used:
  - `SDKROOT=/tmp/evos-sdk-overlay`
  - `RC_DARWIN_KERNEL_VERSION=23.6.0`
- did not modify any upstream XNU files or Makefiles

What happened:

- the original `availability.pl` blocker was fully bypassed
- `_symbol_aliasing.h` was generated successfully
- the generated header was written to:
  - `/Users/khizhnik/Work/EvOS/xnu/BUILD/obj/bsd/sys/_symbol_aliasing.h`

Verification of generated output:

- the header exists
- it contains `__DARWIN_ALIAS_STARTING_*` macro definitions
- it is not empty or placeholder content

Next blocker observed:

- the overlay SDK was not a fully recognized SDK bundle
- `xcodebuild` reported:
  - `SDK "/tmp/evos-sdk-overlay" cannot be located`
- `xcrun` reported:
  - `unable to lookup item 'SDKVersion' in SDK '/tmp/evos-sdk-overlay'`
  - `unable to lookup item 'PlatformPath' in SDK '/tmp/evos-sdk-overlay'`
- the first failing XNU build stage after `_symbol_aliasing.h` generation was header generation for `clock.h`
- the visible compiler failure was:
  - `clang: error: invalid version number in '-mmacosx-version-min='`

Recommendation for the permanent solution:

- keep the `availability.pl` compatibility logic as a local build-lab fallback only
- for a durable fix, use a complete Apple SDK bundle that includes both:
  - the `availability.pl` helper
  - the SDK metadata plist files required by `xcodebuild` / `xcrun`
- if the goal is to keep the experiment reversible, the next minimal local step would be adding the missing `SDKSettings.plist` metadata into the overlay, not modifying XNU

## availability.pl real-SDK injection experiment

This follow-up experiment kept the original Apple SDKROOT intact.

What changed:

- `SDKROOT` remained set to:
  - `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`
- only the missing helper was injected at:
  - `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/local/libexec/availability.pl`
- no XNU source files or Makefiles were modified
- the helper was removed again after the run to keep the experiment reversible

Result:

- `_symbol_aliasing.h` was still generated successfully
- the build proceeded through MIG and IIG generation
- the next real blocker was no longer the missing helper or SDK metadata

First build failure after the helper injection:

- `clang: error: unknown argument: '-mach_msg2'`
- `mig: fatal: "<no name yet>", line -1: no SubSystem declaration`
- later compile failures also appeared in the same run:
  - `__builtin_clzg` / `__builtin_ctzg` not recognized by the active compiler
  - `bsd/dev/monotonic.c` `-Werror` failure
  - `pexpert/i386/pe_serial.c` `-Wunused-but-set-variable` failure

Interpretation:

- the metadata failure was self-inflicted by the temporary overlay SDK
- keeping the original SDKROOT intact avoids that problem
- the first blocker after the helper injection is now toolchain / source compatibility, not SDK metadata

Recommended next step:

- keep the real SDKROOT
- keep the compatibility `availability.pl` shim as a temporary local-only helper
- investigate the `mig` / compiler compatibility issue triggered by `-mach_msg2` before attempting any broader build changes

## mach_msg2 blocker analysis

Diagnostics collected:

- `clang` from the shell:
  - `/usr/bin/clang`
- `xcrun --find clang`:
  - `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang`
- `mig` from the shell:
  - `/usr/bin/mig`
- `xcrun --find mig`:
  - `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/mig`
- `xcrun --find migcom`:
  - `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/libexec/migcom`
- `type -a mig` on the VM:
  - `/usr/bin/mig`
- `type -a clang` on the VM:
  - `/usr/bin/clang`
- `xcodebuild -version`:
  - `Xcode 16.0`
  - `Build version 16A242d`
- `xcodebuild -showsdks` includes:
  - `macOS 15.0`
  - `DriverKit 24.0`

Where `-mach_msg2` comes from:

- [`makedefs/MakeInc.def`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/makedefs/MakeInc.def#L1172-L1175)
- It is part of `MIGKSFLAGS`:
  - `-DMACH_KERNEL_PRIVATE`
  - `-DKERNEL_SERVER=1`
  - `-mach_msg2`
- Consuming build rules:
  - [`osfmk/device/Makefile`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/device/Makefile#L77-L82)
  - [`osfmk/mach/Makefile`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/mach/Makefile#L451-L458)
  - [`osfmk/bank/Makefile`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/bank/Makefile#L118-L122)
  - [`osfmk/voucher/Makefile`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/voucher/Makefile#L112-L116)
  - [`osfmk/UserNotification/Makefile`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/UserNotification/Makefile#L74-L78)
  - [`osfmk/default_pager/Makefile`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/default_pager/Makefile#L114-L118)

What receives the flag:

- the XNU build invokes `$(MIG)` with `$(MIGKSFLAGS)`
- `make -pn` shows:
  - `MIG = /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/mig`
  - `MIGCOM = /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/libexec/migcom`
  - `MIGCC = /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang`
- the `mig` wrapper passes its `-target` argument straight into the compiler front-end, so `-mach_msg2` reaches `clang -E`
- compiler-only probe:
  - `xcrun clang -mach_msg2 -E -x c -`
  - result: `clang: error: unknown argument: '-mach_msg2'`

Conclusions:

- the wrong `mig` binary is not being used by the build
- XNU is using the Xcode 16.0 toolchain `mig`, `migcom`, and `clang`
- the immediate blocker is that the active clang rejects `-mach_msg2`
- this is a toolchain compatibility issue, not an SDK metadata issue

Smallest next experiment:

- run only a single compiler probe against any alternate Apple clang that may be available, or compare the same `-mach_msg2` probe against a newer Xcode toolchain if one becomes available
- no XNU source changes are required for this diagnostic step

## Sonoma tag build attempt

Switched checkout:

- tag: `xnu-10063.141.1`
- commit: `d8b80295118ef25ac3a784134bcf95cd8e88109f`

Current tree state before switch:

- only untracked build output was present in `BUILD/`
- no tracked source modifications were present

Toolchain confirmation:

- `xcode-select -p`:
  - `/Applications/Xcode.app/Contents/Developer`
- `xcodebuild -version`:
  - `Xcode 16.0`
  - `Build version 16A242d`
- `xcrun --find iig`:
  - `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/iig`
- `xcrun --find migcom`:
  - `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/libexec/migcom`
- `xcrun --sdk macosx --show-sdk-path`:
  - `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.0.sdk`

Build attempt:

- command:
  - `RC_DARWIN_KERNEL_VERSION=23.6.0 make SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" ARCH_CONFIGS=X86_64 KERNEL_CONFIGS=DEVELOPMENT`
- no availability.pl shim was needed in this run
- the build did not reach the earlier `-mach_msg2` failure

First real blocker after switching to the Sonoma tag:

- `make[5]: *** No rule to make target 'IOTypes.h', needed by '/Users/khizhnik/Work/EvOS/xnu/BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h'. Stop.`

Generated artifacts observed before failure:

- `BUILD/obj/SETUP/config/config`
- `BUILD/obj/SETUP/config/mkheaders.o`
- `BUILD/obj/SETUP/config/mkmakefile.o`
- `BUILD/obj/DEVELOPMENT_X86_64/osfmk/mach/clock.h`
- `BUILD/obj/DEVELOPMENT_X86_64/bsd/sys/syscall.h`
- `BUILD/obj/DEVELOPMENT_X86_64/bsd/sys/sysproto.h`
- `BUILD/obj/DEVELOPMENT_X86_64/iokit/DriverKit/IODataQueueDispatchSource.h`
- `BUILD/obj/DEVELOPMENT_X86_64/iokit/DriverKit/IOService.h`
- `BUILD/obj/EXPORT_HDRS/osfmk/mach/clock.h`
- `BUILD/obj/EXPORT_HDRS/osfmk/kern/clock.h`
- `BUILD/obj/EXPORT_HDRS/iokit/IOKit/IOTypes.h`
- `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h`

Conclusion:

- `xnu-10063.141.1` avoided the earlier `-mach_msg2` blocker in this run because the build failed earlier in DriverKit export-header generation
- `availability.pl` was not needed during this attempt
- the next blocker is a missing build rule / source packaging issue for `IOTypes.h` in the DriverKit export-header path
- the Sonoma tag is therefore closer to the VM toolchain, but the checkout still does not build cleanly without further investigation of the DriverKit export-header inputs

## IOTypes.h dependency investigation

References found:

- source header:
  - [`iokit/IOKit/IOTypes.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/IOKit/IOTypes.h)
- DriverKit build list reference:
  - [`iokit/DriverKit/Makefile`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/DriverKit/Makefile#L42-L52)
- exported IOKit header:
  - [`BUILD/obj/EXPORT_HDRS/iokit/IOKit/IOTypes.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/BUILD/obj/EXPORT_HDRS/iokit/IOKit/IOTypes.h)
- exported DriverKit header:
  - [`BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h)

Dependency graph:

```text
iokit/IOKit/IOTypes.h
  -> exported via generic install/export rules
  -> BUILD/obj/EXPORT_HDRS/iokit/IOKit/IOTypes.h
  -> consumed by many IOKit and osfmk headers

iokit/DriverKit/Makefile: OTHER_HEADERS += IOTypes.h
  -> generic export/install machinery expects a local source file named IOTypes.h in the DriverKit component
  -> BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h
```

Exact missing edge:

- `iokit/DriverKit/Makefile` names `IOTypes.h` in `OTHER_HEADERS`
- the generic rule in [`makedefs/MakeInc.rule`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/makedefs/MakeInc.rule#L440-L441) exports `$(EXPORT_MI_GEN_LIST)` from a prerequisite named exactly `IOTypes.h`
- there is no source file `iokit/DriverKit/IOTypes.h`
- the only source copy is `iokit/IOKit/IOTypes.h`
- therefore make cannot resolve the prerequisite chain for `/Users/khizhnik/Work/EvOS/xnu/BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h`

Why make reports "No rule to make target":

- the build system is treating `IOTypes.h` as a local DriverKit header input
- the current directory for that component does not provide such a file
- there is no alternate rule in the Sonoma-tag tree that maps `iokit/IOKit/IOTypes.h` into the DriverKit export-header path
- the target is not missing because of Xcode 16 behavior; the source/layout mismatch is already visible in the repository tree

What exists where:

- repository source path:
  - `iokit/IOKit/IOTypes.h`
- expected DriverKit build input path:
  - `iokit/DriverKit/IOTypes.h`
- generated/copy artifact already present:
  - `BUILD/obj/EXPORT_HDRS/iokit/IOKit/IOTypes.h`
- generated DriverKit export artifact already present from prior progress:
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h`

Smallest reversible experiment:

- create a temporary local symlink or copy from `iokit/IOKit/IOTypes.h` to `iokit/DriverKit/IOTypes.h` and rerun only the DriverKit export-header step
- this would test whether the build is missing only the file placement edge, without changing XNU source or Makefiles
- no patching was performed in this investigation

## IOTypes.h history investigation

Repository history checks:

- `git log --all -- iokit/DriverKit/IOTypes.h`
  - history exists and reaches back through older tags
- `git log --all -- iokit/IOKit/IOTypes.h`
  - long history exists and is the currently present source header

Tag presence matrix around `xnu-10063.*`:

| Tag | `iokit/DriverKit/IOTypes.h` | `iokit/DriverKit/Makefile` references `OTHER_HEADERS += IOTypes.h` |
| --- | --- | --- |
| `xnu-10063.101.15` | yes | yes |
| `xnu-10063.121.3` | yes | yes |
| `xnu-10063.141.1` | no | yes |

Interpretation:

- `iokit/DriverKit/IOTypes.h` existed historically in earlier Sonoma-era tags.
- It was present in `xnu-10063.101.15` and `xnu-10063.121.3`.
- It is absent in `xnu-10063.141.1`.
- The DriverKit Makefile still references `IOTypes.h` in `OTHER_HEADERS` in `xnu-10063.141.1`.
- That means the Makefile reference outlived the file in this checkout.

Makefile timeline:

- `iokit/DriverKit/Makefile` already referenced `OTHER_HEADERS = IOTypes.h ...` in the historical tags checked.
- The reference is present in both the older Sonoma tags and the current `xnu-10063.141.1`.

Conclusion:

- the repository is internally inconsistent for this build path
- the file was removed from `iokit/DriverKit/` but the Makefile still expects a local DriverKit header input named `IOTypes.h`
- the current tree therefore has a stale dependency edge rather than a toolchain regression
- the smallest reversible experiment remains a local temporary copy or symlink, but no workaround was applied here

## IOTypes.h validation experiment

Temporary experiment performed:

- created a temporary symlink:
  - `iokit/DriverKit/IOTypes.h -> ../IOKit/IOTypes.h`
- verified the link target with `readlink`
- reran the Sonoma-tag build without changing any Makefiles or source files
- removed the symlink after the run

Result:

- the original `IOTypes.h` blocker was resolved
- the build progressed further into DriverKit export-header generation
- generated DriverKit export artifacts included:
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOReturn.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IORPC.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOService.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/OSObject.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOUserClient.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOWorkGroup.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/OSAction.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOBufferMemoryDescriptor.h`

First new failure:

- `make[5]: *** No rule to make target 'IOReturn.h', needed by '/Users/khizhnik/Work/EvOS/xnu/BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOReturn.h'. Stop.`

Interpretation:

- the DriverKit `IOTypes.h` dependency edge was the first missing file in the chain
- once that link was satisfied, the build advanced to the next missing DriverKit header input
- the DriverKit export-header list appears to depend on multiple local headers that are no longer present in the Sonoma tag checkout

Cleanup:

- the temporary symlink was removed after the run
- no permanent repository changes were made

<a id="fix-f002"></a>
## DriverKit OTHER_HEADERS consistency analysis

`iokit/DriverKit/Makefile` currently lists:

```text
IOTypes.h IOReturn.h IORPC.h IOKitKeys.h IOKernelReportStructs.h IOReportTypes.h
queue_implementation.h macro_help.h bounded_ptr.h bounded_array.h bounded_array_ref.h bounded_ptr_fwd.h
OSBoundedArray.h OSBoundedArrayRef.h OSBoundedPtr.h OSBoundedPtrFwd.h safe_allocation.h
```

Current-tree matrix:

| Header | `iokit/DriverKit/` | `iokit/IOKit/` | Elsewhere in repo | `xnu-10063.101.15` | `xnu-10063.121.3` | `xnu-10063.141.1` | Historical DriverKit vs IOKit |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IOTypes.h` | no | yes | yes | yes | yes | no | same |
| `IOReturn.h` | no | yes | yes | yes | yes | no | same |
| `IORPC.h` | no | yes | yes | yes | yes | no | same |
| `IOKitKeys.h` | no | yes | yes | yes | yes | no | same |
| `IOKernelReportStructs.h` | no | yes | yes | yes | yes | no | same |
| `IOReportTypes.h` | no | yes | yes | yes | yes | no | same |
| `queue_implementation.h` | no | no | no | yes | yes | no | n/a |
| `macro_help.h` | no | no | no | yes | yes | no | n/a |
| `bounded_ptr.h` | no | no | no | yes | yes | no | n/a |
| `bounded_array.h` | no | no | no | yes | yes | no | n/a |
| `bounded_array_ref.h` | no | no | no | yes | yes | no | n/a |
| `bounded_ptr_fwd.h` | no | no | no | yes | yes | no | n/a |
| `OSBoundedArray.h` | no | no | no | yes | yes | no | n/a |
| `OSBoundedArrayRef.h` | no | no | no | yes | yes | no | n/a |
| `OSBoundedPtr.h` | no | no | no | yes | yes | no | n/a |
| `OSBoundedPtrFwd.h` | no | no | no | yes | yes | no | n/a |
| `safe_allocation.h` | no | no | no | yes | yes | no | n/a |

What this means:

- the full `OTHER_HEADERS` set is stale in `xnu-10063.141.1`
- the entire group existed in earlier Sonoma tags and was removed from `iokit/DriverKit/` by `xnu-10063.141.1`
- the first six headers are byte-identical to `iokit/IOKit/` copies in the earlier Sonoma tags
- the remaining eleven headers were only present in `iokit/DriverKit/` historically and have no current repo counterpart
- this is therefore both:
  - a stale Makefile list, and
  - a source packaging regression for the removed DriverKit headers

Exact missing edge:

- `make` expects each entry in `OTHER_HEADERS` to exist locally under `iokit/DriverKit/`
- `xnu-10063.141.1` no longer contains those files there
- the generic export rule still tries to install them into `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/`

Safety of a temporary compatibility layer:

- yes, it is reasonable to test a temporary compatibility header layer
- the safest reversible shape is:
  - symlink or copy the first six headers from `iokit/IOKit/`
  - restore the remaining eleven from the historical Sonoma tag contents into a temporary overlay
- do not patch the repository itself

Smallest reversible validation plan:

1. Create a temporary header overlay for `iokit/DriverKit/`.
2. Map the first six headers to `iokit/IOKit/` copies.
3. Rehydrate the remaining eleven from `xnu-10063.121.3` or `xnu-10063.101.15` into the overlay only.
4. Rerun only the DriverKit export-header stage.
5. Stop at the next distinct failure.

No workaround was executed as part of this investigation.

## Notes

- This investigation is only about source checkout, build prerequisites, and the first build attempt.
- It does not imply Darwin bootability.
- It does not attempt to boot any produced kernel.

## DriverKit compatibility layer experiment

Temporary overlay created outside the repository:

- `/tmp/evos-driverkit-overlay`

Overlay structure:

```text
/tmp/evos-driverkit-overlay/DriverKit/IOTypes.h
/tmp/evos-driverkit-overlay/DriverKit/IOReturn.h
/tmp/evos-driverkit-overlay/DriverKit/IORPC.h
/tmp/evos-driverkit-overlay/DriverKit/IOKitKeys.h
/tmp/evos-driverkit-overlay/DriverKit/IOKernelReportStructs.h
/tmp/evos-driverkit-overlay/DriverKit/IOReportTypes.h
/tmp/evos-driverkit-overlay/DriverKit/queue_implementation.h
/tmp/evos-driverkit-overlay/DriverKit/macro_help.h
/tmp/evos-driverkit-overlay/DriverKit/bounded_ptr.h
/tmp/evos-driverkit-overlay/DriverKit/bounded_array.h
/tmp/evos-driverkit-overlay/DriverKit/bounded_array_ref.h
/tmp/evos-driverkit-overlay/DriverKit/bounded_ptr_fwd.h
/tmp/evos-driverkit-overlay/DriverKit/OSBoundedArray.h
/tmp/evos-driverkit-overlay/DriverKit/OSBoundedArrayRef.h
/tmp/evos-driverkit-overlay/DriverKit/OSBoundedPtr.h
/tmp/evos-driverkit-overlay/DriverKit/OSBoundedPtrFwd.h
/tmp/evos-driverkit-overlay/DriverKit/safe_allocation.h
```

Overlay mapping:

- copied from current `iokit/IOKit/`:
  - `IOTypes.h`
  - `IOReturn.h`
  - `IORPC.h`
  - `IOKitKeys.h`
  - `IOKernelReportStructs.h`
  - `IOReportTypes.h`
- restored from `xnu-10063.121.3`:
  - `queue_implementation.h`
  - `macro_help.h`
  - `bounded_ptr.h`
  - `bounded_array.h`
  - `bounded_array_ref.h`
  - `bounded_ptr_fwd.h`
  - `OSBoundedArray.h`
  - `OSBoundedArrayRef.h`
  - `OSBoundedPtr.h`
  - `OSBoundedPtrFwd.h`
  - `safe_allocation.h`

Validation attempts:

- attempted to drive the DriverKit export-header phase from the overlay using the existing XNU make rules
- attempted top-level recursion and DriverKit-only recursion with the overlay source path
- the build never reached a clean DriverKit-only export-header pass

First blocker encountered in the compatibility-layer attempt:

- `make[1]: /tmp/evos-driverkit-overlay/IOKit/Makefile: No such file or directory`
- this came from the recursive build plumbing still trying to enter `IOKit` even though the overlay only contained `DriverKit`

Conclusion so far:

- the overlay contents themselves are complete for the 17-header DriverKit set
- the remaining issue is build invocation plumbing, not header availability
- the experiment did not yet validate the DriverKit export phase because the recursion still pulled in `IOKit`

Recommendation:

- next reversible step, if continued, is to supply a minimal overlay stub for `IOKit/Makefile` or otherwise isolate the DriverKit submake invocation so recursion no longer enters `IOKit`
- no repository changes were made
- no symlink workaround was added to the repo

## DriverKit compatibility layer experiment

Temporary disposable worktree:

- `/tmp/evos-xnu-lab`

Worktree creation:

```bash
cd ~/Work/EvOS/xnu
git worktree add --detach /tmp/evos-xnu-lab xnu-10063.141.1
```

Restored DriverKit headers inside the worktree only:

- copied from current `iokit/IOKit/`:
  - `IOTypes.h`
  - `IOReturn.h`
  - `IORPC.h`
  - `IOKitKeys.h`
  - `IOKernelReportStructs.h`
  - `IOReportTypes.h`
- restored from `xnu-10063.121.3`:
  - `queue_implementation.h`
  - `macro_help.h`
  - `bounded_ptr.h`
  - `bounded_array.h`
  - `bounded_array_ref.h`
  - `bounded_ptr_fwd.h`
  - `OSBoundedArray.h`
  - `OSBoundedArrayRef.h`
  - `OSBoundedPtr.h`
  - `OSBoundedPtrFwd.h`
  - `safe_allocation.h`

Build command used in the disposable worktree:

```bash
cd /tmp/evos-xnu-lab
RC_DARWIN_KERNEL_VERSION=23.6.0 \
make SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
ARCH_CONFIGS=X86_64 \
KERNEL_CONFIGS=DEVELOPMENT
```

Observed result:

- the DriverKit header blockers disappeared once the 17 headers were restored in the worktree
- the build advanced well past the previous `IOTypes.h` / `IOReturn.h` failures
- generated artifacts included:
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOReturn.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IORPC.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOService.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOUserClient.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOWorkGroup.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/OSAction.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOBufferMemoryDescriptor.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IODataQueueDispatchSource.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IODMACommand.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IODispatchQueue.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IODispatchSource.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOEventLink.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOExtensiblePaniclog.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOInterruptDispatchSource.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOMemoryDescriptor.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOMemoryMap.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOServiceNotificationDispatchSource.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOServiceStateNotificationDispatchSource.h`
  - `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOUserServer.h`
  - `BUILD/obj/DEVELOPMENT_X86_64/...` setup and generated headers

First distinct new failure:

- `pexpert/i386/pe_serial.c:403:11: error: variable 'register_read' set but not used [-Werror,-Wunused-but-set-variable]`
- final failing target chain included:
  - `make[7]: *** [monotonic.o] Error 1`
  - `make[7]: *** [pe_serial.o] Error 1`
  - `make[6]: *** [build_all] Error 2`
  - `make[5]: *** [do_all] Error 2`
  - `make[4]: *** [build_all] Error 2`
  - `make[3]: *** [build_all_recurse_into_conf] Error 2`
  - `make[2]: *** [build_all_recurse_into_pexpert] Error 2`
  - `make[2]: *** [build_all_recurse_into_bsd] Error 2`
  - `make[1]: *** [build_all_bootstrap_DEVELOPMENT^X86_64^NONE] Error 2`
  - `make: *** [all] Error 2`

Conclusion:

- the DriverKit header regressions were bypassed successfully in a disposable worktree
- the next blocker is unrelated to the DriverKit packaging issue
- the original checkout was not modified
- the worktree is disposable and can be deleted after the investigation

## pe_serial.c unused variable investigation

Observed failure:

- `pexpert/i386/pe_serial.c:403:11: error: variable 'register_read' set but not used [-Werror,-Wunused-but-set-variable]`

Source inspection:

- `register_read` is declared in `lpss_uart_re_init(void)` at line 403
- it is assigned repeatedly after each MMIO write:
  - `MMIO_READ(RST)`
  - `MMIO_READ(LCR)`
  - `MMIO_READ(DLL)`
  - `MMIO_READ(DLM)`
  - `MMIO_READ(FCR)`
  - `MMIO_READ(LCR)`
  - `MMIO_READ(MCR)`
  - `MMIO_READ(CLK)`
  - `MMIO_READ(CLK)`
- there are no reads of `register_read` anywhere in the function or the file
- the assignments appear to exist only as discarded MMIO reads

History check:

- `git log -S 'register_read' -- pexpert/i386/pe_serial.c` shows the variable was introduced in:
  - `cc9a635524` / `xnu-4903.221.2`
- later XNU tags inspected here, including:
  - `xnu-11215.81.4`
  - `xnu-12377.101.15`
  keep the same declaration and assignment pattern
- no later fix was found in the public XNU history inspected here

Root cause:

- this is a source bug that has existed for multiple XNU generations
- newer clang diagnostics now flag the pattern as `-Wunused-but-set-variable`
- XNU’s `-Werror` policy turns that warning into a hard build failure

Assessment:

- the variable is genuinely unused from the compiler’s perspective
- no hidden preprocessor-dependent read was found
- the failure is caused by a compiler warning becoming fatal, not by a missing SDK or a missing target file

Recommended minimal fix:

- keep the discarded MMIO reads but avoid the unused-variable diagnostic
- the smallest source-level change would be to cast each MMIO read to `(void)` or remove the temporary variable entirely if the read side effect is all that is needed

Recommended build-system fix:

- do not disable `-Werror` globally
- if a toolchain compatibility workaround is needed, scope it narrowly to this file or guard it by compiler version
- the cleaner long-term fix is still a source cleanup in `pe_serial.c`

<a id="fix-f003"></a>
## pe_serial.c validation fix

Temporary worktree used:

- `/tmp/evos-xnu-lab`

Exact source diff applied only in the disposable worktree:

```diff
diff --git a/pexpert/i386/pe_serial.c b/pexpert/i386/pe_serial.c
index 5e62f293f..61016c456 100644
--- a/pexpert/i386/pe_serial.c
+++ b/pexpert/i386/pe_serial.c
@@ -400,34 +400,33 @@ lpss_uart_enable( boolean_t on_off )
 static void
 lpss_uart_re_init( void )
 {
-	uint32_t register_read;
 
 	MMIO_WRITE(RST, 0x7);                   /* LPSS UART2 controller out of reset */
-	register_read = MMIO_READ(RST);
+	(void)MMIO_READ(RST);
 
 	MMIO_WRITE(LCR, UART_LCR_DLAB);         /* Set DLAB bit to enable reading/writing of DLL, DLH */
-	register_read = MMIO_READ(LCR);
+	(void)MMIO_READ(LCR);
 
 	MMIO_WRITE(DLL, 1);                     /* Divisor Latch Low Register */
-	register_read = MMIO_READ(DLL);
+	(void)MMIO_READ(DLL);
 
 	MMIO_WRITE(DLM, 0);                     /* Divisor Latch High Register */
-	register_read = MMIO_READ(DLM);
+	(void)MMIO_READ(DLM);
 
 	MMIO_WRITE(FCR, 1);                     /* Enable FIFO */
-	register_read = MMIO_READ(FCR);
+	(void)MMIO_READ(FCR);
 
 	MMIO_WRITE(LCR, UART_LCR_8BITS);        /* Set 8 bits, clear DLAB */
-	register_read = MMIO_READ(LCR);
+	(void)MMIO_READ(LCR);
 
 	MMIO_WRITE(MCR, UART_MCR_RTS);          /* Request to send */
-	register_read = MMIO_READ(MCR);
+	(void)MMIO_READ(MCR);
 
 	MMIO_WRITE(CLK, UART_CLK_125M_1);       /* 1.25M Clock speed */
-	register_read = MMIO_READ(CLK);
+	(void)MMIO_READ(CLK);
 
 	MMIO_WRITE(CLK, UART_CLK_125M_2);       /* 1.25M Clock speed */
-	register_read = MMIO_READ(CLK);
+	(void)MMIO_READ(CLK);
 }
```

Result:

- the `pe_serial.c` warning is resolved in the disposable worktree
- the build advanced past `pexpert/i386/pe_serial.c`
- the next distinct failure returned to the known XNU toolchain/MIG issue:
  - `clang: error: unknown argument: '-mach_msg2'`
  - `mig: fatal: "<no name yet>", line -1: no SubSystem declaration`
- the run also produced additional unrelated `-Werror` failures in `OSMetaClass.h`, but those were not the first blocker in the run

Generated artifacts seen before the next blocker:

- `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/*` from the restored DriverKit header set
- `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSMetaClass.h`
- `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSObject.h`
- `BUILD/obj/EXPORT_HDRS/osfmk/kern/*`
- `BUILD/obj/DEVELOPMENT_X86_64/*`

Conclusion:

- the smallest source fix for `pe_serial.c` is valid and reversible
- it removes the `register_read` warning without changing MMIO side effects
- after that fix, the next blocker is not `pe_serial.c` anymore

## mach_msg2 compatibility plan

Inspection of the Xcode MIG wrapper:

- `xcrun --find mig` resolves to:
  - `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/mig`
- the wrapper script delegates preprocessing to clang and then to `migcom`
- the wrapper does **not** define `-mach_msg2` as a supported option
- unknown `-*` options are forwarded into the clang preprocessor argument list

Probe results:

- `xcrun mig -help 2>&1 | grep -i mach` produced no `mach`-related option output
- `xcrun migcom -help 2>&1 | grep -i mach` produced no `mach`-related option output
- `printf '' | xcrun clang -E -x c -mach_msg2 -` fails with:
  - `clang: error: unknown argument: '-mach_msg2'`

XNU make-side origin:

- [`makedefs/MakeInc.def`](file:///home/khizhnik/Work/PROJECTS/EvOS/xnu/makedefs/MakeInc.def#L928-L931) defines:
  - `MIGKSFLAGS = -DMACH_KERNEL_PRIVATE -DKERNEL_SERVER=1 -mach_msg2`
- that variable is consumed by MIG-based kernel-server generation rules in:
  - `osfmk/device/Makefile`
  - `osfmk/mach/Makefile`
  - `osfmk/bank/Makefile`
  - `osfmk/default_pager/Makefile`
  - `osfmk/UserNotification/Makefile`
  - `osfmk/voucher/Makefile`

Assessment:

- `-mach_msg2` is introduced by XNU’s build configuration, not by `migcom`
- the Xcode MIG wrapper treats it as an unrecognized compiler flag and passes it to clang
- on this toolchain, clang rejects the flag immediately, which prevents MIG from finishing
- the failure is therefore a toolchain / build-configuration mismatch, not a missing helper binary

What happens if `-mach_msg2` is removed:

- MIG should still run, because the wrapper still invokes clang + migcom with the remaining flags
- the build may generate the legacy `mach_msg` path instead of the `mach_msg2` path for kernel server stubs
- this is the smallest reversible compatibility probe for `xnu-10063.141.1` x86_64 DEVELOPMENT on Xcode 16.0

Smallest reversible validation plan:

1. Run a one-off build with a command-line override for `MIGKSFLAGS` that removes only `-mach_msg2`.
2. Keep `SDKROOT`, `RC_DARWIN_KERNEL_VERSION`, and the rest of the build command unchanged.
3. Observe whether MIG completes and whether the generated server stubs differ only in `mach_msg` versus `mach_msg2` handling.
4. Stop at the first new blocker and compare it against the current failure.

Current recommendation:

- test the `MIGKSFLAGS` override before considering any source edit
- do not patch Makefiles yet
- do not disable `-Werror`

## mach_msg2 override experiment

Disposable worktree used:

- `/tmp/evos-xnu-lab`

Exact command:

```bash
cd /tmp/evos-xnu-lab
RC_DARWIN_KERNEL_VERSION=23.6.0 \
MIGKSFLAGS="-DMACH_KERNEL_PRIVATE -DKERNEL_SERVER=1" \
make SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
  ARCH_CONFIGS=X86_64 \
  KERNEL_CONFIGS=DEVELOPMENT
```

Result:

- the build still reaches MIG generation paths and header generation
- the specific `-mach_msg2` probe did **not** become the first failure in this run
- the build did still emit the same `clang: error: unknown argument: '-mach_msg2'` and `mig: fatal: "<no name yet>", line -1: no SubSystem declaration` messages while generating `device_server.h` / `device_server.c`
- after that, the first distinct new failure in the run was:
  - `libkern/os/log.c:38:10: fatal error: 'os/firehose_buffer_private.h' file not found`
  - followed by an error in `log.o`

Interpretation:

- the `MIGKSFLAGS` environment override was not sufficient to suppress the `-mach_msg2` path in all build invocations
- the current build plumbing likely injects or recomputes `MIGKSFLAGS` in at least one sub-make, so a one-line environment override is not a complete compatibility fix
- MIG itself still runs, but the toolchain mismatch remains visible in the device-server generation step

Generated artifacts before the next blocker included:

- `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSMetaClass.h`
- `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSObject.h`
- `BUILD/obj/EXPORT_HDRS/osfmk/kern/*`
- `BUILD/obj/DEVELOPMENT_X86_64/*`

Recommendation:

- the smallest durable fix is likely a narrow build-rule override for the specific MIG invocations that still append `-mach_msg2`
- if the goal is only to validate the compatibility path, the next experiment should inspect the expanded `MIG` command lines for the offending sub-make rather than changing source or disabling `Werror`

## mach_msg2 command trace

Search results in the disposable worktree:

```text
./makedefs/MakeInc.def:931:	-mach_msg2
```

Generated make database with the temporary environment override:

```bash
RC_DARWIN_KERNEL_VERSION=23.6.0 \
MIGKSFLAGS="-DMACH_KERNEL_PRIVATE -DKERNEL_SERVER=1" \
make -pn SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
  ARCH_CONFIGS=X86_64 \
  KERNEL_CONFIGS=DEVELOPMENT
```

Key `make -pn` observations:

- `MIGKSFLAGS` still expands to:
  - `-DMACH_KERNEL_PRIVATE -DKERNEL_SERVER=1 -mach_msg2`
- the expanded recipe lines for the MIG-generated files still use:
  - `${MIG} ${MIGFLAGS} ${MIGKSFLAGS}`
- the relevant commands are the `device_server.h` and `device_server.c` rules:
  - `device_server.c: device.defs`
  - `device_server.h: device.defs`
- the make database shows the override is not sticking across the recursive make context

Interpretation:

- the remaining `-mach_msg2` is sourced from `makedefs/MakeInc.def`
- the top-level environment override is being superseded by recursive make evaluation rather than by a generated artifact or stale command file
- no generated BUILD artifact was found containing `-mach_msg2`; the remaining source is live make logic

Exact command line where it appears:

- the active device-server MIG rule is still expanding through `${MIG} ${MIGFLAGS} ${MIGKSFLAGS}`
- because `MIGKSFLAGS` resolves to include `-mach_msg2`, the effective command line still contains that flag when `device_server.h` / `device_server.c` are generated

Stale artifact assessment:

- unlikely
- the grep search only found the live definition in `makedefs/MakeInc.def`
- the make database confirms the flag is reintroduced by make evaluation, not pulled from an old output file

Smallest reversible experiment to remove `-mach_msg2` everywhere:

1. Probe a lower-level recursive make target and override `MIGKSFLAGS` on that invocation only, to see whether the sub-make still resets it.
2. If it still reappears, the next step is a disposable-worktree-only edit of `makedefs/MakeInc.def` to remove `-mach_msg2` from the temporary lab copy.
3. Do not patch the original checkout yet and do not change `Werror`.

<a id="fix-f005"></a>
## mach_msg2 disposable MakeInc.def experiment

Temporary worktree used:

- `/tmp/evos-xnu-lab`

Exact source diff applied only in the disposable worktree:

```diff
diff --git a/makedefs/MakeInc.def b/makedefs/MakeInc.def
index c66add18d..82b4a980c 100644
--- a/makedefs/MakeInc.def
+++ b/makedefs/MakeInc.def
@@ -928,7 +928,6 @@ MIGFLAGS	= $(DEFINES) $(INCFLAGS) -novouchers $($(addsuffix $(CURRENT_ARCH_CONFI
 MIGKSFLAGS = \
 	-DMACH_KERNEL_PRIVATE \
 	-DKERNEL_SERVER=1 \
-	-mach_msg2
 
 #
 # Default MIG KernelUser flags
```

Verification:

```bash
grep -RIn -- "-mach_msg2" /tmp/evos-xnu-lab/makedefs /tmp/evos-xnu-lab/BUILD 2>/dev/null || true
```

Result:

- no output after the edit
- the `-mach_msg2` blocker was resolved in the disposable worktree
- `device_server.h` and `device_server.c` were generated again
- the build advanced beyond MIG kernel-server generation
- the next distinct blocker became:
  - `/tmp/evos-xnu-lab/libkern/os/log.c:38:10: fatal error: 'os/firehose_buffer_private.h' file not found`
  - with the failing target chain including `log.o`

Generated artifacts observed before the next blocker:

- `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSMetaClass.h`
- `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSObject.h`
- `BUILD/obj/EXPORT_HDRS/osfmk/kern/*`
- `BUILD/obj/DEVELOPMENT_X86_64/*`
- `device_server.h`
- `device_server.c`

Conclusion:

- the previous `-mach_msg2` failure was real, not stale
- removing it from the disposable worktree’s `MIGKSFLAGS` is sufficient to get past the MIG wrapper/clang mismatch
- the next blocker is unrelated and should be investigated separately

## firehose_buffer_private.h investigation

References found in the disposable worktree:

- `libkern/os/log.c`
  - `#include <os/firehose_buffer_private.h>`
  - `#include <os/firehose.h>`
  - `#include <os/log_private.h>`
- `libkern/c++/OSKext.cpp`
  - also includes `<os/firehose_buffer_private.h>`
- `bsd/kern/subr_log.c`
  - includes the firehose kernel-private headers, but not `os/firehose_buffer_private.h`
- the firehose kernel-private subtree exists in XNU:
  - `libkern/firehose/private.h`
  - `libkern/firehose/firehose_types_private.h`
  - `libkern/firehose/chunk_private.h`
  - `libkern/firehose/ioctl_private.h`
  - `libkern/firehose/tracepoint_private.h`

Local file search:

- no `firehose_buffer_private.h` exists anywhere in the disposable worktree
- no matching file exists under the active Xcode SDK path
- no matching file name appears in public XNU history
- the exact `git log` searches for the header returned no commits

Interpretation:

- this header is not part of the public XNU source tree
- it is not provided by the installed public macOS SDK
- it is not part of the public `libkern/firehose` subtree
- the include name strongly suggests an Apple-private logging/firehose support header, likely shipped in an internal/private SDK or private Apple logging package rather than a public OSS distribution

Root cause:

- `libkern/os/log.c` depends on a private firehose-buffer definition header that is absent from the public XNU checkout and the installed SDK
- the current build is now reaching a userspace/kernel logging integration boundary where public headers are insufficient

Likely source package:

- Apple private SDK / internal logging support package
- possibly the private portion of the libplatform / os_log / firehose header set
- not libdispatch and not the public XNU firehose subtree

Can `log.c` build without it?

- not as-is for this configuration
- the source includes the header directly, so either a compatibility header or a source-side conditional would be needed to proceed
- a clean validation step would be to create a disposable local compatibility header that provides only the types and declarations needed by `libkern/os/log.c`

Smallest reversible validation experiment:

1. Add a temporary compatibility header only in `/tmp/evos-xnu-lab` under the expected include path `os/firehose_buffer_private.h`.
2. Populate only the minimum declarations needed by `libkern/os/log.c` and `libkern/c++/OSKext.cpp`.
3. Rebuild only until the next failure.
4. Remove the compatibility header after the run.

Conclusion:

- the missing header is a private Apple logging/firehose support artifact, not a public SDK header
- the current blocker is therefore another packaging regression or private-SDK dependency gap
- the next experiment should be a disposable compatibility header, not a source edit in the original checkout

## firehose dependency map

Consumer files:

- [`libkern/os/log.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/libkern/os/log.c)
- [`libkern/c++/OSKext.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/libkern/c++/OSKext.cpp)
- [`bsd/kern/subr_log.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/bsd/kern/subr_log.c)

What already exists elsewhere:

- `firehose_buffer_t`, `firehose_push_reply_t`, `firehose_buffer_map_info_t` are already in [`libkern/firehose/firehose_types_private.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/libkern/firehose/firehose_types_private.h)
- `__firehose_buffer_push_to_logd`, `__firehose_allocate`, `__firehose_critical_region_enter`, `__firehose_critical_region_leave` are already in [`libkern/os/firehose.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/libkern/os/firehose.h)
- `firehose_chunk_t`, `firehose_chunk_for_address`, and `FIREHOSE_CHUNK_SIZE` are already in [`libkern/firehose/chunk_private.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/libkern/firehose/chunk_private.h)
- `firehose_tracepoint_id_u`, `firehose_tracepoint_flags_t`, `FIREHOSE_TRACE_ID_MAKE`, and related tracepoint macros are already in [`libkern/firehose/tracepoint_private.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/libkern/firehose/tracepoint_private.h)
- `OSKext.cpp` does not directly reference any unique symbol from the missing header; its include is transitive/common firehose plumbing

Exact missing declarations still required from `os/firehose_buffer_private.h`:

| Symbol | Source file | First use location | Possible replacement |
| --- | --- | --- | --- |
| `struct firehose_buffer_range_s` | `libkern/os/log.c` | `sizeof(struct firehose_buffer_range_s)` at line 943, initializer at line 1001 | Small local struct shim with `fbr_offset` and `fbr_length` |
| `FIREHOSE_BUFFER_KERNEL_CHUNK_COUNT` | `libkern/os/log.c` | line 1129 | Private constant from historical/private header; no public replacement found |
| `FIREHOSE_BUFFER_KERNEL_DEFAULT_CHUNK_COUNT` | `bsd/kern/subr_log.c` | lines 136, 511, 518 | Private constant from historical/private header; no public replacement found |
| `FIREHOSE_BUFFER_KERNEL_DEFAULT_IO_PAGES` | `bsd/kern/subr_log.c` | lines 138, 514, 519 | Private constant from historical/private header; no public replacement found |
| `__firehose_buffer_tracepoint_reserve(...)` | `libkern/os/log.c` | line 949 | No public replacement; declaration-only shim can unblock compilation |
| `__firehose_buffer_tracepoint_flush(...)` | `libkern/os/log.c` | line 983 | No public replacement; declaration-only shim can unblock compilation |
| `__firehose_merge_updates(...)` | `bsd/kern/subr_log.c` | line 487 | No public replacement; declaration-only shim can unblock compilation |
| `__firehose_kernel_configuration_valid(...)` | `bsd/kern/subr_log.c` | line 516 | No public replacement; declaration-only shim can unblock compilation |
| `__firehose_buffer_create(...)` | `bsd/kern/subr_log.c` | line 529 | No public replacement; declaration-only shim can unblock compilation |

Assessment:

- the missing header is mostly declarations plus one tiny public struct definition
- the two buffer-size constants appear to be private SPI values, not public SDK material
- the helper functions are not declared anywhere else in the public tree

Estimated shim size:

- **tiny** for a compile-only probe: about 20-40 lines if it only forwards declarations and the `firehose_buffer_range_s` struct
- **medium** if it also needs compatibility constants and comments
- **full implementation** is not indicated yet by the current evidence

Recommendation:

- build a temporary declaration-only compatibility header in the disposable worktree first
- keep it minimal and let the next compile or link failure tell us whether additional private SPI is needed

<a id="fix-f006"></a>
## firehose shim validation

Temporary shim locations used in the disposable worktree:

- `/tmp/evos-xnu-lab/BUILD/obj/EXPORT_HDRS/libkern/os/firehose_buffer_private.h`
- `/tmp/evos-xnu-lab/BUILD/obj/EXPORT_HDRS/os/firehose_buffer_private.h`
- `/tmp/evos-xnu-lab/os/firehose_buffer_private.h`

Shim contents:

- `struct firehose_buffer_range_s` with `fbr_offset` and `fbr_length`
- `FIREHOSE_BUFFER_KERNEL_DEFAULT_CHUNK_COUNT`
- `FIREHOSE_BUFFER_KERNEL_CHUNK_COUNT`
- `FIREHOSE_BUFFER_KERNEL_DEFAULT_IO_PAGES`
- forward declarations for:
  - `__firehose_buffer_tracepoint_reserve`
  - `__firehose_buffer_tracepoint_flush`
  - `__firehose_merge_updates`
  - `__firehose_kernel_configuration_valid`
  - `__firehose_buffer_create`

Validation result:

- the missing `os/firehose_buffer_private.h` blocker was bypassed in the disposable worktree
- `libkern/os/log.c` progressed past the missing-header error
- `libkern/c++/OSKext.cpp` no longer hit the missing-header error in the observed build output
- `bsd/kern/subr_log.c` no longer hit the missing-header error in the observed build output
- the next distinct blocker became unrelated to firehose:
  - `bsd/dev/i386/fasttrap_isa.c:665:6: error: variable 'retire_tp' set but not used [-Werror,-Wunused-but-set-variable]`

Interpretation:

- this strongly suggests `os/firehose_buffer_private.h` was a declaration-gap problem, not a missing implementation problem
- the temporary compatibility header was sufficient to move the build past the firehose include boundary

Recommendation:

- keep the shim only for lab validation
- if the goal is a durable solution, the next step is to compare the shim against the private Apple package layout and then decide whether to preserve it as a local build overlay or replace it with the real private header source

<a id="fix-f004"></a>
## fasttrap_isa unused variable investigation

`retire_tp` in `bsd/dev/i386/fasttrap_isa.c` was a straight dead store in `fasttrap_return_common()`.

Findings:

- declaration: `int retire_tp = 1;`
- assignment: `retire_tp = 0;` in the non-oneshot branch
- reads: none in `fasttrap_return_common()`
- history: introduced with the `xnu-4570.1.46` import, and the same pattern remains present in later public tags such as `xnu-12377.101.15`

Conclusion:

- this is a genuine source bug exposed by modern clang's `-Wunused-but-set-variable`
- the bug is not hidden behind a preprocessor branch in the affected function
- the smallest disposable-only fix was to remove the declaration and the dead assignment while preserving the surrounding DTrace/MMIO control flow
- after that fix, the build advanced past `fasttrap_isa.c`
- the next distinct blocker in the disposable worktree was `-Wsuggest-override` errors in `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSMetaClass.h`, with a later concurrent fatal include failure in `libkern/amfi/amfi.h` for `TrustCache/API.h`

## TrustCache dependency investigation

`TrustCache/API.h` is referenced from four public XNU include sites:

- [`libkern/libkern/amfi/amfi.h`](../xnu/libkern/libkern/amfi/amfi.h#L129)
- [`bsd/kern/kern_trustcache.c`](../xnu/bsd/kern/kern_trustcache.c#L44)
- [`bsd/sys/trust_caches.h`](../xnu/bsd/sys/trust_caches.h#L30)
- [`osfmk/vm/pmap_cs.h`](../xnu/osfmk/vm/pmap_cs.h#L63)

Build exposure:

- `libkern/conf/files` compiles `libkern/amfi/amfi.c`
- `bsd/conf/files` compiles `bsd/kern/kern_trustcache.c`
- the first observed build failure in the disposable worktree happened while compiling `amfi.o`, because `libkern/amfi/amfi.h` now includes `TrustCache/API.h` unconditionally

History:

- the TrustCache include first appears in the public XNU history around the `xnu-8792.41.9` / `xnu-8796.101.5` era
- the import commit that added the include to `amfi.h` is `aca3beaa3dfbd42498b42c5e5ce20a938e6554e5` (`xnu-8796.101.5`)

Availability:

- `TrustCache/API.h` does not exist in the public XNU checkout
- it does not exist in the installed Xcode SDK tree or Command Line Tools SDK tree on the VM
- `git log` over the public XNU tree does not show a checked-in `TrustCache/API.h`

Conclusion:

- `TrustCache` looks like a separate Apple-private dependency, not a file generated by XNU
- `API.h` is not expected from the public SDK/KDK layout available in this lab
- the header is missing from the public XNU checkout
- the most likely next step is a temporary compatibility shim or a private Apple package providing the TrustCache SPI, but the public tree alone does not supply it

## TrustCache dependency map

The TrustCache SPI surface used by the four include sites is small enough to shim at the declaration level.

Symbols originating from `TrustCache/API.h` as exercised by the current tree:

| Symbol | Kind | First use | Usage count |
| --- | --- | --- | --- |
| `TCReturn_t` | typedef / struct | `libkern/libkern/amfi/amfi.h:133` | 21 |
| `TrustCache_t` | opaque typedef / struct | `libkern/libkern/amfi/amfi.h:134` | 20 |
| `TrustCacheRuntime_t` | opaque typedef / struct | `libkern/libkern/amfi/amfi.h:140` | 9 |
| `TrustCacheMutableRuntime_t` | opaque typedef / struct | `bsd/kern/kern_trustcache.c:67` | 5 |
| `TCType_t` | enum / typedef | `libkern/libkern/amfi/amfi.h:147` | 13 |
| `TCQueryType_t` | enum / typedef | `libkern/libkern/amfi/amfi.h:171` | 8 |
| `TrustCacheQueryToken_t` | struct / typedef | `libkern/libkern/amfi/amfi.h:173` | 13 |
| `TCCapabilities_t` | integer typedef | `libkern/libkern/amfi/amfi.h:189` | 10 |
| `kUUIDSize` | macro / constant | `libkern/libkern/amfi/amfi.h:141` | 8 |
| `kTCEntryHashSize` | macro / constant | `libkern/libkern/amfi/amfi.h:172` | 8 |
| `kTCReturnSuccess` | enum constant | `bsd/kern/kern_trustcache.c:538` | 7 |
| `kTCReturnDuplicate` | enum constant | `bsd/kern/kern_trustcache.c:173` | 3 |
| `kTCReturnNotFound` | enum constant | `bsd/kern/kern_trustcache.c:235` | 4 |
| `kTCReturnError` | enum constant | `bsd/kern/kern_trustcache.c:1058` | 2 |
| `kTCTypeInvalid` | enum constant | `bsd/kern/kern_trustcache.c:716` | 1 |
| `kTCTypeLTRS` | enum constant | `bsd/kern/kern_trustcache.c:720` | 1 |
| `kTCTypeDTRS` | enum constant | `bsd/kern/kern_trustcache.c:735` | 1 |
| `kTCTypeStatic` | enum constant | `bsd/kern/kern_trustcache.c:821` | 4 |
| `kTCTypeEngineering` | enum constant | `bsd/kern/kern_trustcache.c:821` | 3 |
| `kTCTypeLegacy` | enum constant | `bsd/kern/kern_trustcache.c:582` | 2 |
| `kTCTypeCryptex1BootOS` | enum constant | `bsd/kern/kern_trustcache.c:841` | 3 |
| `kTCTypeCryptex1BootApp` | enum constant | `bsd/kern/kern_trustcache.c:844` | 3 |
| `kTCTypeTotal` | enum constant | `bsd/kern/kern_trustcache.c:720` | 2 |

What already exists in public XNU:

- [`osfmk/kern/trustcache.h`](../xnu/osfmk/kern/trustcache.h) defines a separate, older trust-cache module format (`trust_cache_module0`, `trust_cache_module1`, `trust_cache_entry1`) and the `TC_LOOKUP_*` macros.
- `uuid_t` exists in the public tree, but the named `kUUIDSize` constant does not appear to be provided there.
- None of the `TCReturn_t` / `TrustCache_t` / `TrustCacheRuntime_t` / `TrustCacheMutableRuntime_t` / `TCType_t` / `TCQueryType_t` / `TrustCacheQueryToken_t` / `TCCapabilities_t` declarations are provided by the public tree outside the missing `TrustCache/API.h` include.

Shim estimate:

- declaration-only compatibility header: medium, roughly 100-200 LOC
- no function bodies appear required for the current compile failure
- a full subsystem implementation is not indicated by the current evidence

<a id="fix-f007"></a>
## TrustCache shim validation

Disposable-worktree-only shim locations:

- `/tmp/evos-xnu-lab/TrustCache/API.h`
- `/tmp/evos-xnu-lab/libkern/TrustCache/API.h`
- `/tmp/evos-xnu-lab/bsd/TrustCache/API.h`
- `/tmp/evos-xnu-lab/osfmk/TrustCache/API.h`
- `/tmp/evos-xnu-lab/EXTERNAL_HEADERS/TrustCache/API.h`
- `/tmp/evos-xnu-lab/BUILD/obj/EXPORT_HDRS/TrustCache/API.h`

Shim contents:

- `kUUIDSize = 16`
- `kTCEntryHashSize = 20`
- opaque-ish placeholders:
  - `TrustCache_t`
  - `TrustCacheMutableRuntime_t`
- concrete runtime fields used by the tree:
  - `TrustCacheRuntime_t.allowSecondStaticTC`
  - `TrustCacheRuntime_t.allowEngineeringTC`
- concrete token fields used by the tree:
  - `TrustCacheQueryToken_t.trustCache`
  - `TrustCacheQueryToken_t.trustCacheEntry`
- scalar / enum declarations:
  - `TCReturn_t`
  - `TCCapabilities_t`
  - `TCType_t`
  - `TCQueryType_t`
- return-code constants:
  - `kTCReturnSuccess`
  - `kTCReturnError`
  - `kTCReturnDuplicate`
  - `kTCReturnNotFound`
- type constants:
  - `kTCTypeInvalid`
  - `kTCTypeLTRS`
  - `kTCTypeDTRS`
  - `kTCTypeStatic`
  - `kTCTypeEngineering`
  - `kTCTypeLegacy`
  - `kTCTypeCryptex1BootOS`
  - `kTCTypeCryptex1BootApp`
  - `kTCTypeTotal`

Validation result:

- `TrustCache/API.h` no longer blocks compilation in the disposable worktree
- the build progressed past `amfi.o` and the trust-cache include boundary
- the next distinct blocker became unrelated `OSMetaClass.h` `-Wsuggest-override` errors, with the build stopping in `libkern` / `OSObject.cpo` / `OSCollection.cpo` / `OSMetaClass.cpo`

Interpretation:

- the TrustCache dependency is satisfied by a header-only compatibility shim
- no function bodies were needed for this build-lab step
- the remaining issue is now in the C++ export headers, not TrustCache

<a id="fix-f008"></a>
## OSMetaClass override investigation

The current blocker is a family of clang override diagnostics emitted from [`libkern/libkern/c++/OSMetaClass.h`](../xnu/libkern/libkern/c++/OSMetaClass.h).

Exact failing declarations in the `xnu-10063.141.1` disposable worktree:

- `virtual void retain() const;`
- `virtual void release() const;`
- `virtual void release(int freeWhen) const;`
- `virtual void taggedRetain(const void * tag = NULL) const;`
- `virtual void taggedRelease(const void * tag = NULL) const;`
- `virtual void taggedRelease(const void * tag, const int freeWhen) const;`
- `virtual int getRetainCount() const;`
- `virtual const OSMetaClass * getMetaClass() const;`
- `virtual ~OSMetaClass();`
- `virtual bool serialize(OSSerialize * serializer) const;`

What clang emits:

- `-Werror,-Wsuggest-override`

This is not `-Winconsistent-missing-override`; it is the suggestion-style warning that the compiler now emits for virtuals that override a base method but are missing the `override` keyword.

Later public history shows Apple fixed this in `xnu-12377.101.15`:

- `retain`, `release`, `release(int)`, `taggedRetain`, `taggedRelease`, `getRetainCount`, `getMetaClass`, `~OSMetaClass`, and `serialize` all carry `override` there.
- The older `xnu-11215.*` tags and `xnu-12377.1.9` still have the pre-fix declarations.

Root cause:

- source bug in public XNU: missing `override` on a set of virtual methods in `OSMetaClass.h`
- compiler behavior change: newer clang warns on the missing `override`
- build-flag incompatibility: XNU treats that warning as an error

Estimated impact:

- affected methods: 9 declarations in the `OSMetaClass` class body
- the corresponding `OSObject` abstract declarations are not the issue; the problem is the concrete `OSMetaClass` overrides

Minimal source diff shape:

- add `override` to the 9 affected `OSMetaClass` methods
- no behavior changes are expected

Recommendation:

- the clean fix is a small source update in the disposable worktree first, then a rerun to confirm the next blocker

<a id="fix-f009"></a>
<a id="fix-f010"></a>
## i386 clang dead-store cleanup

The disposable worktree-only cleanup removed two dead stores that modern clang reported as `-Wunused-but-set-variable` under `-Werror`:

- [`osfmk/i386/i386_timer.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/i386/i386_timer.c)
  - removed `orig_abstime`
  - preserved the `mach_absolute_time()` side effect by keeping `abstime = mach_absolute_time();`
- [`osfmk/i386/pmap_internal.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/i386/pmap_internal.h)
  - removed `suppress_ppn`
  - preserved the `suppress_reason` / `action` logic and the `*ppnp = npn` update

After that fix, the build advanced past both warning sites. The next distinct hard failure in the disposable worktree was:

- `osfmk/i386/cpu_threads.c:821:14: error: variable 'phys_cpu' set but not used [-Werror,-Wunused-but-set-variable]`

<a id="fix-f011"></a>
<a id="fix-f012"></a>
## bulk dead-store cleanup investigation

The disposable tree then continued to surface more `-Wunused-but-set-variable` hits in the same build path. The first new cleanup applied was:

- [`osfmk/i386/cpu_threads.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/i386/cpu_threads.c)
  - removed `phys_cpu`
  - the value was assigned from `cpup->cpu_phys_number` and never read

The next `-Wunused-but-set-variable` site was:

- [`bsd/dev/dtrace/dtrace.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/bsd/dev/dtrace/dtrace.c)
  - removed the `np` temporary in `dtrace_difo_destroy()`
  - replaced the dead `ASSERT(id < (uint_t)*np)` pattern with a direct assertion on `scope`

After those fixes, the filtered build still reported additional same-class candidates:

| file | variable | first assignment | read count | safe cleanup candidate |
| --- | --- | --- | --- | --- |
| `bsd/dev/dtrace/dtrace.c` | `rval` at line `2170` | `rval = dtrace_casptr(...)` | 1 read in `ASSERT(rval == NULL)` | yes |
| `bsd/dev/dtrace/dtrace.c` | `rv` at line `3116` | `rv = dtrace_cas32(...)` | 1 read in `ASSERT(rv == current)` | yes |
| `bsd/dev/dtrace/dtrace.c` | `base` at line `5278` | `base = (char *)mstate->dtms_scratch_ptr` | 1 read in `ASSERT(end + 1 >= base)` | yes |
| `bsd/dev/dtrace/dtrace.c` | `rval` at line `15126` | `rval = dtrace_enabling_retain(...)` | 1 read in `ASSERT(rval == 0)` | yes |
| `bsd/dev/dtrace/dtrace_glue.c` | `ret` at line `554` | `ret = assert_wait(...)` / `ret = thread_block(...)` | 2 reads in `ASSERT(...)` | yes |
| `bsd/dev/dtrace/systrace.c` | `uargs` at line `1010` | `uargs = uthread->t_dtrace_syscall_args` | 0 reads | yes |
| `osfmk/i386/locks_i386.c` | `avg_hold_time` at line `1897` | `avg_hold_time = 0` | 0 reads; only mentioned in comments | yes |

The first fundamentally different blocker appeared before this warning class was exhausted:

- `/tmp/evos-xnu-lab/iokit/Kernel/IOKitKernelInternal.h:193:27: error: multi-character character constant [-Werror,-Wfour-char-constants]`
- `osfmk/i386/machine_routines.c` and `bsd/dev/dtrace/systrace.c` also surfaced unrelated non-dead-store diagnostics in the same filtered run.

## four-char-constant investigation

The first blocker after the dead-store sweep is a long-lived Apple kernel signature in [`iokit/Kernel/IOKitKernelInternal.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOKitKernelInternal.h):

```c++
enum{
	kIOPageAllocSignature  = 'iopa'
};
```

The exact offending expression is the multi-character constant `'iopa'`.

What I checked:

- The expression is present at the same source location in `xnu-11215.*` and `xnu-12377.101.15`.
- The public history for this file shows it first appears with the import `aca3beaa3` tagged `xnu-8796.101.5`.
- I did not find a later public tag where Apple removed or suppressed this construct.

Interpretation:

- This is intentional historical XNU code, not a new regression in the source.
- The warning is a compiler behavior change: newer clang treats the four-char literal as an error under XNU’s `-Werror` policy.
- Apple appears to have kept the code in public tags rather than rewriting it in the releases I checked.

Smallest reversible source fix:

- Replace the enum initializer with an equivalent non-multicharacter constant representation, preserving the numeric value of the signature.
- Keep the fix local to the disposable worktree until the next build confirms whether any other `-Wfour-char-constants` sites remain.

<a id="fix-f013"></a>
## four-char-constant validation fix

The disposable worktree-only replacement in [`iokit/Kernel/IOKitKernelInternal.h`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOKitKernelInternal.h) changed:

```c++
kIOPageAllocSignature  = 'iopa'
```

to the equivalent expression:

```c++
kIOPageAllocSignature  = ((uint32_t)'i' << 24) | ((uint32_t)'o' << 16) | ((uint32_t)'p' << 8) | ((uint32_t)'a')
```

Outcome:

- the `-Wfour-char-constants` error is resolved
- no additional four-char constant error surfaced before the build moved on
- the next distinct hard failures are unrelated `-Wunused-but-set-variable` diagnostics in:
  - [`iokit/Kernel/IOServicePM.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOServicePM.cpp)
  - [`iokit/Kernel/IOService.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOService.cpp)

## iokit dead-store cleanup

The disposable worktree-only `-Wunused-but-set-variable` cleanup in `iokit` removed four dead stores:

- [`iokit/Kernel/IOServicePM.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOServicePM.cpp)
  - removed the unused local declarations from `driverSetPowerState()`:
    - `const OSMetaClass *controllingDriverMetaClass = NULL;`
    - `uint32_t controllingDriverRegistryEntryID = 0;`
  - preserved the `SOCD_TRACE_XNU_*` call sites as the original build-lab instrumentation boundary
- [`iokit/Kernel/IOService.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOService.cpp)
  - removed `IOUserServer * us;` and its dead `us = NULL;` assignment in `IOServicePH::systemPowerChange()`
  - removed `bool didRegister;` and the dead assignment in `IOService::doServiceMatch()`

Validation result:

- the `IOServicePM.cpp` and `IOService.cpp` dead-store diagnostics were cleared in the disposable tree
- the build progressed past these `iokit` warning sites
- the next distinct blocker after this cleanup was unrelated and appeared later in `osfmk`

Notes:

- the change is disposable-tree only
- no `Werror` suppression was introduced

<a id="fix-f017"></a>
## IOPolledInterface dead-store cleanup

The next disposable-tree-only `-Wunused-but-set-variable` blocker was in [`iokit/Kernel/IOPolledInterface.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOPolledInterface.cpp).

Exact failing scope:

- `IOPolledFilePollers::copyPollers(IOService * media)`

The variable `err` was:

- declared as `IOReturn err;`
- assigned `kIOReturnNoMemory` when `vars->pollers` allocation failed
- assigned `kIOReturnUnsupported` when no pollers were found
- never read before returning `vars`

That made it a pure dead store. The smallest safe cleanup was to remove the declaration and the two assignments while preserving the early-break control flow.

Exact diff:

```diff
diff --git a/iokit/Kernel/IOPolledInterface.cpp b/iokit/Kernel/IOPolledInterface.cpp
index 61c970d67..341cf8913 100644
--- a/iokit/Kernel/IOPolledInterface.cpp
+++ b/iokit/Kernel/IOPolledInterface.cpp
@@ -102,7 +102,6 @@ IOPolledFilePollers *
 IOPolledFilePollers::copyPollers(IOService * media)
 {
 	IOPolledFilePollers * vars;
-	IOReturn              err;
 	IOService       * service;
 	OSObject        * obj;
 	IORegistryEntry * next;
@@ -122,7 +121,6 @@ IOPolledFilePollers::copyPollers(IOService * media)
 
 		vars->pollers = OSArray::withCapacity(4);
 		if (!vars->pollers) {
-			err = kIOReturnNoMemory;
 			break;
 		}
@@ -150,7 +148,6 @@ IOPolledFilePollers::copyPollers(IOService * media)
 		    && child->isParent(next, gIOServicePlane, true));
 
 		if (!vars->pollers->getCount()) {
-			err = kIOReturnUnsupported;
 			break;
 		}
 	}while (false);
```

Validation result:

- `IOPolledInterface.cpp` no longer emits the dead-store warning
- the build progressed past `IOPolledInterface.cpo`
- the next distinct failure appeared in different `iokit` sources and remains the same warning family:
  - `iokit/Kernel/IODMACommand.cpp:937:39: error: variable 'mapperPageShift' set but not used [-Werror,-Wunused-but-set-variable]`
  - `iokit/Kernel/IODMACommand.cpp:939:39: error: variable 'mapOptions' set but not used [-Werror,-Wunused-but-set-variable]`
  - `iokit/Kernel/IODMACommand.cpp:1344:9: error: variable 'check' set but not used [-Werror,-Wunused-but-set-variable]`
  - `iokit/Kernel/IOMemoryDescriptor.cpp:1244:21: error: variable 'type' set but not used [-Werror,-Wunused-but-set-variable]`
  - `iokit/Kernel/IOMemoryDescriptor.cpp:3573:16: error: variable 'params' set but not used [-Werror,-Wunused-but-set-variable]`
  - `iokit/Kernel/IOMemoryDescriptor.cpp:3896:15: error: variable 'res' set but not used [-Werror,-Wunused-but-set-variable]`

Notes:

- this is still the same dead-store warning class, just in new iokit files
- the disposable-tree-only policy was preserved
- no `Werror` suppression or Makefile edits were introduced

<a id="fix-f018"></a>
<a id="fix-f019"></a>
## IODMACommand and IOMemoryDescriptor dead-store cleanup

The current disposable-tree-only blockers were all `-Wunused-but-set-variable` diagnostics in:

- [`iokit/Kernel/IODMACommand.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IODMACommand.cpp)
- [`iokit/Kernel/IOMemoryDescriptor.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOMemoryDescriptor.cpp)

### `IODMACommand.cpp`

1. `mapperPageShift`
   - surrounding function: `IODMACommand::prepare(...)`
   - declaration: local `uint64_t mapperPageShift;`
   - assignments: `mapperPageShift = (64 - __builtin_clzll(mapperPageMask));`
   - reads: none
   - classification: pure dead store
   - cleanup: remove declaration and assignment

2. `mapOptions`
   - surrounding function: `IODMACommand::prepare(...)`
   - declaration: local `uint32_t mapOptions;`
   - assignments: assigned in a direction switch, never read
   - reads: none
   - classification: pure dead store
   - cleanup: remove declaration and the unused switch

3. `check`
   - surrounding function: `IODMACommand::genIOVMSegments(...)`
   - declaration: local `bool check = false;`
   - assignments: set to `true` in success paths
   - reads: only inside a `#if 0` diagnostic block
   - classification: debug/trace-only logic that is compiled out
   - cleanup: remove declaration and assignments, preserve `done`

### `IOMemoryDescriptor.cpp`

4. `type`
   - surrounding function: `IOGeneralMemoryDescriptor::memoryReferenceMapNew(...)`
   - declaration: local `IOOptionBits type;`
   - assignments: `type = _flags & kIOMemoryTypeMask;`
   - reads: none in that function
   - classification: pure dead store
   - cleanup: remove declaration and assignment

5. `params`
   - surrounding function: `IOMemoryDescriptor::dmaCommandOperation(...)`
   - declaration: local `DMACommandOps params;`
   - assignments: `params = (op & ~kIOMDDMACommandOperationMask & op);`
   - reads: none
   - classification: pure dead store
   - cleanup: remove declaration and assignment

6. `res`
   - surrounding function: `IOMemoryDescriptor::performOperation(...)`
   - declaration: local `unsigned int res;`
   - assignments: initialized and passed to the arm64 coherent-IO helpers
   - reads: only in `#if defined(__arm64__)` branches
   - classification: x86_64-only unused local with arm64 use
   - cleanup: make the declaration/initialization arm64-only so x86_64 no longer sees the dead store

Validation result:

- the six diagnostics were resolved in the disposable tree
- the build moved past both `IODMACommand.cpp` and `IOMemoryDescriptor.cpp`
- the next hard failure in this run was a different `-Wunused-but-set-variable` in:
  - [`bsd/dev/dtrace/dtrace_glue.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/bsd/dev/dtrace/dtrace_glue.c)
  - `ret` at line `554`

Notes:

- the next blocker is still the same warning family (`-Wunused-but-set-variable`)
- no Makefile changes or global warning suppressions were introduced
- no Makefile edits were needed

## machine_routines pointer cast investigation

The current blocker is in [`osfmk/i386/machine_routines.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/i386/machine_routines.c):

```c
ppn = pmap_find_phys(kernel_pmap, vaddr_cur);
assert(ppn != (ppnum_t)NULL);
```

Exact code context:

```c
		/*
		 * Can't free from the middle of a large page.
		 */
		assert((vaddr_cur & (map_size - 1)) == 0);

		ppn = pmap_find_phys(kernel_pmap, vaddr_cur);
		assert(ppn != (ppnum_t)NULL);

		pmap_remove(kernel_pmap, vaddr_cur, vaddr_cur + map_size);
```

Type facts:

- `ppnum_t` is `typedef uint32_t ppnum_t`
- the current build target is `x86_64`
- pointer size on the build target is 8 bytes
- `ppnum_t` is therefore 32 bits, while `void *` is 64 bits

Semantic intent:

- `ppn` is a physical page number returned by `pmap_find_phys()`
- `pmap_find_phys()` returns `0` when the mapping is missing
- the assertion is effectively a nonzero sentinel check before removing the mapping
- the pointer cast is only a historical way of spelling that sentinel check

History:

- `git log -S 'assert(ppn != (ppnum_t)NULL)'` points to `a5e721962` / `xnu-6153.11.26` as the introduction point
- the same assertion is still present in `xnu-11215.81.4` and `xnu-12377.101.15`
- I did not find a public tag where Apple replaced this exact assertion with a newer form

Assessment:

- the warning is valid from the compiler’s point of view because the code casts a pointer constant to a 32-bit integer type in a 64-bit build
- there is no expected runtime truncation here because the value being compared is `NULL`, i.e. zero
- the warning is conservative, but the code style is old and triggers modern clang’s diagnostics under `-Werror`

Smallest safe source fix candidate:

- change the assertion to a zero comparison that preserves the same sentinel intent, for example:

```c
assert(ppn != 0);
```

- this avoids the pointer cast and preserves the nonzero check
- no Makefile, `Werror`, or broader logic changes are needed for the next probe

<a id="fix-f014"></a>
## machine_routines pointer cast validation fix

The disposable worktree-only source change in [`osfmk/i386/machine_routines.c`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/osfmk/i386/machine_routines.c) changed:

```c
assert(ppn != (ppnum_t)NULL);
```

to:

```c
assert(ppn != 0);
```

Exact diff:

```diff
diff --git a/osfmk/i386/machine_routines.c b/osfmk/i386/machine_routines.c
index a8bdbb579..906c9bf21 100644
--- a/osfmk/i386/machine_routines.c
+++ b/osfmk/i386/machine_routines.c
@@ -222,7 +222,7 @@ ml_static_mfree(
 		assert((vaddr_cur & (map_size - 1)) == 0);
 
 		ppn = pmap_find_phys(kernel_pmap, vaddr_cur);
-		assert(ppn != (ppnum_t)NULL);
+		assert(ppn != 0);
 
 		pmap_remove(kernel_pmap, vaddr_cur, vaddr_cur + map_size);
 		while (map_size > 0) {
```

Result of the rerun:

- the pointer-to-integer cast warning in `machine_routines.c` is removed in the disposable tree
- the build did not reach a machine_routines-specific failure in this run
- instead, the first hard failure remained earlier in the `iokit` path:
  - `iokit/Kernel/IOServicePM.cpp:1688:22: error: variable 'controllingDriverMetaClass' set but not used [-Werror,-Wunused-but-set-variable]`
  - `iokit/Kernel/IOServicePM.cpp:1689:22: error: variable 'controllingDriverRegistryEntryID' set but not used [-Werror,-Wunused-but-set-variable]`
  - `iokit/Kernel/IOService.cpp:...` also still emitted dead-store warnings in the same run

Interpretation:

- the `machine_routines.c` fix is syntactically correct and disposable-tree only
- it was not the next limiting blocker in the build because a prior `iokit` dead-store issue still stopped compilation first
- the remaining blocker class in this run is still `-Wunused-but-set-variable`, not a new compiler family

<a id="fix-f020"></a>
## dtrace_glue dead-store cleanup

The current `bsd/dev/dtrace/dtrace_glue.c` blocker was in `cyclic_remove(cyclic_id_t cyclic)`.

Observed failure:

- `bsd/dev/dtrace/dtrace_glue.c:554:7: error: variable 'ret' set but not used [-Werror,-Wunused-but-set-variable]`

Source inspection:

- `ret` was declared inside the `while (!thread_call_cancel(wrapTC->TChdl))` loop
- the first assignment was:
  - `ret = assert_wait(wrapTC, THREAD_UNINT);`
- the second assignment was:
  - `ret = thread_block(THREAD_CONTINUE_NULL);`
- the only reads were in `ASSERT(ret == THREAD_WAITING);` and `ASSERT(ret == THREAD_AWAKENED);`
- on this build path those assertions did not count as uses for clang’s dead-store analysis

History check:

- `xnu-11215.81.4` still contains the same `ret` pattern in `cyclic_remove()`
- `xnu-12377.101.15` also still contains the same pattern
- no newer public XNU tag examined here changed the declaration before this lab fix

Classification:

- the variable was a dead store from the compiler’s perspective
- the side-effecting calls themselves were the important behavior
- the return-value assertions were only diagnostic in this build configuration

Smallest source-level fix:

- remove the temporary `ret`
- keep the side-effecting calls
- use direct calls with `(void)` casts so the loop still performs `assert_wait(...)` and `thread_block(...)`

Exact diff:

```diff
diff --git a/bsd/dev/dtrace/dtrace_glue.c b/bsd/dev/dtrace/dtrace_glue.c
index 0cb6c5dd2..4cb968f84 100644
--- a/bsd/dev/dtrace/dtrace_glue.c
+++ b/bsd/dev/dtrace/dtrace_glue.c
@@ -551,13 +551,11 @@ cyclic_remove(cyclic_id_t cyclic)
 	ASSERT(cyclic != CYCLIC_NONE);
 
 	while (!thread_call_cancel(wrapTC->TChdl)) {
-		int ret = assert_wait(wrapTC, THREAD_UNINT);
-		ASSERT(ret == THREAD_WAITING);
+		(void)assert_wait(wrapTC, THREAD_UNINT);
 
 		wrapTC->when.cyt_interval = WAKEUP_REAPER;
 
-		ret = thread_block(THREAD_CONTINUE_NULL);
-		ASSERT(ret == THREAD_AWAKENED);
+		(void)thread_block(THREAD_CONTINUE_NULL);
 	}
 
 	if (thread_call_free(wrapTC->TChdl)) {
```

Validation result:

- the disposable worktree no longer emits the `ret` dead-store error from `dtrace_glue.c`
- the build progressed past `dtrace_glue.o`
- the next distinct blocker is now in:
  - `iokit/Kernel/IONVRAMV3Handler.cpp`
  - line `99`
  - failure class `-Wfour-char-constants`

<a id="fix-f015"></a>
<a id="fix-f016"></a>
## iokit scoped dead-store cleanup retry

The disposable-tree-only `iokit` cleanup was narrowed to the exact current failing scopes:

- [`iokit/Kernel/IOServicePM.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOServicePM.cpp)
  - fixed `IOService::handleAcknowledgeSetPowerState()`
  - removed the local declarations:
    - `const OSMetaClass *controllingDriverMetaClass = NULL;`
    - `uint32_t controllingDriverRegistryEntryID = 0;`
  - preserved the trace call by inlining the `fControllingDriver` value expressions directly into `SOCD_TRACE_XNU(...)`
- [`iokit/Kernel/IOService.cpp`](/home/khizhnik/Work/PROJECTS/EvOS/xnu/iokit/Kernel/IOService.cpp)
  - fixed `IOService::terminatePhase1()`
    - removed `IOOptionBits callerOptions;`
    - removed the dead assignment `callerOptions = options;`
  - fixed `IOService::actionWillTerminate()`
    - removed the unused local `bool ok;`
    - preserved the call side effect with `(void) client->willTerminate(...)`
  - fixed `IOService::actionWillStop()`
    - removed the unused local `bool ok;`
    - preserved the call side effect with `(void) victim->willTerminate(...)`

Validation result:

- the previous `IOServicePM.cpp` dead-store diagnostics are gone
- the previous `IOService.cpp` dead-store diagnostics are gone
- the build got past those `iokit` sites
- the build reached `osfmk/i386/machine_routines.c` and did not fail there in this run

Next blocker from the same build run:

- `iokit/Kernel/IOPolledInterface.cpp:105:24: error: variable 'err' set but not used [-Werror,-Wunused-but-set-variable]`

Notes:

- this is still a dead-store cleanup class failure, just in a different `iokit` file
- the change is disposable-worktree only
- no `Werror` suppression was introduced

<a id="fix-f021"></a>
## IONVRAMV3Handler four-char constant validation fix

The current `IONVRAMV3Handler.cpp` blocker was the historical variable-store signature:

- `#define VARIABLE_STORE_SIGNATURE         'NVV3'`

Exact code context:

```c++
#define VARIABLE_STORE_SIGNATURE         'NVV3'

// Variable Store Version
#define VARIABLE_STORE_VERSION           0x1
```

Observed failure:

- `iokit/Kernel/IONVRAMV3Handler.cpp:99: error: multi-character character constant [-Werror,-Wfour-char-constants]`

Value preservation:

- The signature value is `0x4E565633`
- It is a long-lived Apple historical four-char signature
- `xnu-11215.81.4` keeps the same macro unchanged
- `xnu-12377.101.15` also keeps the same macro unchanged
- No public tag examined here showed Apple replacing or suppressing it

Smallest source-level fix:

- replace the multi-character literal with an explicit 32-bit shift expression
- preserve the exact value while avoiding the compiler warning

Exact diff:

```diff
diff --git a/iokit/Kernel/IONVRAMV3Handler.cpp b/iokit/Kernel/IONVRAMV3Handler.cpp
index 74143925c..58ddbc47b 100644
--- a/iokit/Kernel/IONVRAMV3Handler.cpp
+++ b/iokit/Kernel/IONVRAMV3Handler.cpp
@@ -28,7 +28,7 @@
 
 #include <libkern/libkern.h>
 
-#define VARIABLE_STORE_SIGNATURE         'NVV3'
+#define VARIABLE_STORE_SIGNATURE         (((uint32_t)'N' << 24) | ((uint32_t)'V' << 16) | ((uint32_t)'V' << 8) | ((uint32_t)'3'))
 
 // Variable Store Version
 #define VARIABLE_STORE_VERSION           0x1
```

Validation result:

- the disposable worktree no longer stops on `VARIABLE_STORE_SIGNATURE`
- the build progressed past `IONVRAMV3Handler.o`
- the next distinct blocker was:
  - `libkern/c++/OSMetaClass.cpp:436:13: error: 'alloc' overrides a member function but is not marked 'override' [-Werror,-Wsuggest-override]`

Notes:

- this is a compiler-compatibility cleanup, not a logic change
- the fix is disposable-worktree only
- the next blocker is a different warning family from the one fixed here

## DriverKit IOTypes.h restoration validation

The disposable worktree had a missing source file:

- `iokit/DriverKit/IOTypes.h`

Current facts before restoration:

- the tree contained `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h`
- the tree contained `iokit/IOKit/IOTypes.h`
- the tree did **not** contain `iokit/DriverKit/IOTypes.h`
- `iokit/DriverKit/Makefile` still lists `IOTypes.h` in `OTHER_HEADERS`

Comparison result:

- `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h` is a DriverKit-shaped variant, not a byte-identical copy of `iokit/IOKit/IOTypes.h`
- the build artifact is the closest known source for the missing DriverKit header

Validation step:

- the generated DriverKit export header was copied back into the disposable source tree as `iokit/DriverKit/IOTypes.h`
- this restored source file is now present in the disposable worktree only

Build progression after restoration:

- the DriverKit export-header phase no longer stopped on `IOTypes.h`
- the next missing source dependency became:
  - `make[5]: *** No rule to make target `IOReturn.h`, needed by `/Users/khizhnik/Work/EvOS/xnu/BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOReturn.h'.  Stop.`

Interpretation:

- the `IOTypes.h` gap was a real missing DriverKit source file in the disposable tree
- restoring it from the generated export artifact was sufficient to move the build graph forward
- the remaining DriverKit packaging regression is broader than a single file, because `IOReturn.h` is now the next missing local prerequisite

## OSMetaClass override investigation

Current blocker observed in the disposable worktree:

- `libkern/c++/OSMetaClass.cpp:436:13: error: 'alloc' overrides a member function but is not marked 'override' [-Werror,-Wsuggest-override]`

Exact site:

```c++
class OSMetaClassMeta : public OSMetaClass
{
public:
	OSMetaClassMeta();
	OSObject * alloc() const;
};
```

Inheritance context:

- `OSMetaClassMeta` derives directly from `OSMetaClass`
- `OSMetaClass::alloc()` is declared pure virtual in [`libkern/libkern/c++/OSMetaClass.h`](../xnu/libkern/libkern/c++/OSMetaClass.h#L1795)
- the helper class `OSMetaClassMeta::alloc()` is therefore a real override of the base virtual

History comparison:

- `xnu-11215.81.4` keeps the same declaration without `override`
- `xnu-12377.101.15` also keeps the same declaration without `override`
- no public tag examined here showed Apple adding, renaming, or suppressing this specific declaration

Smallest source-level fix:

- add `override` to the helper class declaration only
- do not change the implementation body
- do not broaden the fix to other metaclass code

Exact local diff applied in the disposable tree:

```diff
diff --git a/libkern/c++/OSMetaClass.cpp b/libkern/c++/OSMetaClass.cpp
index 4ad2fc782..b7ce8ca11 100644
--- a/libkern/c++/OSMetaClass.cpp
+++ b/libkern/c++/OSMetaClass.cpp
@@ -433,7 +433,7 @@ class OSMetaClassMeta : public OSMetaClass
 {
 public:
 	OSMetaClassMeta();
-	OSObject * alloc() const;
+	OSObject * alloc() const override;
 };
 OSMetaClassMeta::OSMetaClassMeta()
 	: OSMetaClass("OSMetaClass", NULL, sizeof(OSMetaClass))
```

Validation status:

- the source fix is applied in the disposable tree
- the rebuild in this turn was **pre-empted** by an earlier packaging regression:
  - `make[5]: *** No rule to make target \`IOTypes.h', needed by \`/Users/khizhnik/Work/EvOS/xnu/BUILD/obj/EXPORT_HDRS/iokit/DriverKit/IOTypes.h'.  Stop.`
- because the build stopped before `libkern/c++/OSMetaClass.o`, this specific `alloc` override fix is not yet build-validated in this run

Notes:

- the earlier `OSMetaClass.h` `override` family remains fixed in the disposable worktree
- this `alloc` site is part of the same override family, but it lives in the bootstrap metaclass helper in `OSMetaClass.cpp`
- no original checkout files were touched

<a id="fix-f022"></a>
## DriverKit OTHER_HEADERS restoration validation

The disposable DriverKit tree originally lacked local copies of the `OTHER_HEADERS` list from [`iokit/DriverKit/Makefile`](../xnu/iokit/DriverKit/Makefile#L42-L47).

The missing local headers were restored from already-generated DriverKit-shaped export artifacts under:

- `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/`

Restored local source files:

- `IOReturn.h`
- `IORPC.h`
- `IOKitKeys.h`
- `IOKernelReportStructs.h`
- `IOReportTypes.h`
- `queue_implementation.h`
- `macro_help.h`
- `bounded_ptr.h`
- `bounded_array.h`
- `bounded_array_ref.h`
- `bounded_ptr_fwd.h`
- `OSBoundedArray.h`
- `OSBoundedArrayRef.h`
- `OSBoundedPtr.h`
- `OSBoundedPtrFwd.h`
- `safe_allocation.h`

Already present before this restoration:

- `IOTypes.h`

Validation result:

- the DriverKit export-header phase no longer stopped on the missing DriverKit local headers
- the build advanced past the restored DriverKit `OTHER_HEADERS` set
- the next distinct blocker in this run was:
  - `clang: error: unknown argument: '-mach_msg2'`
  - `mig: fatal: "<no name yet>", line -1: no SubSystem declaration`
- `pexpert/i386/pe_serial.c:403:11: error: variable 'register_read' set but not used [-Werror,-Wunused-but-set-variable]` also appeared later in parallel output, but it was not the first blocker

Interpretation:

- the DriverKit packaging regression was broader than `IOTypes.h`
- restoring the complete local `OTHER_HEADERS` set from the already-generated export artifacts was sufficient to move the build graph forward
- the next blocker is the already-known MIG/toolchain mismatch, not a DriverKit source issue
- later `pe_serial.c` output in the same run is not the first distinct blocker and was not investigated in this task

Notes:

- this validation did **not** reach `libkern/c++/OSMetaClass.cpp`
- the `OSMetaClass.cpp` `alloc` override fix remains unvalidated in this run
- no Makefiles were edited

## VM crash recovery and checkpoint policy

- The macOS VM has crashed before and can drop uncommitted lab edits.
- After each validated frontier move, checkpoint the state immediately.
- For each validated F-ID:
  - commit or capture a patch bundle
  - update the registry entry
  - then continue to the next blocker
- Do not let validated fixes accumulate uncheckpointed in the disposable tree.

## Linux-host checkpoint policy

- The Linux-host checkpoint tree is the source of truth.
- VM-local branches and tags are secondary convenience state only.
- After every validated frontier move:
  1. update the research docs
  2. create a Linux-host checkpoint
  3. verify the checkpoint manifest
  4. continue the build investigation only after the checkpoint exists
- Never keep more than one validated fix uncheckpointed.
- Never archive the full `BUILD/` directory blindly.
- Preserve intentional untracked headers and shims explicitly.
