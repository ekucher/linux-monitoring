# Testing

## Test layers

### Static validation

Run before every push:

```bash
bash -n install.sh collectors/*.sh tests/*.sh
find . -type f -name '*.sh' -print0 | xargs -0 shellcheck --severity=warning
find . -type f -name '*.sh' -print0 | xargs -0 shfmt -d -i 4 -ci
```

### Automated tests

Run the repository test target:

```bash
make test
```

Fixture tests must cover:

- valid normal output;
- empty discovery results;
- invalid command output;
- command failures and meaningful exit codes;
- missing optional fields;
- schema compatibility;
- cache validation and atomic replacement where applicable.

### Real-system verification

A feature cannot be marked Supported without verification on a real target system.

Record at minimum:

- operating system and version;
- kernel version;
- relevant package versions;
- hardware or virtual platform;
- commands used for verification;
- representative sanitized output;
- Zabbix import and item status when applicable;
- known limitations.

## Minimum pre-merge checklist

- [ ] `bash -n` passes.
- [ ] ShellCheck passes at warning severity.
- [ ] shfmt reports no differences.
- [ ] `make test` passes.
- [ ] Generated JSON passes `jq -e`.
- [ ] Existing fixture tests remain compatible.
- [ ] New failure paths have tests.
- [ ] Documentation is updated.
- [ ] JSON and Zabbix compatibility are reviewed.
- [ ] Real-system verification is completed for Supported claims.

## Verification commands

Typical module verification:

```bash
sudo systemctl start linux-monitoring-smart.service
systemctl status linux-monitoring-smart.service --no-pager
jq -e . /var/lib/linux-monitoring/smart.json
zabbix_agent2 -t smart.cache.json
```

Use equivalent commands for other modules.

## Evidence and privacy

Logs and fixtures committed to the repository must remove credentials, hostnames where sensitive, serial numbers when required, public IP addresses, tokens, and other private data. Sanitization must not alter the structural behavior being tested.

## Regression policy

Every confirmed regression should receive a failing automated test before or together with the fix whenever the behavior can be reproduced deterministically.
