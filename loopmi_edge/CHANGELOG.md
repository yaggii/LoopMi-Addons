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

## [0.51.37] - 2026-08-22
### Added
- (Cloud) Dashboard tiles (Temperature Monitoring and Water & Gas Monitoring, on both the Location and Area
  dashboards) now show a low-battery warning badge - a battery icon plus percentage in the tile's
  bottom-right corner - whenever the Equipment's most recent Battery-kind reading is at or below the owning
  Organization's low-battery threshold (§06.4). Recomputed fresh from the latest reading each time (same
  "don't trust alert-dedup bookkeeping" rule the Temperature out-of-range glow already follows), so it always
  reflects the Equipment's actual current battery level, not a frozen alert watermark. Hidden entirely when
  there's nothing to warn about.

## [0.51.36] - 2026-08-22
### Fixed
- Battery readings are no longer reported to the cloud for a Home Assistant device that was discovered but
  never assigned to an Equipment (e.g. a phone with the HA companion app). Battery has always been exempt
  from the customer monitoring filter (§05.1) because low-battery alerting depends on it - but that carve-out
  didn't check whether the device was actually under LoopMi management, so any battery-reporting entity HA
  exposed got forwarded regardless of relevance. The check-in config bundle now carries each device's
  Equipment-assignment status, cached locally; the Battery carve-out only applies when the device is
  Equipment-assigned. An older Edge talking to a newer Cloud, or a newer Edge talking to an older Cloud that
  doesn't yet send the new field, defaults to "not assigned" - fails closed (suppressing Battery readings)
  rather than leaking an unmanaged device's battery telemetry during a rollout skew. (Cloud) The check-in
  response's config bundle gained the same field.

## [0.51.35] - 2026-08-22
### Fixed
- Root cause found and fixed for the retry-loop incident v0.51.33/34's diagnostic logging was chasing: SQLite
  has no native decimal type - a `NUMERIC`-affinity column stores a value like a battery level's `100.0` as
  a bare `REAL`, and `SqliteDataReader.GetDecimal()` hands it back as `100` on every future read. Since
  `Value`'s exact string representation feeds the idempotency hash, that silent scale change permanently
  altered the hash on every resend after the very first one - the Edge's locally stored `IdempotencyKey`
  (frozen at the original insert, before the value ever touched SQLite) could then never match what the
  cloud independently recomputes from what's actually being resent, no matter how many times it retried.
  Traced live on a real Edge Gateway: 5 readings for one channel resent roughly every 30 seconds for over a
  day. `EdgeMeasurementSyncWorker` now recomputes the comparison key from each measurement's current
  (ChannelId, SourceTimestampUtc, Value, Unit) at send time instead of trusting the stored `IdempotencyKey`
  column - self-consistent by construction with whatever's actually transmitted, so it can't drift out of
  sync with the cloud's own independent recomputation again, for this or any similar future cause.

## [0.51.34] - 2026-08-22
### Added
- Diagnostic logging for `EdgeMeasurementSyncWorker`'s sync cycle - previously completely silent on a
  routine cycle (success or failure), which made an open incident invisible in this add-on's own logs: a
  handful of readings on some Edge Gateways keep colliding with an already-stored duplicate at the cloud
  every sync cycle without ever clearing, and it isn't yet clear whether the cloud's accepted-keys response
  is missing their key or the local "mark synced" write isn't persisting for them. Now logs a warning
  listing each unaccepted reading's channel, source timestamp, and idempotency key every cycle it recurs,
  and a normal info line once a cycle's readings are all confirmed synced.

## [0.51.33] - 2026-08-22
### Fixed
- (Cloud) `IMeasurementRepository.SaveBatchAsync`'s documented contract now matches the real fix shipped in
  `EfMeasurementRepository` (LoopMi-Cloud): a duplicate-key collision is reported as accepted, the same as a
  fresh insert - both mean the cloud durably has the reading, which is all `EdgeMeasurementSyncWorker` (this
  file) actually needs to know to stop retrying. Previously a duplicate came back unaccepted, so an Edge
  Gateway whose original "accepted" confirmation was ever lost (network blip, restart mid-request) could
  never learn a reading was already safely stored and would retry it forever - a real incident, observed as
  a stuck Edge Gateway resending the same 5 readings roughly every 30 seconds for over a day. No Edge
  behavior changes here (it already just reads whatever the cloud reports) - this release updates the
  interface docs and test fakes/expectations to match the corrected contract.

## [0.51.32] - 2026-08-22
### Added
- (Cloud) `Measurement.EquipmentId` - each reading now freezes which Equipment its Channel's owning Device
  was assigned to at ingest time (`MeasurementIngestionService`), the same denormalization pattern already
  used for `Measurement.OrganizationId`. Fixes a real correctness gap in every historical report/chart that
  used to resolve "which Equipment does this reading belong to" via a *live* join to the Device's *current*
  Equipment assignment: physically moving a sensor to a different Equipment used to retroactively drag every
  reading it had ever recorded - including ones taken while it was still on the old Equipment - along with
  it in every report. `TemperatureReportService`, `EquipmentTemperatureComparisonReportService`,
  `EquipmentEnergyComparisonReportService`, and `LocationDashboardService`'s historical widgets (energy/
  weekly-energy/temperature detail, Location- and Area-scoped) now query by the frozen `EquipmentId`
  instead, so a reassigned device's history stays correctly split across whichever Equipment it actually
  recorded data for at the time. Also fixed a related gap found while wiring this up: the Location/Area-wide
  energy and temperature widgets used to derive their query scope only from Equipment *currently* holding a
  device, so an Equipment that lost its last device entirely would silently drop out of the total - they now
  query every Equipment in scope instead. Existing rows/tables are `NULL` until a forthcoming batched
  backfill migration is run.

## [0.51.31] - 2026-08-21
### Fixed
- (Cloud) `Device.IsExcludedFromDashboard` (0.51.30) was too broad - it excluded the flagged device from
  every dashboard figure `LocationDashboardService.BuildChannelTreeAsync` feeds, including the dashboard's
  own historical widgets (today-vs-yesterday energy chart, weekly energy chart, "today" temperature range).
  That erased a retired device's genuine past readings from anywhere on the dashboard, not just its current
  tile. Narrowed to a consistent rule: excluded only from figures based on `GetLatestByChannelIdsAsync`
  ("most recent reading ever", the exact kind of lookup that shows a dead device's frozen last value forever
  with no time decay - current tiles, current power, humidity decoration); never excluded from figures based
  on `ListByChannelIdsAndTimeRangeAsync` (date-bounded queries, which a dead device naturally stops
  contributing to on its own once it stops reporting, while a past range it was alive for correctly keeps
  including it) - Energy totals/charts and the temperature today-range are unaffected by this flag now.

