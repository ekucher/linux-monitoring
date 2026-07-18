# Contributing

## Робочий процес

1. Створіть окрему гілку від `main`.
2. Вносьте одну логічну зміну на pull request.
3. Перед push виконайте:

```bash
make test
find . -type f -name '*.sh' -print0 | xargs -0 shellcheck --severity=warning
find . -type f -name '*.sh' -print0 | xargs -0 shfmt -d -i 4 -ci
```

4. Не змінюйте формат існуючих JSON-полів без підвищення `schema_version`.
5. Новий collector повинен:
   - бути незалежним від Zabbix;
   - виводити один валідний JSON у stdout;
   - писати діагностику лише у stderr;
   - не змінювати систему під час звичайного збору;
   - мати окремий updater, service, timer, alias і документацію.

## Commit messages

Використовуйте короткі повідомлення у стилі Conventional Commits:

```text
feat: add ZFS pool collector
fix: preserve SMART cache on collection failure
ci: add ShellCheck validation
Docs: document RAID controller support
```

## Pull request checklist

- [ ] `bash -n` проходить для всіх shell scripts.
- [ ] ShellCheck не повертає помилок.
- [ ] shfmt не знаходить відмінностей.
- [ ] JSON перевірено через `jq -e`.
- [ ] Zabbix YAML імпортується у підтримувану версію Zabbix.
- [ ] Документацію оновлено.
- [ ] Зворотна сумісність оцінена.
