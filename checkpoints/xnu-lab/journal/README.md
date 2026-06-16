# XNU Build Lab Journal

This directory stores append-only checkpoint journal entries for the EvOS XNU build lab.

Use one entry per validated snapshot. Each entry should summarize:

- snapshot name
- VM commit / tag
- validated fixes included
- frontier at the time of capture
- notes about excluded unvalidated edits

The Linux-host snapshot tree remains the source of truth. The journal is an index and audit trail.
