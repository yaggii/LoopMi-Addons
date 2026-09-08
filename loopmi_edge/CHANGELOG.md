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

## [0.65.0] - 2026-09-08
### Changed
- (Cloud) Trusted-device window (Azure Boards #57) shortened from 30 days to 7 days - a direct follow-up
  ask, tightening the residual bearer-token exposure window tracked in Azure Boards #59 without giving up
  the convenience the feature is for.
### Added
- (Cloud) Per-device trusted-device management (Azure Boards #58) - `IAuthenticationService.ListTrustedDevicesAsync`/
  `RevokeTrustedDeviceAsync` let a user see and individually revoke one remembered device rather than only
  the existing bulk "sign out of all" action. Revoking a device that doesn't exist or belongs to a different
  account is a silent no-op, the same anti-enumeration posture used elsewhere in this service.

## [0.64.1] - 2026-09-08
### Added
- (Cloud) `ITrustedDeviceRetentionService` - the retention/pruning job for `TrustedDevice` (Azure Boards #57,
  `v0.64.0` below) that was missing from that release, mirroring `IRefreshTokenRetentionService`'s exact
  shape. No grace-period window - a revoked or expired trusted device is deleted outright.

## [0.64.0] - 2026-09-08
### Added
- (Cloud) "Remember this device for TOTP" (Azure Boards #57) - an opt-in checkbox at the second-factor login
  step lets a device skip TOTP/recovery-code entry for a fixed, non-renewing 30-day window on future logins,
  the same pattern GitHub/Google/Microsoft all use. New `TrustedDevice` domain aggregate, shaped like
  `RefreshToken`/`LoginChallenge` (a random raw token, only its hash persisted) but deliberately multi-use
  across its own 30-day life rather than single-use. `IAuthenticationService.VerifyCredentialsAsync` now
  returns a closed `VerifyCredentialsOutcome` (`SecondFactorRequired` or `CompletedViaTrustedDevice`) instead
  of a bare challenge, so a recognized trusted device skips the second factor entirely rather than merely
  pre-filling it - a missing/unknown/expired/revoked token silently falls through to today's normal flow.
  Platform administrators are excluded from this bypass entirely regardless of what's presented or requested.
  Max 3 active trusted devices per user, evicting the oldest on a 4th. Every sensitive account change
  (password change/reset, TOTP re-enrollment) revokes all of a user's trusted devices, plus a new explicit
  "sign out of all trusted devices" action (`IAuthenticationService.SignOutAllTrustedDevicesAsync`) - a
  per-device list/revoke is deferred (Azure Boards #58). A known, accepted residual risk (a copied cookie
  bypasses TOTP given known credentials) is tracked, not fixed, in Azure Boards #59.

## [0.63.1] - 2026-09-04
### Fixed
- Backfills the `0.63.0` entry below - tagged without one, same mistake as `0.61.0`/`0.62.0` (see `0.62.1`'s
  own entry). No code change beyond this file.

## [0.63.0] - 2026-09-04
### Added
- (Cloud) `IDataProtectionSasExpiryMonitorService` (Azure Boards #5 follow-up) - the Data Protection blob SAS
  `bootstrap-secrets.ps1` mints has a 2-year hard expiry and no alerting at all today; a lapsed, unrenewed SAS
  silently breaks TOTP secret decryption for every user. This service parses the SAS's own embedded `se`
  expiry and emails a direct platform-admin warning once within 60 days of expiry (an urgent variant if
  already past it) - wired into a new weekly timer function in `LoopMi.Cloud.Alerting`.

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

Earlier releases (`0.60.4` and before) have been trimmed per this file's 10-release retention policy
(added 2026-09-04) - see `git log -p -- addons/loopmi_edge/CHANGELOG.md` for the full history.
