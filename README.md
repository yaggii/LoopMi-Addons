# LoopMi Add-ons

Home Assistant add-on repository for [LoopMi](https://github.com/yaggii/LoopMi), an
observability platform for Home Assistant deployments in commercial locations.

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮** menu (top right) → **Repositories**.
3. Add this repository's URL: `https://github.com/yaggii/LoopMi-Addons`.
4. The add-on below will appear in the store - install it from there.

## Add-ons in this repository

### [LoopMi Edge](loopmi_edge)

The on-site runtime that connects this Home Assistant instance to your LoopMi Cloud
account: discovers entities, forwards telemetry upward, and reports its own health.
Sends nothing back down - see the add-on's own Documentation tab (or
[`loopmi_edge/DOCS.md`](loopmi_edge/DOCS.md)) after installing for configuration and
setup, and its Changelog tab for release history.

## About this repository

Every file under `loopmi_edge/` here (Dockerfile, `config.yaml`, `rootfs/`,
`DOCS.md`, `CHANGELOG.md`, translations) is synced automatically from
[`yaggii/LoopMi`](https://github.com/yaggii/LoopMi)'s `addons/loopmi_edge/` on every
version release - this repository is a publish target, not where the add-on's source
is developed. Issues and pull requests for the add-on's actual behavior belong in the
`LoopMi` repository; use the issue tracker here for packaging/installation problems
specific to this add-on store listing.
