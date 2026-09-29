#!/usr/bin/env python3
"""Verify the recorded managed scientific export and provenance metadata."""

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_RECORD = (ROOT / "OMIX_MODULE_SOURCE.md").read_text()
EXPECTED_COMMIT = "eee4433cd74d0ce9bd1daba1571ca6312cba7ea2"
EXPECTED_SHA = "75df94195458c63130edaab5a2ee0a90c88ca9aa859591c6810d3eec5948673b"

managed_files = sorted((ROOT / "code/functions").glob("**/*"))
managed_files = [path for path in managed_files if path.is_file()]
assert [path.relative_to(ROOT).as_posix() for path in managed_files] == [
    "code/functions/Volcano_Plot_Enhanced.R"
]

observed_sha = hashlib.sha256(managed_files[0].read_bytes()).hexdigest()
assert observed_sha == EXPECTED_SHA
assert EXPECTED_COMMIT in SOURCE_RECORD
assert EXPECTED_SHA in SOURCE_RECORD
assert "Pending Code Ocean validation" in SOURCE_RECORD
assert "OMIX issue #43" in SOURCE_RECORD
assert "code/adapter/workflow_input.R" in SOURCE_RECORD

print("Managed-source provenance checks passed")
