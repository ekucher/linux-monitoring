# Architecture

## Data flow

All production collectors follow the same data path:

```text
collector
    -> validated JSON
    -> atomic cache update
    -> Zabbix Agent 2 alias
    -> master item
    -> dependent items / LLD / triggers
```

## Collector contract

A collector must:

- run independently from Zabbix;
- emit exactly one valid JSON document to stdout;
- write human-readable diagnostics to stderr;
- avoid modifying host configuration during normal collection;
- expose a `schema_version`;
- report partial and fatal errors explicitly;
- use stable identifiers where available;
- complete within a documented timeout.

## Runtime components

Shared shell libraries live under `lib/`:

- `logging.sh` — consistent log messages;
- `config.sh` — configuration loading and validation;
- `cache.sh` — safe atomic cache replacement.

Collector-specific code must not duplicate these responsibilities without a documented reason.

## Cache model

Collectors write to a temporary file, validate the complete JSON document, and atomically replace the cache. A partial write must never become the active cache.

Recommended top-level fields:

```json
{
  "schema_version": 1,
  "status": "ok",
  "generated_at": "2026-01-01T00:00:00Z",
  "duration_ms": 100,
  "errors": [],
  "data": {}
}
```

Existing collectors may retain compatible historical top-level structures. Convergence must be behavior-preserving and explicitly versioned.

## Zabbix integration

Each module owns:

- one collector;
- one updater or service entry point;
- one systemd service and timer where periodic caching is required;
- one Zabbix Agent alias or user parameter;
- one master item;
- dependent items and discovery rules;
- triggers based on normalized collector data;
- installation and verification documentation.

The Zabbix template should parse cached JSON rather than execute expensive hardware tools for each item.

## Extension rules

A new module must not change unrelated collectors. Shared behavior belongs in `lib/` only after at least two modules need the same contract and the refactor preserves existing output.

Hardware-specific backends must remain isolated so an unverified backend cannot affect verified direct-device collection.
