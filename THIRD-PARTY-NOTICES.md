# Third-party notices and source availability draft

Status: incomplete publication notice. This document preserves provenance and flags missing work; it is not a grant of rights and must not be presented as licensing clearance.

## Create source and assets

Official Create 6.0.10 source: [Creators-of-Create/Create](https://github.com/Creators-of-Create/Create/tree/ac0c444d9828da3453ae8cc65338e8de063286fb), commit `ac0c444d9828da3453ae8cc65338e8de063286fb`.

Preserve the verbatim split-license notice in `licenses/Create-6.0.10-LICENSE.md`. It grants MIT terms for the other files while reserving rights to files under `src/main/resources/assets/`. The current runtime jar's simple MIT metadata does not express that distinction. Redistribution authorization for those protected assets has not been established in this audit.

Fabric donor: [Fabricators-of-Create/Create](https://github.com/Fabricators-of-Create/Create/tree/4c3fe779d135d592548e4cb09da04d742d2637b7), commit `4c3fe779d135d592548e4cb09da04d742d2637b7`. Its pinned license has the same code/asset split. Preserve its notices separately.

Fabric 1.21.1 baseline: [sanufsoiii/create-unofficial](https://github.com/sanufsoiii/create-unofficial), recorded source commit `ee22ed23ccbe034ce6644a29a68f5f5e7a7a4e09`, patched baseline jar SHA-256 `ac2c5c18add02941f71f6917604e24ae857f630d288814acf6f8de17b0ba2192`. The baseline project documents loading separately obtained original assets. This project's current full-asset assembly differs from that packaging.

`Create-UfoPort-LICENSE.txt` preserves an additional local predecessor notice naming vlad250906. The relationship of that predecessor to every component of the baseline binary must be reconciled before treating it as the baseline's complete license record.

## Ponder and Catnip

Source: [Creators-of-Create/Ponder](https://github.com/Creators-of-Create/Ponder). The recorded Catnip donor commit is `eff36cf1a4a1826178cf85f1b475af761df770ab`. Preserve `Ponder-LICENSE.txt` and `Catnip-LICENSE.txt` and match each included adaptation/resource to its donor. These MIT notices do not license the separate reserved Create artwork.

## Embedded libraries

The recursive artifact inventory is `the private artifact audit`. Metadata identifies:

| Component | Recorded version | Declared or embedded licensing evidence |
|---|---|---|
| Flywheel | 0.9.0-a | MIT metadata; license text absent from its nested jar |
| Milk | 1.5.0 | MIT metadata; license text absent from its nested jar |
| Porting Lib UFO | 2.7.0 | LGPL-3.0-or-later metadata; its own license text absent |
| Registrate Fabric | 1.6.0 | MPL-2.0 metadata; its own license text absent |
| Forge Config API Port | 21.1.3 | MPL text, Forge/NightConfig notices, and a separate reserved-assets notice embedded |
| NightConfig core and TOML | 3.8.0 | Separate jars lack their own license text; the Forge Config API Port archive includes NightConfig's LGPL notice |
| Commons Logging | 1.3.3 | LICENSE and NOTICE embedded beneath Porting Lib UFO |

Some components appear more than once because dependency jars embed their own dependencies. Do not infer that an outer archive's MIT metadata relicenses any of these components.

For modified or redistributed LGPL/MPL components, determine the applicable source-availability, notice and redistribution requirements and provide the exact matching sources and modification records. The private source review snapshot has not been verified as complete corresponding source for every binary. [MPL distribution FAQ](https://www.mozilla.org/en-US/MPL/2.0/FAQ/), [LGPL 3.0](https://www.gnu.org/licenses/lgpl-3.0.html).

The embedded Forge Config API Port assets notice reserves rights to its assets. Verify the applicable redistribution permission or use a permitted dependency distribution route; do not discard or override that notice.

## Fork modifications

This fork's compatibility changes and tests were substantially assisted by OpenAI Codex. Maintain source attribution and modification history. Final maintainer identity, license choice for eligible original contributions, public source URL and support URL remain pending. Do not replace third-party copyright notices with the fork maintainers' names.
