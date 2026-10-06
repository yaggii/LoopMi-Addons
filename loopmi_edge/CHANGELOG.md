# Changelog

All notable changes to the LoopMi Edge Home Assistant add-on are documented here.

This file follows [Keep a Changelog](https://keepachangelog.com/) conventions and the
project's [Semantic Versioning](../../deployment/VERSIONING.md) policy. **Every version
tag pushed through `.github/workflows/addon-ghcr.yml` must add an entry here first** -
the workflow checks for a matching `## [X.Y.Z]` heading and fails the release if one
isn't found. See `addons/loopmi_edge/README.md` for the packaging model this supports.

Entries are platform-wide (this repo publishes the Edge add-on and the Cloud shared
kernel from the same tag), so each item is marked with what it actually affects: the
Edge add-on itself, or the Cloud Portal/API only.

**Keeps only the 10 most recent releases** - Home Assistant Supervisor surfaces this
file to end users when offering an update, and 130+ versions of history is noise, not
information, for that audience. When adding a new entry, drop the oldest one so the
file never holds more than 10 - the full history remains in git (`git log -p --
addons/loopmi_edge/CHANGELOG.md`) for anyone who needs it. The release pipeline fails
the build if this file ever exceeds 10 entries, so trim before tagging, not after.

## [0.101.0] - 2026-10-06
### Added
- (Cloud) A file on training and delivery records (Azure Boards #176): a training record can carry one certificate and a delivery record one delivery note (a PDF or an image, up to 5 MB), attached when the entry is made and sealed with it - its hash is part of the sealed record. Opening a file checks it still matches that hash. An Owner can remove a stored file later (for instance when it shows more personal data than may be kept); the removal is a sealed record of its own and the entry keeps verifying. Files are included in an Organization's export and restore (archive format 1.14); archives from before 1.14 still restore.
- No Edge change.

## [0.100.1] - 2026-10-06
### Changed
- (Cloud) Privacy Policy version 3 (Azure Boards #170): the policy now names staff records explicitly - training records, goods-receiving records and signed checklist records - with their legal basis, how long they are kept, and the rights of the employees named in them. Every user is asked to accept the new version at their next sign-in.
- No Edge change.

## [0.100.0] - 2026-10-06
### Added
- (Cloud) Goods-receiving records (Azure Boards #173, part of the HACCP evidence gaps #170): each delivery - supplier, product, lot number, best-before, quantity, arrival temperature, accepted or rejected with the reason - is recorded by an employee with their PIN and sealed into the Location's tamper-evident chain, never edited; a mistake is voided with a reason. Searchable by lot and supplier for a recall. Included in an Organization's export and restore (archive format 1.13); archives from before 1.13 still restore.
- No Edge change.

## [0.99.2] - 2026-10-06
### Fixed
- (Cloud) Release housekeeping only: 0.99.0 and 0.99.1 were tagged without a changelog entry, so their add-on release failed the changelog check; their entries are added here. No behavior change since 0.99.1.
- No Edge change.

## [0.99.1] - 2026-10-06
### Changed
- (Cloud) The failure codes of staff training records are prefixed `Training` (`TrainingDetailsInvalid`, `TrainingVoidReasonRequired`, `TrainingAlreadyVoided`, `TrainingChangeDuringSupportSession`) so they cannot clash with other codes in the Portal's shared message file.
- No Edge change.

## [0.99.0] - 2026-10-06
### Added
- (Cloud) Staff training records (Azure Boards #172, part of the HACCP evidence gaps #170): who was trained on what, when, by whom and until when. Each record is sealed into its Location's tamper-evident chain and is never edited; a mistake is voided with a reason (the voiding is sealed too). Included in an Organization's export and restore (archive format 1.12); archives from before 1.12 still restore.
- No Edge change.

## [0.98.0] - 2026-10-06
### Changed
- (Cloud) Terms of Service / Privacy Policy version raised to 2 (Azure Boards #167): the policy, terms and cookie policy now cover inspector access - disclosure to competent authorities, the organization's responsibility for who it gives access to and for informing its staff, and the inspector's browser session storage. Every user is asked to accept the new version at their next sign-in.
- (Cloud) The email an inspector receives with their access link now carries the privacy notice and a link to the Privacy Policy.
- No Edge change.

## [0.97.0] - 2026-10-05
### Added
- (Cloud) Inspector access, second part (Azure Boards Epic #147): an Organization's export now includes its inspector access grants and everything inspectors read under them (archive format 1.11). Restoring brings every grant back as revoked history - a restore never re-opens access - and the access log exactly as it was. Archives from before 1.11 still restore.
- No Edge change.

## [0.96.0] - 2026-10-05
### Added
- (Cloud) Inspector access, first part (Azure Boards Epic #147): the building blocks for an Owner or Admin to give a food-safety inspector time-limited, read-only, logged access to chosen Locations - the grant, its emailed link and one-time code sign-in, a separate inspection token that can never be used on the management API, and the access log. Nothing is visible in the Portal yet.
- No Edge change.

## [0.95.0] - 2026-09-29
### Added
- (Edge + Cloud) A device Home Assistant reports `unavailable` now counts as offline without waiting for its own "offline after" time (Azure Boards #146). The add-on sends the monitored channels Home Assistant reports unavailable, and since when, with every check-in. The Cloud marks the device offline once every monitored channel has been unavailable for 5 minutes - Home Assistant marks everything unavailable for a moment while it restarts. The alert reads "Home Assistant reports sensor ... unavailable". The per-device "offline after" rule works as before, and a device set to 0 (offline alerting off) still sends no offline alert. `unknown` (no value yet) is not offline.
- (Cloud) New column `Channels.UnavailableSinceUtc` (migration `AddChannelUnavailableSince`).
