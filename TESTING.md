# Testing status for the proposed alpha

Build SHA-256: `62967fd2ce5dbcecdc850923af24bc96d134cb2aa45797ba25db28cdb0b21881`.

No meaningful completion percentage has been measured. Tests establish specific workflows and configurations; class presence and successful compilation are recorded separately from behavior.

| Area | Evidence available | Remaining limits |
|---|---|---|
| Press, mixer, crushing wheels, cardboard production/equipment recipes | Maintainers reported successful private gameplay tests | Not every recipe or modded ingredient combination tested |
| Manual/scheduled trains | Maintainers reported successful gameplay and multiplayer use | Open passenger-update reports; all track/dimension/chunk edge cases not isolated |
| Packaging, unpacking, belts, Frogports, chains, postboxes | Maintainers reported successful end-to-end gameplay tests | No guarantee of every routing, loading or concurrent-use case |
| Stock Links, combined counts, Ticker, Keepers, Requester, shops | Maintainers reported successful ordering, quantity persistence, payment and delivery tests | Every network topology and restart scenario not covered |
| Factory Gauges | Latest basic fixes confirmed in gameplay; packet and render-state checks pass | Full automatic production/restocking graphs and all modes need broader testing |
| Schematicannon and elevators | Maintainers confirmed operation; latest Schematicannon UI confirmed | Complete schematic transform and all multiplayer edge cases not certified |
| Deployer | Dedicated-server assertions passed for lever on/off, three honeycomb collected, and capture cleanup after an exception | Every item-use interaction not tested |
| Harvester | Dedicated-server assertions passed for maturity checks, preserving an extra crop property when resetting age, and loading the sugar-cane tag | Farmer's Delight installed behavior and Cobblemon crops untested |
| Package-address display source | Dedicated-server assertions passed for registration, empty input, inventory and chain addresses, observer filtering, and nonconsumption | Client configuration/display-board presentation needs visual testing |
| New logistics Ponders | Fifteen official schematic assets match; narration/title/timing sequences preserved; scenes and registrations compile | Playback not visually exercised in a client |
| Other contraptions, fluid systems, arms, processing and displays | Source/class audit found implementations | Not a gameplay parity certificate for all of Create |

The latest isolated server test used Minecraft 1.21.1, Fabric Loader 0.19.5, Fabric API 0.116.17+1.21.1 and Cobblemon 1.8.2. This is a tested combination, not a universal compatibility range. Detailed runtime logs and audit records are retained privately by the maintainers.

Open reports include disconnect/registry-sync and passenger-update crashes. The isolated log also contains cardboard advancement trigger errors. These were not resolved by the last scoped addition and must not be described as fixed.

The release-preparation audit changed no gameplay classes or runtime jar. If licensing work changes the asset or dependency packaging, repeat client and server validation on the resulting release candidate.
