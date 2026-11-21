# Source and build review snapshot

This directory publishes the existing source snapshot for review. It does not contain a runnable mod jar, upstream assets, dependency binaries, caches, logs or worlds. No gameplay changes were made for this upload.

## Layout

- `baseline-source/`: baseline source and non-asset data/build files.
- `integration-source/`: adapted port source, including supporting modules.
- `integration-tools/`: build, packaging and audit tools.
- `test-source/`: targeted test source and scripts.
- `build-and-provenance/`: selected-overlay build scripts, pinned references and change manifests.
- License documents and notices are in the repository's root `licenses/` directory and `THIRD-PARTY-NOTICES.md`.

## Build status

The working private build compiles selected source overlays against a pinned, patched baseline binary. A complete from-source build of the whole mod is unverified. Scripts retain the original integration workspace layout and expect locally supplied baseline/dependency inputs; this publication layout is not a turnkey Gradle project. Do not assume running the baseline Gradle project produces the tested private jar.

Start review with `build-and-provenance/ASSEMBLE-ALPHA.ps1`, `BUILD.ps1`, the lock manifests and change manifests. Missing dependency/input reconstruction and matching source obligations remain release tasks. Reserved upstream assets have deliberately been excluded, so this source snapshot alone cannot reproduce the full-asset private runtime.

## Provenance

Published from the prepared source-review snapshot SHA-256 `7f2734698e355fb91f2f26287f9858c8e132ca3d37ea8df0962089e50f7fbb46`. Exact upstream commits are recorded in the manifests. Preserve upstream copyright and license notices. See the root AI disclosure for Codex's role in compatibility adaptations and testing.
