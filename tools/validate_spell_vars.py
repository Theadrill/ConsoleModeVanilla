#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Valida a integridade de marcadores ($s1, $d, etc.) entre EN e PT
seguindo estritamente a lógica do motor de substituição de Data/Localization.lua.
"""
import re

def clean_text(text):
    if not text:
        return ""
    # Remove macros de plural ($l...:...;) e gênero ($g...:...;) do DBC
    return re.sub(r"\$[lg][^;]*;", "", text)

def count_en_vars(en):
    t = clean_text(en)
    # Remove pontuação colada no fim (como ponto ou vírgula)
    matches = re.findall(r"\$[^\s\.,;:]+", t)
    return len(matches)

def count_pt_vars(pt):
    t = clean_text(pt)
    # No Lua: string.gsub(descDBEntry.pt, "%$[a-z]%d*", ...)
    matches = re.findall(r"\$[a-zA-Z]\d*", t)
    return len(matches)

def validate_pair(en, pt):
    en_cnt = count_en_vars(en)
    pt_cnt = count_pt_vars(pt)

    if en_cnt != pt_cnt:
        return False, f"Descompasso de marcadores $: EN={en_cnt} vs PT={pt_cnt}"
    return True, "OK"

if __name__ == "__main__":
    en1 = "Heals a friendly target for $s1."
    pt1 = "Cura um alvo aliado em $s1."
    print("Teste 1 (Healing Wave):", validate_pair(en1, pt1))

    en2 = "Summons an Earthbind Totem with $s1 health at the feet of the caster for $d that slows the movement speed of enemies within $3600a1 yards."
    pt2 = "Evoca um Totem Aprisionador da Terra com $s1 de pontos de vida aos pés do lançador por $d s que reduz a velocidade de movimento de inimigos a até $a1 metros."
    print("Teste 2 (Earthbind Totem):", validate_pair(en2, pt2))

    en3 = "Imbue the Shaman's weapon with fire. Each hit causes $/77;8026m1 to $/25;8026M1 additional Fire damage, based on the speed of the weapon. Slower weapons cause more fire damage per swing. Lasts for 1 hour."
    pt3 = "Encanta a arma do Xamã com fogo. Cada golpe causa de $s1 a $s2 de dano de Fogo adicional, com base na velocidade da arma. Armas mais lentas causam mais dano de fogo por golpe. Dura 1 hora."
    print("Teste 3 (Flametongue Weapon):", validate_pair(en3, pt3))

    en4 = "Imbue the Shaman's weapon, increasing melee attack power by $10400s1 and all threat caused by $10400s2% when using that weapon. Lasts for 1 hour."
    pt4 = "Encanta a arma do Xamã, aumentando o poder de ataque corpo a corpo em $s1 e toda a ameaça gerada em $s2% ao usar esta arma. Dura 1 hora."
    print("Teste 4 (Rockbiter Weapon):", validate_pair(en4, pt4))
