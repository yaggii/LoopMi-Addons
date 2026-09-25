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

## [0.81.0] - 2026-09-25
### Added
- (Cloud) Missed checklists are recorded (Azure Boards #100, architecture §14.2). `ChecklistMiss` is a sealed record
  in the Location's chain, written once when a scheduled slot's window closes with no submission. It keeps what
  any partial draft had reached: who started it, and how many items were answered. `ChecklistMissSweepService`
  finds those slots in each Location's own time zone, over the last two days so a stopped sweep catches up. It
  skips suspended Organizations and checklists archived before the slot opened, and on-demand checklists never
  miss. A late completion that day still works and leaves the miss in place; both records name the same schedule
  and local date.

## [0.80.0] - 2026-09-25
### Added
- (Cloud) Corrections to submitted checklists (Azure Boards #94, architecture §14.3). `ChecklistCorrection` is its
  own sealed record in the Location's chain: it links to the run and item, keeps the value it replaces and the new
  one, and carries the mandatory reason, the corrector and the server time. The run itself never changes. A new
  value is checked with the same rules as the employee's answer (type, options, the limits that applied), and a
  non-conforming value needs a corrective action. A corrected sensor reading is marked as typed. Corrections of the
  same item chain one after another, and each must be based on the latest, so a concurrent correction is refused.
  `ChecklistCorrectionService` refuses corrections during a platform administrator's support session. New
  `ChecklistFailureReason` values: `RunNotSubmitted`, `ItemNotFound`, `ItemNotAnswered`, `CorrectionReasonRequired`,
  `CorrectionUnchanged`, `CorrectionDuringSupportSession`, `ItemCorrectedSinceOpened`.

## [0.79.0] - 2026-09-24
### Added
- (Cloud) Completing checklists on the Location tablet (Azure Boards #87-#90, architecture §14.2). `ChecklistRun`
  is one completion: started by an employee with their PIN, every item copied in with its question, the limits that
  applied (a sensor item's override, else the Equipment's own range), the Equipment's name and any skip reason
  (maintenance, retired, archived, gone, moved). Answers are saved one by one with the server's time; a
  non-conforming answer needs a corrective action; a sensor value records whether it came from the sensor (with the
  reading's time) or was typed because the sensor had no recent reading. Signing needs the PIN again: the server
  stamps the submission, marks it Late after its slot closed (allowed until the end of that local day), and seals
  the run into the Location's chain. `TabletChecklistService` lists what is due, late and on demand, refuses new
  checklists for a suspended Organization, reopens a draft after a reload, and lets only the first of two tablets
  submit a slot. PIN checks are shared with check-in through `IEmployeePinVerifier` (same lockout).
  No Edge-visible change.

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
