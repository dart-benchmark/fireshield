# Generates lib/data/nbc_bis_masterdata.dart from the Excel masterdata.
# Re-run this whenever "NBC_BIS Fire safety masterdata .xlsx" changes.
import json, io, os

SP = r'C:/Users/lenovo/AppData/Local/Temp/claude/C--Users-lenovo-OneDrive-Desktop/0110921e-537b-478c-b5eb-dd794069da7e/scratchpad'
OUT = r'C:/Users/lenovo/OneDrive/Desktop/fire_audit_platform/demo_app/lib/data/nbc_bis_masterdata.dart'

data = json.load(open(SP + '/nbc_bis.json', encoding='utf-8'))

# Severity mapping. Driven by category because the source sheet carries no
# severity column. Reviewed against NBC 2016 Part 4 — life-safety systems are
# critical, support systems major, documentation minor.
NBC_SEVERITY = {
    'Means of Escape': 'critical',
    'Fire Detection & Alarm': 'critical',
    'Fire Fighting Systems': 'critical',
    'Fire Pumps & Water Storage': 'critical',
    'Smoke Management': 'major',
    'Electrical & Standby Power': 'major',
    'Fire Lifts': 'major',
    'Fire Command Centre': 'major',
    'Building Construction': 'major',
    'Emergency Preparedness': 'major',
    'Building Characteristics': 'minor',
    'AC / HVAC': 'minor',
    'Additional Systems': 'minor',
}
BIS_SEVERITY = {
    'IS 2189': 'critical',      # fire detection and alarm
    'IS 15105': 'critical',     # automatic sprinklers
    'IS 3844': 'critical',      # hydrant and hose reel
    'IS 2190': 'major',         # portable extinguishers
    'IS 2309': 'major',         # lightning protection
    'IS 12458': 'major',        # smoke/heat detectors
    'IS 13039': 'major',        # external hydrant system
    'IS/ISO 7240': 'major',     # fire detection components
    'IS 884': 'minor',          # first-aid hose reel
    'IS 15301': 'minor',        # installation and maintenance
    'IS 14665 Pt.2': 'minor',   # lifts
}


def esc(s: str) -> str:
    if s is None:
        return ''
    s = str(s).replace('\\', r'\\').replace("'", r"\'").replace('$', r'\$')
    s = s.replace('\r\n', ' ').replace('\n', ' ').replace('\r', ' ')
    return ' '.join(s.split())


def emit(recs, source, sev_map, prefix):
    lines = []
    for i, r in enumerate(recs, start=1):
        sev = sev_map.get(r['cat'], 'minor')
        lines.append(
            "  Checkpoint(\n"
            f"    id: '{prefix}-{i:03d}',\n"
            f"    source: CheckpointSource.{source},\n"
            f"    category: '{esc(r['cat'])}',\n"
            f"    subCategory: '{esc(r['sub'])}',\n"
            f"    title: '{esc(r['checkpoint'])}',\n"
            f"    description: '{esc(r['desc'])}',\n"
            f"    evidence: '{esc(r['evidence'])}',\n"
            f"    severity: Severity.{sev},\n"
            "  ),"
        )
    return '\n'.join(lines)


nbc = emit(data['NBC'], 'nbc', NBC_SEVERITY, 'NBC')
bis = emit(data['BIS'], 'bis', BIS_SEVERITY, 'BIS')

header = f'''// GENERATED FILE — do not edit by hand.
//
// Source: "NBC_BIS Fire safety masterdata .xlsx" (sheets: NBC, BIS)
// Generator: tool/gen_masterdata.py
//
// {len(data['NBC'])} NBC 2016 Part 4 checkpoints across 13 categories.
// {len(data['BIS'])} BIS standard checkpoints across 11 standards.
//
// Severity is assigned by category in the generator, not by the source sheet.
// See NBC_SEVERITY / BIS_SEVERITY in the generator to change it.

import 'checkpoint_model.dart';

/// All {len(data['NBC'])} NBC 2016 Part 4 checkpoints.
const List<Checkpoint> nbcCheckpoints = [
{nbc}
];

/// All {len(data['BIS'])} BIS standard checkpoints.
const List<Checkpoint> bisCheckpoints = [
{bis}
];

/// Every checkpoint in the master, NBC followed by BIS.
List<Checkpoint> get allCheckpoints => [...nbcCheckpoints, ...bisCheckpoints];
'''

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with io.open(OUT, 'w', encoding='utf-8', newline='\n') as f:
    f.write(header)

print('WROTE', OUT)
print('NBC', len(data['NBC']), 'BIS', len(data['BIS']))
