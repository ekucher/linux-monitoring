# Design principles

## Mission

Build reliable Zabbix collectors for Debian and Proxmox VE that are safe to deploy and straightforward to maintain.

## Core principles

### Quality over quantity

A smaller verified feature set is preferred over broad but uncertain compatibility.

### Production first

Code merged into `main` must remain suitable for deployment. Experimental behavior must not be presented as production support.

### Real-system verification

Automated fixtures validate parsing and edge cases, but they do not replace validation on a real target system. A feature becomes **Supported** only after both levels are complete.

### Stable interfaces

Collectors expose versioned JSON. Existing fields must not change meaning or type without an intentional schema-version increase and migration notes.

### Predictable failure

Collectors must:

- emit valid machine-readable output when possible;
- write diagnostics to stderr or the documented error structure;
- avoid destructive system changes during collection;
- avoid hiding partial failures;
- preserve the last known-good cache when the updater design requires it.

### Minimal dependencies

Use standard Debian and Proxmox tooling where practical. Add dependencies only when they provide clear operational value.

### Documentation is part of the feature

A feature is incomplete until installation, configuration, verification, limitations, and troubleshooting are documented.

## Decision rule

Every change proposed for `main` should answer yes to this question:

> Would we confidently deploy and maintain this change on our own production systems?

If the answer is no, the change remains planned, experimental, or outside the project scope.
