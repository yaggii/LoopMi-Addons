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
