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

## [0.95.0] - 2026-09-29
### Added
- (Edge + Cloud) A device Home Assistant reports `unavailable` now counts as offline without waiting for its own "offline after" time (Azure Boards #146). The add-on sends the monitored channels Home Assistant reports unavailable, and since when, with every check-in. The Cloud marks the device offline once every monitored channel has been unavailable for 5 minutes - Home Assistant marks everything unavailable for a moment while it restarts. The alert reads "Home Assistant reports sensor ... unavailable". The per-device "offline after" rule works as before, and a device set to 0 (offline alerting off) still sends no offline alert. `unknown` (no value yet) is not offline.
- (Cloud) New column `Channels.UnavailableSinceUtc` (migration `AddChannelUnavailableSince`).

## [0.94.1] - 2026-09-29
### Fixed
- (Edge) Steady sensors now really stay fresh (Azure Boards #146). 0.94.0's subscription to Home Assistant's `state_reported` event is refused by every Home Assistant version, because that event needs a per-entity filter (found live on Home Assistant 2026.9). Instead, once a minute the add-on reads Home Assistant's states on its existing connection and records each monitored entity whose `last_reported` time moved, even with an unchanged value. No more "refused the state_reported subscription" warning.
- No Cloud change.

## [0.94.0] - 2026-09-29
### Fixed
- (Edge) A sensor with a steady value no longer looks offline (Azure Boards #146). The add-on also listens to Home Assistant's `state_reported` event (Home Assistant 2024.4 or later), which fires when a device reports the same value again, and sends each monitored channel's last-seen time with its regular check-in - no extra readings are stored. A plug on a constant load (UPS, router) stopped flapping between fresh and stale. On an older Home Assistant the add-on logs a warning and works as before.
- (Edge) A channel Home Assistant marks `unavailable` or `unknown` is no longer reported as seen, so the usual offline alert follows.
- (Edge) Subscribing to Home Assistant events no longer fails when an event arrives before the subscription's reply; that used to force a reconnect.
- (Cloud) Check-in accepts the channels seen and moves their last-seen time forward - never back, never into the future, only for the gateway's own channels.

## [0.93.0] - 2026-09-29
### Changed
- (Cloud) Alert emails read in plain words, never a raw status name (Azure Boards #145). The temperature alert says the Equipment "is too warm" or "is too cold" and gives the reading, when it was taken (Location time) and the acceptable range, e.g. "9.5 °C at 06:31 on Tue 29 Sep 2026 (Europe/Lisbon time) - acceptable 1 to 6 °C". `EquipmentTemperatureRangeStatusChangedDomainEvent` now carries the reading and the limits (optional; older events still read plainly). Battery, offline, leak, gateway connection and storage alerts are reworded the same way.
- (Cloud) A missed checklist a sensor anomaly started names the anomaly and its Equipment or Device, in the missed-checklist alert and in the daily digest, e.g. "Fridge checks - started by: temperature out of range · Under-counter Fridge" (Azure Boards #144). `MissedChecklistSlot` carries the `TriggerId`; `AlertEventDescriber` and `ChecklistMissDigestService` now take an `IChecklistTriggerRepository`.
### Fixed
- (Cloud) The daily digest now leaves out a triggered checklist that was completed late. It matched late completions by slot, which triggered checklists do not have.
- No Edge-visible change.

## [0.92.1] - 2026-09-29
### Fixed
- (Cloud) A door counts as "left open" (Azure Boards #122) only when it is open at a time its expected-state rule calls open a problem. A rule can also make "closed" the problem (a door expected to stay open during service); a closed door was then wrongly counted as left open. Found live on dev before any checklist was triggered by it.

## [0.92.0] - 2026-09-29
### Added
- (Cloud) Checklists started by sensor anomalies (Azure Boards #122): a schedule can be "when a sensor detects a problem", with the anomalies it answers - temperature out of range, a door left open, a sensor offline, a low battery - and a deadline (default 60 minutes, 5 minutes to a day), narrowed to an Area or an Equipment like any schedule. Each anomaly event (from the health sweep, through the outbox) starts the checklist on that Location's tablets as due; only one is open per schedule, anomaly and Equipment at a time. Past its deadline it is recorded as missed (a sealed `ChecklistMiss` naming the trigger) and it can still be completed late until the end of that day.
- (Cloud) Doors left open are detected: a contact sensor open for at least 5 minutes at a time its expected-state rule calls a problem raises `ChannelContactProblemChangedDomainEvent` (it starts checklists; it sends no email)
- (Cloud) Organization archive format 1.10 carries the triggered schedules, the checklists anomalies started (`Triggers.jsonl`), and the trigger each run and miss answers - outside their sealed content, so every record seals as before

## [0.91.0] - 2026-09-29
### Added
- (Cloud) Reference images on checklist items (Azure Boards #114): an Owner or Admin attaches up to 3 JPEG, PNG or WebP images to an item to show how the job should look, and the tablet shows them with the question. The template version keeps each image's hash, type and size, so changing an image makes a new version and every record points at the images it showed. What an image is comes from its upload (`IChecklistReferenceImageService`), never from the editor; a template can only name images its own Organization uploaded.
- (Cloud) Organization archive format 1.9 carries the reference images; a restore copies each one whose bytes match its item

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
