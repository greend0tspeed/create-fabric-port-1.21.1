# Create Fabric Logistics

Unofficial, experimental Create 6.0.10 compatibility work for Minecraft 1.21.1 on Fabric. The project name is provisional.

This project builds on Create, Create Fabric, and Create Reforged. It is not endorsed by or affiliated with their development teams or the Cobblemon team.

## Functionality and testing

The private build includes Create machinery, trains, packaging, Frogports, chains, postboxes, stock networks, requesters, Factory Gauges, shops, elevators, Schematicannon and adapted logistics Ponders.

Core workflows have undergone extensive private singleplayer and multiplayer testing, including use with Cobblemon. Targeted dedicated-server tests passed for Deployer interactions/drop capture, crop replanting, and package-address display output. See [testing status](TESTING.md). Complete upstream parity and universal mod compatibility are not established. New Ponder playback and optional-mod harvesting still need further testing. Disconnect/passenger-update reports and cardboard advancement trigger errors remain open.

## Publication status

**Release preparation only. No runtime download is provided here.** Reserved-asset permissions, bundled-library notices/source obligations and Modrinth eligibility remain unresolved. This repository of documents does not grant permission to redistribute any upstream asset or binary. See [license overview](LICENSE.md), [third-party notices](THIRD-PARTY-NOTICES.md), and [release checklist](RELEASE-CHECKLIST.md).

## AI assistance

OpenAI Codex substantially assisted upstream-source adaptation, compatibility code, debugging, tests, and release documentation. No AI-generated visual or audio assets were added by this porting effort. This disclosure concerns the fork's changes and does not attribute AI use to upstream authors.

## Credits

- [Creators of Create](https://github.com/Creators-of-Create/Create), official 6.0.10 source, commit ac0c444d9828da3453ae8cc65338e8de063286fb.
- [Fabricators of Create](https://github.com/Fabricators-of-Create/Create), Fabric donor, commit 4c3fe779d135d592548e4cb09da04d742d2637b7.
- [sanufsoii / Create Reforged](https://github.com/sanufsoiii/create-unofficial), Fabric 1.21.1 baseline.
- [Ponder contributors](https://github.com/Creators-of-Create/Ponder) and the authors of bundled libraries.

Maintainer identity and a public source/build release remain pending. This document repository is not the complete corresponding source for the private jar. Report this fork's issues to its maintainers rather than upstream developers.