## [0.51.30] - 2026-08-21
### Added
- (Cloud) `Device.IsExcludedFromDashboard` - lets a customer retire a physically dead/replaced device from
  live dashboard tiles (current-reading tiles, Location-wide power/energy totals) while keeping its
  Equipment assignment intact, so historical reports (a separate live join on `Device.EquipmentId`) keep
  including its past readings. Solves the "two temperature tiles for one fridge" symptom left behind by a
  gateway re-registration incident, where the dead device can't safely be unassigned or deleted without
  losing its history. Deliberately does not auto-deduplicate readings per Equipment - genuine multi-sensor
  Equipment (e.g. two real temperature probes on one fridge) must keep showing both, so only an explicit,
  per-device customer decision can distinguish "dead duplicate" from "intentional second sensor." Checked
  at the one chokepoint every dashboard view and drill-down already shares
  (`LocationDashboardService.BuildChannelTreeAsync`). `LoopMi-Cloud`'s Management endpoints, Portal toggle,
  and migration follow separately.

## [0.51.29] - 2026-08-21
### Changed
- (Cloud) Denormalizes `LocationId`/`OrganizationId` onto Outbox rows at write time, resolved once
  (`LoopMiCloudDbContext.SaveChangesAsync` on the `LoopMi-Cloud` side, following this kernel change) instead
  of re-derived on every alert-feed read. `AlertFeedService`'s read methods scanned up to 500 Outbox rows
  platform-wide and described every one of them (2-4 repository round trips each) just to filter down to
  one Location/Organization - up to ~2000 DB round trips for a single alert-feed page load. `DismissAsync`
  did the same scan just to find and check ownership of one row by ID. `IOutboxRepository` gains
  `GetAsync`/`ListRecentByEventTypesForLocationAsync`/`ListRecentByEventTypesForOrganizationAsync`;
  `PendingOutboxMessage` gains optional `LocationId`/`OrganizationId`. No behavior change to what alerts a
  Location/Organization sees - same precedent as `Measurements.OrganizationId` (0.50.x-era fix for the same
  join-defeats-indexing problem). `LoopMi-Cloud`'s `EfOutboxRepository`/migration follow separately.

## [0.51.28] - 2026-08-21
### Fixed
- `HomeAssistantMeasurementConnector` persisted a newly-discovered device/channel's local mapping row
  *before* confirming the cloud actually received it. A local row is meant to mean "the cloud knows about
  this" (§02) - but a discovery report that failed or got cancelled mid-flight (e.g. by 0.51.27's now-fixed
  check-in deadlock) still left the row cached, so that entity was silently treated as "already reported"
  forever, with no retry, orphaning it from the cloud exactly like the incident 0.51.26 fixed - just
  triggered by a network failure instead of a gateway re-registration. Now the local row is only persisted
  once the cloud report actually succeeds; a failed report for a genuinely new entity is retried on the
  next reading instead of being cached as done. A failed report for an already-known channel's
  classification self-heal (label/kind correction) behaves differently: the stale classification is left
  uncorrected (and retried later), but the reading is still queued normally, since a real Channel already
  exists on the cloud side to record it against.

