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

## [0.513.0] - 2026-11-13
### Security
- (Edge) The local REST API on port 5034 is no longer published on the Home Assistant host by default. It serves the readings without a login, so until now anyone on the site's network could read them. Nothing changes for the Cloud connection or for Home Assistant's health check of the add-on. If you use the local dashboard, set a host port for 5034 under the add-on's Network settings and name the dashboard's address in `LocalApi:AllowedOrigins`: web pages from any other address can no longer read the API. (Azure Boards #467)

## [0.512.0] - 2026-11-12
### Security
- (Cloud) The first platform administrator of an environment is now invited by email like every later one: a random temporary password valid for 7 days, a forced password change and the administrator's own authenticator enrolment at first sign-in. The earlier bootstrap used a fixed password and wrote it, the authenticator secret and the recovery codes to the application log; the method that returned those secrets is removed. An invitation that was never used can be sent again. No change for existing accounts. (Azure Boards #466)

## [0.511.0] - 2026-11-13
### Changed
- (Cloud) Terms of Service and Privacy Policy version 12 for the Android app and push notifications: the Terms gain a section saying LoopMi is not a life-safety or certified alarm system, that notifications are best effort and that no time between an event and a notification is promised; the Privacy Policy gains the paired phones, their legal basis, Google Firebase Cloud Messaging as a sub-processor and their retention. Everyone is asked to accept the new version at their next sign-in.

## [0.510.0] - 2026-11-12
### Added
- (Cloud) A reusable pairing code for one demo Organization named "LoopMi Play review", so Google's Play reviewers can pair the Android app whenever they test: it never expires and is never used up, only the platform administrator can create or switch it off, only for an Owner or Admin of that exact Organization, and only one exists in the whole platform. Pairing again with it revokes the oldest phone instead of failing on the five-phone cap. Every other pairing code is unchanged (single use, five minutes).

## [0.509.0] - 2026-11-12
### Changed
- (Edge) Build only: the Native AOT compiler pin moves from 10.0.14 to 10.0.15 so the Edge image builds again on the CI agent (its SDK now carries the 10.0.15 runtime). No change to what the add-on does.

## [0.508.0] - 2026-11-10
### Added
- (Cloud) The platform-level alert (the Data Protection secret about to expire or expired) also reaches the platform administrator's paired phones as a short fixed notice, in the administrator's language; the email with the details is unchanged. An alert can now also be found by its id after its Outbox row was purged, from the permanent alert history, so a notification opened late still opens.

## [0.507.0] - 2026-11-10
### Added
- (Cloud) Groundwork for push notifications to the Android app: alert types can be classified Operational or Safety (every change audited), the Outbox dispatcher delivers Safety alerts first and pushes before it emails (a failed push never stops the email), and push notice texts exist in the six languages. The app side is in too: a phone is paired from the Portal with a one-time code and then holds its own revocable read-only credential (valid while it is used, 30 days by default and adjustable by the platform administrator; a password change, password reset or TOTP re-enrolment ends it), and each user can choose email, push or both for Operational alerts. Nothing is delivered by push yet: the sender, the device registration and the pages come with the next Cloud release, and with none configured alerts behave exactly as before.

## [0.506.1] - 2026-11-10
### Security
- (Edge) The Native AOT compiler used to build the add-on is updated from 10.0.12 to 10.0.14, which fixes a known high-severity .NET Brotli decoder vulnerability (GHSA-p3jp-9v83-76w9) in the build toolchain. No change in behaviour; the add-on image is rebuilt.

## [0.506.0] - 2026-11-06
### Changed
- (Cloud) Energy readings are now stored at most once a minute per channel (a counter that goes down, or the first reading, is always kept). A smart plug that reports its kWh counter every few seconds used to fill the database with rows the reports never use; consumption figures are unchanged because they come from the difference between counter values.

## [0.505.2] - 2026-11-06
### Fixed
- (Edge) A suspended Organization no longer floods the add-on log: the cloud's "organization is suspended" rejection is now logged as one short line at most once an hour (check-in, measurement sync, discovery reports) instead of a full stack trace on every retry and for every discovered entity. Retrying and recovery when the Organization is reactivated are unchanged.
