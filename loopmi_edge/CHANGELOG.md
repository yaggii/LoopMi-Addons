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

## [0.68.1] - 2026-09-15
### Changed
- (Cloud) The Location/Area Dashboard's "This Week vs Last Week" dialog no longer live-recomputes days of
  the current week that are already settled (everything before today) - it now reads those from the same
  nightly `AreaEnergyDailyRollup` table last week's own days already use, only today's still-open partial
  day is computed live. Closes the gap `v0.68.0` left: without this, the live raw-reading range grew every
  day of the week, reintroducing the same cost that release fixed for last week specifically. No Edge-visible
  change - this only touches the Cloud reporting path.

## [0.68.0] - 2026-09-15
### Changed
- (Cloud) Location Dashboard's "% of Yesterday's Full Day" energy tile and the "this week vs last week"
  energy comparison dialogs (Location- and Area-level) no longer reconstruct yesterday/last-week totals
  from raw Power readings on every Portal request - a Location-level load was measured as very slow against
  the dev database. A new nightly sweep now persists each Area's settled-day energy totals once; only the
  still-open current day/week is still computed live. Also removes a duplicate live fetch that existed
  between the `/dashboard` and `/areas/dashboard-summaries` endpoints (the latter is now folded into the
  former's response). No Edge-visible change - this only touches the Cloud reporting path.

## [0.67.1] - 2026-09-14
### Fixed
- Backfills a missing changelog entry - `v0.67.0` was tagged without one (this file's own gate correctly
  failed that release's Edge add-on build as designed, same mistake as `0.61.0`/`0.62.0`/`0.65.2`). No code
  change to the add-on itself beyond this file.

## [0.67.0] - 2026-09-14
### Added
- (Cloud) Compressor Efficiency Report activity tier and rule flags are now evaluated and persisted once a
  night per Equipment, instead of being reconstructed from raw Power readings on every Portal request (a
  single report load was measured at 6-7 seconds against the dev database). Only today's still-open day is
  still evaluated live. No Edge-visible change - this only touches the Cloud reporting path.

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

Earlier releases (`0.65.0` and before) have been trimmed per this file's 10-release retention policy
(added 2026-09-04) - see `git log -p -- addons/loopmi_edge/CHANGELOG.md` for the full history.