## [0.51.27] - 2026-08-21
### Fixed
- Found live, immediately after 0.51.26: the check-in/rescan handshake could deadlock forever.
  `EdgeCheckInWorker` re-triggered a local rescan on *every* check-in as long as the cloud still reported
  `DiscoveryRequested: true` - even when the connector had already finished that exact rescan seconds
  earlier. That re-trigger immediately blocked the very code path that would report the caught-up config
  version back to the cloud, so the cloud's flag could never clear either: neither side could ever break
  out, and the connector kept getting cancelled and reconnecting roughly every 60 seconds indefinitely
  instead of settling once the rescan actually finished. Now a rescan is only triggered once per
  CurrentConfigVersion generation, so a later check-in that still sees a stale `DiscoveryRequested: true`
  (because the cloud hasn't heard back yet) reports progress instead of re-cancelling the connector.

## [0.51.26] - 2026-08-21
### Fixed
- Re-registering this Edge under a genuinely different cloud identity (a pasted registration token, or
  recovering from a wiped `/data` directory per 0.51.24's note) never cleared the local discovery cache
  (`device_mappings`/`channel_mappings`). Every previously-known Home Assistant entity kept matching its
  stale local row, so it was silently treated as "already known" and never reported to the new identity -
  no error, no warning, just devices that stopped appearing. Found live: a Rescan processed 350 entity
  states with zero errors, but only 2 genuinely-new devices showed up out of ~60-80 real ones. Now the
  last-registered EdgeGatewayId is tracked (`/data/registered-edge-gateway-id`), and a re-registration that
  returns a different one clears the local mapping cache first, forcing every entity to be rediscovered and
  reported fresh under the new identity. Does not retroactively fix devices already stuck under a prior
  mismatched registration - see the pinned note in the Cloud Portal / ask support for the one-time manual
  recovery step.

## [0.51.25] - 2026-08-21
### Fixed
- (Cloud) `LocationHealthService.ListUnassignedDevicesAsync` (backing Discovered Devices/Hidden Devices)
  fetched devices one Edge Gateway at a time - a real N+1 that scales directly with how many gateways a
  Location has, found live after a re-registration incident left a Location with two gateways. Now one
  batched query (`IDeviceRepository.ListByEdgeGatewayIdsAsync`) across every gateway at once, same result
  set, fewer round trips regardless of how many gateways accumulate over time.

## [0.51.24] - 2026-08-21
### Documentation
- Documents a real incident: Home Assistant Supervisor's "Repair" action for a broken add-on wipes this
  add-on's `/data` directory - the client identity certificate, CA pin, registration-token hash, and local
  SQLite mapping database, all in one shot. That loss is permanent and can't be undone from the Cloud side
  (this Edge never sends Home Assistant's own entity identifiers to the Cloud, so there's no way to
  recognize "same physical device" after re-registering fresh). `DOCS.md`'s "Data persistence" section now
  explains this plainly and recommends including this add-on in Home Assistant's own Backups so a
  Supervisor repair or bad update has something to recover from. No runtime behavior change.

## [0.51.23] - 2026-08-20
### Fixed
- (Cloud) A channel's very first-ever battery reading now alerts immediately if it's already below
  threshold, instead of being silently suppressed like every other status's first observation. Found live:
  a fridge sensor's first-ever battery reading after the always-sync fix (v0.51.21) came in already at 18%
  and never alerted, because the suppress-first-observation rule (meant to avoid alert storms on a freshly
  onboarded device) doesn't distinguish "just started syncing" from "already been low for a while." Domain
  logic only (`Device.cs`) - no Edge runtime behavior actually changes, but the change lands in
  `LoopMi.Domain` so this still triggers a real Edge image rebuild.

## [0.51.22] - 2026-08-20
### Changed
- (Cloud) Battery-kind channels now join the liveness-only Measurement retention sweep (§05.4) regardless
  of `IsMonitored`, keeping only the most recent ~20 readings per channel instead of accumulating unbounded
  history - the threshold check only ever needs the latest value, not a full history. An explicit
  `AlwaysReport=true` still opts a Battery channel out of pruning, same as every other kind.

## [0.51.21] - 2026-08-20
### Changed
- Battery-kind channels now always sync to the cloud regardless of the `IsMonitored`/`AlwaysReport`
  monitoring filter (§05.1) - low-battery alerting depends on it, so it's no longer customer-optional
  telemetry like every other measurement kind. Fixes a real gap where a battery reading confirmed present
  in Home Assistant/Zigbee2MQTT never reached the cloud because nobody had opted the diagnostic battery
  entity into monitoring.
- The battery-low threshold comparison is now inclusive (`<=`) instead of strictly-below (`<`) - a reading
  exactly at the organization's threshold now counts as Low.
- (Cloud) Low-battery alerting now re-alerts on every further drop below the value that triggered the last
  alert, not just once per Ok→Low transition - e.g. threshold 20%: alerts at 20%, stays silent while still
  at 20%, alerts again at 19%, again at 18%, and so on. A person dismissing an earlier alert never suppresses
  a genuinely lower future reading. New `Channel.LastAlertedBatteryPercent` watermark backs this.

## [0.51.20] - 2026-08-20
### Added
- (Cloud) `Organization.BatteryLowThresholdPercent` - the low-battery alert threshold is now configurable
  per organization (still defaulting to 20%) instead of a single hardcoded platform-wide constant. Platform
  administration API/Portal support to edit it per organization ships in the `LoopMi-Cloud` repo on top of
  this.

## [0.51.19] - 2026-08-16
### Added
- (Cloud) `EquipmentEnergySeries`/`EquipmentTemperatureSeries` (the Energy/Temperature Comparison reports)
  each gained an `HourlyPoints` list alongside the existing `DailyPoints` - the chart can now plot
  intraday detail (a compressor short-cycling, a usage burst) instead of one flattened dot per day, while
  the table's Total/Avg/Min/Max figures stay computed from `DailyPoints` exactly as before.

## [0.51.18] - 2026-08-16
### Fixed
- (Cloud) `EquipmentEnergyComparisonReportService` wrongly required a Channel's `IsMonitored` flag to be
  set before including it - every other place Energy channels are resolved (the Location/Area dashboard's
  own energy estimate, `HasEnergyReadingDevice`) has never gated Energy on that flag, unlike Temperature.
  Any Equipment whose Energy channel had never been individually toggled "monitored" - the common case -
  always computed a zero-consumption comparison despite having real readings.

## [0.51.17] - 2026-08-16
### Added
- (Cloud) `IEquipmentManagementService.DeleteEquipmentAsync` - deletes Equipment that has no Device
  currently assigned to it. A Device that's assigned but has never itself reported a measurement still
  blocks deletion; the caller must unassign it first (`ManagementFailureReason.EquipmentHasAssignedDevices`).
### Changed
- (Cloud) `IEquipmentRepository` gained a `Remove` method alongside its existing `Add`, the first delete
  capability on this repository.

## [0.51.16] - 2026-08-16
### Added
- (Cloud) Kernel services behind two new Reporting-area comparison reports: `EquipmentEnergyComparisonReportService`
  and `EquipmentTemperatureComparisonReportService` compare several pieces of Equipment against each other
  over the same date range (energy consumption and temperature, respectively), to surface an outlier unit
  that might indicate a developing fault - an Equipment consuming noticeably more than its selected peers,
  or running noticeably hotter/colder/more variably. Purely additive: no existing service, endpoint, or
  report was touched. An Equipment with more than one qualifying channel has them summed (energy) or
  averaged (temperature) rather than requiring a channel-picker step.

## [0.51.15] - 2026-08-15
### Fixed
- (Edge) The Edge Gateways page's "Edge Software Version" and "Home Assistant Version" columns showed
  meaningless placeholder values ("1.0.0" and "unknown") on every real install - both were hardcoded
  defaults that nothing ever overrode. Edge Software Version is now the real add-on version, threaded from
  the Docker image's own build version through to the running app. Home Assistant Version is now queried
  live from the Home Assistant Supervisor's REST API (`GET /core/info`) on every check-in, falling back to
  the same placeholder only when no Supervisor is available (e.g. local dev outside a real installation).

## [0.51.14] - 2026-08-15
### Added
- (Edge) Self-heals from an orphaned certificate: if the cloud-side EdgeGateway record is ever deleted
  (accidentally, or by a future decommissioning feature), the Edge previously got stuck in a permanent
  authentication-rejection loop, since it only checked local file existence to decide whether it was
  already registered and never noticed its certificate was no longer recognized. It now recognizes the
  cloud's specific "UnknownEdgeGateway" rejection reason and automatically re-registers using whatever
  registration token is currently configured, resetting its mTLS client so the fresh identity takes effect
  immediately - no restart or manual file deletion needed. A deliberately revoked gateway does NOT
  self-heal (by design - that must stay a manual fix, not silently undone).

## [0.51.13] - 2026-08-15
### Fixed
- (Edge) The 0.51.12 log-timestamp fix didn't actually take effect in the shipped add-on: it configured the
  console formatter via appsettings.json's `Logging:Console:FormatterOptions`, which binds through
  reflection-based `ConfigurationBinder` - silently stripped by Native AOT trimming in the real published
  binary (worked fine in a plain `dotnet run`, which isn't AOT-compiled, so the gap wasn't visible locally).
  Now set directly via `builder.Logging.AddSimpleConsole(...)` in code, which needs no reflection and is
  guaranteed to survive trimming.

## [0.51.12] - 2026-08-15
### Fixed
- (Edge) Log lines now carry a UTC timestamp prefix (e.g. `2026-08-15 08:38:46.907 info: ...`) instead of
  appearing with no date/time at all - the console formatter previously had no `TimestampFormat` configured,
  so entries in the Supervisor log viewer couldn't be placed in time or correlated with other events.

## [0.51.11] - 2026-08-15
### Fixed
- (Cloud) A Carbon Monoxide channel (an HA `carbon_monoxide` device_class binary sensor) is now included in
  the dashboard's Water & Gas Monitoring tile grid, alongside the existing Leak/GasLeak/Smoke channels - the
  same gap as the Smoke fix in 0.51.10, just for a different MeasurementKind that the dashboard's
  channel-tree builder hadn't been extended to cover yet.

## [0.51.10] - 2026-08-14
### Fixed
- (Cloud) A Smoke channel (an HA `smoke` device_class binary sensor) is now included in the dashboard's
  Water & Gas Monitoring tile grid, alongside the existing Leak/GasLeak channels - previously it was
  correctly mapped by the Home Assistant device_class table but silently dropped by the dashboard's
  channel-tree builder, so it never appeared on any tile.

## [0.51.9] - 2026-08-14
### Added
- (Cloud) Area-scoped dashboards: every alert now carries the Area/Equipment it concerns when one can be
  resolved, and the Location dashboard service gained a full Area-scoped counterpart to its existing
  Location-scoped dashboard, energy, and temperature drill-downs - the shared kernel piece behind the
  Portal's new "Location → Areas → single Area" drill-down.

## [0.51.8] - 2026-08-14
### Added
- (Cloud) The Organization dashboard's Location tiles now show current electric power draw, today's
  energy consumption, and average temperature, alongside the existing name/status/alert-count summary. The
  top of the dashboard also gains Organization-wide totals for current power draw and today's consumption,
  next to the existing all-locations active-alerts count.

## [0.51.7] - 2026-08-14
### Added
- (Cloud) A read side for the terms-acceptance compliance-evidence trail: a self-service "My Terms
  Acceptance History" view and an Owner/Admin view of a specific member's history, mirroring the existing
  login-attempt history feature. Both that dialog and this new one now page their rows client-side instead
  of rendering the full list at once.

## [0.51.6] - 2026-08-14
### Added
- (Cloud) A just-in-time support-access flow: a platform administrator can request time-boxed, full-Owner
  access to a customer Organization; any one Owner of that Organization is emailed and can approve or
  reject it from the Portal; once approved, the administrator can enter with a short-lived, non-refreshable
  access token that re-validates the grant live on every renewal, so an Owner's revoke takes effect within
  one token lifetime instead of lingering for weeks.

## [0.51.5] - 2026-08-14
### Added
- (Cloud) A fourth first-run gate requires every user to accept the current Terms of Service/Privacy Policy
  bundle before using the Portal - checked first, ahead of password change and TOTP enrollment. Acceptance
  is recorded permanently (never pruned) with the accepting user, version, timestamp, and IP address as a
  compliance-evidence trail, and is versioned so a future policy change can re-gate every user at once.

## [0.51.4] - 2026-08-13
### Added
- (Cloud) Login-attempt summaries now expose the login challenge ID that correlates a two-step login's
  CredentialVerification and SecondFactor rows, so the Portal's login-history view can group them into one
  expandable event instead of two unrelated-looking rows.

## [0.51.3] - 2026-08-13
### Added
- (Cloud) Portal login-history views on top of the login-attempt security log: Owner/Admin can view any
  organization member's login history from the Members page; a member can view their own from a new
  account menu in the top-right corner. Members are no longer able to open the Members page at all.

## [0.51.2] - 2026-08-13
### Added
- (Cloud) A login-attempt security log records every login attempt - success and failure alike, at both
  two-step login stages - with IP address, User-Agent, resolved auth method, and correlated challenge/
  refresh-token IDs, for brute-force/credential-stuffing investigation. 15-day retention.

## [0.51.1] - 2026-08-11
### Added
- (Cloud) A "Clear All" button on the Active Alerts dialog dismisses every currently-active alert for a
  Location in one action, alongside the existing one-at-a-time Dismiss.
- (Cloud) A Device's "went Stale" alert now auto-resolves the moment its data freshness recovers back to
  Fresh on its own, instead of sitting there until a user dismisses it by hand. Deliberately narrow to data
  freshness - Leak/GasLeak, battery, and temperature-range alerts still require a human to dismiss them even
  if the next reading looks normal.

### Changed
- (Cloud) `OperationalHealth.Offline` renamed to `Unknown`. It never actually meant "offline" - the only way
  an Equipment reaches this state is every attached Device's Data Freshness reading Unknown, which never
  observes connectivity at all. That happens both for a Device that's never reported yet and for one whose
  `OfflineAfterMinutes` is deliberately 0/unset (the Freshness opt-out) - found live on a Power Plug that was
  actively reporting and still showed as permanently "Offline" for the latter reason.

## [0.51.0] - 2026-08-06
### Fixed
- (Cloud) The Location dashboard and its "Temperature Ranges Today" drill-down no longer 500 when an
  Equipment has more than one monitored Humidity channel (e.g. several Devices assigned to the same
  Equipment, each reporting Humidity). The most-recently-reported Humidity channel now decorates the
  Equipment's Temperature tile, instead of a `Dictionary` keyed by Equipment throwing on the second one.

## [0.50.0] - 2026-08-04
### Changed
- (Cloud) `IEmailSender` gained `SendDirectAsync`, addressed directly ("To:") to a single recipient,
  for anything personal to one named account - an invite's temporary password, a future password-reset
  email. The existing BCC-everyone `SendAsync` stays exactly as it was, reserved for genuinely
  multi-recipient sends (an operational alert going to every Owner/Admin). Previously every email,
  including one-to-one invites, went out via BCC with the sender's own address as "To:" and the real
  recipient hidden in "Bcc:" - correct RFC 5322 usage for a broadcast, wrong for a message addressed to
  one person.

## [0.49.0] - 2026-08-04
### Fixed
- (Cloud) Alert emails now go out as a single send, BCC to every Owner/Admin, instead of one send per
  recipient. Root cause of persistent `429 Too Many Requests` errors: the ACS Email resource's free Azure
  Managed Domain caps sending at 5 emails/minute and 10/hour *per subscription* - a limit that cannot be
  raised for this domain type at all - and that cap is per API call, not per recipient, so one alert
  reaching 4 people as 4 separate sends burned 4x the scarce quota for the same notification.
  `AzureCommunicationServicesEmailSender` also now holds a short cooldown after any 429, since immediate
  retries still count against the usage limit per Microsoft's own guidance - and disables the Azure SDK's
  own automatic retry policy (`EmailClientOptions.Retry.MaxRetries = 0`), confirmed live as necessary: with
  the SDK's default retries, a 429 never actually surfaced as a catchable exception within any reasonable
  time, so the cooldown above never engaged at all and every attempt kept burning real quota via the SDK's
  own silent internal retries. This replaces the per-recipient delivery tracking added a day earlier
  (`OutboxMessage.SentToEmails`) - no longer needed, since a single BCC send is all-or-nothing for the whole
  alert, with no partial-recipient state to preserve across a retry.
- (Cloud) A second real gap found live while diagnosing the above: `DispatchPendingAsync` processed pending
  Outbox messages in one sequential loop with no per-message bound, so a single hanging send (ACS's
  `WaitUntil.Completed` polling an email that was taking unusually long) blocked every message behind it in
  the same sweep - including non-alert bookkeeping events (e.g. `RefreshTokenUsedDomainEvent`) that need no
  network call at all and would otherwise be marked processed instantly. Each message's processing is now
  bounded to 20 seconds; a message that doesn't finish in time is simply left pending for the next sweep
  instead of blocking everything after it.

## [0.48.0] - 2026-08-03
### Added
- (Cloud) `Device.OfflineAfterMinutes` now accepts `0` as an explicit opt-out from Data Freshness (§06.2),
  instead of only positive values. A Device whose only monitored channels are event-driven (a Leak sensor,
  which only reports when its state actually changes and can otherwise sit silent for months while working
  correctly) previously had no way to avoid false "Stale" alerts, since "no recent reading" isn't evidence
  of a stalled device the way it is for a channel with a real reporting cadence. `0` is device-level, not
  per-channel - a deliberate, simpler choice over a more granular per-Channel design that was also
  considered.

## [0.47.0] - 2026-08-03
### Fixed
- (Cloud) A real, live gap in `OutboxDispatchService`: sending an alert email to an Organization's
  Owners/Admins was one try/catch around the whole recipient loop, so a single recipient's transient send
  failure (e.g. a provider rate limit) restarted the loop from the top on every retry - whoever was early
  in enumeration order got duplicate emails indefinitely, and everyone after the failure point got nothing
  for as long as it lasted. Each recipient's success is now persisted immediately and independently, so a
  retry only ever (re)targets recipients who haven't actually received the alert yet.
- (Cloud) `DispatchOutbox`'s cadence dropped from once a minute to once every 5 seconds (still the same
  Timer-triggered function, with an in-process guard against overlapping runs), so a pending alert waits
  far less time before it's first attempted.
- (Cloud) The Device Messages dialog's channel filter now only lists `AlwaysReport` channels - a
  liveness-only channel is bounded to a small retention buffer (§05.4) and is very often one the HA
  integration never actually reports on at all (a diagnostic/config channel), so including it invited
  "where did my data go" confusion for devices with plenty of real data under a different channel.

## [0.46.0] - 2026-08-03
### Added
- (Cloud) A periodic sweep (`PruneOutboxFunction`/`IOutboxRetentionService`, every 5 minutes) now permanently
  deletes dispatched Outbox messages older than 30 days. The Outbox previously had no purge mechanism at
  all - a past materialization bug (fixed separately, v0.29.0) produced 320,000+ Outbox rows from 79 real
  Devices, 97%+ of the entire database's disk usage, purely because nothing ever cleaned up dispatched
  rows. This closes that gap regardless of what causes a future flood, not just the one bug that caused
  this one.

## [0.45.0] - 2026-08-03
### Added
- The Edge can now recover on its own from an orphaned certificate (e.g. its Cloud-side Edge Gateway
  record was deleted) instead of requiring someone to delete local files by hand: pasting a fresh
  `registration_token` and restarting is now enough on its own, and a new self-resetting
  `clear_connection` option forces the same re-registration even when the token hasn't changed. A
  failed attempt never disturbs a working identity - re-registration only replaces local files after
  the Cloud confirms success. Requires the add-on's new `hassio_api` permission (used only to reset the
  `clear_connection` option back to off once it succeeds).

