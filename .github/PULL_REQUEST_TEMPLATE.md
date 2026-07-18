## Purpose

Describe the problem and the intended outcome.

## Changes

Describe the implementation and the affected modules or interfaces.

## Compatibility

- [ ] Existing JSON field types and meanings are preserved.
- [ ] Existing Zabbix keys and discovery macros are preserved.
- [ ] Any intentional breaking change increases `schema_version` and includes migration notes.

## Automated validation

- [ ] `bash -n` passes.
- [ ] ShellCheck passes.
- [ ] shfmt reports no differences.
- [ ] `make test` passes.
- [ ] Generated JSON passes `jq -e`.
- [ ] New normal and failure paths have tests.

## Real-system verification

Status requested:

- [ ] Supported
- [ ] Experimental
- [ ] No support-status change

Verified on:

- OS and version:
- Kernel:
- Relevant package versions:
- Hardware or virtual platform:
- Commands executed:
- Result and known limitations:

## Zabbix verification

- [ ] Not applicable.
- [ ] Template imports successfully.
- [ ] Master and dependent items become supported.
- [ ] Discovery and triggers were checked.

## Documentation

- [ ] Installation/configuration documentation updated.
- [ ] Verification/troubleshooting documentation updated.
- [ ] Support matrix or roadmap updated when applicable.
- [ ] Logs and fixtures contain no sensitive data.
