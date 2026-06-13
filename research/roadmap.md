# EvOS Research Roadmap

## Possible Technical Directions

1. Darwin-first reconstruction
- Use PureDarwin as the experimental guest and treat Apple's XNU sources as reference material.
- Goal: prove how far a standalone Darwin-flavored x86_64 QEMU image can go today.

2. OpenStep-first desktop
- Build on GNUstep as the primary userland and desktop framework.
- Keep the kernel choice open at first so the project can move without waiting on Darwin reconstruction.

3. Linux-hosted visual prototype
- Run GNUstep applications on a Linux base with wlmaker or a similar compositor/window-manager stack.
- Use this to validate look, workflow, and ergonomics before committing to a low-level OS direction.

4. Split-track strategy
- Keep one branch focused on bootability and one branch focused on the desktop model.
- This avoids blocking UI research on kernel/userland reconstruction work.

5. Comparative control path
- Study RavynOS as a live control sample for bootloader, packaging, self-hosting, and Darwin-like system layering.
- Use it to benchmark what a non-Apple base can solve that a pure Darwin reconstruction still cannot.

## Recommended First Milestone

Create a reproducible x86_64 QEMU research harness around the best currently bootable Darwin-flavored artifact, which is PureDarwin 17.4, and document exactly where it succeeds and fails.

Why this first:

- It answers the only high-risk question that cannot be answered by reading code alone: what actually boots today.
- It gives the project a concrete ceiling for the Darwin path.
- It prevents the team from over-investing in a hypothetical fresh Darwin build before the boot chain is understood.

## Recommended Next Steps

1. Audit the PureDarwin boot path.
- Capture firmware, CPU model, device model, storage, networking, and console requirements.

2. Map the missing userland pieces.
- Separate what comes from Apple sources, what PureDarwin reconstructed, and what is still absent.

3. Establish a GNUstep baseline.
- Identify the smallest useful GNUstep app set and the minimum runtime/dependency stack.

4. Decide the display stack direction.
- If the project wants a modern Linux-hosted prototype, wlmaker is the current fit.
- If the project wants a pure Darwin experiment, Wayland is secondary and should not drive the architecture.

5. Resolve Darnix before spending time on it.
- Do not plan around Darnix until a canonical repository or website is found.

6. Freeze the architecture after the first boot evidence.
- Only after the first bootable milestone should the project commit to a long-term kernel/userland direction.

## Fresh XNU Boot Feasibility Study

Goal:

- Determine whether a fresh build from the latest public XNU sources can produce a kernel that is meaningfully bootable in x86_64 QEMU.

Scope boundaries:

- Separate kernel compilation from full Darwin bootability.
- Treat Apple source publishing, bootloader setup, root filesystem composition, and userland reconstruction as distinct problems.
- Do not use a historical bootable artifact as proof that a fresh XNU tree boots.
- Treat Linux-hosted cross-toolchain progress as helpful for userland work, but not as evidence that the kernel or boot chain is solved.
- Treat OSX-KVM as bootstrap infrastructure for getting a macOS Apple-toolchain host, not as evidence of standalone Darwin viability.

Questions to answer next:

1. Can the current public XNU tree be built reproducibly on macOS with the documented SDK/KDK-based flow?
2. What exact bootloader path is required to hand the kernel off in QEMU?
3. What is the minimum root filesystem needed to reach a shell?
4. Which userland pieces are absolutely required versus optional?
5. Can any of this be done on Linux without turning the setup into a larger porting project than the kernel itself?
6. Can OSX-KVM reduce the cost of the first documented XNU build enough to justify using it as the initial host path?

Decision rule:

- If a fresh XNU build cannot be booted without major reconstruction, EvOS should treat Darwin/XNU as a reference lineage rather than the primary system base.

## Bottom Line

- PureDarwin is the only public Darwin-flavored x86_64 QEMU path I could verify as bootable, but it is old and incomplete.
- XNU is alive and useful as reference material, but not a standalone OS plan.
- GNUstep is the strongest living userland technology for EvOS.
- wlmaker is useful for desktop prototyping on a Linux host.
- Darnix is not ready for architectural decisions.

## The long-term goal is self-hosting.

The first EvOS images may be built using Linux, macOS, Xcode,
Apple SDKs, or other external tools.

This is acceptable for bootstrapping.

However, the project should treat external dependency as technical debt.

A mature EvOS system should eventually be able to build itself.
