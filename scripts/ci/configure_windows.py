#!/usr/bin/env python3
"""Idempotent patch for the generated windows/runner/Runner.rc (file properties)."""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
rc = path.read_text(encoding="utf-8", errors="ignore")

values = {
    "CompanyName": "Kazama Tech",
    "FileDescription": "Nuvio Launcher",
    "ProductName": "Nuvio Launcher",
    "LegalCopyright": "Copyright (C) 2026 Kazama Tech. All rights reserved.",
}
for key, value in values.items():
    rc = re.sub(rf'(VALUE "{key}", )"[^"]*"', rf'\1"{value}"', rc)

path.write_text(rc, encoding="utf-8")
print(f"patched {path}")
