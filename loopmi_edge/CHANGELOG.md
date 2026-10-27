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

## [0.162.0] - 2026-10-27
### Added
- (Cloud, Edge) An Owner can stop a Location from the end of the month (Azure Boards #383). From that instant the Location registers nothing: its readings are accepted and discarded (so the gateway does not retry), its tablets refuse new records with a clear message, no alert, health sweep, missed-checklist record or nightly digest is produced for it, and its days are not billed (the quote and the monthly summary use the same rule: a Location counts on a day unless it was stopped for the whole day). The Owner can cancel a scheduled stop, and resume at once; the time it was stopped stays excluded for good - a reading is judged by the time it was taken, so a backlog sent after the resume loses exactly the stopped stretch - and the temperature report shows that time as *Stopped by the Owner*, not as a fault or data lost. Everything recorded before stays readable and sealed records are untouched. The stop and resume history is append-only and is carried in the organisation export and restore (archive format 1.24). The Edge add-on now learns the stopped periods from the check-in answer: it stops keeping readings taken inside one, deletes the unsent ones it already holds (saving its storage and traffic) and reports them with their own reason, *Location stopped*, so they are never shown as a full-disk purge. An older Edge keeps working and the Cloud still discards, so either side can be deployed first. Database migration: new table of stop changes.

## [0.161.0] - 2026-10-27
### Changed
- (Cloud) Trainings follow the employee for an inspector (Azure Boards #379, #380). An inspector now sees, for the Locations their access covers, the training records of those Locations and also those of every employee who works at one of them (assigned there, or at every Location), wherever the training was recorded - so an employee who moved to another Location does not lose their earlier trainings from the inspector's view there; the Location they left still shows them as its own. Each row says where it was recorded, and a training certificate opens by the same rule. Nothing sealed is changed, and a manager's own list is as before. Also fixed: the certificate of a training recorded for the whole organization could not be opened or removed; it can now, and a removal is sealed in the Organization's own record chain. No change to the Edge add-on.

## [0.160.0] - 2026-10-27
### Added
- (Cloud) Organization-level training (Azure Boards #362, #371-#377). A training record can now belong to the whole Organization instead of one Location: leave the Location empty when recording it. It is sealed into a record chain of its own, the Organization's, kept next to the Locations' chains and checked, signed and backed up exactly like them (organization exports and restores carry it, archive format 1.23; the chain keeps its identity when restored into another Organization). A training recorded at a Location can only be for an employee who works there or at every Location. The Training page shows, filters and verifies the organization-wide records. An inspector reaches them when their access covers every Location, or when the access was given with the new option *also show organization-wide training*; access given earlier is unchanged and sees no more than before. HACCP plans and every existing record, chain and seal are untouched. No change to the Edge add-on.

## [0.159.0] - 2026-10-27
### Added
- (Cloud) Tablet employees can be assigned to one or more Locations (Azure Boards #362, #365-#370). An employee with no Location is organization-wide and works everywhere, exactly as before, so nothing changes until someone is assigned. A tablet lists, and accepts the PIN of, only the employees who are organization-wide or assigned to its Location; an employee assigned only to other Locations is refused as not found, and the refusal does not count as a wrong PIN. The PIN and its lockout stay one per employee, shared by every Location. Owners and Admins set the Locations on the Employees page, and a new Management endpoint sets them. Organization exports and restores carry the assignment (archive format 1.22); an older archive restores with every employee organization-wide. No change to the Edge add-on.

## [0.158.0] - 2026-10-26
### Changed
- (Cloud) Door and compressor in the efficiency report (Azure Boards #360): the nightly evaluation now also stores, once, the door profile of every past day that was evaluated before the door was marked as a door of the equipment (while its raw door and power readings are still kept, up to 33 days), with the same compressor figures as before. The report then reads the stored profile instead of working it out from a month of power readings each time it is opened, which makes it faster with the door on. No change to the figures, flags or alerts, and no change to the Edge add-on.

## [0.157.0] - 2026-10-26
### Fixed
- (Cloud) Compressor efficiency report: it was slow to open (about 27 seconds on the dev database, which hit its limit while the report loaded). An equipment with no door contact marked as its door now costs the report no door query at all, and for one with a door the door readings are looked at first, so the heavy read of a month of power readings only happens when there is door data to work out. No change to the figures, flags or alerts, and no change to the Edge add-on.

## [0.156.0] - 2026-10-26
### Fixed
- (Cloud) Door and compressor in the efficiency report (Azure Boards #360): days from before the door was marked as a door of the equipment, whose raw door and power readings are still kept, now get their door facts worked out when the report is opened, so the flagged days that predate the marking show their door analysis too (before, they said there was no door data). No change to the report's own figures, flags or alerts, and no change to the Edge add-on.

## [0.155.0] - 2026-10-26
### Changed
- (Cloud) Door and compressor in the efficiency report (Azure Boards #360): door times are now given in seconds (shown as minutes and seconds), and each day carries how busy its door was against that equipment's own other days (quiet, usual or busy), so the report can set a flagged day beside what the door did that day. No change to the report's own figures, flags or alerts, and no change to the Edge add-on.

## [0.154.0] - 2026-10-26
### Added
- (Cloud) Door facts beside the compressor efficiency report (Azure Boards #360, Feature #356): for an Equipment with a power plug and a door contact, each day of the report now also shows how often and for how long the door was open and how many compressor cycles started soon after an opening (up to 5, 15 and 30 minutes) or with the door open. It is informational: the report's own figures, flags and alerts are exactly as before, and an Equipment with no door contact shows nothing new. The nightly evaluation stores the door profile of each day beside the compressor result, from the same cycles. Included in the organisation export and restore. Database migration: new columns on the efficiency results. No change to the Edge add-on.

## [0.153.0] - 2026-10-26
### Added
- (Cloud) The compressor analysis keeps the fridge door (Azure Boards #358, Feature #356): for an Equipment with a power plug and a contact marked as its door, the nightly summary of each settled day now also stores how often and for how long the door was open, an hourly profile (openings, open seconds, compressor-on seconds, cycles) and, for every compressor cycle, how the door stood just before it. The raw door readings of a summarized day are deleted (the most recent reading of each door is always kept); the Location's raw retention window now applies to both power and door. Nothing in today's compressor report or alerts changes. Included in the organisation export and restore. Database migration: new columns on the power rollups. No change to the Edge add-on.
