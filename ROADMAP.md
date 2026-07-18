# Roadmap

The roadmap prioritizes completed, verified modules over a large feature count. Release targets are directional and do not imply a fixed delivery date.

## v0.1 — SMART

Goal: complete the supported direct-device SMART workflow.

- verified SATA/ATA and NVMe collection;
- stable versioned JSON;
- cache updater and systemd timer;
- fixture tests for normal and failure paths;
- Zabbix master item, dependent items, discovery, and triggers;
- installation, verification, and troubleshooting documentation.

Unverified RAID/HBA and USB bridge backends are outside the supported milestone.

## v0.2 — Hardware inventory

Goal: reliable inventory for verified Debian and Proxmox hosts.

- operating system and kernel;
- CPU topology and model;
- memory summary;
- BIOS/UEFI and system board;
- PCI and network inventory;
- stable hardware identifiers with privacy-conscious defaults.

## v0.3 — Sensors

Goal: complete the verified `lm-sensors` monitoring path.

- normalized temperature, fan, voltage, current, and power data;
- sensor discovery;
- configurable thresholds;
- verified Zabbix triggers;
- documented handling of missing or renamed sensor chips.

## v0.4 — ZFS

Goal: production monitoring for verified ZFS systems.

- pool and vdev health;
- capacity and fragmentation;
- read, write, and checksum errors;
- scrub state and age;
- degraded and faulted device discovery;
- verified operation on available Proxmox/Debian ZFS hosts.

## v0.5 — Proxmox VE

Goal: host and cluster monitoring for the verified Proxmox environment.

- node health and version;
- VM and container discovery;
- storage state;
- cluster and quorum state where applicable;
- documented permissions and failure behavior.

## v0.6 — NFS and Samba

Goal: monitor the verified file-service paths.

- service availability;
- configured exports and shares;
- client mount state;
- capacity and accessibility checks;
- safe discovery without exposing credentials.

## v1.0 — Production baseline

Criteria:

- all included Supported modules meet `SUPPORT_POLICY.md`;
- JSON and Zabbix interfaces are documented;
- installation and upgrade paths are verified;
- CI and regression coverage are stable;
- known limitations are explicit;
- no unverified compatibility is advertised as Supported.

## Deferred until testable

The following areas are considered only after real hardware or a verified test environment becomes available:

- MegaRAID and Dell PERC;
- HP Smart Array;
- Areca and Adaptec controllers;
- vendor-specific USB-SAT bridges;
- Ceph;
- IPMI and UPS hardware;
- additional Linux distributions.
