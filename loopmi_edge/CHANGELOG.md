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

## [0.113.0] - 2026-10-15
### Added
- The Edge no longer fills the Home Assistant disk (Azure Boards #238-#240). Readings already sent to the Cloud, and the Edge's own local-dashboard readings, are now deleted after 7 days; before, they were kept forever and the database only grew. A daily job does it in small batches, and readings still waiting to be sent are never touched by it.
- When readings cannot be sent for any reason (the Organization suspended, a long internet outage) and the free space of the disk falls below 10%, the Edge deletes the unsent readings of the 2 oldest days, measures again and repeats until the space is back to 10%. The last 7 days are never deleted, whatever the free space. Each purge is written to the log as a warning and kept on the device so the Cloud can show the gap in a later release.
### Changed
- The "remaining storage" the Edge reports on every check-in now measures the disk the database lives on (the whole Home Assistant disk, plus the free space inside the database file) instead of the container's root, so the Cloud's storage alert sees the real disk. The first daily run may delete months of old readings on an Edge that has been running for a long time; the database file keeps its size (the freed space is reused by new readings and counted as free).

## [0.112.0] - 2026-10-14
### Changed
- (Cloud) Privacy Policy version 6 (Azure Boards #237): the staff records it describes now include stock control - the employee who marked a delivered product as used up or thrown away, and why; a discard is kept as a sealed record. Every Portal user reviews and accepts the updated policy at their next sign-in.
- No Edge change.

## [0.111.0] - 2026-10-14
### Added
- (Cloud) Stock control per Location, phase 1 (Azure Boards #230-#236). An Owner or Admin switches it on per Location (off by default) and sets how many days before a best-before date to warn (1-30, default 2). From then on every accepted delivery is a stock line on the Location's tablet, listed "use first"; an employee marks it Finished or Discarded with their PIN, and a discard (past its date, damaged, or another reason) is kept as a sealed record. The tablet shows a banner when products expire soon or are past their date, and Owners and Admins get one email a day at 08:00, in their language, only when there is something to report. Lines forgotten in stock close automatically 60 days after their date; nothing is deleted.
- (Cloud) Product and supplier lists for the Organization (Azure Boards #231): the tablet's goods-receiving form suggests them while typing and adds a new name in one tap; the Portal's Products and Suppliers pages rename, deactivate and reactivate them. A delivery record keeps the name it was signed with. Existing deliveries are linked to lists built from their names.
- (Cloud) Organization exports carry the lists, the stock settings, the stock state of each delivery and the discards (archive format 1.17); older exports restore with stock control off.
- No Edge change.

## [0.110.0] - 2026-10-14
### Changed
- (Cloud) Privacy Policy version 5 (Azure Boards #227): it now says how long the public export check at /verify keeps what it is given - the uploaded file is deleted as soon as it is checked, the result after a day. Every Portal user reviews and accepts the updated policy at their next sign-in.
- No Edge change.

## [0.109.0] - 2026-10-14
### Changed
- (Cloud) Export check at /verify (Azure Boards #227): an export LoopMi signed whose files are all as exported is no longer called "changed after export" when one of its records already failed its check at export time (for example a photo missing from storage, found by the first check of a real export on dev). It now gets its own answer - unchanged since export, with those records listed - so whoever hands over a copy is never blamed for a gap in the original data.
- No Edge change.

## [0.108.0] - 2026-10-14
### Added
- (Cloud) Anyone can check an Organization export at /verify, without signing in (Azure Boards #227): upload the .zip from Data Export (up to 500 MB) and LoopMi tells, in plain words and in your language, whether it is exactly what LoopMi produced - signed by LoopMi, every file as exported, every Location's sealed records unchanged - or names what was changed. The file is deleted as soon as it is checked, the result after a day. Handy for inspectors and auditors who receive a copy of the records.
- No Edge change.

## [0.107.0] - 2026-10-14
### Added
- (Cloud) Warned before a fridge or freezer fails (Azure Boards #226): when the nightly Compressor Efficiency check sees a compressor start to behave worse than its own normal - running for hours without stopping, drawing more power or running longer per cycle, or starting and stopping too often - Owners and Admins get an alert, in their language, with what was seen and where to look. It is sent once when it starts, not every day; it waits until a unit has two weeks of history; days of low activity (which a closed day also shows) only appear in the report. On the dev data this means about one alert per unit every five months.
- No Edge change.

## [0.106.0] - 2026-10-14
### Added
- (Cloud) Emails are written in each person's own language (Azure Boards #225): alerts, the daily missed-checklist digest, invitations, notices to Owners and the inspector's emails come in the language the person uses the Portal in - English, Portuguese, Spanish, French, Italian or German - with dates and numbers written that language's way. Switching the Portal's language also switches the emails, and the choice follows the person to any device. Managers who read different languages each get the alert in theirs, and nobody gets it twice. Alerts shown in the Portal follow the reader's language too.
- No Edge change.

## [0.105.0] - 2026-10-12
### Changed
- The add-on now tells the Cloud, once per device, when Home Assistant last heard from any of the device's measuring channels (energy, power, temperature, ...), instead of one entry per channel. Only one timestamp per device travels: no readings, and nothing about channels nobody configured. The Cloud uses it so a device is not reported as "stopped sending data" while any of its measuring channels still reports. Monitored channels are reported as before. Setting a device's "Offline after (minutes)" to 0 still means it is not watched, and that is the default.

## [0.104.0] - 2026-10-10
### Fixed
- A device is no longer reported as "stopped sending data" while it is still sending: the check counts any channel that measures something (energy, power, temperature, ...), not only the monitored one. A steady load changes no value, so its monitored power reading can stay quiet for a while although the device is fine. Battery and diagnostic channels still do not count, so a daily battery report cannot hide a stalled device. The add-on now tells the Cloud when Home Assistant last heard from every measuring channel of a device. Setting a device's "Offline after (minutes)" to 0 still means it is not watched, and that is the default.
