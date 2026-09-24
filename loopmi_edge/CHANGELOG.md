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

## [0.78.1] - 2026-09-24
### Fixed
- (Cloud) A weekly checklist schedule paused or changed on the day it was created still expected the week already
  under way under its first revision - that week would have been reported as missed. Days before a schedule's
  first revision applies now follow the newest revision saved on its creation day (Azure Boards #85).
  No Edge-visible change.

## [0.78.0] - 2026-09-24
### Added
- (Cloud) Checklist schedules per Location (Azure Boards #85, architecture §14.2). `ChecklistSchedule` places a
  template at a Location, optionally narrowed to one of its Areas or Equipment: daily, chosen weekdays, weekly or
  on demand, with an optional local time window (one ending before it starts runs past midnight). Every change,
  pausing included, is an immutable `ChecklistScheduleRevision` with who, the support access request if any, and
  the local date it applies from - the next day, so a slot already under way keeps its rules (the creation day is
  the exception). `ChecklistSlots.Between` works out expected slots for any range from the revisions, in the
  Location's time zone and daylight-saving safe (a skipped hour moves forward, a repeated hour counts once);
  `ChecklistScheduleService` validates the Location, template, Area and Equipment and lists slots for up to 62 days.
  `ChecklistItemSkipping` gives the reason an item about Equipment is skipped when a run starts (maintenance,
  retired, archived, gone, moved to another Location). New `ChecklistFailureReason` values for schedules.
  No Edge-visible change.

## [0.77.0] - 2026-09-24
### Added
- (Cloud) Checklist templates with versioned items (Azure Boards #83, architecture §14.2). `ChecklistTemplate`
  points at its current `ChecklistTemplateVersion`; versions never change, so editing creates the next version
  recording who (and, in a support session, which access request) and when, and every run will reference the
  version it used. Templates are archived, never deleted. Item types: yes/no (with the non-conforming answer and
  optional "not applicable"), number (limits, unit), sensor reading of an Equipment (limits optional - empty means
  the Equipment's own range at run time), choice (options can be non-conforming) and free text, each with optional
  instructions and a key that stays stable across versions; corrective-action presets per template.
  `ChecklistTemplateService` only accepts sensor-reading Equipment of the same Organization that is not Archived and
  has a temperature Channel, and reports two editors saving from the same version as `TemplateChangedSinceOpened`.
  No Edge-visible change.

## [0.76.1] - 2026-09-24
### Fixed
- (Cloud) Seal key escrow no longer breaks when an old key version is disabled after a rotation or a compromise
  (Azure Boards #81): a version whose public key the vault will not return is skipped when it was already
  escrowed (no false "registry disagrees" alarm), and reported when it never was. Found while writing the record
  integrity administrator guide's rotation procedure. No Edge-visible change.

## [0.76.0] - 2026-09-24
### Added
- (Cloud) Seal key escrow (Azure Boards #81, architecture §14.5). `SealKeyEscrowService` gives every seal key
  version a write-once bundle the first time it is seen - public key (DER and PEM), metadata and the vault's own
  encrypted backup - records which archive formats each version vouched for, adds the per-Location range it
  sealed when it retires, and cross-checks the key registry against the vault (emailing the platform
  administrator on any disagreement). `ReadKeysFromEscrowAsync` rebuilds a key registry from escrow files alone,
  so sealed records verify without the database or Key Vault. New `ISealKeyVault`/`ISealKeyEscrowStore` seams and
  `IRecordSealRepository.SummarizeByKeyVersionAsync`. No Edge-visible change.

## [0.75.0] - 2026-09-24
### Added
- (Cloud) Record sealing foundation (Azure Boards #80, architecture §14.4): tamper-evident records for the
  upcoming operational checklists. `CanonicalRecordBuilder` gives each record one unambiguous byte form (never
  including OrganizationId, so restored records still verify); `RecordChainHashing` chains records per Location
  (SHA-256 links from a Location-bound genesis); `RecordChainEntry`/`RecordSeal`/`SealKeyVersion` are the
  append-only chain, its signatures and the public key registry. `RecordChainService` appends a record in the
  same save as the record and retries when another tablet took the same position; `RecordSealService` signs
  through an `IRecordSigner` (Key Vault in the Cloud), never blocks a save when signing is unavailable, sweeps
  unsigned entries and warns the platform administrator after an hour; `RecordChainVerification` detects a
  changed field, reordered, removed or unchained records, and forged or unknown-key seals. No Edge-visible change.

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
