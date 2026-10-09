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

## [0.103.0] - 2026-10-08
### Changed
- (Cloud) The readings database no longer grows with time (Azure Boards #222): Humidity readings are kept for a week (only the latest value is ever shown), and Temperature and Energy readings older than two months and one month respectively are folded into 15-minute and one-hour summaries that keep everything the reports use - averages, minimums, maximums, standard deviation, conformance and consumption - so every temperature and energy report, the inspector view and the organization export give the same figures as before. An organization export now also carries those summaries (archive format 1.16).
- No Edge change.

## [0.102.1] - 2026-10-07
### Fixed
- (Cloud) A Portal session no longer stays valid for days (Azure Boards #180): a sign-in now ends after one hour without activity, and every use of the Portal keeps it going, so only an inactive session needs a new login. Before, a session lasted 30 days. The authentication code on a trusted device is unchanged.
- No Edge change.

## [0.102.0] - 2026-10-06
### Added
- (Cloud) The HACCP plan of each Location (Azure Boards #178, part of the HACCP evidence gaps #170): a manager uploads the plan as a PDF of up to 20 MB, with a title, a version label and the date it comes into force. Every upload is a new version, sealed into the Location's tamper-evident chain together with the PDF's fingerprint and never changed - a corrected plan is a new version, so the history of what was in force when is never rewritten. The plan opens only if the stored file still matches its fingerprint. Included in an Organization's export and restore (archive format 1.15); archives from before 1.15 still restore.
- No Edge change.

## [0.101.1] - 2026-10-06
### Changed
- (Cloud) Privacy Policy version 4 (Azure Boards #176): the retention and rights wording now names the one exception to "sealed records cannot be deleted" - an Owner can remove the file (a certificate or a delivery note) attached to a training or delivery entry, for example to answer an erasure request; the entry stays with the file's fingerprint and a sealed note of who removed it, when and why. Every user is asked to accept the new version at their next sign-in.
- No Edge change.

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

