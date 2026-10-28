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

## [0.500.0] - 2026-10-29
### Milestone
- (Cloud, Edge) LoopMi goes live with its first commercial trial: an Organization in trial mode that stays at least 90 days, installed at a real site and sending real measurements. The version number jumps from 0.165.1 to 0.500.0 on purpose, to mark the milestone; 0.166 to 0.499 will never exist. The Cloud and the Edge add-on are released together under this one number.
- (Edge) The add-on is rebuilt and published as 0.500.0. The Edge code is the one of 0.162.0 (stopped Locations: the Edge deletes and reports the readings of a stopped period); nothing in the Edge changed since.
- (Cloud) Everything since 0.162.0: an operational action can only be assigned to the people who work at its Location (0.164.0); the nightly record verification reads the new records plus a rotating slice instead of the whole history, and every sealed record is still checked at least every 30 days (0.165.0); the build pipelines run on pinned images (0.165.1).

## [0.165.1] - 2026-10-29
### Changed
- (Cloud) No functional change. The build and release pipelines run on pinned Ubuntu 24.04 images instead of the moving `ubuntu-latest` label (which is being moved to Ubuntu 26), so release builds stay what they were. No change to the Edge add-on.

## [0.165.0] - 2026-10-29
### Changed
- (Cloud) The nightly verification of the sealed records no longer re-reads every record of every chain each night (Azure Boards #387). Each chain keeps a checkpoint (the last entry verified and its link, outside the export and deleted with the Organization); a night verifies the entries added since, plus one slice of the older ones, so the cost follows the new records and one slice instead of the whole history. A pass over the older entries takes half the period (15 nights for the default 30 days, `RecordIntegrity:VerifyCoverageDays` of the Alerting app), so every sealed record is still read again at least once every 30 days and each chain shows its last full coverage date. A changed recent record is found the same night, a changed old one within the period; a night that finds something open does not move the checkpoint, so it is found again the next night. The first night of a chain, a restore and the platform administrator's on-demand request run a full verification (which is also what finds a record that was never chained). No change to the Edge add-on.

## [0.164.0] - 2026-10-28
### Changed
- (Cloud) The assign dialog of an operational action lists only the people who can act at the Location of the action (Azure Boards #386): the employees assigned to that Location, the employees who work organization-wide, and the Organization's users (a user has no Location list, so a user stays assignable everywhere). The server enforces it: assigning an action to an employee who does not work at its Location is refused with the new code `OperationalPersonNotAtLocation`. An action already assigned to someone who no longer works at its Location keeps its owner and shows it; only a new assignment is checked. The list of performers for an intervention is unchanged. No change to the Edge add-on.

## [0.163.1] - 2026-10-28
### Fixed
- (Cloud) A discovery report no longer answers 500 when Home Assistant lists an entity under another device than before (Azure Boards #385). The Edge keeps the entity's channel id but derives a new device id, so the Cloud tried to add a channel that already existed under the first device and failed on every report (and every retry). The channel now stays on the device that has it, only its label and kind are refreshed, and the report is accepted.

## [0.163.0] - 2026-10-28
### Changed
- (Cloud) Stopping a Location follows the product owner's decisions (Azure Boards #383). The platform administrator can stop, cancel and resume a Location from the Organizations page, with the same history and audit trail as the Owner; an Admin or a Member is refused. An Organization's last active Location (not stopped and with no stop scheduled) is never stopped by a stop: the Owner is told to ask the platform administrator, and the platform administrator is asked whether to suspend the Organization instead - on Yes it is suspended with the existing Suspend organization (same audit trail, effects and e-mails), on No nothing changes; the server refuses the stop whatever the client does, so the question cannot be skipped. A stopped Location now refuses every new write: also training records and their voiding, the voiding of a delivery record, checklist corrections and events recorded by a person or by an integration (the system's own events are skipped); reading stays open. The compressor efficiency report, the temperature comparison and the inspector's temperature report show the stopped time as *Stopped by the Owner*. The Terms of Service are version 11: everyone accepts again at their next sign-in, with new wording about stopped Locations in the modules and billing section. No change to the Edge add-on.

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
