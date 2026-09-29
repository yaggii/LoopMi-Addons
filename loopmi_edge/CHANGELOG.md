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

## [0.90.0] - 2026-09-29
### Added
- (Cloud) Checklist photos travel in the Organization backup (Azure Boards #143): archive format 1.8 carries each photo's image, listed with its SHA-256 in the signed manifest; a photo an Owner removed is not included. A restore checks every image against the hash its record's seal covers and refuses a missing or changed one as tampering (a platform administrator can override, and the record is then flagged), then copies the images to the target Organization.
- (Cloud) The export records the archive's size, so the Owner sees it before downloading
### Changed
- (Cloud) Restore reads the uploaded archive from private blob storage as a stream instead of keeping it in the database and in memory, and each Location's readings are imported a batch at a time - memory no longer grows with the archive. The upload goes straight to storage through a short-lived link (`CreateUploadAsync`), and `RequestRestoreAsync` takes that upload's identifier instead of the archive's bytes. A finished or failed job's uploaded archive is deleted. `OrganizationRestoreJob.ArchiveContent` is replaced by `ArchiveBlobPath`.

## [0.89.0] - 2026-09-28
### Added
- (Cloud) An Owner can redact a checklist photo (Azure Boards #142), for instance under an erasure request: the image is deleted, while the photo's hash stays in the record's seal. The removal is its own sealed record (which photo, why, who and when), so the record still verifies. Refused during a support session and without a reason; a photo is redacted once.
- (Cloud) Organization archive format 1.7 carries photo redactions

## [0.88.0] - 2026-09-28
### Added
- (Cloud) Checklist photos as proof (Azure Boards #113): each checklist item can ask for a photo (optional, required, or required when the answer is a non-conformity), and a checklist can require a photo of every corrective action. A tablet adds up to 3 photos of each kind per item; signing is refused while a required photo is missing. The seal covers each photo's SHA-256, type and size. Runs without photos are sealed exactly as before, so every existing record still verifies.
- (Cloud) Organization archive format 1.6: photo settings and each photo's hash travel with the checklist records (the images themselves follow in a later release)

## [0.87.0] - 2026-09-28
### Fixed
- (Cloud) A seal key rotation whose new key version keeps failing its checks on the effective date can now be cancelled by a platform administrator; before, cancelling stopped at the effective date, so a stuck rotation retried forever
- (Cloud) A stuck rotation now emails platform administrators once, then once a day while it fails the same way, instead of every 15 minutes

## [0.86.1] - 2026-09-28
### Changed
- (Cloud) A finished Organization export can now be downloaded for three full days instead of 48 hours
  (`OrganizationExportService.DownloadLinkLifetime`). That leaves time to fetch it even if the Organization is
  deleted right after. The storage cleanup rule moves to 3 days to match (LoopMi-Infra). No Edge-visible change.

## [0.86.0] - 2026-09-27
### Added
- (Cloud) Seal key rotation on its effective date (Azure Boards #110) and archive format 1.5.
  - New `SealKeyRotationService`. Shortly after a rotation is scheduled, it creates the next key version, or
    adopts one an interrupted run already created. It registers that version as pending
    (`SealKeyVersion.Prepare`, `IsPending`) and escrows it. The pending version signs nothing.
  - On the effective date the service first checks the new version: it is in the vault with the registered public
    key, it is escrowed, and it produces a signature that verifies. If any check fails, nothing changes; the
    failure is recorded and platform administrators are emailed. Otherwise the new version is activated and the
    old one retired.
  - Every Location chain then gets a `RecordChainCheckpoint` sealed with the new version. The old version is
    disabled in the vault (never deleted), the escrow records its range, and platform administrators get a
    report. Steps after the switch are retried if they fail.
  - The registry, not the vault's newest version, now decides which version signs. A version the registry has
    never seen still signs at once (a hand rotation), except while a scheduled rotation is creating its next
    version.
  - New `ISealKeyRotator`, `IRecordChainCheckpointRepository` and
    `ISealKeyVersionRepository.IsNextVersionBeingPreparedAsync`.
  - Archive format 1.5 adds each Location's `Checkpoints.jsonl` and `RestoredFlags.jsonl`. A record flagged at an
    earlier restore still fails verification, but the archive's signature vouches for its flag, so the problem
    counts as known and the flag carries over to the restored Organization. Formats 1.0 to 1.4 restore as before.
  - No Edge-visible change.

## [0.85.0] - 2026-09-25
### Added
- (Cloud) Scheduled seal key rotations and archive format retirements (Azure Boards #108, #109).
  - New platform-wide `ArchiveCompatibilityChange`: a rotation (retires the key version signing today) or a
    format retirement (that version and older), with a required reason.
  - Notice rules: 15 days or more; 7 to 14 days only when forced; never less than 7 or more than 365.
  - Only one pending change per kind. A change can be cancelled before its effective date, and every action goes
    into the change's audit trail.
  - `ArchiveCompatibilityService` schedules, cancels and lists changes. Its `RunAsync` puts due format retirements
    in effect and emails the Owners of every Organization holding an affected export: when the change is
    scheduled, 3 days before, on the effective date, and if a change they were told about is cancelled.
  - New permanent export log `OrganizationExportRecord` (Organization, date, format version, signing key version,
    who asked; facts only). `OrganizationExportService` writes it when an export completes.
  - Restore refuses an archive whose format was retired by a change now in effect, with new
    `DataPortabilityFailureReason.ArchiveFormatRetired`. A platform administrator can still override it (#106).
  - New repositories `IArchiveCompatibilityChangeRepository` and `IOrganizationExportRecordRepository`.
  - No Edge-visible change.

## [0.84.0] - 2026-09-25
### Added
- (Cloud) Restoring a refused archive anyway (Azure Boards #106). A platform administrator can override an
  integrity refusal by giving a reason and typing the target Organization's name
  (`RestoreIntegrityOverride`). The job records the reason, when it happened, and a report of everything the
  check found (`OrganizationRestoreJob.RecordIntegrityOverride`).
  - Every record is restored as it is in the archive. Only the sealed records that failed verification get a
    permanent `RestoredRecordFlag` (Location, record, restore job, issue).
  - New `OrganizationArchiveVerifier.Inspect`, which lists every checksum problem, and a lenient
    `ChecklistArchiveIntegrity.ReadAndVerifyAsync(allowFailures)`.
  - New `IDataPortabilityRepository.AddRestoredRecordFlags`.
  - New `DataPortabilityFailureReason` values: `IntegrityOverrideReasonRequired` and
    `IntegrityOverrideConfirmationMismatch`.
  - No Edge-visible change.

## [0.83.0] - 2026-09-25
### Added
- (Cloud) Checklists in backup and restore (Azure Boards #104, #105). Archive format 1.4:
  - The export now carries checklist templates and schedules with their history. Per Location, as JSON Lines, it
    carries the sealed runs, corrections and missed records with their record chain and seals. It also includes
    the seal keys used, and a manifest signed with the seal key (`manifest.sig.json`), so an edit to any file is
    detectable.
  - Before anything is imported, a restore checks the manifest signature against the platform's key registry,
    then every checksum, then every Location's chain and seals against the records rebuilt from the archive. Any
    failure refuses the restore with a report naming the Location and records.
  - An unknown or retired signing key is refused too. New `DataPortabilityFailureReason` values:
    `ArchiveSignatureInvalid`, `ArchiveSealKeyUnknown`, `ArchiveSealKeyRetired` and
    `ArchiveRecordsFailedVerification`.
  - Restored records keep their identifiers and seals, and each chain continues from its restored head.
  - Older archives (1.0-1.3) restore as before.

## [0.82.0] - 2026-09-25
### Added
- (Cloud) Emails about missed checklists (Azure Boards #101, #102).
  - When the sweep records misses at a Location, the last of them raises one `ChecklistSlotsMissedDomainEvent`
    listing them all. It goes through the existing Outbox, so it is emailed to Owners and Admins once per Location
    per sweep (never one per slot) and appears in the alert feed. Each line gives the checklist, its window in the
    Location's time zone, and any partial draft's progress.
  - `ChecklistMissDigestService` sends a daily digest at 08:00 local time. It goes out once per Organization and
    time zone, grouping that zone's Locations, and lists the previous day's misses, leaving out those completed
    late since. There is no email when there is nothing to report. A `ChecklistMissDigest` note records each
    digest sent, so it goes out once.
  - Alert and digest emails format dates in English whatever the server's culture.
