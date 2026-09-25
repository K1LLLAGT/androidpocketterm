#!/usr/bin/env python3
"""Swap the package name inside Termux bootstrap zips (same-length, byte-for-byte).
Usage: patch_bootstrap.py <dir-with-bootstrap-*.zip> <old> <new>"""
import sys, zipfile, glob, os, shutil, gzip

d, old, new = sys.argv[1], sys.argv[2].encode(), sys.argv[3].encode()
if len(old) != len(new):
    sys.exit(f"'{new.decode()}' is {len(new)} chars; it must be exactly {len(old)} like '{old.decode()}'")

zips = sorted(glob.glob(os.path.join(d, "bootstrap-*.zip")))
if not zips:
    sys.exit(f"No bootstrap-*.zip in {d}")

for path in zips:
    tmp = path + ".tmp"
    files = hits = 0
    with zipfile.ZipFile(path) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for info in zin.infolist():
            data = zin.read(info)
            if info.filename.endswith(".gz"):  # man pages: patch inside the compression too
                raw = gzip.decompress(data)
                if old in raw:
                    data = gzip.compress(raw.replace(old, new), mtime=0)
                    files += 1
                    hits += raw.count(old)
                zout.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)
                continue
            n = data.count(old)
            if n:
                data = data.replace(old, new)
                files += 1
                hits += n
            zout.writestr(info, data, compress_type=zipfile.ZIP_STORED if info.is_dir() else zipfile.ZIP_DEFLATED)
    with zipfile.ZipFile(tmp) as zchk:
        left = sum((gzip.decompress(zchk.read(i)) if i.filename.endswith(".gz") else zchk.read(i)).count(old)
                   for i in zchk.infolist())
    if left:
        sys.exit(f"{path}: {left} occurrences left after patching")
    shutil.move(tmp, path)
    print(f"{os.path.basename(path)}: replaced {hits} occurrences in {files} files")
