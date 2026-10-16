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

## [0.117.0] - 2026-10-16
### Added
- (Cloud) Modules (Azure Boards Epic #242, third phase): Sensor monitoring is now switched on and off per Organization. With it off, an Edge keeps running but everything it sends is accepted and discarded - readings are not stored, devices are not added to Discovered devices, and what the gateway saw of its sensors is ignored (its versions, storage and configuration are still kept) - so it never fills its disk or retries; new Edge registration tokens, device, channel and threshold changes and the sensor pages (dashboards, devices, gateways, temperature, energy and efficiency reports) are no longer offered, while the history stays readable.
- (Cloud) Nothing is evaluated for an Organization without Sensor monitoring: no stale device, offline gateway, battery, leak, temperature, door or compressor-efficiency alert can follow from silence nobody is watching. When it is switched back on every device gets a full reporting interval before it can be called stale (no "stale" email for the weeks it was off), and the daily efficiency evaluation covers only days watched from midnight to midnight.
- (Cloud) An Organization with only HACCP checklists, Goods receiving and the like works without an Edge: the tablet home shows just the buttons of the active modules (no equipment grid, no shift check), a checklist item that reads a sensor is skipped for a stated reason ("sensor monitoring is not switched on") and the rest of the checklist is asked as usual, and a template or schedule cannot be given sensor items or a sensor trigger.

## [0.116.0] - 2026-10-16
### Added
- (Cloud) Modules (Azure Boards Epic #242, second phase): HACCP checklists and Goods receiving are now switched on and off per Organization. With HACCP checklists off, no template, schedule, correction or photo change can be made, the tablet offers no checklists and no sensor-triggered checklist starts; with Goods receiving off, no delivery can be recorded on the tablet and the product and supplier lists cannot be changed (and Expiry control, which needs it, goes off with it). Records, non-conformities, the compliance ranking, earlier deliveries and the recall search stay readable.
- (Cloud) Nothing from a period in which HACCP checklists was off is evaluated: a missed checklist is recorded, counted or mailed only if the module was on for the whole window, from its start to its late deadline - so switching the module back on never records the off period as missed, and the compliance ranking leaves such windows out of both "due" and "missed".
- (Cloud) The tablet and the employee roster follow the modules: the tablet (pairing, sign-in, shift check-in, PIN change) needs Sensor monitoring, HACCP checklists, Goods receiving or Expiry control, and shows only the buttons of the modules that are on, or "No active functions" - it stays paired and works again by itself; an Organization with only Training and HACCP plan can keep its employee roster, and employees are then added without a PIN (the Employees page asks for the PINs when a module that uses the tablet is switched on).

## [0.115.0] - 2026-10-16
### Added
- (Cloud) Modules (Azure Boards Epic #242, first phase): LoopMi is now switched on and off per Organization by module - Sensor monitoring, HACCP checklists, Goods receiving, Expiry control, Training and HACCP plan and Inspector access, with Platform always on - each with a price per Location per month. A platform administrator sets an Organization's modules from the Organizations page (puzzle icon) and chooses the bought modules when activating a Trial; every change is kept in a history that the database refuses to alter, with who made it, the price in force and the number of Locations. Existing Organizations keep every module.
- (Cloud) A new Module prices page (Administration) keeps the price catalogue: a price in force, or in the past, is never edited - a new one is added from a later date.
- (Cloud) With Expiry control off, receipts no longer become stock lines, the daily expiry email and the automatic close pause and the tablet hides the stock screens; with Inspector access off, no new grants can be given, the active ones are revoked and inspectors lose access; with Training and HACCP plan off, no new training records or plan versions can be added. History stays readable and nothing is deleted. The menus and pages follow the Organization's modules, and the inspector's view only shows the sections of modules the Organization has or had.
### Changed
- (Cloud) An inspection grant revoked by the system records why (the module was switched off).

## [0.114.0] - 2026-10-15
### Added
- When the Edge has to delete unsent readings because the Home Assistant disk is nearly full (0.113.0), it now tells the Cloud (Azure Boards #241). Each purge is sent with the next check-in until the Cloud confirms it, so a lost connection never makes the report disappear.
- (Cloud) The Edge Gateways page of a Location shows a "Readings discarded by the Edge" table with the dates and the number of readings that never reached LoopMi. The Temperature report shows a notice above the table when a gap in its period overlaps one (the PDF carries the same note), so a gap caused by the disk protection is not mistaken for a sensor fault. Older Edges keep working unchanged.

## [0.113.2] - 2026-10-15
### Changed
- The cleanup of old readings now writes its progress to the log every 50 batches (about 50,000 readings): "Local storage cleanup of ... in progress: N reading(s) deleted so far". On an Edge with months of readings the first cleanup can take many minutes, and before this it was silent until it finished.

## [0.113.1] - 2026-10-15
### Fixed
- The daily cleanup of old readings (0.113.0) could hold the local database locked for tens of seconds on an Edge with months of data, making the Home Assistant connection, the check-in and the reading upload fail once with "database is locked" before recovering by themselves. The cleanup now builds no index and deletes in smaller batches with pauses, so the other parts of the Edge keep working while it runs.

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
