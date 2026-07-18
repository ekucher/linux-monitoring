# linux-monitoring 2.0.0

Production-oriented collectors for Zabbix Agent 2 on Debian and Proxmox VE.

> **Quality over quantity. Every supported feature is verified on real systems.**

The project collects host data into stable JSON caches and exposes them to Zabbix through master items, dependent items, discovery rules, and triggers.

```text
collector -> JSON cache -> Zabbix Agent alias -> master item -> dependent items / LLD / triggers
```

## Current modules

| Module | Status | Scope |
|---|---|---|
| SMART | Supported | Directly attached SATA/ATA and NVMe devices verified in the project test environment |
| Sensors | Supported | `lm-sensors` JSON collection on verified Debian/Proxmox systems |
| Hardware inventory | Planned | CPU, memory, firmware, board, PCI, USB, network inventory |
| ZFS | Planned | Pool, vdev, capacity, error, scrub and health monitoring |
| Proxmox VE | Planned | Node, guest, storage and cluster monitoring |
| NFS / Samba | Planned | Mount, export/share and service monitoring |

Unverified RAID controllers, storage backends, distributions, and device transports are not advertised as supported.

## Supported environment

The project currently targets the environments that can be tested directly:

- Debian 13 (Trixie);
- Proxmox VE 8.x;
- Zabbix Agent 2 7.4;
- directly attached SATA/ATA and NVMe storage;
- `lm-sensors` on verified hardware.

See [SUPPORT_POLICY.md](SUPPORT_POLICY.md) for the exact meaning of support statuses.

## Quick start

```bash
sudo apt update
sudo apt install -y unzip zabbix-agent2 zabbix-get

unzip linux-monitoring-v2.0.0.zip
cd linux-monitoring-v2.0.0

sudo ./install.sh
```

Verify the installation:

```bash
systemctl status linux-monitoring-smart.timer --no-pager
systemctl status linux-monitoring-sensors.timer --no-pager

jq . /var/lib/linux-monitoring/smart.json
jq . /var/lib/linux-monitoring/sensors.json

zabbix_agent2 -t smart.cache.json
zabbix_agent2 -t sensors.cache.json
```

## Installer options

```text
--timer-interval VALUE    timer interval, default: 5m
--modules LIST            smart,sensors or smart
--skip-packages           do not install packages
--skip-agent-restart      do not restart zabbix-agent2
--run-sensors-detect      run sensors-detect --auto
--dry-run                 print actions without changing the system
--debug                   enable Bash tracing
```

Examples:

```bash
sudo ./install.sh --modules smart,sensors --timer-interval 5m
sudo ./install.sh --modules smart
sudo ./install.sh --run-sensors-detect
```

`sensors-detect --auto` is not executed implicitly because it can change the set of loaded kernel modules.

## Documentation

- [Requirements](docs/02-Requirements.md)
- [Installation](docs/03-Installation.md)
- [Zabbix configuration](docs/04-Zabbix-Configuration.md)
- [Verification](docs/05-Verification.md)
- [Troubleshooting](docs/08-Troubleshooting.md)
- [Design principles](DESIGN_PRINCIPLES.md)
- [Support policy](SUPPORT_POLICY.md)
- [Architecture](ARCHITECTURE.md)
- [Testing](TESTING.md)
- [Roadmap](ROADMAP.md)
- [Contributing](CONTRIBUTING.md)

## Project rules

- `main` must remain deployable.
- Existing JSON fields remain compatible unless `schema_version` is intentionally increased.
- A feature is marked **Supported** only after automated checks and verification on a real target system.
- Unsupported hardware is not silently treated as supported.
- Every collector must fail predictably and preserve diagnostic information.

## Non-goals

The project does not aim to support every Linux distribution, controller, enclosure, bridge, or monitoring use case. New coverage is added only when it can be implemented, tested, documented, and maintained with confidence.
