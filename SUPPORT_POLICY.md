# Support policy

This document defines how compatibility claims are made in `linux-monitoring`.

## Status levels

### Supported

A feature or platform is **Supported** only when all applicable conditions are met:

- implementation is complete;
- automated tests cover normal and failure paths;
- CI passes;
- behavior is verified on a real target system;
- Zabbix integration is verified when applicable;
- installation, verification, limitations, and troubleshooting are documented;
- compatibility impact is reviewed.

### Experimental

**Experimental** means the implementation exists but one or more Supported criteria are incomplete. Experimental behavior may change and must not be relied on for unattended production deployment.

### Planned

**Planned** identifies an accepted direction with no support commitment or delivery date.

### Deprecated

**Deprecated** functionality remains temporarily available for compatibility but is scheduled for removal. Deprecation requires release notes and a migration path where practical.

### Unsupported

Hardware, platforms, transports, and configurations not explicitly listed as Supported are unsupported. The project does not infer support from similarity to a tested configuration.

## Current supported scope

The currently declared scope is intentionally narrow:

- Debian 13 (Trixie);
- Proxmox VE 8.x;
- Zabbix Agent 2 7.4;
- SMART collection for verified directly attached SATA/ATA and NVMe devices;
- sensor collection through `lm-sensors` on verified hosts.

Exact support may be further constrained by collector documentation and known limitations.

## Hardware-specific features

Support for RAID controllers, HBAs, USB bridges, enclosures, vendor-specific SMART backends, IPMI devices, UPS hardware, and similar components is added only after real-system verification.

Fixture data or third-party reports can justify implementation work, but do not by themselves grant Supported status.

## Compatibility

- Existing JSON fields must preserve their meaning and type within a schema version.
- Breaking changes require a schema-version increase and migration notes.
- New optional fields may be added without breaking existing consumers.
- Zabbix keys and discovery macros should remain stable unless a documented migration is provided.

## Bug handling

A defect in a Supported path is treated as a regression. A defect in an Experimental path may result in a behavior change, redesign, or removal.
