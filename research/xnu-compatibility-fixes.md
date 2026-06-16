# XNU Compatibility Fixes Registry

## Scope

This registry tracks disposable-worktree compatibility fixes discovered while building public XNU with modern Xcode/clang.

Current lab context:

- macOS 14.8.7 VM
- Xcode 16.0
- `xnu-10063.141.1`
- `ARCH_CONFIGS=X86_64`
- `KERNEL_CONFIGS=DEVELOPMENT`
- disposable worktree: `/tmp/evos-xnu-lab`

## Status legend

- `confirmed`: root cause identified, no validation fix applied yet
- `validated`: disposable-worktree fix applied and build advanced
- `pending`: researched but not yet fixed
- `superseded`: later work replaced the entry
- `risky`: workaround exists but should not be generalized

## Fix registry

| ID | Area | File | Symbol / Issue | Warning / Failure | Type | Fix strategy | Status | Research section | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-001 | SDK/bootstrap | `bsd/sys/make_symbol_aliasing.sh` | `availability.pl` missing | missing SDK helper | missing Apple/private header/tool | temporary compatibility generator / SDK helper shim | validated | [Availability.pl](xnu-build-lab.md#fix-f001) | `_symbol_aliasing.h` generation depends on public SDK metadata; no public `availability.pl` found |
| F-002 | DriverKit packaging | `iokit/DriverKit/Makefile` | 17 missing DriverKit headers | `No rule to make target` | stale public OSS snapshot contents | restore/copy headers from earlier Sonoma tags or map to `iokit/IOKit/` where identical | validated | [DriverKit headers](xnu-build-lab.md#fix-f002) | Public `xnu-10063.141.1` lost `iokit/DriverKit/*` files while the Makefile kept referencing them |
| F-003 | clang dead store | `pexpert/i386/pe_serial.c` | `register_read` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | replace assignments with `(void)MMIO_READ(...)` and remove dead local | validated | [pe_serial validation](xnu-build-lab.md#fix-f003) | Preserve MMIO read side effects |
| F-004 | DTrace dead store | `bsd/dev/i386/fasttrap_isa.c` | `retire_tp` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead store / declaration | validated | [fasttrap investigation](xnu-build-lab.md#fix-f004) | `retire_tp` was never read |
| F-005 | Build flags / MIG | `makedefs/MakeInc.def` | `-mach_msg2` in `MIGKSFLAGS` | clang rejects flag via MIG path | MIG/toolchain mismatch | remove `-mach_msg2` for the lab worktree or scope override to specific sub-makes | validated | [mach_msg2 experiment](xnu-build-lab.md#fix-f005) | Allows build to continue on Xcode 16.0 |
| F-006 | Firehose SPI | `os/firehose_buffer_private.h` | missing declarations | missing header | missing Apple/private header | temporary header-only compatibility shim | validated | [firehose shim](xnu-build-lab.md#fix-f006) | Declaration gap only; no function bodies needed for current build progression |
| F-007 | TrustCache SPI | `TrustCache/API.h` | missing declarations | missing header | missing Apple/private header | temporary header-only compatibility shim | validated | [TrustCache shim](xnu-build-lab.md#fix-f007) | Header-only shim was sufficient to cross `amfi.o` |
| F-008 | clang override diagnostics | `libkern/libkern/c++/OSMetaClass.h` | missing `override` annotations | `-Wsuggest-override` | clang 16 warning policy change | add `override` to affected virtuals | validated | [OSMetaClass validation](xnu-build-lab.md#fix-f008) | Apple later fixed the same family in `xnu-12377.101.15` |
| F-009 | clang dead store | `osfmk/i386/i386_timer.c` | `orig_abstime` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead local, preserve `mach_absolute_time()` call | validated | [i386 dead-store cleanup](xnu-build-lab.md#fix-f009) |  |
| F-010 | clang dead store | `osfmk/i386/pmap_internal.h` | `suppress_ppn` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead local / dead assignment | validated | [i386 dead-store cleanup](xnu-build-lab.md#fix-f010) |  |
| F-011 | clang dead store | `osfmk/i386/cpu_threads.c` | `phys_cpu` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead local / assignment | validated | [bulk dead-store cleanup](xnu-build-lab.md#fix-f011) |  |
| F-012 | clang dead store | `bsd/dev/dtrace/dtrace.c` | `np` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | replace dead temporary with direct assertion expression | validated | [bulk dead-store cleanup](xnu-build-lab.md#fix-f012) |  |
| F-013 | four-char constant | `iokit/Kernel/IOKitKernelInternal.h` | `kIOPageAllocSignature = 'iopa'` | `-Wfour-char-constants` | compiler behavior change | replace with explicit bit-shift expression preserving value | validated | [four-char validation](xnu-build-lab.md#fix-f013) |  |
| F-014 | pointer/int cast | `osfmk/i386/machine_routines.c` | `assert(ppn != (ppnum_t)NULL)` | `-Wvoid-pointer-to-int-cast` | compiler behavior change | change sentinel check to `assert(ppn != 0)` | validated | [machine_routines validation](xnu-build-lab.md#fix-f014) | `ppnum_t` is 32-bit; `pmap_find_phys()` returns zero on miss |
| F-015 | clang dead store | `iokit/Kernel/IOServicePM.cpp` | `controllingDriverMetaClass`, `controllingDriverRegistryEntryID` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | scope cleanup in `handleAcknowledgeSetPowerState()` only; keep trace behavior | validated | [iokit scoped cleanup](xnu-build-lab.md#fix-f015) | Avoid broad removal because the names are used in other functions |
| F-016 | clang dead store | `iokit/Kernel/IOService.cpp` | `us`, `didRegister`, `callerOptions`, `ok` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead locals/assignments only in failing functions; keep call side effects | validated | [iokit scoped cleanup](xnu-build-lab.md#fix-f016) | Scoped fixes applied in `IOServicePH::systemPowerChange()`, `terminatePhase1()`, `actionWillTerminate()`, and `actionWillStop()` |
| F-017 | clang dead store | `iokit/Kernel/IOPolledInterface.cpp` | `err` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead local / preserve break-only control flow | validated | [IOPolledInterface validation](xnu-build-lab.md#fix-f017) | `copyPollers()` returned `vars`; `err` was not propagated |
| F-018 | clang dead store | `iokit/Kernel/IODMACommand.cpp` | `mapperPageShift`, `mapOptions`, `check` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove unused locals and dead debug-only toggles | validated | [IODMACommand/IOMemoryDescriptor cleanup](xnu-build-lab.md#fix-f018) | `check` was only used in a `#if 0` block |
| F-019 | clang dead store | `iokit/Kernel/IOMemoryDescriptor.cpp` | `type`, `params`, `res` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead locals; keep `res` arm64-only use | validated | [IODMACommand/IOMemoryDescriptor cleanup](xnu-build-lab.md#fix-f019) | `res` is used only on arm64 coherent-IO path |
| F-020 | DTrace dead store | `bsd/dev/dtrace/dtrace_glue.c` | `ret` | `-Wunused-but-set-variable` | clang 16 dead-store diagnostic | remove dead declaration / replace return-value temp with direct calls | validated | [dtrace_glue cleanup](xnu-build-lab.md#fix-f020) | `assert_wait(...)` and `thread_block(...)` were only feeding ASSERTs in this build path |
| F-021 | four-char constant | `iokit/Kernel/IONVRAMV3Handler.cpp` | `VARIABLE_STORE_SIGNATURE = 'NVV3'` | `-Wfour-char-constants` | compiler behavior change | replace with explicit bit-shift expression preserving the same 32-bit signature value | validated | [IONVRAMV3Handler validation](xnu-build-lab.md#fix-f021) | Public Sonoma-era tags kept the historical signature unchanged; the build next advanced into `libkern/c++/OSMetaClass.cpp` |
| F-022 | DriverKit packaging | `iokit/DriverKit/Makefile` | missing local `OTHER_HEADERS` copies restored from export artifacts | `No rule to make target` | disposable-tree source restoration | copy the DriverKit-shaped export artifacts back into `iokit/DriverKit/` without touching Makefiles | validated | [DriverKit OTHER_HEADERS restoration](xnu-build-lab.md#fix-f022) | Restored `IOReturn.h`, `IORPC.h`, `IOKitKeys.h`, `IOKernelReportStructs.h`, `IOReportTypes.h`, `queue_implementation.h`, `macro_help.h`, `bounded_ptr.h`, `bounded_array.h`, `bounded_array_ref.h`, `bounded_ptr_fwd.h`, `OSBoundedArray.h`, `OSBoundedArrayRef.h`, `OSBoundedPtr.h`, `OSBoundedPtrFwd.h`, `safe_allocation.h`; `IOTypes.h` had already been restored earlier |

## Open blockers

| Priority | File | Issue | Failure class | First seen after | Next action |
| --- | --- | --- | --- | --- | --- |
| P1 | `makedefs/MakeInc.def` | `-mach_msg2` in `MIGKSFLAGS` | `clang rejects flag via MIG path` | DriverKit OTHER_HEADERS restoration | restore the lab-tree MIGKSFLAGS override / remove `-mach_msg2` in the disposable tree | current blocker | [mach_msg2 experiment](xnu-build-lab.md#fix-f005) | This blocker reappeared in the current disposable tree; `device_server.h` failed first, and `pe_serial.c` surfaced later in parallel |
| P2 | `bsd/dev/dtrace/dtrace.c` | `rval` / `rv` / `base` / `rval` | `-Wunused-but-set-variable` | earlier dtrace cleanup passes | continue scoped dead-store cleanup in the active dtrace functions | open blocker family | [bulk dead-store cleanup](xnu-build-lab.md#fix-f012) | later blocker family from previous runs |
| P3 | `bsd/dev/systrace.c` | `uargs` | `-Wunused-but-set-variable` | dtrace cleanup passes | verify if it is a pure dead local or used in a disabled trace path | open blocker family | [bulk dead-store cleanup](xnu-build-lab.md#fix-f012) | later blocker family from previous runs |
| P4 | `osfmk/i386/locks_i386.c` | `avg_hold_time` | `-Wunused-but-set-variable` | dtrace cleanup passes | inspect lock timing code and preserve any trace/log side effects | open blocker family | [bulk dead-store cleanup](xnu-build-lab.md#fix-f012) | later blocker family from previous runs |

## Build progression timeline

| Order | Blocker | Fix ID | Result |
| --- | --- | --- | --- |
| 1 | `availability.pl` missing | F-001 | validated in disposable worktree |
| 2 | 17 DriverKit headers missing | F-002 | validated in disposable worktree |
| 3 | `pe_serial.c` `register_read` | F-003 | validated in disposable worktree |
| 4 | `fasttrap_isa.c` `retire_tp` | F-004 | validated in disposable worktree |
| 5 | `-mach_msg2` in `MIGKSFLAGS` | F-005 | validated in disposable worktree |
| 6 | `firehose_buffer_private.h` missing declarations | F-006 | validated in disposable worktree |
| 7 | `TrustCache/API.h` missing declarations | F-007 | validated in disposable worktree |
| 8 | `OSMetaClass.h` missing `override` | F-008 | validated in disposable worktree |
| 9 | `i386_timer.c` `orig_abstime` | F-009 | validated in disposable worktree |
| 10 | `pmap_internal.h` `suppress_ppn` | F-010 | validated in disposable worktree |
| 11 | `cpu_threads.c` `phys_cpu` | F-011 | validated in disposable worktree |
| 12 | `dtrace.c` `np` | F-012 | validated in disposable worktree |
| 13 | `IOKitKernelInternal.h` four-char `iopa` | F-013 | validated in disposable worktree |
| 14 | `machine_routines.c` `(ppnum_t)NULL` | F-014 | validated in disposable worktree |
| 15 | `IOServicePM.cpp` dead stores | F-015 | validated in disposable worktree |
| 16 | `IOService.cpp` dead stores | F-016 | validated in disposable worktree |
| 17 | `IOPolledInterface.cpp` `err` | F-017 | validated in disposable worktree |
| 18 | `IODMACommand.cpp` `mapperPageShift` / `mapOptions` / `check` | F-018 | validated in disposable worktree |
| 19 | `IOMemoryDescriptor.cpp` `type` / `params` / `res` | F-019 | validated in disposable worktree |
| 20 | `dtrace_glue.c` `ret` | F-020 | validated in disposable worktree |
| 21 | `IONVRAMV3Handler.cpp` `VARIABLE_STORE_SIGNATURE` | F-021 | validated in disposable worktree |
| 22 | `DriverKit/OTHER_HEADERS` local restoration | F-022 | validated in disposable worktree |
| 23 | `makedefs/MakeInc.def` `-mach_msg2` | F-005 | current blocker after DriverKit restoration |
| 24 | `pe_serial.c` `register_read` | — | later parallel warning seen in the same run |
| 25 | `OSMetaClass.cpp` `alloc` | — | later blocker seen in another disposable run |
| 26 | `dtrace.c` `rval` / `rv` / `base` / `rval` | — | open blocker family |
| 27 | `systrace.c` `uargs` | — | open blocker family |
| 28 | `locks_i386.c` `avg_hold_time` | — | open blocker family |

## Statistics

| Metric | Count | Notes |
| --- | --- | --- |
| Total fixes | 22 | F-001 through F-022 |
| Validated fixes | 22 | all seeded registry entries have disposable-worktree validation |
| Pending fixes | 0 | no seeded fix remains unvalidated |
| Dead-store fixes | 12 | F-003, F-004, F-009, F-010, F-011, F-012, F-015, F-016, F-017, F-018, F-019, F-020 |
| clang compatibility fixes | 16 | dead-store + override + four-char + pointer/int classes |
| SDK/header fixes | 5 | F-001, F-002, F-006, F-007, F-022 |
| MIG fixes | 1 | F-005 |

## Current frontier

- Current blocker: `BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSMetaClass.h:1232`
- Current failure class: `-Winconsistent-missing-override`
- Latest successful subsystem reached: `pexpert/i386` after reapplying F-003; the build advanced past `pe_serial.o` and then failed in generated `libkern/c++` export headers

## Fix categories

- missing Apple/private headers
  - `availability.pl`
  - `firehose_buffer_private.h`
  - `TrustCache/API.h`
- stale public OSS snapshot contents
  - DriverKit header set under `iokit/DriverKit/`
- disposable-tree DriverKit export-header restoration
  - local copies restored from `BUILD/obj/EXPORT_HDRS/iokit/DriverKit/`
- clang 16 dead-store diagnostics
  - `pe_serial.c`
  - `fasttrap_isa.c`
  - `i386_timer.c`
  - `pmap_internal.h`
  - `cpu_threads.c`
  - `dtrace.c`
  - `IOServicePM.cpp`
  - `IOService.cpp`
  - `IOPolledInterface.cpp`
  - `IODMACommand.cpp`
  - `IOMemoryDescriptor.cpp`
- clang override diagnostics
  - `OSMetaClass.h`
- clang four-char constant diagnostics
  - `IOKitKernelInternal.h`
- pointer/integer cast diagnostics
  - `machine_routines.c`
- MIG/toolchain mismatch
- `-mach_msg2` in `MIGKSFLAGS`

## Rules for future fixes

- disposable worktree first
- no original checkout changes until validated
- no global `-Werror` suppression
- no broad search/replace
- preserve side effects
- prefer source-compatible fixes over build-flag suppression
- record exact diff and next blocker

## Links

- Primary research log: [research/xnu-build-lab.md](research/xnu-build-lab.md)

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
