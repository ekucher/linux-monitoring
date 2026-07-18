#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_DIR = ROOT / "zabbix" / "templates"
UUID_RE = re.compile(r"^[0-9a-f]{32}$")


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def ensure_uuid(value: Any, context: str) -> None:
    if not isinstance(value, str) or UUID_RE.fullmatch(value) is None:
        fail(f"Некоректний UUID у {context}: {value!r}")


def validate_template(path: Path) -> None:
    with path.open(encoding="utf-8") as stream:
        document = yaml.safe_load(stream)

    if not isinstance(document, dict):
        fail(f"{path}: кореневий YAML-вузол повинен бути object")

    export = document.get("zabbix_export")
    if not isinstance(export, dict):
        fail(f"{path}: відсутній zabbix_export")
    if str(export.get("version")) != "7.4":
        fail(f"{path}: потрібен zabbix_export.version=7.4")

    templates = export.get("templates")
    if not isinstance(templates, list) or not templates:
        fail(f"{path}: відсутні templates")

    for template in templates:
        if not isinstance(template, dict):
            fail(f"{path}: template повинен бути object")
        ensure_uuid(template.get("uuid"), f"{path}:template")
        if not template.get("template") or not template.get("name"):
            fail(f"{path}: template/name не можуть бути порожніми")
        if not template.get("groups"):
            fail(f"{path}: шаблон не має groups")

        items = template.get("items") or []
        discovery_rules = template.get("discovery_rules") or []
        if not items:
            fail(f"{path}: шаблон не має master item")
        if not discovery_rules:
            fail(f"{path}: шаблон не має discovery_rules")

        keys: set[str] = set()
        for item in items:
            ensure_uuid(item.get("uuid"), f"{path}:item")
            key = item.get("key")
            if not isinstance(key, str) or not key:
                fail(f"{path}: item без key")
            if key in keys:
                fail(f"{path}: дубльований key {key}")
            keys.add(key)

        for rule in discovery_rules:
            ensure_uuid(rule.get("uuid"), f"{path}:discovery_rule")
            key = rule.get("key")
            if not isinstance(key, str) or not key:
                fail(f"{path}: discovery rule без key")
            if rule.get("type") != "DEPENDENT":
                fail(f"{path}: discovery rule {key} повинен бути DEPENDENT")

            master_item = rule.get("master_item")
            master_key = master_item.get("key") if isinstance(master_item, dict) else None
            if master_key not in keys:
                fail(f"{path}: discovery rule {key} посилається на відсутній master item {master_key}")

            preprocessing = rule.get("preprocessing") or []
            if not preprocessing:
                fail(f"{path}: discovery rule {key} не має preprocessing")

            prototypes = rule.get("item_prototypes") or []
            if not prototypes:
                fail(f"{path}: discovery rule {key} не має item_prototypes")
            prototype_keys: set[str] = set()
            for prototype in prototypes:
                ensure_uuid(prototype.get("uuid"), f"{path}:item_prototype")
                prototype_key = prototype.get("key")
                if not isinstance(prototype_key, str) or not prototype_key:
                    fail(f"{path}: item prototype без key")
                if prototype_key in prototype_keys:
                    fail(f"{path}: дубльований prototype key {prototype_key}")
                prototype_keys.add(prototype_key)
                if prototype.get("type") != "DEPENDENT":
                    fail(f"{path}: prototype {prototype_key} повинен бути DEPENDENT")

                prototype_master = prototype.get("master_item")
                prototype_master_key = (
                    prototype_master.get("key") if isinstance(prototype_master, dict) else None
                )
                if prototype_master_key not in keys:
                    fail(
                        f"{path}: prototype {prototype_key} посилається на відсутній "
                        f"master item {prototype_master_key}"
                    )

    print(f"[PASS] {path.relative_to(ROOT)}")


def main() -> None:
    paths = sorted(TEMPLATE_DIR.glob("*.yaml"))
    if not paths:
        fail("У zabbix/templates відсутні YAML-шаблони")
    for path in paths:
        validate_template(path)


if __name__ == "__main__":
    main()
