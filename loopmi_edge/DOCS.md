# LoopMi Edge

LoopMi Edge is the on-site runtime that connects this Home Assistant instance to your
LoopMi Cloud account. It observes your Home Assistant devices and sends telemetry
upward to the Cloud for monitoring, dashboards, and alerting - it never sends commands
back down. If something here isn't working the way you expect, it's the Edge's job to
report that honestly, not to quietly "fix" it by controlling your home.

## Before you start

You'll need a **registration token**, issued from the LoopMi Cloud Portal when you add
a Location there. It's single-use and expires in 15 minutes, so generate it right
before you configure this add-on.

## Configuration

Open this add-on's **Configuration** tab and set:

| Option | Required | Description |
|---|---|---|
| `registration_token` | Yes, on first setup | The one-time token from the Cloud Portal. Paste it in and start (or restart) the add-on - registration runs once and is a no-op on every later restart if already registered. Safe to leave the value in place afterward. |
| `cloud_base_url` | For real deployments | The Provisioning API's base URL, used only for that one-time registration call. Leave blank only for local development against a Cloud instance reachable at `https://localhost:7071/api/` from inside the container - not what you want for a real installation. |
| `ingestion_base_url` | For real deployments | The Ingestion API's base URL - a *different* host from `cloud_base_url` - used for every check-in, discovery report, and measurement upload after registration. Same local-dev-only default and caveat as above. |
| `clear_connection` | No | A one-off recovery switch, not a normal setting - see "Recovering a lost connection" below. |

After registration succeeds, `registration_token` is no longer used - you can leave it
set or clear it, either is fine.

## Recovering a lost connection

If your Cloud-side connection to this Edge is ever removed (for example, the Location
or Edge Gateway was deleted from the Cloud Portal), this Edge can recover on its own,
without deleting any files by hand:

- **Paste a new registration token and restart.** As soon as this Edge notices the
  configured `registration_token` is different from the one it last registered with,
  it re-registers automatically using the new token - no other action needed.
- **Or tick `clear_connection` and save**, if you want to force a fresh registration
  using the *same* token still in `registration_token` (for example, after fixing
  something on the Cloud side without changing the token). This add-on resets the
  checkbox back to off by itself once re-registration succeeds - if it stays ticked
  after a restart, registration hasn't succeeded yet (check the add-on log, and that
  your token/URLs are correct).

Either path is safe to try: your existing identity is only ever replaced after the
Cloud confirms the new registration succeeded, so a failed attempt never leaves this
Edge worse off than before.

## What it does

- Discovers your Home Assistant entities and reports them to LoopMi Cloud, where you
  group them under Equipment and Areas.
- Watches entity state changes and periodically sweeps full state, forwarding
  measurements upward.
- Reports its own health (connectivity, storage) so Cloud-side alerting knows if this
  Edge instance itself goes quiet.

## Ports

| Port | Purpose |
|---|---|
| `5034/tcp` | LoopMi Edge REST API, also used as this add-on's watchdog health check (`/health`). |

## Data persistence

If you're troubleshooting or planning a backup, the Edge keeps state at:

- `/data/loopmi-edge.db` - SQLite database.
- `/data/logs/loopmi-edge.log` - application logs.
- `/config/loopmi/appsettings.json` - configuration file.
- `/data/edge-identity.pfx` - client identity certificate, written during registration.
- `/data/loopmi-ca.pem` - pinned CA certificate, written during registration.
- `/data/registered-token.hash` - a hash (not the plaintext) of the registration token last used, so this Edge can notice when you paste a different one.

Deleting the identity certificate or database forces re-registration on next start -
you'd need a fresh registration token from the Cloud Portal.

## Support

- Cloud Portal and account questions: your LoopMi Cloud organization's Owner/Admin.
- Add-on issues: https://github.com/yaggii/LoopMi-Addons/issues
