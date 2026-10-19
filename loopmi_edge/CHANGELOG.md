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

## [0.129.0] - 2026-10-19
### Added
- (Cloud) Foundations of the new "Operational follow-up" module: events become actions that are assigned to a user or an employee, worked, recorded and resolved, with a complete, unchangeable log of every step. Nothing is visible in the Portal yet and the module cannot be switched on until its price is set; it will appear on the Modules page when it is launched.
### Changed
- (Cloud) A module that has no price yet can no longer be switched on, so it is never billed at 0.00 without anybody saying so. New trial Organizations do not start with Operational follow-up.
- (Edge) The Edge add-on image is rebuilt with this release because the list of modules, shared by the Cloud and the Edge, gained an entry. Its behaviour is unchanged.

## [0.128.0] - 2026-10-19
### Fixed
- (Cloud) An extended audit history module (5 or 10 years) that is switched off now keeps its period for the full 30 days even when it had been on for less than 30 days. Before, a module switched on and off again within a month had no grace: the Alert history page showed the shorter period at once while the banner promised the removal in 30 days. The page, the daily clean-up, the restore and the removal preview now agree.
### Changed
- (Edge) No change for the Edge add-on: this release changes only the Cloud.

## [0.127.0] - 2026-10-19
### Added
- (Cloud) New "Alert history" page under Reporting for Owners and Admins: every alert raised for the Organization, where, who it was sent to and what became of it. It shows how many years the history is kept, when it starts, and - during the 30 days after an extended history module is switched off - the date the older history will be removed. Filters by period, Location, Equipment, alert type and state; downloads as CSV or PDF without naming any account. Alerts recovered from the send queue say that who received them was not recorded.
- (Cloud) The Organization export (archive format 1.18) now includes the alert history, and a restore brings it back. Alerts older than the retention of the Organization restored into are left out - the export's modules are not part of the archive - and how many were left out is recorded.
- (Cloud) When an Owner removes a member, they can also erase that person's identifier from the Organization's alert history: it is replaced by "removed user" and the facts of each alert are kept.
### Changed
- (Edge) No change for the Edge add-on: this release changes only the Cloud.

## [0.126.0] - 2026-10-19
### Added
- (Cloud) Switching off an extended audit history module (5 or 10 years) now asks for a second, explicit confirmation that shows how many alert-history records would be deleted and from which date. The history older than the period that remains is kept for 30 more days after the switch-off takes effect and deleted only after that; switching the module back on before then cancels the deletion. The organization's Owners and LoopMi's administrators are emailed when the switch-off is scheduled, the day it takes effect, 7 days and 1 day before the deletion, and after it with the number of records removed.
### Changed
- (Edge) No change for the Edge add-on: this release changes only the Cloud.

## [0.125.0] - 2026-10-19
### Added
- (Cloud) Two new optional modules, "Audit history, 5 years" and "Audit history, 10 years", extend how long the alert history is kept beyond the standard 3 years. They are priced per Location per month (4 EUR and 6 EUR, added together for both); switching on the 10-year module also switches on the 5-year one it needs, and switching the 5-year one off also switches the 10-year one off. A platform administrator can grant both to the existing organizations at no charge with a counting-only trial run first; no emails are sent for the grant.
### Changed
- (Edge) No change for the Edge add-on: the module list is shared code that only the Cloud uses, so this release rebuilds the add-on image without changing what it does.

## [0.124.0] - 2026-10-18
### Added
- (Cloud) Alerts are now kept in a permanent alert history, for at least 3 years from the time of the alert (the queue that sends the alert emails still keeps its own records for 20 days only). For each alert the history records what was raised, for which Location, which manager accounts it was sent to and in which language (accounts only, never email addresses), and who dismissed it or whether the system resolved it. A daily upkeep job (05:30 UTC) writes the history rows of alerts still in the queue and later removes history older than the retention; both steps start in a counting-only mode and write or delete only when switched on.
### Changed
- (Cloud) Terms of Service and Privacy Policy version 8: the Privacy Policy now states that alert history is kept for 3 years and what it contains, and the Terms name the one exception to "nothing is deleted when a module is switched off". Everyone accepts the new version at their next sign-in.

## [0.123.1] - 2026-10-18
### Fixed
- (Cloud) The monthly billing summaries are generated again. The timer that creates them failed on every run since 2026-10-16 ("PlatformInternalTenantAccessor can never be scoped to a single Organization"), because the billing service tried to scope a platform-internal session to one Organization. It now leaves such a session as it is; the summaries that were due (September) are made up by the next run, without duplicates.
### Changed
- (Edge) The libraries the add-on is built with are updated to the .NET 10 servicing release 10.0.13 (Microsoft.Extensions.*, SQLite storage); no change in behaviour.

## [0.123.0] - 2026-10-16
### Added
- (Cloud) A platform administrator can change the values of a billing summary that is still waiting for validation: Locations, days, price and amount of each line, by hand. What the system computed stays on the line, the line is marked as changed by hand, the summary keeps who changed it and when, and the total follows. A recalculation discards the changes, and a validated summary can no longer be changed.

## [0.122.0] - 2026-10-16
### Added
- (Cloud) An agreement with an Organization can now be a percentage off the catalogue price instead of a fixed price - for one module or for every module - and either kind can end on a date (the last day it applies; from the next day the catalogue price applies again). A percentage follows the catalogue when the catalogue price changes; the arrangement that started last is the one in force. Billing summaries show the discount, the end and on how many days an agreement applied; the Owner sees "agreed price - 10% off - until ..." on the Modules page and is emailed when an agreement is made.

## [0.121.0] - 2026-10-16
### Added
- (Cloud) A platform administrator can agree a price with one Organization for one module - a different arrangement with a customer: a fixed price per Location per month (0 is free) from a date in the current month or later, with a reason. Billing summaries, the Owner's quote, estimate and module history all use it; the Owner sees it marked as an agreed price and, like the platform administrators, is emailed in their own language when one is agreed. A price already billed never changes, and a catalogue price change does not alter an agreed price.
