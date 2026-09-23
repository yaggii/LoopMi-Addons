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

## [0.74.1] - 2026-09-23
### Fixed
- (Cloud) Organization export/restore now keeps each Location's time zone and where it came from (archive
  format 1.3, Azure Boards #76). Found in the live export/delete/restore E2E: a restored Location fell back to
  Europe/Lisbon, and since restored tablets come back revoked, nothing would report its real zone again until
  a tablet was re-paired - so its days would be cut at the wrong midnight. Archives from before 1.3 still
  restore, with the default zone; an identifier the host can't resolve is ignored. No Edge-visible change.

## [0.74.0] - 2026-09-23
### Changed
- (Cloud) Tablet check-ins now belong to their Location directly (Azure Boards #77): `TabletCheckIn` records its
  tablet's Location, check-in history is listed by Location, and access to check-ins is scoped by it - so the
  check-ins of a revoked or missing tablet can no longer disappear from view. Existing check-ins are updated
  from their tablet's Location. No Edge-visible change.

## [0.73.0] - 2026-09-23
### Added
- (Cloud) Locations now have their own time zone, always taken from browser information (Azure Boards #76):
  the browser of whoever creates or edits the Location, and - as soon as one reports - its paired tablet's
  browser, since the tablet is physically there. Every timestamp is still stored in UTC; the zone is only
  used to interpret the Location's own wall-clock rules (its local day, door-rule windows, report days).
### Changed
- (Cloud) The Location dashboard, Temperature Report, Temperature Comparison Report and tablet status now use
  the Location's time zone instead of a hard-coded Europe/Lisbon. Existing Locations keep Europe/Lisbon until a
  browser reports their real zone. No Edge-visible change.

## [0.72.0] - 2026-09-23
### Added
- (Cloud) Organization export archives are now versioned and self-checking (Azure Boards #74): every archive
  carries a `manifest.json` with its format version and a SHA-256 checksum and row count for every file.
  Restore checks the archive against its manifest when the restore is requested, and refuses one that was
  edited, has files added or removed, or is in a format this platform cannot read. Archives exported before
  this release have no manifest and are still accepted as format 1.0.
- (Cloud) Organization export/restore now carries each Location's energy and compressor-efficiency history -
  daily power rollups, efficiency results and flags, and Area energy rollups (Azure Boards #75). Raw power
  readings are pruned after the raw-retention window, so this is the only history for older periods; it
  used to be lost on restore. Archive format 1.2. No Edge-visible change.

## [0.71.0] - 2026-09-23
### Added
- (Cloud) Organization export/restore now carries the Location Status Tablet data (Azure Boards #71): the
  employee roster, tablets, contact-sensor expected-state rules and check-in history. Employee PIN hashes and
  tablet credentials are never exported - restored employees are marked "PIN reset required" until an
  Owner/Admin sets a new PIN, and restored tablets come back revoked and must be paired again. Archives
  exported before this release still restore, with no tablet data. No Edge-visible change.
- (Cloud) New `TabletCheckInFailureReason.PinResetRequired` - checked before the PIN lockout, so a restored
  employee's attempts never count towards it.

## [0.70.2] - 2026-09-17
### Fixed
- Backfills the `0.70.0`/`0.70.1` entries below - both tagged without one, same mistake as
  `0.61.0`/`0.62.0`/`0.63.0` (see `0.62.1`/`0.63.1`'s own entries) and `0.65.2`/`0.65.1` (see `0.65.3`'s own
  entry) before them - this gate keeps catching it. No code change beyond this file.

## [0.70.1] - 2026-09-17
### Fixed
- (Cloud) Wired the new `Reactivate` transition (see `0.70.0` below) into
  `EquipmentManagementService.ApplyLifecycleTransitionAsync`'s dispatch switch - missed in that release, so
  the Management API's lifecycle endpoint rejected it with `ArgumentOutOfRangeException` until this fix. No
  Edge-visible change - this only touches the Cloud management path.

## [0.70.0] - 2026-09-17
### Added
- (Cloud) `Equipment.Reactivate()` ("un-retire") - lets Retired equipment return to Operational, undoing a
  mistaken `Retire()`. Retired was never the terminal lifecycle state (Archived is), so this simply reopens
  that path; raises `EquipmentReactivatedDomainEvent` on success, matching `CompleteMaintenance`'s shape.
  Exposed as a new `Reactivate` value on the existing lifecycle transition endpoint, alongside
  `Commission`/`MakeOperational`/etc. No Edge-visible change - Equipment lifecycle management is a
  Cloud/Portal-only concern.

## [0.69.0] - 2026-09-15
### Changed
- (Cloud) `IMeasurementRepository.ListByEquipmentIdsAndTimeRangeAsync` now filters by the Channel's kind at
  the source (a join to Channels), instead of every caller fetching every kind an Equipment has ever
  recorded and filtering down to the relevant one afterward in memory. Found live: an Equipment carrying
  channels of several kinds (e.g. a Fridge with both a Temperature sensor and a Power-metering smart plug)
  meant a Temperature-only report also paid to fetch and transfer that Equipment's entire
  Power/Humidity/Battery history - part of why the Temperature Comparison report measured much slower than
  the Energy Comparison report for an equivalent range/reading volume. All 5 callers (the Energy/Temperature
  dashboard tiles, both comparison reports, and the plain Temperature report) updated to pass their own
  kind. No Edge-visible change - this only touches the Cloud reporting path.

## [0.68.2] - 2026-09-15
### Fixed
- (Cloud) The Temperature Comparison report's per-Equipment day loop re-scanned that Equipment's entire
  reading list once per day in the range (O(days x readings)) - found live as the reason it measured much
  slower than the Energy Comparison report for an equivalent range/reading volume, which already bucketed
  readings in one linear pass. Now buckets every reading against the range's day boundaries once, same
  result, no behavior change. No Edge-visible change - this only touches the Cloud reporting path.
