#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import pathlib

p = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\spell_en.json")
spells = json.loads(p.read_text(encoding="utf-8"))
auth = json.loads(pathlib.Path("tools/spell_pt_authoral.json").read_text(encoding="utf-8"))

total_spells = len(spells)
spells_with_desc = sum(1 for e in spells.values() if e.get("d"))
unique_descs = len(set(e["d"] for e in spells.values() if e.get("d")))
descs_in_auth = len(auth)

# Quantas magias no SpellDescDB tem PT ativo hoje
content = pathlib.Path("Data/SpellDescDB_ptBR.lua").read_text(encoding="utf-8")
import re
spells_with_pt = len([m for m in re.findall(r'pt="([^"]*)"', content) if m.strip()])

# Categorização das descrições únicas
descs_player_class = json.loads(pathlib.Path("tools/player_class_templates.json").read_text(encoding="utf-8"))
descs_player_other = json.loads(pathlib.Path("tools/player_other_templates.json").read_text(encoding="utf-8"))

print(f"Total de magias (IDs de feitiços no client): {total_spells}")
print(f"Magias que possuem algum texto de descrição: {spells_with_desc}")
print(f"Descrições únicas no jogo (templates base): {unique_descs}")
print(f"  - Templates de Habilidades de Classe/Pet/Raciais: {len(descs_player_class)}")
print(f"  - Demais templates de jogador (profissões, itens, buffs): {len(descs_player_other)}")
print(f"  - Cauda restante (criaturas, NPCs, mecânicas internas de bosses): {unique_descs - len(descs_player_class) - len(descs_player_other)}")
print(f"Templates cadastrados atualmente em spell_pt_authoral.json: {descs_in_auth}")
print(f"Total de magias no jogo que já exibem PT no SpellDescDB: {spells_with_pt}")
