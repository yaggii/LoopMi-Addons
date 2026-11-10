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

## [0.506.1] - 2026-11-10
### Security
- (Edge) The Native AOT compiler used to build the add-on is updated from 10.0.12 to 10.0.14, which fixes a known high-severity .NET Brotli decoder vulnerability (GHSA-p3jp-9v83-76w9) in the build toolchain. No change in behaviour; the add-on image is rebuilt.

## [0.506.0] - 2026-11-06
### Changed
- (Cloud) Energy readings are now stored at most once a minute per channel (a counter that goes down, or the first reading, is always kept). A smart plug that reports its kWh counter every few seconds used to fill the database with rows the reports never use; consumption figures are unchanged because they come from the difference between counter values.

## [0.505.2] - 2026-11-06
### Fixed
- (Edge) A suspended Organization no longer floods the add-on log: the cloud's "organization is suspended" rejection is now logged as one short line at most once an hour (check-in, measurement sync, discovery reports) instead of a full stack trace on every retry and for every discovered entity. Retrying and recovery when the Organization is reactivated are unchanged.

## [0.505.1] - 2026-11-04
### Fixed
- (Cloud) The Energy report e-mail (Azure Boards #409): the grey line at the bottom of the e-mail ("Automated message from LoopMi Cloud...") now comes in the recipients' language instead of always English. The e-mail sender takes the footer line as a parameter.

## [0.505.0] - 2026-11-04
### Added
- (Cloud) The Energy report by e-mail (Azure Boards #409): after each month, quarter and half-year ends, the Owners and Admins of an Organization with the Energy module get one e-mail (one per language, hiding the other recipients) with a line per Location - energy, approximate cost, change, how many need attention - a link to the Portal page, and the PDF of each Location's report attached. It is sent once per Organization and period, from the 2nd to the 8th day of the month; stopped Locations and Locations with nothing to report are left out. Each person can switch it off (new setting on the user, on by default). The e-mail sender can attach files.

## [0.504.1] - 2026-11-03
### Fixed
- (Cloud) The Energy review for a quarter or a half-year (Azure Boards #406): the counts of days in the rules (compressor flagged days, peaks, very high days, long door openings, days without power use) now grow with the days actually counted - a month's allowance for up to about 45 days, three times for a complete quarter, six times for a half-year - instead of with the length of the period, so a quarter that is only a month old (like the quarter in progress) is judged like a month and still shows a compressor flagged on 4 days.

## [0.504.0] - 2026-11-03
### Added
- (Cloud) The Energy review for a quarter and for a half-year (Azure Boards #405, #406): the same rules, kWh and approximate cost as the monthly review for a calendar quarter (Q1-Q4) or half-year (H1, H2), compared with the quarter or half-year before; the counts of days in the rules (peaks, very high days, flagged compressor days, long door openings, days without power use) grow with the length of the period, so a quarter is not judged on a month's allowance. A month behaves exactly as before.

## [0.503.6] - 2026-11-03
### Changed
- (Cloud) The Energy review, calibrated with the owner on a real kitchen (Azure Boards #396): equipment that is not a fridge, freezer or cold room - a washer, a dishwasher, a stove, an oven - is never reported as "Needs attention" for using more than last month (at most "worth watching": more laundry is not a fault), is not told "if maintenance or a repair was done, it worked" when it was simply used less, and its "rising month after month" remark needs a rise of at least 20 percent a month and is at most "worth watching". Fridges, freezers and cold rooms keep the stricter rules.

## [0.503.5] - 2026-11-03
### Fixed
- (Cloud) The Energy review (Azure Boards #404): one unit with no readings in the month no longer blanks the Location's approximate cost and its change against last month - those are over the units that have days with readings, and the unit keeps its own "not enough data" line. A month in which no day could be priced still says where the price would come from (the national average or the Location's own), instead of "No price known".

## [0.503.4] - 2026-11-03
### Fixed
- (Cloud) The Energy review (Azure Boards #403): only the days an energy meter actually covers count as days with readings. A month in which the meter started reporting on its last days no longer shows "31 of 31 days with readings", an average over the whole month or "almost no power use on 28 days"; it says there is not enough data. When a meter reported irregularly, the kWh it credits to the day of its next reading are spread over the silent days before it, so those days are neither days of "no power use" nor one very high day.
