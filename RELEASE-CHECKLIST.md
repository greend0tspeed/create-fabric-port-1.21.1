# Release checklist

This checklist applies to the audited build in README.md. No file is currently designated approved for upload.

## Publication gates

- [x] Record the exact gameplay jar hash; preserve the working jar unchanged.
- [x] Draft an accurate feature description and separate testing evidence from unverified behavior.
- [x] Preserve provenance for official Create, the Fabric donor, the Reforged baseline and Ponder.
- [x] Inventory the main jar, nested components and reserved-source asset paths.
- [x] Stage available license documents without changing their text.
- [ ] Establish authorization to distribute the protected assets, or complete a separately tested code-only packaging route.
- [ ] Ask Modrinth whether the disclosed AI-assisted fork meets its publication policy. Do not assume the word "assisted" changes how the actual contribution is assessed.
- [ ] Resolve missing license texts, notices, and exact source obligations for all nested components. Keep each component under its own applicable terms.
- [ ] Approve a distinct project name and identify the actual maintainers.
- [ ] Publish this fork's public source and issue tracker. Keep upstream credits, but send support requests to this fork.
- [ ] Prepare honest public build instructions with pinned, legally obtainable inputs. Do not call the selected overlay build a complete source build.
- [ ] Apply final metadata to a separate release candidate; retain mod ID `create` for interoperability. Add Java 21, declare the tested loader/API range, and list required external dependencies on the version page.
- [ ] Validate the final distribution layout on client and dedicated server, especially if assets or nested dependencies are repackaged.
- [ ] Visually test the new Ponders and record remaining open issues.

## Modrinth settings

- Project type: mod. Version channel: alpha. Game version: 1.21.1. Loader: Fabric. Client and server environments: required for this content mod.
- Declare derivative content and credit the source projects.
- Declare AI-generated code for substantial Codex-authored adaptations, and AI-generated text if this draft is used. Do not select AI-generated assets merely because development used AI; no such assets were added by this porting effort. Describe what the disclosure covers. [Disclosure guidance](https://support.modrinth.com/en/articles/16567675-content-disclosures).
- Use real in-game screenshots and an independently licensed, non-AI project icon or no icon. Do not reuse upstream branding without checking permission.
- Select licensing metadata that reflects the actual chosen distribution, not a blanket MIT label over reserved assets or separately licensed libraries.
- Check each external dependency against its exact published file/version; do not attach unrelated mods, resource jars or a full pack to this mod's release.

## Intended public files after clearance

1. One clearly named, versioned runtime jar for the approved packaging route.
2. Exact license texts and third-party notices inside the appropriate archives, plus an accessible source-availability notice.
3. A public matching source repository; a source jar may be an appropriate additional file if it meets Modrinth's file rules.
4. Release notes, known issues, dependency declarations, and a SHA-256 checksum tied to that exact runtime jar.

Do **not** upload the whole preparation directory. Exclude test-only harnesses, test worlds, logs, crash reports, development caches, the working full-asset jar until cleared, the official Create asset jar, and existing `.mrpack` files that have not had their own redistribution audit.

## Evidence already available

- Private gameplay confirmations are recorded in this chat and summarized in the description; they are not an exhaustive automated suite.
- Latest targeted server test: `../official-gap-runtime-pass.log`.
- Scoped addition/protection audit: `../official-gap-completion.json`.
- 376 protected classes remained byte-identical during the latest scoped completion work.
- Fifteen official logistics Ponder schematic assets matched upstream byte-for-byte in the private gameplay jar. That integrity check does not establish permission to redistribute them.

All public files must satisfy Modrinth's rights, attribution, accuracy and file-purpose rules. [Content Rules](https://modrinth.com/legal/rules).
