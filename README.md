# Tau Ceti optimal transport layer: build check

This repository has one purpose: to let GitHub Actions compile, from source, the optimal
transport layer of the Lean library [Tau Ceti](https://github.com/TauCetiProject/TauCeti)
(the modules under `TauCeti/MeasureTheory/OptimalTransport/`, together with the Tau Ceti
modules they import) at one pinned commit, and to publish a readable build report.

It contains no Lean mathematics and no copy of Tau Ceti. Tau Ceti is fetched by the workflows
at run time.

## What is pinned

| item | value |
|---|---|
| Tau Ceti repository | `TauCetiProject/TauCeti` |
| Tau Ceti commit | `aa1b4e9e2a25944efe7815c1898fb9fd5e879c11` |
| Lean toolchain (from Tau Ceti's `lean-toolchain` at that commit) | `leanprover/lean4:v4.37.0-rc1` |
| Mathlib commit (from Tau Ceti's `lake-manifest.json` at that commit) | `31ce06eaadf4a200c0e1407c5f10953cf606b8f8` |
| elan | release `v4.2.3`, archive SHA-256 `df0b2b3a439961ffcbb3985214365ffe40f49bc871df04dff268c7d8e21ca8b2` |
| `actions/checkout` | `3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1) |
| `actions/upload-artifact` | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` (v7.0.2) |
| runner | `ubuntu-24.04` (a label: GitHub updates the image behind it) |

Every job checks the commit, the toolchain and the Mathlib revision it actually obtained against
these values, and stops if they differ.

## Two workflows

Both are started by hand only (`workflow_dispatch`). They differ in how Tau Ceti is obtained.

- **`ot-from-source.yml` (variant A).** Checks out Tau Ceti at the pinned commit and builds the
  layer inside Tau Ceti's own tree, with Tau Ceti's own `lakefile.toml` and `lake-manifest.json`.
- **`ot-as-dependency.yml` (variant B).** Treats Tau Ceti as a Lake dependency of this repository
  (`lakefile.toml`, `lean-toolchain` at the root of this repository) and builds the layer's
  modules as modules of that dependency. The transitive Mathlib revision is chosen by Lake; the
  job stops if it is not the pinned one.

In both, Mathlib's prebuilt files are fetched with `lake exe cache get`. Tau Ceti's own build
cache is **not** used, so the Tau Ceti modules are compiled by the job.

## How to run

The workflow files must be on the default branch. Then: *Actions* tab, choose a workflow,
*Run workflow*. The optional input `build_minutes` (default 300) limits the `lake build` step;
the job stops at 355 minutes, under GitHub's 6-hour limit for hosted jobs.

## The report

Each run uploads an artifact (`ot-build-report-from-source` or `ot-build-report-as-dependency`)
and writes the same Markdown report to the run's summary page. It contains:

- the machine as it reports itself (processors, memory, disk, image);
- the result of the pin checks;
- the duration of each scripted step (elan and toolchain installation, Mathlib cache, build);
- the exit code of `lake build` (124 means the time limit was reached) and its wall time;
- memory: the lowest `MemAvailable` seen in samples taken every 10 seconds during the build, and
  the peak resident memory of the largest single process (GNU `time`, if installed);
- the lowest free disk seen during the build;
- counts of `.olean` files present and written during the build, for the layer, for all of Tau
  Ceti and for Mathlib (Mathlib files written during the build mean the Mathlib cache did not
  cover the pinned revision);
- the first lines of the log that contain `error`, and the end of the log.

The full build log is in the artifact.

Nothing in this repository has been run yet. The workflows are a first attempt and may need
adjustments after the first run.

## Sources

Each action, option and command used here, and where it is documented:

- Runner sizes and limits: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
  and https://docs.github.com/en/actions/reference/limits
- `timeout-minutes`, `workflow_dispatch`, `permissions`, default `bash` shell:
  https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- `if: ${{ !cancelled() }}`: https://docs.github.com/en/actions/reference/workflows-and-actions/expressions
- `$GITHUB_STEP_SUMMARY`, `$GITHUB_ENV`, `$GITHUB_PATH`:
  https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands
- `actions/checkout` inputs (`repository`, `ref`, `path`, `fetch-depth`, `persist-credentials`):
  https://github.com/actions/checkout/blob/3d3c42e5aac5ba805825da76410c181273ba90b1/README.md
- `actions/upload-artifact` inputs (`name`, `path`, `if-no-files-found`, `retention-days`):
  https://github.com/actions/upload-artifact/blob/cf430e030ddbb5b0abf93d22962f4752f3646cd9/README.md
- elan release archive and installer flags (`-y`, `--no-modify-path`, `--default-toolchain none`):
  https://github.com/leanprover/elan/releases/tag/v4.2.3 and
  https://github.com/leanprover/elan/blob/v4.2.3/elan-init.sh
- `lake build` targets `+Module` and `@package/+Module`, Git dependencies in `lakefile.toml`:
  https://github.com/leanprover/lean4/blob/v4.37.0-rc1/src/lake/README.md
- `lake exe cache get`: https://github.com/leanprover-community/mathlib4/wiki/Using-mathlib4-as-a-dependency
- The installation sequence (pinned elan with checksum, `elan toolchain install`, `lake exe cache get`
  then `lake exe cache get!` on failure, raising `vm.max_map_count`) follows Tau Ceti's own CI,
  `.github/workflows/ci.yml` at the pinned commit:
  https://github.com/TauCetiProject/TauCeti/blob/aa1b4e9e2a25944efe7815c1898fb9fd5e879c11/.github/workflows/ci.yml

The official `leanprover/lean-action` is not used: its installer step downloads elan's installer
from a branch, which cannot be pinned by pinning the action
(https://github.com/leanprover/lean-action/blob/ba3fdfe5c4476c925da13bf11a005ddb47e47aee/scripts/install_elan.sh).

## Tau Ceti and its license

Tau Ceti is developed by the Tau Ceti contributors at https://github.com/TauCetiProject/TauCeti
and is licensed under the Apache License 2.0
(https://github.com/TauCetiProject/TauCeti/blob/aa1b4e9e2a25944efe7815c1898fb9fd5e879c11/LICENSE).
This repository does not contain or redistribute Tau Ceti's files; the workflows download them
from Tau Ceti's repository when they run, and the uploaded artifact contains build logs and
counts, not Tau Ceti's sources or compiled files.