## [0.44.0] - 2026-08-03
### Added
- (Cloud) Leak/GasLeak channels and Equipment temperature-range thresholds now feed a real calculated
  state (`DetectionStatus`/`TemperatureRangeStatus`), detected by the same periodic health sweep that
  already drives connectivity/freshness alerting - a leak or an out-of-range temperature now raises its
  own alert, independent of Equipment's existing overall health rollup.
- (Cloud) Bounded Measurement retention for Channels tracked purely for liveness (monitored, but not
  flagged for full history): a new periodic sweep keeps only the 20 most recent readings per such
  Channel, instead of accumulating unbounded history forever like an analytical channel does.
### Fixed
- (Cloud) A live SQL execution-timeout 500 on the Location Dashboard, caused by an N+1 query pattern
  that scaled with a Location's Area/Equipment count, and a redundant double-scan in the "latest reading
  per channel" query underneath it - both replaced with bulk/indexed queries, confirmed live.
- (Cloud) The Temperature Report now flags non-conformance per 15-minute averaged bucket, matching how
  HACCP compliance is actually assessed, instead of flagging on any single raw reading outside range.

## [0.43.0] - 2026-08-01
### Changed
- (Cloud) `Measurement` now carries its owning Organization directly (denormalized at ingestion time
  from the reporting Edge Gateway's Location), and Row-Level Security on `Measurements` filters on that
  plain column instead of a Channel -> Device -> EdgeGateway -> Location join. The join defeated the
  table's own index once it grew past a trivial size - reproduced directly against the real dev database
  at 8.6s for a query now down to under 200ms. The Edge-Cloud wire protocol is unchanged; this only
  affects Cloud-side storage and query performance. `Measurement`'s constructor gained a required
  parameter as part of this, a breaking change for any other direct kernel consumer.

## [0.42.0] - 2026-08-01
### Changed
- (Cloud) `Equipment` gains configurable `MinAcceptableTemperature`/`MaxAcceptableTemperature`
  thresholds (§13), and a new `TemperatureReportService` builds a HACCP-style daily temperature
  log for a Location - one row per Equipment/Channel/calendar-day (min/max/avg, reading count,
  and a Conforme/Não Conforme verdict when thresholds are set), foundation for the Portal's new
  Reporting section.

## [0.41.0] - 2026-07-31
### Changed
- (Cloud) Alerts can now be dismissed permanently, so a handled alert stops appearing in every alert feed
  (dashboard "Recent Alerts", the Active Alerts drill-down, and Active/Recent counts). `DescribedAlertEvent`
  now carries the underlying Outbox message's `Id` (previously discarded in translation), and
  `IOutboxRepository`/`IAlertFeedService` gained `TryDismissAsync`/`DismissAsync`.

## [0.40.1] - 2026-07-31
### Fixed
- (Edge, Cloud) Every Leak/GasLeak reading (and any other boolean/detection MeasurementKind sourced from a
  Home Assistant `binary_sensor` entity, which never reports a `unit_of_measurement`) was being silently
  and permanently discarded on ingestion - `Measurement`'s constructor and `MeasurementIngestionService`'s
  validation both rejected an empty `Unit` as invalid, logged a warning, then marked the reading "accepted"
  anyway so the Edge never retried it. An empty Unit is now accepted as legitimate for these readings.

## [0.40.0] - 2026-07-31
### Changed
- (Cloud) `LocationDashboardService`/`LocationDashboardResult`: a Humidity channel's latest reading now
  decorates its Equipment's own Temperature reading (`HumidityValue`/`HumidityUnit`), and every Power
  channel's latest instantaneous reading is summed into a new Location-wide `CurrentPowerWatts`/
  `CurrentPowerUnit` figure - the "how much is this place drawing right now" complement to the existing
  cumulative Energy estimate.

## [0.39.5] - 2026-07-31
### Changed
- (Cloud) Reverts the 0.39.4 test comment from `src/LoopMi.Edge/Program.cs` now that both selective-build
  gate cases (Cloud-only skip in 0.39.3, Edge-relevant full-build in 0.39.4) are confirmed working.

## [0.39.4] - 2026-07-31
### Changed
- (Edge) Test: verifies the opposite case of 0.39.3 - this release touches `src/LoopMi.Edge/Program.cs`
  (a comment, outside the safe list), so `addon-ghcr.yml`'s selective-build gate should correctly trigger a
  full Edge rebuild this time. Confirmed live: full build ran (2m19s, every step executed).

## [0.39.3] - 2026-07-31
### Changed
- (Cloud) Reverts the 0.39.1 test comment. Also re-verifies the fixed selective-build gate (0.39.2): this
  release touches only `LoopMi.Application.Cloud` and this changelog, so `addon-ghcr.yml` should skip the
  Edge Docker rebuild entirely this time.

## [0.39.2] - 2026-07-31
### Fixed
- (Cloud) `addon-ghcr.yml`'s selective-build gate (added in 0.39.0) used `dorny/paths-filter`'s inverted
  pattern idiom (`'**'` plus `!`-negated safe paths) to decide whether a release needs a new Edge Docker
  image - a live test release (0.39.1, a Cloud-only-only change) proved this doesn't actually exclude the
  safe paths the way a `.gitignore`-style reading would suggest, so every release was still triggering a
  full rebuild regardless. Replaced with a plain bash `case` match against `git diff --name-only`, fully
  auditable line by line and verified locally against the real 0.39.0..0.39.1 diff before shipping.

## [0.39.1] - 2026-07-31
### Changed
- (Cloud) A trivial, comment-only change to `LoopMi.Application.Cloud` (verifying `addon-ghcr.yml`'s new
  selective-build gate skips the Edge Docker rebuild for a Cloud-only release, per the plan approved this
  session). To be reverted in the next release once confirmed.

## [0.39.0] - 2026-07-31
### Changed
- (Cloud) Split the Cloud-only portion of `LoopMi.Application` (dashboards, alerting, identity/auth,
  multi-tenancy - never referenced by the Edge add-on) into a new `LoopMi.Application.Cloud` project/package.
  Namespaces are unchanged, so `yaggii/LoopMi-Cloud` needs only a new `PackageReference` added, no `using`
  changes. `addon-ghcr.yml` now skips the Edge Docker rebuild (ARM64 Native AOT build/test/publish + GHCR
  push + the `LoopMi-Addons` sync) entirely when a release's diff since the previous tag only touches
  `LoopMi.Application.Cloud` - most releases from here on, based on this repo's actual history. This release
  itself still does a full rebuild (introducing the new project structure touches shared files), proving the
  split and the new skip logic both work before the fast path is ever exercised for real.

## [0.38.0] - 2026-07-31
### Changed
- (Cloud) The Location energy estimate (dashboard tile, hourly/daily/weekly drill-downs, and per-Area
  consumption breakdown) is now computed from Energy-kind Channels' cumulative kWh meter readings (an exact
  delta between two readings, however sparsely the meter happens to be polled) instead of Power-kind
  Channels' instantaneous kW readings (a numeric integration over time that degrades badly when Power
  samples are sparse - which they always are in practice). Adds `CumulativeEnergyCalculator` alongside the
  existing `EnergyConsumptionCalculator`, which is no longer called for this estimate but is kept for a
  possible future "current instantaneous power" display - a Power channel measures something a cumulative
  Energy channel cannot. `MeasurementKind.Energy` previously had no consumer anywhere in the dashboard at
  all - Energy-kind readings were captured and stored correctly but silently went nowhere.

