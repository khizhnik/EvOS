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

## Bottom Line

- PureDarwin is the only public Darwin-flavored x86_64 QEMU path I could verify as bootable, but it is old and incomplete.
- XNU is alive and useful as reference material, but not a standalone OS plan.
- GNUstep is the strongest living userland technology for EvOS.
- wlmaker is useful for desktop prototyping on a Linux host.
- Darnix is not ready for architectural decisions.
