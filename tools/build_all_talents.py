# -*- coding: utf-8 -*-
"""
Script to build the complete Data/TalentDescriptions_ptBR.lua file
with all 460 unique talents across all 9 classes.
"""

import json
import re
import os

with open('/tmp/unique_talents.json', 'r', encoding='utf-8') as f:
    unique_talents = json.load(f)

with open('/tmp/batch1.json', 'r', encoding='utf-8') as f:
    b1 = json.load(f)

from talents_batch2 import HUNTER, ROGUE
from talents_batch3 import PRIEST, MAGE
from talents_batch4 import WARLOCK, DRUID

# Read existing file
with open('Data/TalentDescriptions_ptBR.lua', 'r', encoding='utf-8') as f:
    orig_code = f.read()

# Extract existing warrior and shaman entries
m_start = orig_code.find('CM_TalentDesc_ptBR.talents = {')
m_end = orig_code.find('CM_TalentDesc_ptBR.templates = {')
existing_block = orig_code[m_start:m_end]

# Separate classes
classes = {
    'WARRIOR': {},
    'PALADIN': {},
    'HUNTER': {},
    'ROGUE': {},
    'PRIEST': {},
    'SHAMAN': {},
    'MAGE': {},
    'WARLOCK': {},
    'DRUID': {}
}

# Parse existing entries from Lua
for match in re.finditer(r'\[\"([^\"]+)\"\]\s*=\s*(\{[^}]+\}|\"[^\"]+\")', existing_block):
    k = match.group(1).lower()
    raw_val = match.group(2)
    # determine class from unique_talents
    for uname, udata in unique_talents.items():
        if uname.lower() == k:
            cls = udata.get('class')
            if cls in classes:
                classes[cls][k] = raw_val
            break

# Merge batch1 (Warrior, Shaman, Paladin)
for k, v in b1.items():
    k_lower = k.lower()
    for uname, udata in unique_talents.items():
        if uname.lower() == k_lower:
            cls = udata.get('class')
            if cls in classes:
                classes[cls][k_lower] = f'"{v}"'
            break

# Merge batch2 (Hunter, Rogue)
for k, v in HUNTER.items():
    classes['HUNTER'][k.lower()] = f'"{v}"'
for k, v in ROGUE.items():
    classes['ROGUE'][k.lower()] = f'"{v}"'

# Merge batch3 (Priest, Mage)
for k, v in PRIEST.items():
    classes['PRIEST'][k.lower()] = f'"{v}"'
for k, v in MAGE.items():
    classes['MAGE'][k.lower()] = f'"{v}"'

# Merge batch4 (Warlock, Druid)
for k, v in WARLOCK.items():
    classes['WARLOCK'][k.lower()] = f'"{v}"'
for k, v in DRUID.items():
    classes['DRUID'][k.lower()] = f'"{v}"'

# Verify counts
total_talents = sum(len(d) for d in classes.values())
print(f'Total compiled talents: {total_talents}')
for cls, d in classes.items():
    print(f'  {cls}: {len(d)}')

# Build Lua code for talents table
lua_lines = ['CM_TalentDesc_ptBR.talents = {\n']

class_headers = [
    ('WARRIOR', 'GUERREIRO (WARRIOR)'),
    ('PALADIN', 'PALADINO (PALADIN)'),
    ('HUNTER', 'CAÇADOR (HUNTER)'),
    ('ROGUE', 'LADINO (ROGUE)'),
    ('PRIEST', 'SACERDOTE (PRIEST)'),
    ('SHAMAN', 'XAMÃ (SHAMAN)'),
    ('MAGE', 'MAGO (MAGE)'),
    ('WARLOCK', 'BRUXO (WARLOCK)'),
    ('DRUID', 'DRUIDA (DRUID)')
]

for cls_key, cls_label in class_headers:
    lua_lines.append(f'    -- ------------------------------------------------------------------------\n')
    lua_lines.append(f'    -- {cls_label}\n')
    lua_lines.append(f'    -- ------------------------------------------------------------------------\n')
    d = classes[cls_key]
    for k in sorted(d.keys()):
        val = d[k]
        if isinstance(val, str) and not (val.strip().startswith('{') and val.strip().endswith('}')):
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            val = val.replace('\r\n', '\\n').replace('\n', '\\n').replace('\r', '\\n')
            val = f'"{val}"'
        lua_lines.append(f'    ["{k}"] = {val},\n')

lua_lines.append('}\n\n')

new_talents_block = "".join(lua_lines)

# Replace in file
new_file_content = orig_code[:m_start] + new_talents_block + orig_code[m_end:]

with open('Data/TalentDescriptions_ptBR.lua', 'w', encoding='utf-8') as f:
    f.write(new_file_content)

print("Successfully written Data/TalentDescriptions_ptBR.lua")
