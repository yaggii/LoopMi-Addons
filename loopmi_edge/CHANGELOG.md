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

## [0.66.0] - 2026-09-11
### Added
- (Cloud) Employee self-service PIN change from the tablet (Azure Boards #65) - `ITabletCheckInService.ChangePinAsync`
  verifies the employee's current PIN (same lockout/anti-brute-force gate as check-in, Azure Boards #56) before
  setting a new one via the existing `Employee.ResetPin`. Originally scoped as part of #53 but never wired
  into the tablet UI until now.
- (Cloud) `TabletStatusResult.NowLocal` (Azure Boards #67) - the current instant converted to the tablet's
  Location's own local timezone, so the kiosk page can render a date that actually matches the physical
  Location's wall clock instead of the server/browser's own.

## [0.65.3] - 2026-09-10
### Fixed
- Backfills the `0.65.2` entry below - tagged without one, same mistake as `0.61.0`/`0.62.0`/`0.63.0` (see
  `0.62.1`/`0.63.1`'s own entries). No code change beyond this file.

## [0.65.2] - 2026-09-10
### Fixed
- (Cloud) Tablet status DTU spike (real Azure SQL incident) - `TabletStatusService` was re-running the full
  compressor efficiency report (a raw-reading duty-cycle reconstruction over up to 31 days) for every
  Equipment on every 30s tablet status poll. Now skips the report entirely for Equipment with no Power-kind
  Channel (also fixes Azure Boards #63 - a freezer with no energy monitoring was being flagged via the
  report's UnexplainedLowActivity rule misreading "zero power data" as a possible failure), and caches each
  Equipment's result per local day for 1 hour, since the rule engine's own dwell/baseline windows are
  day-granular and nothing about today's flag can legitimately change within an hour, let alone a 30s poll.

## [0.65.1] - 2026-09-08
### Added
- (Cloud) Organization-wide trusted-device view (Azure Boards #58 follow-up, direct user request) -
  `IAuthenticationService.ListOrganizationTrustedDevicesAsync`/`RevokeMemberTrustedDeviceAsync` let an
  Owner/Admin see and revoke every member's trusted devices in one view (including their own, since they're
  also a member), not just their own via the existing self-service methods. Revoking a device that belongs
  to a user of a *different* Organization is a silent no-op - a tenant-boundary check, not just the existing
  anti-enumeration one.

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

Earlier releases (`0.62.0` and before) have been trimmed per this file's 10-release retention policy
(added 2026-09-04) - see `git log -p -- addons/loopmi_edge/CHANGELOG.md` for the full history.
