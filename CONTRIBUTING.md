# Contributing

## Project standard

`linux-monitoring` prioritizes verified behavior over feature count. A change must not claim support for hardware, platforms, or configurations that have not been tested on a real target system.

Read before contributing:

- [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md)
- [SUPPORT_POLICY.md](SUPPORT_POLICY.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [TESTING.md](TESTING.md)

## Workflow

1. Create a dedicated branch from `main`.
2. Keep one logical change per pull request.
3. Preserve existing behavior unless the PR explicitly documents and justifies a breaking change.
4. Before push, run:

```bash
make test
find . -type f -name '*.sh' -print0 | xargs -0 shellcheck --severity=warning
find . -type f -name '*.sh' -print0 | xargs -0 shfmt -d -i 4 -ci
```

5. Do not change the type or meaning of existing JSON fields without increasing `schema_version` and documenting migration impact.
6. Update documentation in the same pull request.
7. Record real-system verification when requesting Supported status.

## Collector requirements

A new collector must:

- run independently from Zabbix;
- emit exactly one valid JSON document to stdout;
- write diagnostics only to stderr or the documented JSON error structure;
- avoid changing the system during normal collection;
- use shared runtime helpers where applicable;
- use atomic cache replacement;
- include an updater, service, timer, Zabbix alias, tests, and documentation where applicable;
- define explicit behavior for missing tools, permissions, invalid output, timeouts, and partial collection failures.

A collector must not silently classify an unverified backend as Supported.

## Support claims

Fixture data and automated tests are required but not sufficient for Supported status. The pull request must identify the real system used for verification and the exact scope tested.

Unverified implementations may be accepted only when clearly isolated and documented as Experimental. They must not affect verified default paths.

## Commit messages

Use concise Conventional Commit-style messages:

```text
feat: add ZFS pool collector
fix: preserve SMART cache on collection failure
ci: add ShellCheck validation
docs: document storage support policy
test: cover invalid smartctl JSON
```

## Pull request checklist

- [ ] The change has one clear purpose.
- [ ] `bash -n` passes for affected scripts.
- [ ] ShellCheck returns no warnings or errors.
- [ ] shfmt reports no differences.
- [ ] `make test` passes.
- [ ] Generated JSON is validated with `jq -e`.
- [ ] New normal and failure paths have automated tests.
- [ ] Zabbix YAML imports into the supported Zabbix version when applicable.
- [ ] Documentation is updated.
- [ ] JSON and Zabbix compatibility are reviewed.
- [ ] Supported claims include real-system verification evidence.
- [ ] Sensitive information has been removed from fixtures and logs.