## [0.37.0] - 2026-07-31
### Fixed
- (Cloud) A single malformed reading in a measurement batch (most commonly a binary Leak/GasLeak sensor's
  "wet"/"dry" state, which Home Assistant reports with no `unit_of_measurement` at all) used to throw out of
  `IngestBatchAsync` entirely, failing the whole HTTP call with a 400 and marking nothing in that batch as
  synced - including every other perfectly valid reading riding alongside it. Since an Edge Gateway resends
  the same unsynced batch verbatim every retry cycle, one bad reading could permanently wedge a gateway's
  sync forever. Invalid readings are now discarded individually (logged, and still counted as "accepted" so
  the Edge doesn't retry something that will never become valid) without affecting the rest of the batch.

## [0.36.0] - 2026-07-31
### Changed
- (Cloud) The dashboard's Temperature/Water/Gas Monitoring grids now only show a tile for a Channel that is
  both monitored (`IsMonitored`) and belongs to an Operational Equipment - previously every Temperature/
  Leak/GasLeak-kind Channel got a tile regardless, showing a blank or (before 0.35.0's ingestion gate)
  stale value for equipment nobody had actually finished setting up. Applies everywhere the shared
  Channel tree is built: the dashboard grids themselves, the Avg Temperature figure and its drill-down, and
  the per-Channel 15-minute-interval drill-down. Power Channels (energy estimate) are unaffected - unlike
  Temperature/Water/Gas, Power never renders as its own tile.

## [0.35.0] - 2026-07-30
### Added
- (Cloud) Measurement ingestion now only stores readings for Channels whose Device is assigned to an
  Operational Equipment. Created, Commissioned (but not yet made Operational), Maintenance, Retired, and
  Archived Equipment all silently discard incoming readings instead of storing them - a Device with no
  Equipment assigned at all is unaffected (no lifecycle to gate on). Discarded readings still count as
  "accepted" in the ingestion response so the Edge doesn't keep retrying a reading that will never be
  stored under this policy. `Channel.LastSeenUtc`/Data Freshness tracking is unaffected either way - that's
  a connectivity fact, independent of whether a reading's value was worth keeping.

## [0.34.0] - 2026-07-30
### Fixed
- (Cloud) `Channel.LastSeenUtc` — what Data Freshness (§06.2), and therefore `Equipment.OperationalHealth`,
  is actually computed from — was never updated by measurement ingestion. `Channel.RecordSeen` existed but
  had zero callers, so every channel stayed "never seen" forever regardless of how much data was really
  arriving, and every Device/Equipment showed permanently Offline even with monitoring enabled and fresh
  readings flowing in. `MeasurementIngestionService.IngestBatchAsync` now calls the new
  `Device.RecordChannelSeen` for every channel in a batch (accepted or duplicate) using the cloud's own
  receipt instant, via a new bulk `IDeviceRepository.ListByChannelIdsAsync`.

## [0.33.0] - 2026-07-30
### Fixed
- (Cloud) The per-Equipment temperature drill-down added in 0.32.0 was scoped by Equipment only, so an
  Equipment with two separate Temperature Channels (e.g. front/back sensors on the same fridge) had both
  tiles open the SAME combined min/max/average across both channels' readings, instead of each tile showing
  only its own channel. Rescoped `ILocationDashboardService.GetEquipmentTemperatureDetailAsync` to
  `GetChannelTemperatureDetailAsync(LocationId, ChannelId, ...)`, matching how the Temperature Monitoring
  grid itself already renders one tile per (Equipment, Channel) pair, not per Equipment.
  `LocationDashboardEquipmentReading` gains `ChannelId` and `EquipmentTemperatureDetailResult` gains
  `ChannelLabel` so the Cloud/Portal layers can carry the distinction through.

## [0.32.0] - 2026-07-30
### Added
- (Cloud) A new per-Equipment temperature drill-down: today's readings bucketed into 15-minute intervals,
  each with its own min/max/average, behind a tile in the dashboard's Temperature Monitoring grid (not the
  Location-wide Avg Temperature tile, which already had its own drill-down). Adds
  `ReadingStatisticsCalculator`, a generic min/max/average interval bucketer (temperature today, but not
  temperature-specific) alongside the existing kWh-specific `EnergyConsumptionCalculator`.

## [0.31.0] - 2026-07-30
### Fixed
- (Cloud) `Equipment.OperationalHealth` now actually gets computed. `UpdateOperationalHealth` has existed
  on the domain aggregate since it was introduced, but nothing ever called it - every Equipment showed
  permanently "Offline" on the dashboard's Temperature Monitoring / Water & Gas grids from the moment it
  was created, regardless of how fresh its data really was. `HealthTransitionDetectionService`'s existing
  5-minute sweep (already computing per-Device data freshness and per-Channel battery status) now also
  rolls those up per Equipment: Healthy when every assigned Device is fresh with no low battery, Critical
  if any is Stale, Warning if only a battery is Low, Offline only when no assigned Device has ever
  reported. No manual data fix needed - the field self-corrects on the sweep's next run after this
  deploys.

## [0.30.0] - 2026-07-30
### Changed
- (Edge add-on + Cloud) Replaced the hand-drawn "Scan Arc / Signal Fade" logo mark with the real
  loopmi.com brand mark, fetched from the live site and checked in as the new canonical raster source
  (`branding/loopmi-logo-master.png`) - there's no vector source, so `gen_logo.py` now resizes instead of
  redrawing, capped at 512px (the source's native resolution). Updated everywhere the mark is wired in:
  the Edge add-on's `icon.png`/`logo.png`, `LoopMi.UI`'s favicon/icon-192, and (via the Cloud repo) the
  Cloud Portal's favicon/icon-192. No C# changed in this release - version bumped to keep this repo's HA
  add-on and NuGet package versions in lockstep, per the existing shared-tag release process.

## [0.29.0] - 2026-07-30
### Fixed
- (Cloud) Fixed a real production bug found while investigating unexpectedly high Azure SQL usage:
  `Device` and `Equipment` had only one constructor each, so EF Core's constructor-binding materialization
  convention invoked it - re-raising `DeviceRegisteredDomainEvent`/`EquipmentCreatedDomainEvent` - on every
  load of an already-existing row, not just on genuine creation. A single real Device had accumulated
  roughly 4,000 duplicate Outbox rows purely from being read back by ordinary repository calls (79 real
  Devices → 320,374 Outbox rows), which never purge - 97%+ of the entire database's disk usage. Both
  aggregates now have the same private ORM-materialization-only constructor every other aggregate
  (`Area`, `EdgeGateway`, `Location`, `Organization`, `RegistrationToken`) already had. Neither event type
  is alert-worthy, but the flood of junk rows was also crowding genuine alerts out of the Active Alerts
  feed's recent-history scan window within roughly 10-15 minutes.

## [0.28.0] - 2026-07-30
### Added
- (Cloud) `EquipmentTemperatureRange` gains `AverageValue` - the plain mean of today's readings for each
  Temperature-reporting Equipment/Channel, alongside the existing min/max, so the Avg Temperature drill-down
  can show a headline average with the min/max as supporting detail.

## [0.27.0] - 2026-07-30
### Added
- (Cloud) Two new dashboard drill-downs: `GetTemperatureDetailAsync` returns today's min/max range per
  Temperature-reporting Equipment/Channel (behind the Avg Temperature tile), and
  `IAlertFeedService.ListForLocationAsync` returns a Location's alerts within an arbitrary time range
  (behind the Active Alerts tile, with a Last 24 hours/7 days/30 days picker). `AlertFeedService`'s scan
  window grows from 100 to 500 rows so a 30-day query still reaches back far enough at today's alert volume.

## [0.26.0] - 2026-07-30
### Changed
- (Cloud) The Consumption Today drill-down now shows yesterday's consumption in FULL (all 24 hours),
  instead of only the same elapsed portion of the day as today - a whole-day reference for the chart to
  plot today's so-far line against, rather than a same-timeframe comparison (that comparison still exists,
  computed separately for the dashboard's percentage tile).

## [0.25.0] - 2026-07-30
### Added
- (Cloud) A new weekly energy drill-down behind the dashboard's "% of Yesterday's Full Day" tile: this
  week's consumption so far compared day-by-day against last week's, bucketed by calendar day.
  `EnergyConsumptionCalculator` gains `ComputeDailyBuckets`, sharing its boundary-interpolation core with
  the existing hourly bucketing so both stay reconciled with `Compute`'s totals. A day later in the current
  week that hasn't happened yet is simply absent from the result, not reported as zero.

## [0.24.0] - 2026-07-29
### Changed
- (Cloud) The Consumption Today drill-down now returns hour-by-hour consumption buckets instead of raw
  Power-channel readings, so the Portal can chart and table today vs. yesterday one hour at a time rather
  than one instantaneous reading at a time. `EnergyConsumptionCalculator` gains `ComputeHourlyBuckets`,
  reusing the same trapezoidal integration `Compute` already uses so the two always reconcile.

## [0.23.0] - 2026-07-29
### Added
- (Cloud) `ILocationDashboardService` gains `GetEnergyDetailAsync`, returning today's raw Power-channel
  registries alongside yesterday's over the identical elapsed portion of the day - the "show the actual
  numbers" drill-down behind the dashboard's Consumption Today tile, for a chart and table view rather
  than the single rolled-up estimate.

## [0.22.0] - 2026-07-29
### Added
- (Cloud) LocationHealthResult now also carries the least remaining local storage across a Location's
  Edge Gateways, so the Portal's storage icon can show the actual free space (e.g. "48.2 GB free") instead
  of the last-synced timestamp, which made more sense for the connectivity icon than for storage.

## [0.21.0] - 2026-07-29
### Fixed
- (Cloud) A revoked Edge Gateway (e.g. an old one superseded by a fresh registration after the Edge lost
  its identity and had to re-register) is now excluded from a Location's health rollup entirely. Before
  this, a permanently-dead, never-syncing-again gateway could drag a Location's connectivity to
  Disconnected forever - visible as a real live case: "Disconnected" and "last synced just now"
  simultaneously, once one gateway's stale last-known facts and another's live ones got rolled up together.

## [0.20.0] - 2026-07-29
### Added
- (Cloud) LocationHealthResult now carries the most recent successful sync timestamp across a Location's
  Edge Gateways, so the Portal can show "how long ago" alongside connectivity/storage status instead of
  just the status word.

## [0.19.0] - 2026-07-29
### Fixed
- (Cloud) The dashboard's energy day boundary now uses Lisbon local time instead of UTC's own calendar
  midnight - during WEST (UTC+1, in effect most of the year), the old UTC boundary was an hour later than
  the real local midnight, skewing the "today vs yesterday" comparison by that hour's readings.
- (Cloud) The "Recent Alerts" panel is now genuinely limited to the last 24 hours, rather than always
  showing up to 20 entries regardless of age.
### Added
- (Cloud) The consumption dashboard now shows yesterday's absolute kWh figure for the same elapsed time of
  day alongside the percentage comparison, not the percentage alone.

## [0.18.0] - 2026-07-29
### Added
- (Cloud) A real-time monitoring dashboard for the Portal - an Organization-wide landing page
  summarizing every Location's health and active alerts, linking into a per-Location dashboard with
  current Equipment readings (grouped by Temperature and Water/Gas), a best-effort energy consumption
  estimate (today's total plus two comparisons against yesterday - cost/savings deliberately parked,
  no metering/billing concept exists yet), a "Recent Alerts" feed built from the existing alert
  history, and a per-Area consumption breakdown. Refreshes automatically every 30 seconds while open.

## [0.17.0] - 2026-07-29
### Added
- (Cloud) Re-inviting an email that belongs to an account previously removed from every
  organization now reactivates that same account instead of failing with "already
  registered": a fresh temporary password is emailed, and TOTP/recovery codes are cleared
  entirely so the member re-enrolls from scratch. Still rejected if the email belongs to
  a currently active member elsewhere, or to the platform administrator.

## [0.16.0] - 2026-07-29
### Changed
- (Cloud) An invited organization member's temporary password is now emailed directly to
  them instead of being shown to the inviting Owner.
### Added
- (Cloud) Owners can now remove a member from their organization (the sole-Owner
  guardrail still applies); removal also revokes the member's outstanding sessions.

## [0.15.0] - 2026-07-28
### Added
- (Cloud) Organizations now have a trial deadline (30 days from creation by default, adjustable per
  organization by a platform administrator). A Suspended organization - whether from a lapsed trial or
  direct administrative action - now actually enforces something for the first time: existing data stays
  readable through the Portal, but the Ingestion API rejects new data from that organization's Edge
  Gateways. No Edge-visible change unless your own organization's trial lapses.

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
