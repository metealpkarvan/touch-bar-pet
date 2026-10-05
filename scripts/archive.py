#!/usr/bin/env python3
"""Create portable ZIPs with UTF-8 filenames and Unix executable permissions."""
import stat
import sys
import zipfile
from pathlib import Path
source, destination = map(Path, sys.argv[1:])
with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for path in sorted(source.rglob("*")):
        if path.is_symlink():
            raise ValueError("Unexpected symlink in release")
        if path.is_file():
            info = zipfile.ZipInfo(path.relative_to(source).as_posix())
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | stat.S_IMODE(path.stat().st_mode)) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes())
