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

## [0.147.0] - 2026-10-24
### Fixed
- (Edge) A Home Assistant binary_sensor with device_class battery (the "battery low" flag, off or on) is no longer taken for a battery percentage: it is no longer a Battery channel, so a 0 meaning "battery fine" can never look like an empty battery (Azure Boards #325, #326). A channel already created that way is reclassified at the next reading.

### Added
- (Edge) After each full discovery sweep the Edge tells the Cloud which of its channels Home Assistant no longer has (their entity is in neither the current states nor the entity registry, as after a rename in Zigbee2MQTT); the Cloud removes those that never reported and keeps the others (Azure Boards #326).

## [0.146.0] - 2026-10-24
### Added
- (Cloud) A channel that never reported anything (typically left over when a sensor was renamed in Zigbee2MQTT) can be removed by an Owner or Admin from the device's Channels dialog; a channel that has reported keeps its history and cannot be removed (Azure Boards #326). The discovery report can also list channels the Edge no longer has, for the Cloud to remove under the same rule.
- (Cloud) When a door's problem ends, the log of the open action made from its alert says "The door is back to normal" (a note only: the action is still closed by a person) (Azure Boards #327).

### Changed
- (Cloud) The battery of a device is the percentage with the newest reading, not that of the first Battery channel found, so a device with an empty leftover channel shows its battery again (Azure Boards #326).
- (Cloud) The Channels dialog is wider, so the contact rule of a door sensor is visible at once (Azure Boards #324).

### Fixed
- (Cloud) Back from an action no longer loses the tab it was opened from after following a recurrence (Azure Boards #328).

## [0.145.1] - 2026-10-23
### Fixed
- (Cloud) A door alert can be turned into an action: it is now an operational event of its own kind, "Door problem" (high when the door was left open, low when it is closed but should be open), instead of being refused as not valid.

## [0.145.0] - 2026-10-23
### Added
- (Cloud) Operations: an action's page lists the actions for the same problem (the same Location, Equipment and kind), earliest first, each linking to its page, so the recurrences can be reached from an action (Azure Boards #321).

## [0.144.0] - 2026-10-23
### Added
- (Cloud) Operations: every action and every event to follow up says where it stands among the actions for the same problem (the same Location, Equipment and kind) - "Occurrence 2 of 3" - counted the way the metrics count recurrences, so a recurrence seen in the metrics can be found in the lists.
- (Cloud) Operations: an action's page says that its response and resolution times count from its first event, and the list of actions says when only open actions are shown.

### Changed
- (Cloud) Operations: "Back" from an action returns to the tab it was opened from (Events to follow up or Actions).
- (Cloud) The error bar of the Portal has the Portal's own look.

## [0.143.1] - 2026-10-23
### Fixed
- (Cloud) The "Doors" tile now also shows a door sensor that has an expected-state rule but is not marked monitored, as the alert and the tablet already did (Azure Boards #313).

## [0.143.0] - 2026-10-23
### Added
- (Cloud) Doors: a door sensor whose state is a problem under its own rule (open or closed, by time of day) for longer than its alert-after time raises an alert in the feed of the Location and the Area and by email; the alert leaves the feed when the door is back to normal. The time is set per sensor in the sensor's rule (1 to 1440 minutes, 5 by default) and is carried by the organisation export and restore (Azure Boards #122).
- (Cloud) The Location and Area dashboards show a live "Doors" tile for each monitored door sensor - Open or Closed, red as soon as the state is a problem under the sensor's rule.

### Fixed
- (Cloud) A door opened and closed within one sync interval could show as open: when several readings arrive together, the latest is now the one the sensor itself reported last.

## [0.142.0] - 2026-10-22
### Added
- (Cloud) Tablet "My problems": the work an employee records on a problem can carry up to three photos (JPEG, PNG or WebP, 5 MB each), stored and shown like the photos of work recorded in the Portal and covered by the same removal, retention, export and restore rules (Azure Boards #306).

## [0.141.0] - 2026-10-22
### Added
- (Cloud) Compare Locations (Azure Boards #128): the Organization's Locations side by side - alerts, incidents, mean time to acknowledge and to resolve, what is open now, recurrences, Equipment in service and days observed - with the incidents per piece of Equipment per 30 days so a large and a small Location compare fairly. The figures count only from when Operational follow-up was switched on. A Location is marked Needs attention (with the reason: a critical action open, many incidents for its size, slow acknowledgement, problems that keep returning), Reference, Typical or Not enough data, by fixed rules stated on the page. CSV export; about Locations and problems, never about people.
- (Cloud) Tablet "My problems" (Azure Boards #128): an employee confirms their name with their PIN and sees only the open problems assigned to them at the tablet's Location, then takes note, starts work, records what they did or resolves. The server checks the PIN on every call; the log names the employee. Removing an employee from the roster also clears their identifier from the actions they worked.

## [0.140.0] - 2026-10-22
### Added
- (Cloud) Inspectors can read corrective actions: when work is recorded on an action of the operational follow-up (a corrective action, maintenance or a calibration) the organization can leave it marked as visible to inspectors - on by default, never for a note, and fixed once saved. An inspector sees the problem, the times and state, how it was resolved and that work with the display name of who did it, in a new Corrective actions section; never notes, review notes, integration details, e-mail addresses, user identifiers or photos. Each time one opens the section it is written to the inspector access log. Work recorded before this change stays hidden (Azure Boards #298).
### Changed
- (Cloud) Terms of Service and Privacy Policy version 10: the disclosure to inspectors names this work and what stays hidden, and the Terms add the duty to check the flag before recording work; everyone accepts again at the next sign-in (Azure Boards #298).
- (Cloud) Organization export archive format 1.21: each intervention carries whether inspectors may see it; older archives still restore, with their interventions hidden from inspectors (Azure Boards #298).
