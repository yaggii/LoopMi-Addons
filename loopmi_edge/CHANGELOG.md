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

## [0.21.0] - 2026-07-29
### Fixed
- (Cloud) A revoked Edge Gateway (e.g. an old one superseded by a fresh registration after the Edge lost
  its identity and had to re-register) is now excluded from a Location's health rollup entirely. Before
  this, a permanently-dead, never-syncing-again gateway could drag a Location's connectivity to
  Disconnected forever - visible as a real live case: "Disconnected" and "last synced just now"
  simultaneously, once one gateway's stale last-known facts and another's live ones got rolled up together.

## [0.20.0] - 2026-07-29
### Added
- (Cloud) LocationHealthResult now carries the most recent successful sync timestamp across a Location's
  Edge Gateways, so the Portal can show "how long ago" alongside connectivity/storage status instead of
  just the status word.

## [0.19.0] - 2026-07-29
### Fixed
- (Cloud) The dashboard's energy day boundary now uses Lisbon local time instead of UTC's own calendar
  midnight - during WEST (UTC+1, in effect most of the year), the old UTC boundary was an hour later than
  the real local midnight, skewing the "today vs yesterday" comparison by that hour's readings.
- (Cloud) The "Recent Alerts" panel is now genuinely limited to the last 24 hours, rather than always
  showing up to 20 entries regardless of age.
### Added
- (Cloud) The consumption dashboard now shows yesterday's absolute kWh figure for the same elapsed time of
  day alongside the percentage comparison, not the percentage alone.

## [0.18.0] - 2026-07-29
### Added
- (Cloud) A real-time monitoring dashboard for the Portal - an Organization-wide landing page
  summarizing every Location's health and active alerts, linking into a per-Location dashboard with
  current Equipment readings (grouped by Temperature and Water/Gas), a best-effort energy consumption
  estimate (today's total plus two comparisons against yesterday - cost/savings deliberately parked,
  no metering/billing concept exists yet), a "Recent Alerts" feed built from the existing alert
  history, and a per-Area consumption breakdown. Refreshes automatically every 30 seconds while open.

## [0.17.0] - 2026-07-29
### Added
- (Cloud) Re-inviting an email that belongs to an account previously removed from every
  organization now reactivates that same account instead of failing with "already
  registered": a fresh temporary password is emailed, and TOTP/recovery codes are cleared
  entirely so the member re-enrolls from scratch. Still rejected if the email belongs to
  a currently active member elsewhere, or to the platform administrator.

## [0.16.0] - 2026-07-29
### Changed
- (Cloud) An invited organization member's temporary password is now emailed directly to
  them instead of being shown to the inviting Owner.
### Added
- (Cloud) Owners can now remove a member from their organization (the sole-Owner
  guardrail still applies); removal also revokes the member's outstanding sessions.

## [0.15.0] - 2026-07-28
### Added
- (Cloud) Organizations now have a trial deadline (30 days from creation by default, adjustable per
  organization by a platform administrator). A Suspended organization - whether from a lapsed trial or
  direct administrative action - now actually enforces something for the first time: existing data stays
  readable through the Portal, but the Ingestion API rejects new data from that organization's Edge
  Gateways. No Edge-visible change unless your own organization's trial lapses.

## [0.14.0] - 2026-07-28
### Changed
- (Cloud) Equipment lifecycle state now has real effect for the first time: Archived
  equipment can no longer receive new Device assignments, and alerting is suppressed
  for Devices attached to Equipment that isn't yet Operational or Maintenance.

## [0.13.0] - 2026-07-28
### Added
- (Cloud) Area nesting (parent area) implemented end to end.

## [0.12.1] - 2026-07-28
### Fixed
- Stale channel classification now self-heals instead of being cached forever.

## [0.12.0] - 2026-07-28
### Added
- Expanded `MeasurementKind` coverage and per-channel display labels.

## [0.11.1] - 2026-07-27
### Added
- LoopMi logo (Scan Arc / Signal Fade) wired into the add-on and Cloud Portal.

## [0.11.0] - 2026-07-27
### Changed
- Upgraded to .NET 10.

## [0.10.1] - 2026-07-27
### Fixed
- `state_changed` subscription no longer fails after the proactive discovery sweep.

## [0.10.0] - 2026-07-27
### Changed
- Non-physical Home Assistant domains excluded from discovery.
### Added
- Per-device hide option.

## [0.9.0] - 2026-07-27
### Changed
- Home Assistant discovery broadened to all entity domains.
### Added
- Proactive full-state sweep.

## [0.8.2] - 2026-07-27
### Fixed
- Edge's ongoing API client was pointed at the Provisioning endpoint instead of Ingestion.
- Alerting now only notifies on a genuine degradation, not onboarding or recovery.
- Add-on version realigned with the shared kernel's tag history after an earlier drift.
### Added
- Separate `ingestion_base_url` add-on option, threaded through to the app.
### Changed
- Edge's server-TLS trust temporarily relaxed from pinned-CA to standard trust (interim
  state - see `cd28276` in this repo's history for context before relying on this).

## [0.8.1] - 2026-07-25
### Added
- (Cloud) `IOrganizationRepository.ListAllAsync`, for the platform admin view. No
  Edge-visible change.

## [0.8.0] - 2026-07-24
### Added
- (Cloud) Self-service TOTP enrollment, replacing admin-provisioned secrets.

## [0.7.0] - 2026-07-24
### Added
- (Cloud) Self-service password reset, gated by TOTP/recovery code.

## [0.6.0] - 2026-07-24
### Added
- (Cloud) Platform administrator capability, outside Organization RBAC.

## [0.5.0] - 2026-07-24
### Changed
- (Cloud) Login split into two explicit steps: password, then TOTP.

## [0.4.0] - 2026-07-24
### Added
- Low-battery alerting and measurement read APIs in the shared kernel.

## [0.3.0] - 2026-07-24
### Added
- (Cloud) Self-service password change.

## [0.2.2] - 2026-07-23
### Added
- `registration_token` option added to the add-on's Settings tab.

## [0.2.1] - 2026-07-23
### Fixed
- Edge no longer crashes at startup on a fresh, unregistered install.
### Added
- Application-level payload signing over mTLS.
- The Edge measurement sync worker (was missing entirely).

## [0.2.0] and earlier
Initial development versions (`0.1.0`-`0.1.22`), predating this changelog and the
add-on's first stable packaging.
