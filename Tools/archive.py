#!/usr/bin/env python3
"""Create a source-only sharing archive; never copy build or signing artifacts."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=ROOT.parent / 'PresentInk-Mac-iPad-Xcode.zip')
args = parser.parse_args()
# Explicit source roots: work/, build/, hidden files and future local folders stay out.
roots = {'SharedUI', 'Apps', 'Packages', 'Docs', 'Tools', 'Automation', 'Design', 'PresentInk.xcodeproj'}
blocked = {'.build', '.swiftpm', 'xcuserdata', '__pycache__', 'build', 'DerivedData'}
allowed = {'.swift', '.plist', '.entitlements', '.sdef', '.json', '.png', '.icns',
           '.applescript', '.xcstrings', '.strings', '.md', '.html', '.py', '.sh', '.pbxproj', '.xcworkspacedata', '.xcscheme'}
root_files = {'README.md', 'BUILD-STATUS.md', 'LICENSE', 'NOTICE', '.gitignore'}
files = []
candidates = []
# Prune ignored directories before descending into them, including large build trees.
for directory, dirs, names in os.walk(ROOT, followlinks=False):
    base = Path(directory)
    dirs[:] = sorted(name for name in dirs
                     if not name.startswith('.') and name not in blocked
                     and not (base / name).is_symlink()
                     and (base != ROOT or name in roots))
    for name in sorted(names):
        p = base / name
        rel = p.relative_to(ROOT)
        if p.is_symlink() or not p.is_file():
            continue
        if base == ROOT:
            if name not in root_files:
                continue
        elif name.startswith('.'):
            continue
        if p.suffix not in allowed and name not in {'LICENSE', 'NOTICE', '.gitignore'}:
            continue
        candidates.append(p)
for p in sorted(candidates):
    rel = p.relative_to(ROOT)
    data = p.read_bytes()
    if p.suffix == '.pbxproj':
        text = data.decode('utf-8')
        text = re.sub(r'DEVELOPMENT_TEAM\s*=\s*[^;]*;', 'DEVELOPMENT_TEAM = "";', text)
        text = re.sub(r'"?DevelopmentTeam"?\s*=\s*[^;]*;', 'DevelopmentTeam = "";', text)
        data = text.encode('utf-8')
    if re.search(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', data):
        raise SystemExit(f'Abbruch: privater Schlüssel in {rel}')
    files.append((p, rel, data))
# Reject incomplete source archives before replacing a previously valid ZIP.
for example in (ROOT / "Automation/Examples").glob("*.applescript"):
    if str(example.relative_to(ROOT)) not in {str(rel) for _, rel, _ in files}:
        raise SystemExit(f"Abbruch: Automation-Beispiel fehlt: {example.name}")
packed = {str(rel) for _, rel, _ in files}
# Resolve navigator groups instead of treating each child path as project-relative.
# Localized variants use de.lproj/en.lproj paths beneath their parent group.
project_file = ROOT / 'PresentInk.xcodeproj/project.pbxproj'
objects = json.loads(subprocess.check_output(
    ['plutil', '-convert', 'json', '-o', '-', str(project_file)]))['objects']
parents = {}
for identifier, item in objects.items():
    if item['isa'] in {'PBXGroup', 'PBXVariantGroup'}:
        for child in item.get('children', []):
            parents[child] = identifier

def resolve_reference(identifier):
    item = objects[identifier]
    tree = item.get('sourceTree', '<group>')
    if tree == 'SOURCE_ROOT':
        base = ROOT
    elif tree == '<group>':
        base = resolve_reference(parents[identifier]) if identifier in parents else ROOT
        if base is None:
            return None
    else:
        return None  # Products and SDK references are not source archive inputs.
    return (base / item.get('path', '')).resolve()

for identifier, item in objects.items():
    if item['isa'] != 'PBXFileReference':
        continue
    target = resolve_reference(identifier)
    if target is None:
        continue
    if not target.is_relative_to(ROOT):
        raise SystemExit(f'Abbruch: Xcode-Eingabedatei außerhalb des Projekts: {item.get("path")}')
    reference = target.relative_to(ROOT).as_posix()
    present = (any(name.startswith(reference + '/') for name in packed)
               if target.is_dir() else reference in packed)
    if not present:
        raise SystemExit(f'Abbruch: Xcode-Eingabedatei fehlt im Archiv: {reference}')
args.output = args.output.expanduser().resolve()
if args.output.is_relative_to(ROOT):
    raise SystemExit('Bitte das Archiv außerhalb des Projektordners speichern.')
args.output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for p, rel, data in files:
        info = zipfile.ZipInfo.from_file(p, arcname=str(Path('PresentInk') / rel))
        archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)
print(f'{len(files)} Quelldateien archiviert: {args.output}')
print('Team-ID im ZIP entfernt; das lokale Xcode-Projekt bleibt unverändert.')
