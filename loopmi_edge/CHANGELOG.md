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

## [0.62.1] - 2026-09-04
### Fixed
- Backfills the two changelog entries below - `v0.61.0` and `v0.62.0` were tagged without a matching entry
  here, which is exactly what this file's own gate exists to catch (`azure-pipelines-addon-ghcr.yml`'s
  "Verify CHANGELOG.md has an entry for this version" step correctly failed both of those releases as
  designed). No code change beyond this file.

## [0.62.0] - 2026-09-04
### Added
- (Cloud) `IEmployeeManagementService.ClearLockoutAsync` (Azure Boards #56) - lets an Owner/Admin manually
  clear an employee's PIN lockout (see 0.61.0 below), for when the employee simply mistyped their own PIN
  repeatedly rather than an attack.

## [0.61.0] - 2026-09-04
### Added
- (Cloud) `Employee` PIN lockout (Azure Boards #56) - locks out after 5 consecutive failed check-in PIN
  attempts, mirroring `User`'s existing Portal-login lockout (`AccessFailedCount`/`LockoutEndUtc`/
  `IsLockedOut`/`RecordFailedPinAttempt`/`RecordSuccessfulCheckIn`). Closes a real brute-force gap: a
  4-digit PIN is only 10,000 combinations, and `tablet-check-in` has no Portal JWT gating it, so a stolen
  tablet device credential could otherwise script through every combination for one employee unopposed.
  `TabletCheckInService.SubmitCheckInAsync` checks the lockout before even touching `IPasswordHasher`.

## [0.60.6] - 2026-09-03
### Added
- (Cloud) `TabletCheckIn` domain model (Azure Boards #54, Location Status Tablet epic #48) - the "tap
  Check, pick your name, enter your PIN, done" flow: `ITabletCheckInService.SubmitCheckInAsync` verifies
  the presented PIN via the existing `IPasswordHasher`, rejects an employee that exists but belongs to a
  different Organization than the tablet with the exact same message as a missing employee (a cross-tenant
  guard, not just a not-found check), and records a `TabletCheckIn` snapshotting the employee's name and a
  human-readable summary of whatever was flagged as a problem at that moment (reusing `ITabletStatusService`
  rather than recomputing status a second way). `TabletStatusResult` gains a `RequiresCheck` field so the
  kiosk knows whether to offer the Check action at all. This repo adds the EF configuration + migration
  (incl. RLS, via a new `fn_TenantAccessByTabletDeviceId` predicate function), the two tablet-facing
  Provisioning endpoints (roster read + check-in submit, both device-credential authenticated), the
  Management history-listing endpoint, and the Portal check-in UI + history page.

## [0.60.5] - 2026-09-03
### Added
- (Cloud) `Employee` domain model (Azure Boards #53, Location Status Tablet epic #48) - a lightweight,
  Organization-wide identity used only for tablet check-in: a name and a 4-digit PIN, deliberately distinct
  from a Portal `User` (no email, no password, no TOTP, no Portal login capability at all). PINs are hashed
  with the existing Argon2id `IPasswordHasher` before storage - the same hasher used for full passwords,
  chosen deliberately because a 4-digit PIN's much smaller keyspace makes a slow, memory-hard hash more
  important, not less. `IEmployeeManagementService` covers add/rename/reset-PIN/remove; this repo adds the
  EF configuration + Row-Level Security migration, Management API endpoints, and the Portal admin CRUD page.

## [0.60.4] - 2026-09-02
### Added
- (Cloud) `ITabletStatusService` (Azure Boards #52, Location Status Tablet epic #48) - computes a paired
  tablet's current status across all three signal types for every Equipment it's configured to show:
  out-of-temperature (latest Temperature reading vs Equipment's own thresholds), Contact-kind Channel rule
  violations (via #51's `ContactExpectedStateRule`, skipped entirely when no rule is configured for a
  Channel), and compressor efficiency problems (reuses the existing Compressor Efficiency Report, checking
  whether today's local calendar day raised any flag - a 30-day lookback window gives its own baseline
  comparisons real history to work with, not just a factory-fresh empty range). This repo adds the
  tablet-facing status-read endpoint (device-credential authenticated) and the kiosk UI itself.

## [0.60.3] - 2026-09-02
### Added
- (Cloud) `TabletDevice`/`TabletPairingToken` domain model plus `ITabletPairingService`/`ITabletManagementService`
  (Azure Boards #49, Location Status Tablet epic #48) - a wall-mounted Android tablet pairs to exactly one
  Location via a short-lived pairing token (the same shape as `RegistrationToken`'s own Edge Gateway
  pairing flow), receiving a long-lived device credential in exchange, minted once and never rotated on
  its own - revoking the tablet is the only way to invalidate it. Admin can rename a tablet, pick which of
  its Location's Equipment are visible on it, toggle an informational "requires check" flag, and revoke.
  This repo adds the EF configurations + migration (incl. Row-Level Security), repository implementations,
  Management API endpoints (admin CRUD + the tablet-facing pairing exchange), and Portal admin UI.

## [0.60.2] - 2026-09-02
### Added
- (Cloud) `ContactExpectedStateRule`/`ContactExpectedStateWindow` and `IContactExpectedStateRuleRepository` -
  the admin-configurable "what counts as a problem right now" engine for a Contact-kind Channel (Azure
  Boards #51, Location Status Tablet epic #48). The same physical sensor type means different things
  depending on where it's mounted: a fridge door open is always a problem, a floor door open is always
  fine, a fridge curtain retrofit is fine open 09:00-23:00 but a problem open 23:00-09:00 - one rule per
  Channel, a default plus optional time-of-day overrides. This repo adds the EF configuration + migration,
  repository implementation, Management API endpoints, and Portal admin UI.

## [0.60.1] - 2026-09-02
### Fixed
- `HomeAssistantMeasurementKindMapping` now maps a Home Assistant `cover` entity's device_class (curtain,
  blind, shutter, shade, awning, damper, garage, gate) to `MeasurementKind.Contact`, matching what
  `binary_sensor`'s door/garage_door/window/opening device_classes already mapped to. A cover entity's
  open/closed state was already ingested correctly (its value already parsed via the existing on/off/
  open/closed state-word table), but its Channel was misclassified as `Other` since only binary_sensor's
  device_class vocabulary was recognized - found while scoping Azure Boards #50 (contact/door sensor
  support for the Location Status Tablet feature, epic #48).

## [0.60.0] - 2026-08-29
### Changed
- Version milestone bump - no functional change to the Edge add-on or the Cloud shared kernel beyond what
  already shipped in 0.51.62. Marks the close of the Data Analysis Follow-ups line of work (Azure Boards
  Epic #40): retention/pruning for OutboxMessages/RefreshTokens/LoginChallenges/PasswordResetChallenges,
  orphaned-user deletion, the Power rollup DateTimeKind fix, the asymmetric Power ingestion filter (plus its
  retroactive backfill), and the activity-tier terciles fix.

Earlier releases (`0.51.62` and before) have been trimmed per this file's 10-release retention policy
(added 2026-09-04) - see `git log -p -- addons/loopmi_edge/CHANGELOG.md` for the full history.
