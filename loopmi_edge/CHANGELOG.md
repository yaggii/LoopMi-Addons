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

## [0.529.0] - 2026-11-25
### Added
- (Edge) A device made by LoopMi with several probes (the LM-DT2) now appears in LoopMi as one device per probe, "<device name> · Probe 1" and "· Probe 2", so each probe can be assigned to its own Equipment. Only devices whose manufacturer is LoopMi and whose entities end in `_probe_<n>` are split; signal strength and firmware stay with Probe 1. An LM-DT2 discovered before this version moves to the two new devices on its next reading; the old device stops reporting. Devices from any other manufacturer are unchanged. (Azure Boards #522)

## [0.528.0] - 2026-11-23
### Added
- (Cloud) One-time settings code for a Location tablet (decision D9, architecture 15.11): an Owner or Admin issues six digits for one tablet; the tablet opens its settings with it once, within 10 minutes. Stored hashed, recorded with who issued it and when it was used; five wrong tries burn it; revoking the tablet clears it. New `ITabletManagementService.IssueSettingsCodeAsync` and `TryOpenSettingsAsync`. (Azure Boards #512)

## [0.527.0] - 2026-11-23
### Changed
- (Cloud) Members may pair a phone with the LoopMi app and use it (decision D2, architecture 15.2): their phone reads and acts like the Portal for their role but receives no push - alerts still go to Owners and Admins only (15.5). New `ReceivesPushAsync` says whose phones are notified. (Azure Boards #506)

## [0.526.0] - 2026-11-23
### Changed
- (Cloud) A Location tablet's pairing code is now 8 characters (ABCD-EFGH, no 0, 1, I or O), like the phone's, instead of a 43-character string; spaces, dashes and case do not matter when it is typed. It works once, for 5 minutes (was 15), also like the phone code. (Azure Boards #504)

## [0.525.0] - 2026-11-22
### Added
- (Cloud) Each Location tablet remembers when it was last seen (its status poll, written at most every five minutes), so the Portal and the app show it online or offline. (Azure Boards #504)

## [0.524.0] - 2026-11-22
### Fixed
- (Cloud) "Create action" on an alert whose problem already has an open action now joins that action and opens it, in the Portal and in the app, instead of answering "another action is already open". (Azure Boards #503)

## [0.523.0] - 2026-11-22
### Added
- (Cloud) A problem a Portal or app user reports by hand can carry up to three photos, like an employee's report from the tablet: each photo's type comes from its own bytes, the images are kept under the event and removed again when the report is refused. (Azure Boards #502)

## [0.522.0] - 2026-11-20
### Added
- (Cloud) The Android app can show a Location's checklists for today, read only: the same due, late and on-demand list the Location tablet shows, read for the Location without a tablet. Filling in and signing stay on the tablet with the employee PIN. (Azure Boards #496)

## [0.521.0] - 2026-11-20
### Added
- (Cloud) An alert now carries the numbers behind it - the reading, its unit and time, and the acceptable range - so the Android app can draw the alert detail: the value against its range, the curve of the hours around it with the acceptable band, and the timeline of the same equipment's alerts. The alert wording is unchanged. (Azure Boards #492)

## [0.520.0] - 2026-11-20
### Added
- (Cloud) The Android app can now do more than read alerts, safely: after the unlock it exchanges its device credential for a 10-minute app token that works only on a fixed list of app routes, each marked read, act or sensitive. Every request checks the phone again, so a revoked phone stops at once. A platform setting can later demand a full sign-in for sensitive or acting routes; it is off. The first app routes are the person's own Operational alerts choice. (Azure Boards #488)
