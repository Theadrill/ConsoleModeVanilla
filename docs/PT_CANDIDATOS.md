# Candidatos PT-BR no codigo (gerado por tools/extract_pt_candidates.py)

Objetivo: zero itens DISPLAY/TABLE/OTHER. PARSER = nao tocar.

Resumo: DISPLAY=31, TABLE=241, OTHER=127, PARSER=134

| arquivo:linha | funcao | hint | literal | codigo |
|---|---|---|---|---|
| Core.lua:292 | CM:ToggleRightActionBars | OTHER | idioma | if cmd == "lang" or cmd == "idioma" or cmd == "language" then |
| Core.lua:403 | CM:ToggleRightActionBars | OTHER | mouse | elseif cmd == "mouse" then |
| Keybindings.lua:42 | - | TABLE | ConsoleMode - Botões Fixos | ["BINDING_HEADER_CONSOLEMODEFIXED"]  = { key = "BIND_HEAD_FIXED",    pt = "ConsoleMode - Botões Fixos" }, |
| Keybindings.lua:43 | - | TABLE | ConsoleMode - Navegação de Cursor | ["BINDING_HEADER_CONSOLEMODECURSOR"] = { key = "BIND_HEAD_CURSOR",   pt = "ConsoleMode - Navegação de Cursor" }, |
| Keybindings.lua:45 | - | TABLE | L2+R2+D-Pad Cima (Selecionar Amigo) | ["BINDING_NAME_CM_TARGET_FRIENDLY"]  = { key = "BIND_TARGET_FRIENDLY", pt = "L2+R2+D-Pad Cima (Selecionar Amigo)" }, |
| Keybindings.lua:47 | - | TABLE | Select (Mapa) | ["BINDING_NAME_CM_FIXED_SELECT"]     = { key = "BIND_FIXED_SELECT",  pt = "Select (Mapa)" }, |
| Keybindings.lua:49 | - | TABLE | R3 (Clique Direito) | ["BINDING_NAME_CM_MOUSERIGHT"]       = { key = "BIND_MOUSERIGHT",    pt = "R3 (Clique Direito)" }, |
| Keybindings.lua:50 | - | TABLE | L3 (Toggle Mouse Mode) | ["BINDING_NAME_CM_TOGGLE_MOUSEMODE"] = { key = "BIND_TOGGLE_MOUSEMODE", pt = "L3 (Toggle Mouse Mode)" }, |
| Keybindings.lua:52 | - | TABLE | ConsoleMode - Atalhos de Interface | ["BINDING_HEADER_CONSOLEMODEUI"]     = { key = "BIND_HEAD_UI",       pt = "ConsoleMode - Atalhos de Interface" }, |
| Keybindings.lua:53 | - | TABLE | L2 + Select (Personagem - C) | ["BINDING_NAME_CM_UI_CHARACTER"]     = { key = "BIND_UI_CHARACTER",  pt = "L2 + Select (Personagem - C)" }, |
| Keybindings.lua:54 | - | TABLE | L2 + Start (Bolsas - B) | ["BINDING_NAME_CM_UI_BAGS"]          = { key = "BIND_UI_BAGS",       pt = "L2 + Start (Bolsas - B)" }, |
| Keybindings.lua:55 | - | TABLE | R2 + Select (Talentos - N) | ["BINDING_NAME_CM_UI_TALENTS"]       = { key = "BIND_UI_TALENTS",    pt = "R2 + Select (Talentos - N)" }, |
| Keybindings.lua:56 | - | TABLE | R2 + Start (Livro de Magias - P) | ["BINDING_NAME_CM_UI_SPELLBOOK"]     = { key = "BIND_UI_SPELLBOOK",  pt = "R2 + Start (Livro de Magias - P)" }, |
| Keybindings.lua:61 | - | TABLE | Cursor: Confirmar (A) | ["BINDING_NAME_CM_CURSOR_CONFIRM"]   = { key = "BIND_CURSOR_CONFIRM", pt = "Cursor: Confirmar (A)" }, |
| Keybindings.lua:62 | - | TABLE | Cursor: Cancelar (B) | ["BINDING_NAME_CM_CURSOR_CANCEL"]    = { key = "BIND_CURSOR_CANCEL", pt = "Cursor: Cancelar (B)" }, |
| Logger.lua:121 | Logger:PrintStatus | OTHER | \|cff88ff88Mouse\|r | elseif KB.mouseModeActive then modeStr = "\|cff88ff88Mouse\|r" |
| Data\Localization.lua:541 | CM:HandleLangCommand | OTHER | Português (Brasil) | CM_RegisterLang("ptBR", "Português (Brasil)", "Data\\Locales\\ptBR\\UI.lua", "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Locales\\ptBR\\flag_ptBR.tga") |
| Data\Locales\enUS\UI.lua:39 | - | TABLE | Language / Idioma | LANG_TITLE = "Language / Idioma", |
| Data\Locales\enUS\UI.lua:78 | - | TABLE | Current Health/Mana/Rage/Energy.nMana Regen = base(Spi) + MP5x0.4; in combat only % casting. | CHAR_DETAIL_RES_BODY = "Current Health/Mana/Rage/Energy.\nMana Regen = base(Spi) + MP5x0.4; in combat only % casting.", |
| Data\Locales\enUS\UI.lua:120 | - | TABLE | Mana | CHAR_POWER_MANA = "Mana", |
| Data\Locales\enUS\UI.lua:144 | - | TABLE | Health Regen: — (no formula in 1.12) | CHAR_RES_HP_REGEN_NONE = "Health Regen: — (no formula in 1.12)", |
| Data\Locales\enUS\UI.lua:145 | - | TABLE | Mana Regen: %d (%d MP2 in combat) | CHAR_RES_MANA_FMT = "Mana Regen: %d (%d MP2 in combat)", |
| Data\Locales\enUS\UI.lua:146 | - | TABLE | Mana Regen: %d MP2 | CHAR_RES_MANA_SIMPLE_FMT = "Mana Regen: %d MP2", |
| Data\Locales\enUS\UI.lua:147 | - | TABLE | %s Regen: — (no formula in 1.12) | CHAR_RES_NONMANA_FMT = "%s Regen: — (no formula in 1.12)", |
| Data\Locales\enUS\UI.lua:156 | - | TABLE | Crit: — | CHAR_MELEE_CRIT_NONE = "Crit: —", |
| Data\Locales\enUS\UI.lua:168 | - | TABLE | Effective Crit: — | CHAR_BOSS_EFF_NONE = "Effective Crit: —", |
| Data\Locales\enUS\UI.lua:171 | - | TABLE | Damage: — (no ranged weapon) | CHAR_RANGED_NO_WEAPON = "Damage: — (no ranged weapon)", |
| Data\Locales\enUS\UI.lua:172 | - | TABLE | Speed: — | CHAR_RANGED_NO_SPEED = "Speed: —", |
| Data\Locales\enUS\UI.lua:173 | - | TABLE | Ranged Attack Power: — | CHAR_RANGED_NO_RAP = "Ranged Attack Power: —", |
| Data\Locales\enUS\UI.lua:182 | - | TABLE | Mana Regen: %d (%d in combat) | CHAR_SPELL_REGEN_FMT = "Mana Regen: %d (%d in combat)", |
| Data\Locales\enUS\UI.lua:183 | - | TABLE | Mana Regen: — (no mana) | CHAR_SPELL_NO_MANA = "Mana Regen: — (no mana)", |
| Data\Locales\enUS\UI.lua:191 | - | TABLE | Defense: — | CHAR_DEF_NO_DEFENSE = "Defense: —", |
| Data\Locales\enUS\UI.lua:193 | - | TABLE | Dodge: — | CHAR_DEF_NO_DODGE = "Dodge: —", |
| Data\Locales\enUS\UI.lua:195 | - | TABLE | Parry: — | CHAR_DEF_NO_PARRY = "Parry: —", |
| Data\Locales\enUS\UI.lua:197 | - | TABLE | Block: — | CHAR_DEF_NO_BLOCK = "Block: —", |
| Data\Locales\enUS\UI.lua:199 | - | TABLE | Total Avoidance: — | CHAR_DEF_NO_TOTAL = "Total Avoidance: —", |
| Data\Locales\enUS\UI.lua:206 | - | TABLE | Skills: — (header not found) | CHAR_WEAPON_NO_HEADER = "Skills: — (header not found)", |
| Data\Locales\enUS\UI.lua:230 | - | TABLE | Weekly progress: — | CHAR_HONOR_NO_PROGRESS = "Weekly progress: —", |
| Data\Locales\enUS\UI.lua:233 | - | TABLE | Kills today: — | CHAR_HONOR_TODAY_NONE = "Kills today: —", |
| Data\Locales\enUS\UI.lua:236 | - | TABLE | Kills yesterday: — | CHAR_HONOR_YEST_NONE = "Kills yesterday: —", |
| Data\Locales\enUS\UI.lua:238 | - | TABLE | Lifetime: — | CHAR_HONOR_LIFE_NONE = "Lifetime: —", |
| Data\Locales\enUS\UI.lua:240 | - | TABLE | Languages: — (see SkillFrame K) | CHAR_LANG_NONE = "Languages: — (see SkillFrame K)", |
| Data\Locales\enUS\UI.lua:245 | - | TABLE | Racials: — | CHAR_LANG_NO_RACIAL = "Racials: —", |
| Data\Locales\enUS\UI.lua:391 | - | TABLE | OctoWoW realm detected (%s): compatibility layer auto-enabled. Adjust in Settings → Addon Settings. | OCTO_AUTO_MSG = "OctoWoW realm detected (%s): compatibility layer auto-enabled. Adjust in Settings → Addon Settings.", |
| Data\Locales\enUS\UI.lua:402 | - | TABLE | \|cffffcc00⚔️ COMPARISON\|r | DETAIL_COMPARE_HEADER = "\|cffffcc00⚔️ COMPARISON\|r", |
| Data\Locales\enUS\UI.lua:428 | - | TABLE | \|cffaaaaaaWEAPON ENCHANT  •  Temporary\|r | DETAIL_ENCHANT_TYPE = "\|cffaaaaaaWEAPON ENCHANT  •  Temporary\|r", |
| Data\Locales\enUS\UI.lua:430 | - | TABLE | \|cffaaaaaa%s  •  Beneficial Effect\|r | DETAIL_BUFF_TYPE_FMT = "\|cffaaaaaa%s  •  Beneficial Effect\|r", |
| Data\Locales\enUS\UI.lua:541 | - | TABLE | \|cffffffff• %s\|r \|cffaaaaaax%s\|r | MAIL_COMPOSE_ITEM_FMT = "\|cffffffff• %s\|r \|cffaaaaaax%s\|r", |
| Data\Locales\enUS\UI.lua:542 | - | TABLE | \|cffffffff• %s\|r \|cffaaaaaax%s\|r  \|cff888888(+%s)\|r | MAIL_COMPOSE_ITEM_MORE_FMT = "\|cffffffff• %s\|r \|cffaaaaaax%s\|r  \|cff888888(+%s)\|r", |
| Data\Locales\enUS\UI.lua:783 | - | TABLE | \|cffff4444[CM Core]\|r ❌ ERROR: Cursor module did not load! Aborting init. | MSG_ERR_CURSOR = "\|cffff4444[CM Core]\|r ❌ ERROR: Cursor module did not load! Aborting init.", |
| Data\Locales\enUS\UI.lua:784 | - | TABLE | \|cffff4444[CM Core]\|r ❌ ERROR: Hooks module did not load! Aborting init. | MSG_ERR_HOOKS = "\|cffff4444[CM Core]\|r ❌ ERROR: Hooks module did not load! Aborting init.", |
| Data\Locales\enUS\UI.lua:820 | - | TABLE | \|cffff4444[CM]\|r No frame under the mouse | MSG_FRAME_NONE = "\|cffff4444[CM]\|r No frame under the mouse", |
| Data\Locales\enUS\UI.lua:826 | - | TABLE |   \|cffffcc00/cm keyboard\|r   - Restore the keyboard/mouse profile | MSG_HELP_KEYBOARD = "  \|cffffcc00/cm keyboard\|r   - Restore the keyboard/mouse profile", |
| Data\Locales\enUS\UI.lua:827 | - | TABLE |   \|cffffcc00/cm mouse\|r      - Toggle Mouse Mode (Free Cursor) | MSG_HELP_MOUSE = "  \|cffffcc00/cm mouse\|r      - Toggle Mouse Mode (Free Cursor)", |
| Data\Locales\enUS\UI.lua:831 | - | TABLE |   \|cffffcc00/cm frame\|r      - Identify the frame under the mouse | MSG_HELP_FRAME = "  \|cffffcc00/cm frame\|r      - Identify the frame under the mouse", |
| Data\Locales\enUS\UI.lua:844 | - | TABLE | \|cff00ccff[ConsoleMode]\|r Mouse Mode \|cff00ff00ENABLED\|r | MSG_MOUSE_ON = "\|cff00ccff[ConsoleMode]\|r Mouse Mode \|cff00ff00ENABLED\|r", |
| Data\Locales\enUS\UI.lua:845 | - | TABLE | \|cff00ccff[ConsoleMode]\|r Mouse Mode \|cffff4444DISABLED\|r | MSG_MOUSE_OFF = "\|cff00ccff[ConsoleMode]\|r Mouse Mode \|cffff4444DISABLED\|r", |
| Data\Locales\enUS\UI.lua:848 | - | TABLE | \|cff00ccff[ConsoleMode]\|r Mouse Mode: \|cff00ff00ENABLED\|r (Free Cursor) | MSG_MOUSE_FREE_ON = "\|cff00ccff[ConsoleMode]\|r Mouse Mode: \|cff00ff00ENABLED\|r (Free Cursor)", |
| Data\Locales\enUS\UI.lua:849 | - | TABLE | \|cff00ccff[ConsoleMode]\|r Mouse Mode: \|cffff4444DISABLED\|r (Camera on Stick) | MSG_MOUSE_FREE_OFF = "\|cff00ccff[ConsoleMode]\|r Mouse Mode: \|cffff4444DISABLED\|r (Camera on Stick)", |
| Data\Locales\enUS\UI.lua:858 | - | TABLE | Mana | POWER_MANA = "Mana", |
| Data\Locales\enUS\UI.lua:865 | - | TABLE | \|cffaaaaaaTree %d of 3 — ConsoleMode Vanilla\|r | TALENT_TREE_COUNT_FMT = "\|cffaaaaaaTree %d of 3 — ConsoleMode Vanilla\|r", |
| Data\Locales\enUS\UI.lua:868 | - | TABLE | \|cffaaaaaaConsole Mode — Talents 1.12\|r | TALENT_MODE_LABEL = "\|cffaaaaaaConsole Mode — Talents 1.12\|r", |
| Data\Locales\enUS\UI.lua:878 | - | TABLE | \|cff888888[D-Pad] Navigate  •  [A] Learn Talent  •  [B] Back\|r | TALENT_TREE_FOOTER_HINT = "\|cff888888[D-Pad] Navigate  •  [A] Learn Talent  •  [B] Back\|r", |
| Data\Locales\enUS\UI.lua:882 | - | TABLE | \|cffe09a15[ConsoleMode]\|r SortBag addon not found — ORGANIZE unavailable. | BAGS_SORT_MISSING_MSG = "\|cffe09a15[ConsoleMode]\|r SortBag addon not found — ORGANIZE unavailable.", |
| Data\Locales\enUS\UI.lua:883 | - | TABLE | \|cffaaaaaaConsole Mode — Spellbook 1.12\|r | SPELLS_MODE_LABEL = "\|cffaaaaaaConsole Mode — Spellbook 1.12\|r", |
| Data\Locales\enUS\UI.lua:888 | - | TABLE | \|cff888888[D-Pad] Navigate  •  [A] Cast Spell  •  [B] Back\|r | SPELLS_FOOTER_HINT = "\|cff888888[D-Pad] Navigate  •  [A] Cast Spell  •  [B] Back\|r", |
| Data\Locales\enUS\UI.lua:904 | - | TABLE | \|cffaaaaaaCompanion / Pet — ConsoleMode Vanilla\|r | SPELL_TYPE_PET = "\|cffaaaaaaCompanion / Pet — ConsoleMode Vanilla\|r", |
| Data\Locales\enUS\UI.lua:905 | - | TABLE | \|cffaaaaaaGeneral Skills — ConsoleMode Vanilla\|r | SPELL_TYPE_GENERAL = "\|cffaaaaaaGeneral Skills — ConsoleMode Vanilla\|r", |
| Data\Locales\enUS\UI.lua:906 | - | TABLE | \|cffaaaaaaSpecialization %d of 3 — ConsoleMode Vanilla\|r | SPELL_TYPE_SPEC_FMT = "\|cffaaaaaaSpecialization %d of 3 — ConsoleMode Vanilla\|r", |
| Data\Locales\enUS\UI.lua:907 | - | TABLE | \|cffaaaaaaCategory %d of %d — ConsoleMode Vanilla\|r | SPELL_TYPE_CATEGORY_COUNT_FMT = "\|cffaaaaaaCategory %d of %d — ConsoleMode Vanilla\|r", |
| Data\Locales\enUS\UI.lua:933 | - | TABLE | \|cff888888[LT] Zoom Out  •  [RT] Zoom In  •  [L-Stick / Drag] Move Free Map\|r | MAP_FOOTER_HINT = "\|cff888888[LT] Zoom Out  •  [RT] Zoom In  •  [L-Stick / Drag] Move Free Map\|r", |
| Data\Locales\enUS\UI.lua:947 | - | TABLE | \|cff888888(A) Read Mission  •  (X) Track  •  (Y) Abandon\|r | QUEST_DETAIL_FOOTER_HINTS = "\|cff888888(A) Read Mission  •  (X) Track  •  (Y) Abandon\|r", |
| Data\Locales\enUS\UI.lua:951 | - | TABLE | \|cffe09a15[D-Pad] Navigate  •  [A] Enter  •  [B] Back\|r | MAP_HINT_NAVIGATE_ENTER_BACK = "\|cffe09a15[D-Pad] Navigate  •  [A] Enter  •  [B] Back\|r", |
| Data\Locales\enUS\UI.lua:952 | - | TABLE | \|cffe09a15[D-Pad] Select  •  [A] Open  •  [B] Back\|r | MAP_HINT_SELECT_OPEN_BACK = "\|cffe09a15[D-Pad] Select  •  [A] Open  •  [B] Back\|r", |
| Data\Locales\enUS\UI.lua:973 | - | TABLE | Interior map only inside the instance — shows entrance zone | MAP_INSTANCE_TOOLTIP_INTERIOR_ONLY = "Interior map only inside the instance — shows entrance zone", |
| Data\Locales\enUS\UI.lua:976 | - | TABLE | \|cff888888— interior only inside the instance\|r | MAP_DUNGEON_INTERIOR_ONLY = "\|cff888888— interior only inside the instance\|r", |
| Data\Locales\enUS\UI.lua:989 | - | TABLE |  Mana | COMPARE_MANA_LABEL = " Mana", |
| Data\Locales\enUS\UI.lua:998 | - | TABLE | Mana | COMPARE_ABBR_MANA = "Mana", |
| Data\Locales\enUS\UI.lua:1011 | - | TABLE | \|cffffffff↳ Slot %d:\|r | COMPARE_SLOT_FMT = "\|cffffffff↳ Slot %d:\|r", |
| Data\Locales\enUS\UI.lua:1024 | - | TABLE | \|cffaaaaaaConsole Mode — Spells, Bags, Macros and Bars\|r | PICKER_TYPE = "\|cffaaaaaaConsole Mode — Spells, Bags, Macros and Bars\|r", |
| Data\Locales\enUS\UI.lua:1034 | - | TABLE | \|cffaaaaaaPhysical Key: \|cffffffff%s\|r  •  \|cffaaaaaaAction Bar: \|cffffffffSlot %d\|r | BINDS_DETAIL_KEY_BAR_SLOT_FMT = "\|cffaaaaaaPhysical Key: \|cffffffff%s\|r  •  \|cffaaaaaaAction Bar: \|cffffffffSlot %d\|r", |
| Data\Locales\enUS\UI.lua:1040 | - | TABLE | \|cff888888Empty Slot — No action assigned (Key: %s)\|r | BINDS_DETAIL_EMPTY_SLOT_FMT = "\|cff888888Empty Slot — No action assigned (Key: %s)\|r", |
| Data\Locales\enUS\UI.lua:1046 | - | TABLE | \|cffaaaaaaConsole Mode — Controller Shortcuts (Pages 1 to 4)\|r | BINDS_MAPPER_SUBTITLE = "\|cffaaaaaaConsole Mode — Controller Shortcuts (Pages 1 to 4)\|r", |
| Data\Locales\enUS\UI.lua:1073 | - | TABLE | \|cffaaaaaaSpellbook  •  \|cffffffff%s\|r | PICKER_DETAIL_SPELLBOOK_FMT = "\|cffaaaaaaSpellbook  •  \|cffffffff%s\|r", |
| Data\Locales\enUS\UI.lua:1076 | - | TABLE |   •  Quantity: x | PICKER_DETAIL_QTY = "  •  Quantity: x", |
| Data\Locales\enUS\UI.lua:1082 | - | TABLE | \|cffaaaaaa%s  •  Slot %d (Real Slot: %d)\|r | PICKER_DETAIL_BAR_SLOT_FMT = "\|cffaaaaaa%s  •  Slot %d (Real Slot: %d)\|r", |
| Data\Locales\enUS\UI.lua:1086 | - | TABLE | Master of tactical melee combat — heavy two-handed weapons, bleed control and overwhelming strikes. | SPEC_WARRIOR_1_DESC = "Master of tactical melee combat — heavy two-handed weapons, bleed control and overwhelming strikes.", |
| Data\Locales\enUS\UI.lua:1088 | - | TABLE | Wild berserker warrior — devastating damage, continuous strike haste and uncontrollable fury. | SPEC_WARRIOR_2_DESC = "Wild berserker warrior — devastating damage, continuous strike haste and uncontrollable fury.", |
| Data\Locales\enUS\UI.lua:1090 | - | TABLE | Unshakable bastion with shield and heavy armor — supreme damage mitigation and absolute threat control. | SPEC_WARRIOR_3_DESC = "Unshakable bastion with shield and heavy armor — supreme damage mitigation and absolute threat control.", |
| Data\Locales\enUS\UI.lua:1092 | - | TABLE | Invoker of Divine Light — purifying heals, protective blessings and unshakable vital support to allies. | SPEC_PALADIN_1_DESC = "Invoker of Divine Light — purifying heals, protective blessings and unshakable vital support to allies.", |
| Data\Locales\enUS\UI.lua:1094 | - | TABLE | Sacred guardian of faith — resistance auras, efficient blocks and unshakable shield defense. | SPEC_PALADIN_2_DESC = "Sacred guardian of faith — resistance auras, efficient blocks and unshakable shield defense.", |
| Data\Locales\enUS\UI.lua:1096 | - | TABLE | Zealous crusader of justice — divine punishment with two-handed weapons, righteous seals and holy strikes. | SPEC_PALADIN_3_DESC = "Zealous crusader of justice — divine punishment with two-handed weapons, righteous seals and holy strikes.", |
| Data\Locales\enUS\UI.lua:1098 | - | TABLE | Master of wildlife — primal bond with tamed beasts, amplifying your pet's power. | SPEC_HUNTER_1_DESC = "Master of wildlife — primal bond with tamed beasts, amplifying your pet's power.", |
| Data\Locales\enUS\UI.lua:1100 | - | TABLE | Lethal elite sharpshooter — surgical long-range shots with bows, crossbows and firearms. | SPEC_HUNTER_2_DESC = "Lethal elite sharpshooter — surgical long-range shots with bows, crossbows and firearms.", |
| Data\Locales\enUS\UI.lua:1102 | - | TABLE | Wilderness survival expert — treacherous traps, tactical mobility and deadly poisons. | SPEC_HUNTER_3_DESC = "Wilderness survival expert — treacherous traps, tactical mobility and deadly poisons.", |
| Data\Locales\enUS\UI.lua:1104 | - | TABLE | Master of lethal poisons and surgical strikes — concentrated stealth attacks that quickly drain the victim. | SPEC_ROGUE_1_DESC = "Master of lethal poisons and surgical strikes — concentrated stealth attacks that quickly drain the victim.", |
| Data\Locales\enUS\UI.lua:1106 | - | TABLE | Fearless agile fencer — direct combat with swords, maces and daggers with great energy regeneration. | SPEC_ROGUE_2_DESC = "Fearless agile fencer — direct combat with swords, maces and daggers with great energy regeneration.", |
| Data\Locales\enUS\UI.lua:1108 | - | TABLE | Master of shadows and deception — ghostly mobility, surprise attacks and stealthy repositioning. | SPEC_ROGUE_3_DESC = "Master of shadows and deception — ghostly mobility, surprise attacks and stealthy repositioning.", |
| Data\Locales\enUS\UI.lua:1110 | - | TABLE | Mental fortress and spiritual discipline — absorption shields, preventive protection and inner fortitude. | SPEC_PRIEST_1_DESC = "Mental fortress and spiritual discipline — absorption shields, preventive protection and inner fortitude.", |
| Data\Locales\enUS\UI.lua:1112 | - | TABLE | Pure channeler of Divine Light — deep heals, vital renews and miracles that save the group from death. | SPEC_PRIEST_2_DESC = "Pure channeler of Divine Light — deep heals, vital renews and miracles that save the group from death.", |
| Data\Locales\enUS\UI.lua:1114 | - | TABLE | Manipulator of Void and madness — continuous mind damage spells, soul corruption and psychological terror. | SPEC_PRIEST_3_DESC = "Manipulator of Void and madness — continuous mind damage spells, soul corruption and psychological terror.", |
| Data\Locales\enUS\UI.lua:1116 | - | TABLE | Invoker of nature's fury — devastating lightning, earth and fire spells with high ranged impact damage. | SPEC_SHAMAN_1_DESC = "Invoker of nature's fury — devastating lightning, earth and fire spells with high ranged impact damage.", |
| Data\Locales\enUS\UI.lua:1118 | - | TABLE | Totemic melee fighter — weapons imbued by the spirits of the elements with furious strikes. | SPEC_SHAMAN_2_DESC = "Totemic melee fighter — weapons imbued by the spirits of the elements with furious strikes.", |
| Data\Locales\enUS\UI.lua:1120 | - | TABLE | Healer of sacred and ancestral waters — deep chain healing, purification and group sustain. | SPEC_SHAMAN_3_DESC = "Healer of sacred and ancestral waters — deep chain healing, purification and group sustain.", |
| Data\Locales\enUS\UI.lua:1122 | - | TABLE | Master of the pure energies of the Cosmos — mana flow manipulation, temporal acceleration and raw arcane damage. | SPEC_MAGE_1_DESC = "Master of the pure energies of the Cosmos — mana flow manipulation, temporal acceleration and raw arcane damage.", |
| Data\Locales\enUS\UI.lua:1124 | - | TABLE | Devastating incendiary mage — continuous burns, incandescent explosions and high critical peaks. | SPEC_MAGE_2_DESC = "Devastating incendiary mage — continuous burns, incandescent explosions and high critical peaks.", |
| Data\Locales\enUS\UI.lua:1126 | - | TABLE | Commander of eternal ice — freezing barriers, field slows and absolute survival. | SPEC_MAGE_3_DESC = "Commander of eternal ice — freezing barriers, field slows and absolute survival.", |
| Data\Locales\enUS\UI.lua:1128 | - | TABLE | Master of curses and slow agony — corrosive damage-over-time spells that drain the target's vitality. | SPEC_WARLOCK_1_DESC = "Master of curses and slow agony — corrosive damage-over-time spells that drain the target's vitality.", |
| Data\Locales\enUS\UI.lua:1130 | - | TABLE | Commander of the Legion — summoning and empowering demonic servants to crush your opponents. | SPEC_WARLOCK_2_DESC = "Commander of the Legion — summoning and empowering demonic servants to crush your opponents.", |
| Data\Locales\enUS\UI.lua:1132 | - | TABLE | Conjurer of chaotic fel fire — explosive immediate-impact spells and incandescent annihilation. | SPEC_WARLOCK_3_DESC = "Conjurer of chaotic fel fire — explosive immediate-impact spells and incandescent annihilation.", |
| Data\Locales\enUS\UI.lua:1134 | - | TABLE | Channeler of astral forces and nature — solar and lunar spells with the ancestral Moonkin Form. | SPEC_DRUID_1_DESC = "Channeler of astral forces and nature — solar and lunar spells with the ancestral Moonkin Form.", |
| Data\Locales\enUS\UI.lua:1136 | - | TABLE | Shapeshifting predator — ferocious combat as Bear for tenacious defense or Cat for stealthy attacks. | SPEC_DRUID_2_DESC = "Shapeshifting predator — ferocious combat as Bear for tenacious defense or Cat for stealthy attacks.", |
| Data\Locales\enUS\UI.lua:1138 | - | TABLE | Guardian of healing and life — continuous health regeneration through over-time spells and Dream blessings. | SPEC_DRUID_3_DESC = "Guardian of healing and life — continuous health regeneration through over-time spells and Dream blessings.", |
| Data\Locales\enUS\UI.lua:1215 | - | TABLE | L3 (Toggle Mouse Mode) | BIND_TOGGLE_MOUSEMODE = "L3 (Toggle Mouse Mode)", |
| Data\Locales\enUS\UI.lua:1236 | - | TABLE |   Mouse Mode:  %s | LOG_MOUSE_MODE_FMT = "  Mouse Mode:  %s", |
| Data\NPCs\NPC_Data_CustomTurtle.lua:478 | - | TABLE | Mana Remnant | [11483] = { "Mana Remnant", "", 0.0, 0.0 }, |
| Data\NPCs\NPC_Data_CustomTurtle.lua:560 | - | TABLE | Corrupted Bronze Whelp | [14025] = { "Corrupted Bronze Whelp", "", 0.0, 0.0 }, |
| Data\NPCs\NPC_Data_CustomTurtle.lua:620 | - | TABLE | Bronze Riding Crab | [33006] = { "Bronze Riding Crab", "", 58.75, 41.04 }, |
| Data\NPCs\NPC_Data_CustomTurtle.lua:895 | - | TABLE | Emerald Mana Wyrm | [61775] = { "Emerald Mana Wyrm", "", 50.56, 15.7 }, |
| Data\NPCs\NPC_Data_CustomTurtle.lua:896 | - | TABLE | Lavender Mana Wyrm | [61776] = { "Lavender Mana Wyrm", "", 51.24, 16.68 }, |
| Data\NPCs\NPC_Data_EasternKingdoms.lua:2163 | - | TABLE | Mouse | [6271] = { "Mouse", "", 32.53, 71.74 }, |
| Data\NPCs\NPC_Data_EasternKingdoms.lua:3832 | - | TABLE | Brilliant Mana Wyrm | [61774] = { "Brilliant Mana Wyrm", "", 2.908, 6.392 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:1155 | - | TABLE | Mana Eater | [4678] = { "Mana Eater", "", 52.92, 68.12 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:1723 | - | TABLE | Bronze Whelpling | [7546] = { "Bronze Whelpling", "", 57.39, 56.39 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:2334 | - | TABLE | Lui'Mala | [12032] = { "Lui'Mala", "Fisherman", 22.72, 72.42 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:2831 | - | TABLE | Bronze Drake | [50113] = { "Bronze Drake", "", 64.95, 50.65 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:3211 | - | TABLE | Mana Stalker | [61354] = { "Mana Stalker", "", 27.79, 85.63 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:3518 | - | TABLE | Baxdi’zha | [63116] = { "Baxdi’zha", "", 80.6, 17.18 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:3527 | - | TABLE | Lord Ta’jax | [63149] = { "Lord Ta’jax", "", 90.79, 20.14 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:3538 | - | TABLE | Keeper N’las | [63183] = { "Keeper N’las", "", 93.08, 36.43 }, |
| Data\NPCs\NPC_Data_Kalimdor.lua:3561 | - | TABLE | Bronze Drake | [80156] = { "Bronze Drake", "", 63.58, 57.74 }, |
| UI\BagPicker.lua:30 | - | TABLE | consumÃ­vel | ["consumÃ­vel"]      = true, |
| UI\BagPicker.lua:31 | - | TABLE | consumÃ­veis | ["consumÃ­veis"]     = true, |
| UI\BagPicker.lua:33 | - | TABLE | missÃ£o | ["missÃ£o"]          = true, |
| UI\BagPicker.lua:46 | - | TABLE | poÃ§Ã£o | ["poÃ§Ã£o"]             = true, |
| UI\BagPicker.lua:48 | - | TABLE | poÃ§Ãµes | ["poÃ§Ãµes"]            = true, |
| UI\BagPicker.lua:60 | - | TABLE | veneno | ["veneno"]            = true, |
| UI\BagPicker.lua:66 | - | TABLE | lixo | ["lixo"]              = true, |
| UI\BagPicker.lua:79 | - | TABLE | projÃ©til | ["projÃ©til"]          = true, |
| UI\BagPicker.lua:151 | BP:IsUsableItem | OTHER | consumÃ­vel \| consumÃ­veis | if typeLower == "consumable" or typeLower == "consumables" or typeLower == "consumÃ­vel" or typeLower == "consumÃ­veis" then |
| UI\BagPicker.lua:158 | BP:IsUsableItem | OTHER | lixo | if subLower == "junk" or subLower == "lixo" or subLower == "other" or subLower == "outro" or subLower == "outros" then |
| UI\BagPicker.lua:174 | BP:IsUsableItem | OTHER | missÃ£o | if typeLower == "quest" or typeLower == "missÃ£o" or typeLower == "key" or typeLower == "chave" then |
| UI\CharacterScreen.lua:386 | CS_Fmt1 | OTHER | — | if type(v) ~= "number" then return "—" end |
| UI\CharacterScreen.lua:392 | CS_Fmt2 | OTHER | — | if type(v) ~= "number" then return "—" end |
| UI\CharacterScreen.lua:398 | CS_DPS | OTHER | — | if type(minD) ~= "number" or type(maxD) ~= "number" then return "—" end |
| UI\CharacterScreen.lua:399 | CS_DPS | OTHER | — | if type(speed) ~= "number" or speed <= 0 then return "—" end |
| UI\CharacterScreen.lua:556 | CS_MatchNum | OTHER | Mana Regen %+(%d+) | { "mp5",    "Mana Regen %+(%d+)" }, |
| UI\CharacterScreen.lua:557 | CS_MatchNum | OTHER | Restores (%d+) mana per 5 sec | { "mp5",    "Restores (%d+) mana per 5 sec" }, |
| UI\CharacterScreen.lua:558 | CS_MatchNum | OTHER | Healing %+%d+ and (%d+) mana per 5 sec | { "mp5",    "Healing %+%d+ and (%d+) mana per 5 sec" }, |
| UI\CharacterScreen.lua:559 | CS_MatchNum | OTHER | %+(%d+) mana every 5 sec | { "mp5",    "%+(%d+) mana every 5 sec" }, |
| UI\CharacterScreen.lua:560 | CS_MatchNum | OTHER | Allows (%d+)%% of your Mana regeneration to continue while casting | { "casting","Allows (%d+)%% of your Mana regeneration to continue while casting" }, |
| UI\CharacterScreen.lua:609 | CS_MatchNum | OTHER | ^Set: Restores (%d+) mana per 5 sec | { "mp5",       "^Set: Restores (%d+) mana per 5 sec" }, |
| UI\CharacterScreen.lua:610 | CS_MatchNum | OTHER | ^Set: Allows (%d+)%% of your Mana regeneration to continue while casting | { "casting",   "^Set: Allows (%d+)%% of your Mana regeneration to continue while casting" }, |
| UI\CharacterScreen.lua:741 | CS_ScanTalents | OTHER | allows (%d+)%% of your mana regeneration to continue while casting | v = CS_MatchNum(low, "allows (%d+)%% of your mana regeneration to continue while casting") |
| UI\CharacterScreen.lua:826 | CS_ScanAuraLines | OTHER | Restores (%d+) mana per 5 sec | v = CS_MatchNum(text, "Restores (%d+) mana per 5 sec") |
| UI\CharacterScreen.lua:828 | CS_ScanAuraLines | OTHER | Regenerate (%d+) mana per 5 sec | v = CS_MatchNum(text, "Regenerate (%d+) mana per 5 sec") |
| UI\CharacterScreen.lua:830 | CS_ScanAuraLines | OTHER | Regenerating (%d+) Mana every 5 seconds | v = CS_MatchNum(text, "Regenerating (%d+) Mana every 5 seconds") |
| UI\CharacterScreen.lua:832 | CS_ScanAuraLines | OTHER | Mana Regeneration increased by (%d+) every 5 seconds | v = CS_MatchNum(text, "Mana Regeneration increased by (%d+) every 5 seconds") |
| UI\CharacterScreen.lua:834 | CS_ScanAuraLines | OTHER | Restores (%d+) mana every 1 sec | v = CS_MatchNum(text, "Restores (%d+) mana every 1 sec") |
| UI\CharacterScreen.lua:836 | CS_ScanAuraLines | OTHER | Restores (%d+) mana per 5 seconds | v = CS_MatchNum(text, "Restores (%d+) mana per 5 seconds") |
| UI\CharacterScreen.lua:839 | CS_ScanAuraLines | OTHER | Mana regeneration increased by (%d+)%% | v = CS_MatchNum(text, "Mana regeneration increased by (%d+)%%") |
| UI\CharacterScreen.lua:842 | CS_ScanAuraLines | OTHER | (%d+)%% of your Mana regeneration continuing while casting | v = CS_MatchNum(text, "(%d+)%% of your Mana regeneration continuing while casting") |
| UI\CharacterScreen.lua:844 | CS_ScanAuraLines | OTHER | (%d+)%% of your mana regeneration to continue while casting | v = CS_MatchNum(text, "(%d+)%% of your mana regeneration to continue while casting") |
| UI\CharacterScreen.lua:846 | CS_ScanAuraLines | OTHER | Allows (%d+)%% of mana regeneration while casting | v = CS_MatchNum(text, "Allows (%d+)%% of mana regeneration while casting") |
| UI\CharacterScreen.lua:848 | CS_ScanAuraLines | OTHER | (%d+)%% Mana regeneration may continue while casting | v = CS_MatchNum(text, "(%d+)%% Mana regeneration may continue while casting") |
| UI\CharacterScreen.lua:2311 | CharacterScreen:CreateUI | OTHER | Profissoes | if self.cardProf then self.cardProf.detailKey = "Profissoes" end |
| UI\EnhanceModal.lua:146 | - | TABLE | Mão Principal \| Mão Secundária | slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" }, |
| UI\EnhanceModal.lua:154 | - | TABLE | Mão Principal \| Mão Secundária | slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" }, |
| UI\EnhanceModal.lua:162 | - | TABLE | Mão Principal \| Mão Secundária | slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" }, |
| UI\EnhanceModal.lua:170 | - | TABLE | Mão Principal \| Mão Secundária | slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" }, |
| UI\EnhanceModal.lua:178 | - | TABLE | Pernas | slotNames   = { [5] = "Peitoral", [7] = "Pernas", [10] = "Luvas", [8] = "Botas" }, |
| UI\EnhanceModal.lua:194 | - | TABLE | Mão Secundária | slotNames   = { [17] = "Mão Secundária" }, |
| UI\EnhanceModal.lua:409 | EnhanceModal:BuildIconHints | DISPLAY | \|cff666666•\|r | sep:SetText("\|cff666666•\|r") |
| UI\EnhanceModal.lua:670 | EnhanceModal:ScanItemEnhancement | DISPLAY |  •  | if string.len(tempEnhance .. " • " .. permEnchant) <= 38 then |
| UI\EnhanceModal.lua:671 | EnhanceModal:ScanItemEnhancement | DISPLAY |  •  | return tempEnhance .. " • " .. permEnchant |
| UI\EnhanceModal.lua:1196 | EnhanceModal:CreateUI | DISPLAY | Sair | closeTxt:SetText((CM.T and CM:T("ENHANCE_CLOSE")) or "Sair") |
| UI\EnhanceModal.lua:1239 | EnhanceModal:CreateUI | DISPLAY | Selecione onde deseja aplicar | subText:SetText((CM.T and CM:T("ENHANCE_MODAL_SUBTITLE")) or "Selecione onde deseja aplicar") |
| UI\EnhanceModal.lua:1461 | EnhanceModal:RenderEquippedTab | DISPLAY | Nenhum equipamento compatível equipado.nPressione [RB] para verificar itens na mochila. | content.placeholder:SetText((CM.T and CM:T("ENHANCE_NO_EQUIP_FOUND")) or "Nenhum equipamento compatível equipado.\nPressione [RB] para verificar itens na mochila.") |
| UI\EnhanceModal.lua:1545 | EnhanceModal:RenderBagTab | DISPLAY | Nenhum item compatível encontrado na mochila. | content.placeholder:SetText((CM.T and CM:T("ENHANCE_NO_BAG_FOUND")) or "Nenhum item compatível encontrado na mochila.") |
| UI\EnhanceModal.lua:1623 | EnhanceModal:RenderBagTab | OTHER | \|cffffd100▲\|r  \| \|cff555555▲\|r  | local arrowUp = (offset > 0) and "\|cffffd100▲\|r " or "\|cff555555▲\|r " |
| UI\EnhanceModal.lua:1624 | EnhanceModal:RenderBagTab | OTHER |  \|cffffd100▼\|r \|  \|cff555555▼\|r | local arrowDown = (offset + 4 < count) and " \|cffffd100▼\|r" or " \|cff555555▼\|r" |
| UI\EnhanceModal.lua:1809 | EnhanceModal:UpdateFooter | TABLE | Cancelar | { icons = { "B" },        label = (CM.T and CM:T("ENHANCE_HINT_CANCEL")) or "Cancelar" }, |
| UI\EnhanceModal.lua:1872 | EnhanceModal:Open | DISPLAY | Sair | self.frame.closeBtn.text:SetText((CM.T and CM:T("ENHANCE_CLOSE")) or "Sair") |
| UI\KeybindingsList.lua:31 | - | TABLE | Pagina 1 (Base) | [1] = { label = "Pagina 1 (Base)",      tkey = "BIND_PAGE_1" }, |
| UI\KeybindingsList.lua:32 | - | TABLE | Pagina 2 (L2 / Shift) | [2] = { label = "Pagina 2 (L2 / Shift)", tkey = "BIND_PAGE_2" }, |
| UI\KeybindingsList.lua:33 | - | TABLE | Pagina 3 (R1 / Ctrl) | [3] = { label = "Pagina 3 (R1 / Ctrl)",  tkey = "BIND_PAGE_3" }, |
| UI\KeybindingsList.lua:34 | - | TABLE | Pagina 4 (R2 / Alt) | [4] = { label = "Pagina 4 (R2 / Alt)",   tkey = "BIND_PAGE_4" }, |
| UI\KeybindingsList.lua:78 | KBList:GetDisplayForButton | OTHER | Alvo Amigo (Party / Mundo) | return nil, (CM.T and CM:T("BIND_TARGET_FRIENDLY")) or "Alvo Amigo (Party / Mundo)", "Interface\\Icons\\Spell_Holy_PrayerOfHealing02" |
| UI\MailScreen.lua:638 | MailScreen:BuildFooterHintsSet | DISPLAY | \|cff666666•\|r | sep:SetText("\|cff666666•\|r") |
| UI\MailScreen.lua:718 | MailScreen:BuildIconHints | DISPLAY | \|cff666666•\|r | sep:SetText("\|cff666666•\|r") |
| UI\MailScreen.lua:1686 | MailScreen:RefreshInboxList | OTHER | ▲  | local arrowUp = (self.inboxScrollOffset > 0) and "▲ " or "" |
| UI\MailScreen.lua:1687 | MailScreen:RefreshInboxList | OTHER |  ▼ | local arrowDown = ((self.inboxScrollOffset + visible) < numItems) and " ▼" or "" |
| UI\MailScreen.lua:1962 | MailScreen:ClearComposeFocus | TABLE | ASSUNTO | { key = "composeSubject", label = "ASSUNTO",  tkey = "MAIL_FIELD_SUBJECT", h = 44,  kind = "edit",   max = 64 }, |
| UI\MailScreen.lua:1963 | MailScreen:ClearComposeFocus | TABLE | MENSAGEM | { key = "composeBody",    label = "MENSAGEM", tkey = "MAIL_FIELD_BODY",    h = 122, kind = "editml", max = 2000 }, |
| UI\MailScreen.lua:4626 | MailScreen:ClearComposeAfterSend | TABLE | RETIRAR \| RETIRAR | { key = "RETIRAR",  label = "RETIRAR",  tkey = "MAIL_BTN_TAKE",   icon = "Interface\\MoneyFrame\\UI-GoldIcon", action = "take" }, |
| UI\MailScreen.lua:4627 | MailScreen:ClearComposeAfterSend | TABLE | DEVOLVER \| DEVOLVER | { key = "DEVOLVER", label = "DEVOLVER", tkey = "MAIL_BTN_RETURN", icon = "Interface\\Icons\\INV_Misc_Note_01", action = "return" }, |
| UI\MailScreen.lua:4628 | MailScreen:ClearComposeAfterSend | TABLE | APAGAR \| APAGAR | { key = "APAGAR",   label = "APAGAR",   tkey = "MAIL_BTN_DELETE", icon = nil, action = "delete" }, |
| UI\MainMenu.lua:216 | CMSafeSetMap | TABLE | CABEÇA | { name = "HeadSlot",          label = "CABEÇA",   lkey = "SLOT_HEAD" }, |
| UI\MainMenu.lua:224 | CMSafeSetMap | TABLE | PERNAS | { name = "LegsSlot",          label = "PERNAS",   lkey = "SLOT_LEGS" }, |
| UI\MainMenu.lua:230 | CMSafeSetMap | TABLE | MÃO DIR. | { name = "MainHandSlot",      label = "MÃO DIR.", lkey = "SLOT_MAINHAND" }, |
| UI\MainMenu.lua:231 | CMSafeSetMap | TABLE | MÃO ESQ. | { name = "SecondaryHandSlot", label = "MÃO ESQ.", lkey = "SLOT_OFFHAND" }, |
| UI\MainMenu.lua:401 | CMSafeSetMap | TABLE | Mestre do combate corpo-a-corpo tático — foco em armas pesadas de duas mãos, controle de sangramento e golpes avassaladores. | [1] = { name = "Armas", nkey = "SPEC_WARRIOR_1_NAME", desc = "Mestre do combate corpo-a-corpo tático — foco em armas pesadas de duas mãos, controle de sangramento e golpes avassaladores.", dkey = "SPEC_WARRIOR_1_DESC" }, |
| UI\MainMenu.lua:402 | CMSafeSetMap | TABLE | Fúria \| Guerreiro berserker selvagem — foco em dano devastador, aceleração contínua de golpes e fúria incontrolável. | [2] = { name = "Fúria", nkey = "SPEC_WARRIOR_2_NAME", desc = "Guerreiro berserker selvagem — foco em dano devastador, aceleração contínua de golpes e fúria incontrolável.", dkey = "SPEC_WARRIOR_2_DESC" }, |
| UI\MainMenu.lua:403 | CMSafeSetMap | TABLE | Proteção \| Bastião inabalável com escudo e armadura pesada — mitigação suprema de dano e controle absoluto de ameaça. | [3] = { name = "Proteção", nkey = "SPEC_WARRIOR_3_NAME", desc = "Bastião inabalável com escudo e armadura pesada — mitigação suprema de dano e controle absoluto de ameaça.", dkey = "SPEC_WARRIOR_3_DESC" }, |
| UI\MainMenu.lua:406 | CMSafeSetMap | TABLE | Invocador da Luz Divina — curas purificadoras, bênçãos de proteção e suporte vital inabalável aos aliados. | [1] = { name = "Sagrado", nkey = "SPEC_PALADIN_1_NAME", desc = "Invocador da Luz Divina — curas purificadoras, bênçãos de proteção e suporte vital inabalável aos aliados.", dkey = "SPEC_PALADIN_1_DESC" }, |
| UI\MainMenu.lua:407 | CMSafeSetMap | TABLE | Proteção \| Guardião sagrado da fé — auras de resistência, bloqueios eficientes e defesa inabalável com escudo. | [2] = { name = "Proteção", nkey = "SPEC_PALADIN_2_NAME", desc = "Guardião sagrado da fé — auras de resistência, bloqueios eficientes e defesa inabalável com escudo.", dkey = "SPEC_PALADIN_2_DESC" }, |
| UI\MainMenu.lua:408 | CMSafeSetMap | TABLE | Retribuição \| Cruzado zeloso da justiça — punição divina com armas de duas mãos, selos justiceiros e golpes sagrados. | [3] = { name = "Retribuição", nkey = "SPEC_PALADIN_3_NAME", desc = "Cruzado zeloso da justiça — punição divina com armas de duas mãos, selos justiceiros e golpes sagrados.", dkey = "SPEC_PALADIN_3_DESC" }, |
| UI\MainMenu.lua:411 | CMSafeSetMap | TABLE | Domínio das Feras \| Mestre da vida selvagem — ligação primordial com feras domesticadas, amplificando o poder do ajudante. | [1] = { name = "Domínio das Feras", nkey = "SPEC_HUNTER_1_NAME", desc = "Mestre da vida selvagem — ligação primordial com feras domesticadas, amplificando o poder do ajudante.", dkey = "SPEC_HUNTER_1_DESC" }, |
| UI\MainMenu.lua:412 | CMSafeSetMap | TABLE | Precisão \| Atirador de elite letal — disparos cirúrgicos de longo alcance com arcos, bestas e armas de fogo. | [2] = { name = "Precisão", nkey = "SPEC_HUNTER_2_NAME", desc = "Atirador de elite letal — disparos cirúrgicos de longo alcance com arcos, bestas e armas de fogo.", dkey = "SPEC_HUNTER_2_DESC" }, |
| UI\MainMenu.lua:413 | CMSafeSetMap | TABLE | Sobrevivência \| Especialista em sobrevivência no ermo — armadilhas traiçoeiras, mobilidade tática e venenos mortais. | [3] = { name = "Sobrevivência", nkey = "SPEC_HUNTER_3_NAME", desc = "Especialista em sobrevivência no ermo — armadilhas traiçoeiras, mobilidade tática e venenos mortais.", dkey = "SPEC_HUNTER_3_DESC" }, |
| UI\MainMenu.lua:416 | CMSafeSetMap | TABLE | Mestre em venenos letais e golpes cirúrgicos — ataques furtivos concentrados que drenam rapidamente a vítima. | [1] = { name = "Assassinato", nkey = "SPEC_ROGUE_1_NAME", desc = "Mestre em venenos letais e golpes cirúrgicos — ataques furtivos concentrados que drenam rapidamente a vítima.", dkey = "SPEC_ROGUE_1_DESC" }, |
| UI\MainMenu.lua:417 | CMSafeSetMap | TABLE | Espadachim destemido e ágil — combate direto com espadas, maças e adagas com grande regeneração de energia. | [2] = { name = "Combate", nkey = "SPEC_ROGUE_2_NAME", desc = "Espadachim destemido e ágil — combate direto com espadas, maças e adagas com grande regeneração de energia.", dkey = "SPEC_ROGUE_2_DESC" }, |
| UI\MainMenu.lua:418 | CMSafeSetMap | TABLE | Subterfúgio \| Mestre das sombras e do engano — mobilidade fantasmagórica, ataques surpresa e reposicionamento furtivo. | [3] = { name = "Subterfúgio", nkey = "SPEC_ROGUE_3_NAME", desc = "Mestre das sombras e do engano — mobilidade fantasmagórica, ataques surpresa e reposicionamento furtivo.", dkey = "SPEC_ROGUE_3_DESC" }, |
| UI\MainMenu.lua:421 | CMSafeSetMap | TABLE | Fortaleza mental e disciplina espiritual — escudos de absorção, proteção preventiva e fortalecimento interior. | [1] = { name = "Disciplina", nkey = "SPEC_PRIEST_1_NAME", desc = "Fortaleza mental e disciplina espiritual — escudos de absorção, proteção preventiva e fortalecimento interior.", dkey = "SPEC_PRIEST_1_DESC" }, |
| UI\MainMenu.lua:422 | CMSafeSetMap | TABLE | Canalizador puro da Luz Divina — curas profundas, renovações vitais e milagres que salvam o grupo da morte. | [2] = { name = "Sagrado", nkey = "SPEC_PRIEST_2_NAME", desc = "Canalizador puro da Luz Divina — curas profundas, renovações vitais e milagres que salvam o grupo da morte.", dkey = "SPEC_PRIEST_2_DESC" }, |
| UI\MainMenu.lua:423 | CMSafeSetMap | TABLE | Manipulador do Vazio e da loucura — feitiços de dano mental contínuo, corrupção da alma e terror psicológico. | [3] = { name = "Sombra", nkey = "SPEC_PRIEST_3_NAME", desc = "Manipulador do Vazio e da loucura — feitiços de dano mental contínuo, corrupção da alma e terror psicológico.", dkey = "SPEC_PRIEST_3_DESC" }, |
| UI\MainMenu.lua:426 | CMSafeSetMap | TABLE | Invocador da fúria da natureza — magias devastadoras de raio, terra e fogo com alto dano de impacto à distância. | [1] = { name = "Elemental", nkey = "SPEC_SHAMAN_1_NAME", desc = "Invocador da fúria da natureza — magias devastadoras de raio, terra e fogo com alto dano de impacto à distância.", dkey = "SPEC_SHAMAN_1_DESC" }, |
| UI\MainMenu.lua:427 | CMSafeSetMap | TABLE | Aperfeiçoamento \| Combatente corpo-a-corpo totemico — armas imbuídas pelos espíritos dos elementos com golpes furiosos. | [2] = { name = "Aperfeiçoamento", nkey = "SPEC_SHAMAN_2_NAME", desc = "Combatente corpo-a-corpo totemico — armas imbuídas pelos espíritos dos elementos com golpes furiosos.", dkey = "SPEC_SHAMAN_2_DESC" }, |
| UI\MainMenu.lua:428 | CMSafeSetMap | TABLE | Restauração \| Curador das águas sagradas e ancestrais — cura em cadeia profunda, purificação e sustentação de grupo. | [3] = { name = "Restauração", nkey = "SPEC_SHAMAN_3_NAME", desc = "Curador das águas sagradas e ancestrais — cura em cadeia profunda, purificação e sustentação de grupo.", dkey = "SPEC_SHAMAN_3_DESC" }, |
| UI\MainMenu.lua:431 | CMSafeSetMap | TABLE | Mestre das energias puras do Cosmos — manipulação do fluxo de mana, aceleração temporal e dano arcano bruto. | [1] = { name = "Arcano", nkey = "SPEC_MAGE_1_NAME", desc = "Mestre das energias puras do Cosmos — manipulação do fluxo de mana, aceleração temporal e dano arcano bruto.", dkey = "SPEC_MAGE_1_DESC" }, |
| UI\MainMenu.lua:432 | CMSafeSetMap | TABLE | Mago incendiário devastador — queimaduras contínuas, explosões incandescentes e altos picos de acerto crítico. | [2] = { name = "Fogo", nkey = "SPEC_MAGE_2_NAME", desc = "Mago incendiário devastador — queimaduras contínuas, explosões incandescentes e altos picos de acerto crítico.", dkey = "SPEC_MAGE_2_DESC" }, |
| UI\MainMenu.lua:433 | CMSafeSetMap | TABLE | Gélido \| Comandante do gelo eterno — barreiras congelantes, desacelerações de campo e sobrevivência absoluta. | [3] = { name = "Gélido", nkey = "SPEC_MAGE_3_NAME", desc = "Comandante do gelo eterno — barreiras congelantes, desacelerações de campo e sobrevivência absoluta.", dkey = "SPEC_MAGE_3_DESC" }, |
| UI\MainMenu.lua:436 | CMSafeSetMap | TABLE | Aflição \| Mestre das maldições e agonia lenta — feitiços de dano periódico corrosivo que drenam a vitalidade do alvo. | [1] = { name = "Aflição", nkey = "SPEC_WARLOCK_1_NAME", desc = "Mestre das maldições e agonia lenta — feitiços de dano periódico corrosivo que drenam a vitalidade do alvo.", dkey = "SPEC_WARLOCK_1_DESC" }, |
| UI\MainMenu.lua:437 | CMSafeSetMap | TABLE | Comandante da Legião — invocação e fortalecimento de servos demoníacos para esmagar seus oponentes. | [2] = { name = "Demonologia", nkey = "SPEC_WARLOCK_2_NAME", desc = "Comandante da Legião — invocação e fortalecimento de servos demoníacos para esmagar seus oponentes.", dkey = "SPEC_WARLOCK_2_DESC" }, |
| UI\MainMenu.lua:438 | CMSafeSetMap | TABLE | Destruição \| Conjurador do fogo caótico vil — feitiços explosivos de impacto imediato e aniquilação incandescente. | [3] = { name = "Destruição", nkey = "SPEC_WARLOCK_3_NAME", desc = "Conjurador do fogo caótico vil — feitiços explosivos de impacto imediato e aniquilação incandescente.", dkey = "SPEC_WARLOCK_3_DESC" }, |
| UI\MainMenu.lua:441 | CMSafeSetMap | TABLE | Equilíbrio \| Canalizador das forças astrais e da natureza — feitiços solares e lunares com a Forma de Luniscélio ancestral. | [1] = { name = "Equilíbrio", nkey = "SPEC_DRUID_1_NAME", desc = "Canalizador das forças astrais e da natureza — feitiços solares e lunares com a Forma de Luniscélio ancestral.", dkey = "SPEC_DRUID_1_DESC" }, |
| UI\MainMenu.lua:442 | CMSafeSetMap | TABLE | Predador mutamorfo — combate feroz como Urso para defesa tenaz ou Felino para ataques furtivos. | [2] = { name = "Feral", nkey = "SPEC_DRUID_2_NAME", desc = "Predador mutamorfo — combate feroz como Urso para defesa tenaz ou Felino para ataques furtivos.", dkey = "SPEC_DRUID_2_DESC" }, |
| UI\MainMenu.lua:443 | CMSafeSetMap | TABLE | Restauração \| Guardião da cura e da vida — regeneração contínua de saúde por feitiços sobre o tempo e bênçãos do Sonho. | [3] = { name = "Restauração", nkey = "SPEC_DRUID_3_NAME", desc = "Guardião da cura e da vida — regeneração contínua de saúde por feitiços sobre o tempo e bênçãos do Sonho.", dkey = "SPEC_DRUID_3_DESC" }, |
| UI\MainMenu.lua:1452 | MainMenu:CreateStatsAndBuffsColumn | OTHER | Força \| Agilidade \| Vigor \| Intelecto \| Espírito \| Armadura | local statKeys = { "HP", "Recurso", "Força", "Agilidade", "Vigor", "Intelecto", "Espírito", "Armadura" } |
| UI\MainMenu.lua:1641 | MainMenu:RefreshBaseStatLines | DISPLAY | Força | lines["Força"]:SetText("\|cffffffff" .. CM:T("STAT_STRENGTH") .. ":\|r " .. GetPlayerEffectiveStat(1)) |
| UI\MainMenu.lua:1642 | MainMenu:RefreshBaseStatLines | DISPLAY | Agilidade | lines["Agilidade"]:SetText("\|cffffffff" .. CM:T("STAT_AGILITY") .. ":\|r " .. GetPlayerEffectiveStat(2)) |
| UI\MainMenu.lua:1643 | MainMenu:RefreshBaseStatLines | DISPLAY | Vigor | lines["Vigor"]:SetText("\|cffffffff" .. CM:T("STAT_STAMINA") .. ":\|r " .. GetPlayerEffectiveStat(3)) |
| UI\MainMenu.lua:1644 | MainMenu:RefreshBaseStatLines | DISPLAY | Intelecto | lines["Intelecto"]:SetText("\|cffffffff" .. CM:T("STAT_INTELLECT") .. ":\|r " .. GetPlayerEffectiveStat(4)) |
| UI\MainMenu.lua:1645 | MainMenu:RefreshBaseStatLines | DISPLAY | Espírito | lines["Espírito"]:SetText("\|cffffffff" .. CM:T("STAT_SPIRIT") .. ":\|r " .. GetPlayerEffectiveStat(5)) |
| UI\MainMenu.lua:1647 | MainMenu:RefreshBaseStatLines | DISPLAY | Armadura | lines["Armadura"]:SetText("\|cffffffff" .. CM:T("STAT_ARMOR") .. ":\|r " .. (armorEff or 0)) |
| UI\MainMenu.lua:2151 | MainMenu:ClearStatCompareCache | OTHER | mana | "hp", "mana", |
| UI\MainMenu.lua:2382 | MainMenu:FormatCompareDiffDebug | TABLE | Força \| Agilidade \| Vigor | str = "Força", agi = "Agilidade", sta = "Vigor", |
| UI\MainMenu.lua:2383 | MainMenu:FormatCompareDiffDebug | TABLE | Intelecto \| Espírito \| Armadura | int = "Intelecto", spi = "Espírito", armor = "Armadura", |
| UI\MainMenu.lua:2388 | MainMenu:FormatCompareDiffDebug | OTHER | Força \| Agilidade \| Vigor \| Intelecto \| Espírito \| Armadura | "Força", "Agilidade", "Vigor", "Intelecto", "Espírito", "Armadura", |
| UI\MainMenu.lua:2474 | MainMenu:HideCompare | OTHER | mana | "armor", "spellDmg", "healing", "hp", "mana", |
| UI\MainMenu.lua:2589 | Compare_FormatSecondary | OTHER | mana | elseif key == "mana" then |
| UI\MainMenu.lua:2613 | Compare_FormatSecondary | OTHER | mana | "hp", "mana", "ap", "hit", "crit", "dodge", "block", |
| UI\MainMenu.lua:3258 | card:ShowItem | DISPLAY |   •   | self.typeText:SetText("\|cffaaaaaa" .. table.concat(subParts, "  •  ") .. "\|r") |
| UI\MainMenu.lua:3587 | card:ShowEquipSlot | DISPLAY |   •   | self.typeText:SetText("\|cffaaaaaa" .. table.concat(subParts, "  •  ") .. "\|r") |
| UI\MainMenu.lua:3597 | card:ShowEquipSlot | TABLE | cabeça \| pescoço | ["cabeça"]=true, ["pescoço"]=true, ["ombros"]=true, ["camisa"]=true, ["peitoral"]=true, |
| UI\MainMenu.lua:3598 | card:ShowEquipSlot | TABLE | pernas \| pés \| mãos | ["cintura"]=true, ["pernas"]=true, ["pés"]=true, ["punhos"]=true, ["mãos"]=true, |
| UI\MainMenu.lua:3599 | card:ShowEquipSlot | TABLE | mão principal \| mão secundária | ["dedo"]=true, ["berloque"]=true, ["costas"]=true, ["mão principal"]=true, ["mão secundária"]=true |
| UI\MainMenu.lua:4284 | IsRedObj | OTHER | Armadura | if itemType == "Armadura" or itemType == "Armor" or itemType == "Arma" or itemType == "Weapon" then |
| UI\MainMenu.lua:4286 | IsRedObj | OTHER | Consumível | elseif itemType == "Consumível" or itemType == "Consumable" then |
| UI\MainMenu.lua:4412 | IsSpellRangeLine | OTHER | corpo a corpo | if s == "melee range" or s == "corpo a corpo" or s == "unlimited range" or s == "alcance ilimitado" then |
| UI\MainMenu.lua:4599 | MainMenu:ParseSpellData | OTHER | ataque | if lowerName == "attack" or lowerName == "ataque" then |
| UI\MainMenu.lua:4971 | MainMenu:SetupBagsPage | OTHER | Pedra de Regressão | if itemName == "Hearthstone" or itemName == "Pedra de Regresso" or itemName == "Pedra de Regressão" then |
| UI\MainMenu.lua:5499 | MainMenu:GetSpellTabTypeInfo | TABLE | furia \| fúria | [2] = { "fury", "furia", "fúria" }, |
| UI\MainMenu.lua:5500 | MainMenu:GetSpellTabTypeInfo | TABLE | proteção | [3] = { "protection", "protecao", "proteção" }, |
| UI\MainMenu.lua:5504 | MainMenu:GetSpellTabTypeInfo | TABLE | proteção | [2] = { "protection", "protecao", "proteção" }, |
| UI\MainMenu.lua:5505 | MainMenu:GetSpellTabTypeInfo | TABLE | retribuição | [3] = { "retribution", "retribuicao", "retribuição" }, |
| UI\MainMenu.lua:5508 | MainMenu:GetSpellTabTypeInfo | TABLE | domínio | [1] = { "beast", "feras", "dominio", "domínio" }, |
| UI\MainMenu.lua:5509 | MainMenu:GetSpellTabTypeInfo | TABLE | precisão | [2] = { "marksman", "precisao", "precisão" }, |
| UI\MainMenu.lua:5510 | MainMenu:GetSpellTabTypeInfo | TABLE | sobrevivência | [3] = { "survival", "sobrevivencia", "sobrevivência" }, |
| UI\MainMenu.lua:5515 | MainMenu:GetSpellTabTypeInfo | TABLE | subterfúgio | [3] = { "subtlety", "subterfugio", "subterfúgio" }, |
| UI\MainMenu.lua:5524 | MainMenu:GetSpellTabTypeInfo | TABLE | aperfeiçoamento | [2] = { "enhancement", "aperfeicoamento", "aperfeiçoamento" }, |
| UI\MainMenu.lua:5525 | MainMenu:GetSpellTabTypeInfo | TABLE | restauração | [3] = { "restoration", "restauracao", "restauração" }, |
| UI\MainMenu.lua:5530 | MainMenu:GetSpellTabTypeInfo | TABLE | gélido | [3] = { "frost", "gelido", "gélido" }, |
| UI\MainMenu.lua:5533 | MainMenu:GetSpellTabTypeInfo | TABLE | aflição | [1] = { "affliction", "aflicao", "aflição" }, |
| UI\MainMenu.lua:5535 | MainMenu:GetSpellTabTypeInfo | TABLE | destruição | [3] = { "destruction", "destruicao", "destruição" }, |
| UI\MainMenu.lua:5538 | MainMenu:GetSpellTabTypeInfo | TABLE | equilíbrio | [1] = { "balance", "equilibrio", "equilíbrio" }, |
| UI\MainMenu.lua:5540 | MainMenu:GetSpellTabTypeInfo | TABLE | restauração | [3] = { "restoration", "restauracao", "restauração" }, |
| UI\MainMenu.lua:6844 | MainMenu:FocusTalentSlot | DISPLAY | \|cffaaaaaa%s %d  •  %s/%d\|r | card.typeText:SetText(string.format("\|cffaaaaaa%s %d  •  %s/%d\|r", tierLabel, data.tier, rankStr, data.maxRank)) |
| UI\MainMenu.lua:7294 | MainMenu:CreateTalentInspectModal | DISPLAY | Fechar | cText:SetText(CM:T("BTN_CLOSE") or "Fechar") |
| UI\MainMenu.lua:7348 | MainMenu:ShowTalentInspectModal | DISPLAY | \|cffaaaaaa%s %d  •  %s/%d\|r | modal.badgesText:SetText(string.format("\|cffaaaaaa%s %d  •  %s/%d\|r", tierLabel, data.tier, rankStr, data.maxRank)) |
| UI\MainMenu.lua:10443 | MainMenu:SelectQuest | OTHER | \|cff00ff00✔ \|r | local bullet = isDone and "\|cff00ff00✔ \|r" or "\|cffffcc00- \|r" |
| UI\MainMenu.lua:11426 | MainMenu:UpdatePfQuestPins | TABLE | Líder | ["LEADER"]              = { cat = "leader",     role = "Líder",                  rkey = "NPC_ROLE_LEADER",             icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", prio = 2 }, |
| UI\MainMenu.lua:11427 | MainMenu:UpdatePfQuestPins | TABLE | Mestre do Estábulo | ["STABLE"]              = { cat = "stable",     role = "Mestre do Estábulo",     rkey = "NPC_ROLE_STABLE",             icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar", prio = 3 }, |
| UI\MainMenu.lua:11428 | MainMenu:UpdatePfQuestPins | TABLE | Comerciante / Reparo | ["OTHER"]               = { cat = "repair",     role = "Comerciante / Reparo",   rkey = "NPC_ROLE_VENDOR_REPAIR",      icon = "Interface\\Icons\\INV_Hammer_20", prio = 5 }, |
| UI\MainMenu.lua:11432 | MainMenu:UpdatePfQuestPins | TABLE | Instrutor de Caçadores | ["TRAINER_HUNTER"]      = { cat = "trainer",    role = "Instrutor de Caçadores",  rkey = "NPC_ROLE_TRAINER_HUNTER",    icon = "Interface\\Icons\\ClassIcon_Hunter", prio = 2 }, |
| UI\MainMenu.lua:11435 | MainMenu:UpdatePfQuestPins | TABLE | Instrutor de Xamãs | ["TRAINER_SHAMAN"]      = { cat = "trainer",    role = "Instrutor de Xamãs",      rkey = "NPC_ROLE_TRAINER_SHAMAN",    icon = "Interface\\Icons\\ClassIcon_Shaman", prio = 2 }, |
| UI\MainMenu.lua:11442 | MainMenu:UpdatePfQuestPins | TABLE | Instrutor de Culinária | ["PROF_COOKING"]        = { cat = "profession", role = "Instrutor de Culinária",     rkey = "NPC_ROLE_PROF_COOKING",        icon = "Interface\\Icons\\INV_Misc_Food_15", prio = 3 }, |
| UI\MainMenu.lua:11449 | MainMenu:UpdatePfQuestPins | TABLE | Instrutor de Mineração | ["PROF_MINING"]         = { cat = "profession", role = "Instrutor de Mineração",     rkey = "NPC_ROLE_PROF_MINING",         icon = "Interface\\Icons\\Trade_Mining", prio = 3 }, |
| UI\MainMenu.lua:11451 | MainMenu:UpdatePfQuestPins | TABLE | Instrutor de Sobrevivência | ["PROF_SURVIVAL"]       = { cat = "profession", role = "Instrutor de Sobrevivência",rkey = "NPC_ROLE_PROF_SURVIVAL",       icon = "Interface\\Icons\\Spell_Fire_Fire", prio = 3 }, |
| UI\MainMenu.lua:13313 | MainMenu:UpdateSystemPage | TABLE | Espaço (Pulo) | ["SPACE"]           = "Espaço (Pulo)", |
| UI\MainMenu.lua:13314 | MainMenu:UpdateSystemPage | TABLE | Shift + Espaço | ["SHIFT-SPACE"]     = "Shift + Espaço", |
| UI\MainMenu.lua:13315 | MainMenu:UpdateSystemPage | TABLE | Ctrl + Espaço | ["CTRL-SPACE"]      = "Ctrl + Espaço", |
| UI\MainMenu.lua:13316 | MainMenu:UpdateSystemPage | TABLE | Alt + Espaço | ["ALT-SPACE"]       = "Alt + Espaço", |
| UI\MainMenu.lua:13317 | MainMenu:UpdateSystemPage | TABLE | Shift + Alt + Espaço | ["ALT-SHIFT-SPACE"] = "Shift + Alt + Espaço", |
| UI\MainMenu.lua:13318 | MainMenu:UpdateSystemPage | TABLE | Tecla 1 \| Tecla 2 \| Tecla 3 | ["1"] = "Tecla 1", ["2"] = "Tecla 2", ["3"] = "Tecla 3", |
| UI\MainMenu.lua:13319 | MainMenu:UpdateSystemPage | TABLE | Tecla 7 \| Tecla 8 \| Tecla 9 \| Tecla 0 | ["7"] = "Tecla 7", ["8"] = "Tecla 8", ["9"] = "Tecla 9", ["0"] = "Tecla 0", |
| UI\MainMenu.lua:13361 | MainMenu:UpdateSystemPage | TABLE | BOTÕES FACIAIS (ABXY) | title = "BOTÕES FACIAIS (ABXY)", |
| UI\MainMenu.lua:13364 | MainMenu:UpdateSystemPage | TABLE | Botão Y | { key = "Y", glyph = "[Y]", label = "Botão Y", lkey = "BINDS_BTN_Y_LABEL", icon = CFG.Icons.Y }, |
| UI\MainMenu.lua:13365 | MainMenu:UpdateSystemPage | TABLE | Botão X | { key = "X", glyph = "[X]", label = "Botão X", lkey = "BINDS_BTN_X_LABEL", icon = CFG.Icons.X }, |
| UI\MainMenu.lua:13366 | MainMenu:UpdateSystemPage | TABLE | Botão B | { key = "B", glyph = "[B]", label = "Botão B", lkey = "BINDS_BTN_B_LABEL", icon = CFG.Icons.B }, |
| UI\MainMenu.lua:13367 | MainMenu:UpdateSystemPage | TABLE | Botão A | { key = "A", glyph = "[A]", label = "Botão A", lkey = "BINDS_BTN_A_LABEL", icon = CFG.Icons.A }, |
| UI\MainMenu.lua:15686 | MainMenu:CreateFooterHints | DISPLAY | \|cff666666•\|r | sep:SetText("\|cff666666•\|r") |
| UI\MainMenuNav.lua:1765 | Nav_EnsureFocus | OTHER | ZONAS | if f.zone ~= "TABBAR" and f.zone ~= "EQUIP" and f.zone ~= "CATS" and f.zone ~= "GRID" and f.zone ~= "BUFFS" and f.zone ~= "PAGENAV" and f.zone ~= "SORT" and f.zone ~= "SPCAT" and f.zone ~= "SPGRID" and f.zone ~= "SPTABS" |
| UI\MainMenuNav.lua:1768 | Nav_EnsureFocus | OTHER | ZONAS | if f.returnZone ~= "EQUIP" and f.returnZone ~= "CATS" and f.returnZone ~= "GRID" and f.returnZone ~= "BUFFS" and f.returnZone ~= "PAGENAV" and f.returnZone ~= "SORT" and f.returnZone ~= "SPCAT" and f.returnZone ~= "SPGRI |
| UI\MainMenuNav.lua:1777 | Nav_EnsureFocus | OTHER | ZONAS | if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "EQUIP" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "ZONAS" |
| UI\MainMenuNav.lua:1780 | Nav_EnsureFocus | OTHER | ZONAS | if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "EQUIP" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" or f.returnZone == "QMISSO |
| UI\MainMenuNav.lua:1787 | Nav_EnsureFocus | OTHER | ZONAS | if f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "ZONAS" or f.zone == "QN |
| UI\MainMenuNav.lua:1790 | Nav_EnsureFocus | OTHER | ZONAS | if f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" or f.returnZone == "QMISSOES" or f.returnZone ==  |
| UI\MainMenuNav.lua:1797 | Nav_EnsureFocus | OTHER | ZONAS | if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "EQUIP" or f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "QMISSOES" or f. |
| UI\MainMenuNav.lua:1800 | Nav_EnsureFocus | OTHER | ZONAS | if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "EQUIP" or f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or  |
| UI\MainMenuNav.lua:1822 | Nav_EnsureFocus | OTHER | ZONAS | if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or |
| UI\MainMenuNav.lua:1827 | Nav_EnsureFocus | OTHER | ZONAS | if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or |
| UI\MainMenuNav.lua:1858 | Nav_EnsureFocus | OTHER | ZONAS | elseif f.zone == "ZONAS" then |
| UI\MainMenuNav.lua:3193 | Nav_OnQuestsDirection | OTHER | ZONAS | if f.zone == "ZONAS" then |
| UI\MainMenuNav.lua:4697 | Nav:OnConfirm | OTHER | ZONAS | if fq.zone == "QZONAS" or fq.zone == "ZONAS" then |
| UI\MainMenuNav.lua:5067 | Nav:OnCancel | OTHER | ZONAS | if fq.zone == "QZONAS" or fq.zone == "QMAPAS" or fq.zone == "ZONAS" then |
| UI\MerchantMenu.lua:55 | - | TABLE | Consumíveis | { id = "CONSUMABLE", name = "Consumíveis", tkey = "MERCH_FILTER_CONSUM" }, |
| UI\MerchantMenu.lua:56 | - | TABLE | Lixo | { id = "JUNK",       name = "Lixo",        tkey = "MERCH_FILTER_JUNK" }, |
| UI\MerchantMenu.lua:64 | - | TABLE | Recompra | { id = "BUYBACK", name = "Recompra", tkey = "MERCH_FILTER_BUYBACK" }, |
| UI\MerchantMenu.lua:369 | MerchantMenu:ParseBagItem | OTHER | Armadura | if itemType == "Armadura" or itemType == "Armor" or itemType == "Arma" or itemType == "Weapon" or (itemEquipLoc and itemEquipLoc ~= "") then |
| UI\MerchantMenu.lua:371 | MerchantMenu:ParseBagItem | OTHER | Consumível | elseif itemType == "Consumível" or itemType == "Consumable" or itemType == "Potion" or itemType == "Food & Drink" then |
| UI\MerchantMenu.lua:576 | MerchantMenu:ParseVendorItem | OTHER | Armadura | if (itemEquipLoc and itemEquipLoc ~= "") or itemType == "Armor" or itemType == "Armadura" or itemType == "Weapon" or itemType == "Arma" then |
| UI\MerchantMenu.lua:578 | MerchantMenu:ParseVendorItem | OTHER | Consumível | elseif itemType == "Consumable" or itemType == "Consumível" or itemType == "Potion" or itemType == "Food & Drink" then |
| UI\MerchantMenu.lua:1143 | MerchantMenu:CreateFooterHints | DISPLAY | \|cff666666•\|r | sep:SetText("\|cff666666•\|r") |
| UI\MerchantMenu.lua:1907 | MerchantMenu:UpdateBagRows | OTHER | ▲  | local arrowUp = (self.bagScrollOffset > 0) and "▲ " or "" |
| UI\MerchantMenu.lua:1908 | MerchantMenu:UpdateBagRows | OTHER |  ▼ | local arrowDown = ((self.bagScrollOffset + 7) < numItems) and " ▼" or "" |
| UI\MerchantMenu.lua:1984 | MerchantMenu:UpdateVendorRows | OTHER | ▲  | local arrowUp = (self.vendorScrollOffset > 0) and "▲ " or "" |
| UI\MerchantMenu.lua:1985 | MerchantMenu:UpdateVendorRows | OTHER |  ▼ | local arrowDown = ((self.vendorScrollOffset + 7) < numItems) and " ▼" or "" |
| UI\MerchantMenu.lua:2226 | MerchantMenu:ShowItemDetail | DISPLAY |   •   | local subStr = table.concat(typeParts, "  •  ") |
| UI\QuantityPicker.lua:209 | BuildHints | DISPLAY | \|cff666666•\|r | sep:SetText("\|cff666666•\|r") |
| UI\QuestItemDistributor.lua:134 | NormalizeText | OTHER | carta \| cartas | "carta", "cartas", |
| UI\QuestItemDistributor.lua:137 | NormalizeText | OTHER | письмо \| письма \| письмецо \| Письмо \| ПИСЬМО | "письмо", "письма", "письмецо", "Письмо", "ПИСЬМО", |
| UI\QuestItemDistributor.lua:138 | NormalizeText | OTHER | 信 \| 信件 \| 书信 \| 密信 \| 信函 | "信", "信件", "书信", "密信", "信函", |
| UI\QuestItemDistributor.lua:139 | NormalizeText | OTHER | 편지 \| 서한 | "편지", "서한", |
| UI\QuestItemDistributor.lua:145 | NormalizeText | OTHER | записка \| записки \| заметка \| заметки \| Записка \| ЗАПИСКА | "записка", "записки", "заметка", "заметки", "Записка", "ЗАПИСКА", |
| UI\QuestItemDistributor.lua:146 | NormalizeText | OTHER | 便条 \| 便笺 \| 便签 \| 笔记 \| 记事 | "便条", "便笺", "便签", "笔记", "记事", |
| UI\QuestItemDistributor.lua:147 | NormalizeText | OTHER | 쪽지 \| 메모 | "쪽지", "메모", |
| UI\QuestItemDistributor.lua:151 | NormalizeText | OTHER | mensagem | "mensagem", "mensagens", "missiva", "missivas", "recado", "recados", |
| UI\QuestItemDistributor.lua:153 | NormalizeText | OTHER | послание \| послания \| сообщение \| сообщения \| депеша \| депеши \| Послание \| ПОСЛАНИЕ | "послание", "послания", "сообщение", "сообщения", "депеша", "депеши", "Послание", "ПОСЛАНИЕ", |
| UI\QuestItemDistributor.lua:154 | NormalizeText | OTHER | 密函 \| 简讯 \| 讯息 \| 信息 \| 书函 | "密函", "简讯", "讯息", "信息", "书函", |
| UI\QuestItemDistributor.lua:155 | NormalizeText | OTHER | 기별 \| 전갈 | "기별", "전갈", |
| UI\QuestItemDistributor.lua:161 | NormalizeText | OTHER | документ \| документы \| бумага \| бумаги \| Документ \| ДОКУМЕНТ | "документ", "документы", "бумага", "бумаги", "Документ", "ДОКУМЕНТ", |
| UI\QuestItemDistributor.lua:162 | NormalizeText | OTHER | 文件 \| 文档 \| 文书 \| 公文 | "文件", "文档", "文书", "公文", |
| UI\QuestItemDistributor.lua:163 | NormalizeText | OTHER | 문서 \| 서류 \| 공문 | "문서", "서류", "공문", |
| UI\QuestItemDistributor.lua:170 | NormalizeText | OTHER | свиток \| свитки \| пергамент \| пергаменты \| Свиток \| СВИТОК | "свиток", "свитки", "пергамент", "пергаменты", "Свиток", "СВИТОК", |
| UI\QuestItemDistributor.lua:171 | NormalizeText | OTHER | 卷轴 \| 羊皮纸 | "卷轴", "羊皮纸", |
| UI\QuestItemDistributor.lua:172 | NormalizeText | OTHER | 두루마리 \| 양피지 | "두루마리", "양피지", |
| UI\QuestItemDistributor.lua:176 | NormalizeText | OTHER | grimorio | "livro", "livros", "tomo", "tomos", "grimorio", "grimorios", |
| UI\QuestItemDistributor.lua:177 | NormalizeText | OTHER | bücher | "buch", "bücher", "buecher", |
| UI\QuestItemDistributor.lua:179 | NormalizeText | OTHER | книга \| книги \| фолиант \| фолианты \| гримуар \| гримуары \| Книга \| КНИГА \| Фолиант \| ФОЛИАНТ | "книга", "книги", "фолиант", "фолианты", "гримуар", "гримуары", "Книга", "КНИГА", "Фолиант", "ФОЛИАНТ", |
| UI\QuestItemDistributor.lua:180 | NormalizeText | OTHER | 书籍 \| 典籍 \| 魔法书 \| 秘典 \| 宝典 | "书籍", "典籍", "魔法书", "秘典", "宝典", |
| UI\QuestItemDistributor.lua:181 | NormalizeText | OTHER | 서적 \| 마법서 | "서적", "마법서", |
| UI\QuestItemDistributor.lua:186 | NormalizeText | OTHER | tagebücher \| logbücher | "tagebuch", "tagebücher", "tagebuecher", "logbuch", "logbücher", |
| UI\QuestItemDistributor.lua:187 | NormalizeText | OTHER | дневник \| дневники \| Дневник \| ДНЕВНИК | "дневник", "дневники", "Дневник", "ДНЕВНИК", |
| UI\QuestItemDistributor.lua:188 | NormalizeText | OTHER | 日记 \| 航海日志 | "日记", "航海日志", |
| UI\QuestItemDistributor.lua:189 | NormalizeText | OTHER | 일지 \| 일기 | "일지", "일기", |
| UI\QuestItemDistributor.lua:197 | NormalizeText | OTHER | отчет \| отчеты \| отчёт \| отчёты \| доклад \| доклады \| донесение \| донесения \| Отчет \| ОТЧЕТ \| Доклад \| ДОКЛАД | "отчет", "отчеты", "отчёт", "отчёты", "доклад", "доклады", "донесение", "донесения", "Отчет", "ОТЧЕТ", "Доклад", "ДОКЛАД", |
| UI\QuestItemDistributor.lua:198 | NormalizeText | OTHER | 报告 \| 通报 | "报告", "通报", |
| UI\QuestItemDistributor.lua:199 | NormalizeText | OTHER | 보고서 \| 보고 | "보고서", "보고", |
| UI\QuestItemDistributor.lua:204 | NormalizeText | OTHER | órdenes | "órdenes", "ordenes", "instruccion", "instrucciones", |
| UI\QuestItemDistributor.lua:207 | NormalizeText | OTHER | приказ \| приказы \| инструкция \| инструкции \| директива \| директивы \| распоряжение \| Приказ \| ПРИКАЗ | "приказ", "приказы", "инструкция", "инструкции", "директива", "директивы", "распоряжение", "Приказ", "ПРИКАЗ", |
| UI\QuestItemDistributor.lua:208 | NormalizeText | OTHER | 指令 \| 命令 \| 指示 \| 训令 | "指令", "命令", "指示", "训令", |
| UI\QuestItemDistributor.lua:209 | NormalizeText | OTHER | 명령 \| 명령서 \| 지시서 \| 지령 | "명령", "명령서", "지시서", "지령", |
| UI\QuestItemDistributor.lua:213 | NormalizeText | OTHER | aviso | "proclamacao", "proclamacoes", "decreto", "decretos", "mandado", "mandados", "aviso", "avisos", "boletim", |
| UI\QuestItemDistributor.lua:216 | NormalizeText | OTHER | прокламация \| прокламации \| указ \| указы \| манифест \| манифесты \| объявление \| объявления \| Указ \| УКАЗ | "прокламация", "прокламации", "указ", "указы", "манифест", "манифесты", "объявление", "объявления", "Указ", "УКАЗ", |
| UI\QuestItemDistributor.lua:217 | NormalizeText | OTHER | 告示 \| 公告 \| 宣言 \| 诏令 | "告示", "公告", "宣言", "诏令", |
| UI\QuestItemDistributor.lua:218 | NormalizeText | OTHER | 포고 \| 포고문 \| 칙령 \| 공고 | "포고", "포고문", "칙령", "공고", |
| UI\QuestItemDistributor.lua:223 | NormalizeText | OTHER | flugblätter \| broschüre | "flugblatt", "flugblätter", "flugblaetter", "broschuere", "broschüre", "tract", |
| UI\QuestItemDistributor.lua:224 | NormalizeText | OTHER | листовка \| листовки \| брошюра \| брошюры \| Листовка \| ЛИСТОВКА | "листовка", "листовки", "брошюра", "брошюры", "Листовка", "ЛИСТОВКА", |
| UI\QuestItemDistributor.lua:225 | NormalizeText | OTHER | 传单 \| 小册子 | "传单", "小册子", |
| UI\QuestItemDistributor.lua:226 | NormalizeText | OTHER | 전단 \| 전단지 | "전단", "전단지", |
| UI\QuestItemDistributor.lua:232 | NormalizeText | OTHER | табличка \| таблички \| рукопись \| рукописи \| Табличка \| ТАБЛИЧКА \| Рукопись \| РУКОПИСЬ | "табличка", "таблички", "рукопись", "рукописи", "Табличка", "ТАБЛИЧКА", "Рукопись", "РУКОПИСЬ", |
| UI\QuestItemDistributor.lua:233 | NormalizeText | OTHER | 石板 \| 泥板 \| 手稿 | "石板", "泥板", "手稿", |
| UI\QuestItemDistributor.lua:234 | NormalizeText | OTHER | 석판 \| 필사본 | "석판", "필사본", |
| UI\QuestItemDistributor.lua:239 | NormalizeText | OTHER | verträge | "vertrag", "verträge", "vertraege", "urkunde", "urkunden", "hauptbuch", |
| UI\QuestItemDistributor.lua:240 | NormalizeText | OTHER | договор \| договоры \| контракт \| контракты \| гроссбух \| Договор \| ДОГОВОР \| Контракт \| КОНТРАКТ | "договор", "договоры", "контракт", "контракты", "гроссбух", "Договор", "ДОГОВОР", "Контракт", "КОНТРАКТ", |
| UI\QuestItemDistributor.lua:241 | NormalizeText | OTHER | 契约 \| 合同 \| 账本 \| 帐本 | "契约", "合同", "账本", "帐本", |
| UI\QuestItemDistributor.lua:242 | NormalizeText | OTHER | 계약서 \| 장부 | "계약서", "장부", |
| UI\QuestItemDistributor.lua:248 | NormalizeText | OTHER | трактат \| трактаты \| руководство \| Трактат \| Руководство | "трактат", "трактаты", "руководство", "Трактат", "Руководство", |
| UI\QuestItemDistributor.lua:249 | NormalizeText | OTHER | 指南 \| 手册 \| 论著 | "指南", "手册", "论著", |
| UI\QuestItemDistributor.lua:250 | NormalizeText | OTHER | 논문 \| 교본 \| 지침서 | "논문", "교본", "지침서", |
| UI\QuestItemDistributor.lua:254 | NormalizeText | OTHER | pagina \| paginas | "pagina", "paginas", |
| UI\QuestItemDistributor.lua:256 | NormalizeText | OTHER | страница \| страницы \| Страница \| СТРАНИЦА | "страница", "страницы", "Страница", "СТРАНИЦА", |
| UI\QuestItemDistributor.lua:257 | NormalizeText | OTHER | 页码 \| 书页 | "页码", "书页", |
| UI\QuestItemDistributor.lua:258 | NormalizeText | OTHER | 페이지 | "페이지", |
| UI\QuestItemDistributor.lua:609 | QID:RunDeduplicator | DISPLAY |  removida com sucesso. | QLog("[Deduplicador] Duplicata do slot " .. slot .. " removida com sucesso.") |
| UI\QuestItemDistributor.lua:648 | QID:DistributeQuestItems | DISPLAY | Novo item de missao encontrado: \|cffffff00[ | QLog("Novo item de missao encontrado: \|cffffff00[" .. (item.itemName or "Item") .. "]\|r") |
| UI\QuestItemDistributor.lua:696 | QID:DistributeQuestItems | DISPLAY | ' nao esta mais na bolsa. Limpando slot  | QLog("Item '" .. oldName .. "' nao esta mais na bolsa. Limpando slot " .. actionSlot .. " (" .. btnLabel .. ").") |
| UI\QuestItemDistributor.lua:711 | QID:DistributeQuestItems | DISPLAY | Falha ao colocar item  | QDebug("Falha ao colocar item " .. (itemToPlace.itemName or "?") .. " no slot " .. actionSlot .. " (nao aceito na action bar)") |
| UI\QuestItemDistributor.lua:719 | QID:DistributeQuestItems | DISPLAY | ' nao esta mais na bolsa. Limpando slot  | QLog("Item '" .. oldName .. "' nao esta mais na bolsa. Limpando slot " .. actionSlot .. " (" .. btnLabel .. ").") |
| UI\TargetFrame.lua:378 | TF:Initialize | TABLE | Cura Maior \| Cura Superior | ["Greater Heal"] = 2.5, ["Cura Maior"] = 2.5, ["Cura Superior"] = 2.5, |
| UI\TargetFrame.lua:379 | TF:Initialize | TABLE | Cura | ["Heal"] = 2.5, ["Cura"] = 2.5, |
| UI\TargetFrame.lua:380 | TF:Initialize | TABLE | Cura Célere | ["Flash Heal"] = 1.5, ["Cura Célere"] = 1.5, |
| UI\TargetFrame.lua:381 | TF:Initialize | TABLE | Punição | ["Smite"] = 2.0, ["Punição"] = 2.0, |
| UI\TargetFrame.lua:384 | TF:Initialize | TABLE | Mana Burn \| Queimar Mana | ["Mana Burn"] = 2.5, ["Queimar Mana"] = 2.5, |
| UI\TargetFrame.lua:385 | TF:Initialize | TABLE | Onda de Cura | ["Healing Wave"] = 2.5, ["Onda de Cura"] = 2.5, |
| UI\TargetFrame.lua:386 | TF:Initialize | TABLE | Onda de Cura Menor | ["Lesser Healing Wave"] = 1.5, ["Onda de Cura Menor"] = 1.5, |
| UI\TargetFrame.lua:387 | TF:Initialize | TABLE | Cadeia de Cura | ["Chain Heal"] = 2.5, ["Cadeia de Cura"] = 2.5, |
| UI\TargetFrame.lua:390 | TF:Initialize | TABLE | Toque de Cura | ["Healing Touch"] = 3.0, ["Toque de Cura"] = 3.0, |
| UI\TargetFrame.lua:394 | TF:Initialize | TABLE | Raízes Enredantes | ["Entangling Roots"] = 1.5, ["Raízes Enredantes"] = 1.5, |
| UI\VirtualKeyboard.lua:113 | - | OTHER | APAGAR | local VK_EXTRA_BACKSPACE = { label = "APAGAR", lkey = "VK_BACKSPACE", op = "backspace", w = 52, textSize = 11, r = 1, g = 0.35, b = 0.3, icon = "X" } |
| UI\VirtualKeyboard.lua:115 | - | OTHER | ESPACO | local VK_EXTRA_SPACE = { label = "ESPACO", lkey = "VK_SPACE", op = "space", w = 220, textSize = 11, r = 0.66, g = 0.66, b = 0.66 } |
| UI\VirtualKeyboard.lua:159 | - | TABLE | fechar | { icons = { "B" },        label = "fechar",   lkey = "VK_HINT_CLOSE" }, |
| UI\VirtualKeyboard.lua:160 | - | TABLE | apagar | { icons = { "X" },        label = "apagar",   lkey = "VK_HINT_DELETE" }, |
| UI\VirtualKeyboard.lua:162 | - | TABLE | pág | { icons = { "LB", "RB" }, label = "pág",      lkey = "VK_HINT_PAGE" }, |
| UI\VirtualKeyboard.lua:187 | - | TABLE | ã \| õ \| ç \| á \| é \| í \| ó \| ú \| â \| ê | { keys = { "ã", "õ", "ç", "á", "é", "í", "ó", "ú", "â", "ê" } }, |
| UI\VirtualKeyboard.lua:188 | - | TABLE | à \| è \| ì \| ò \| ù \| î \| ô \| û | { keys = { "à", "è", "ì", "ò", "ù", "î", "ô", "û" }, extra = VK_EXTRA_BACKSPACE }, |
| UI\VirtualKeyboard.lua:189 | - | TABLE | ä \| ë \| ï \| ö \| ü \| ñ \| ý \| ÿ \| æ \| œ | { keys = { "ä", "ë", "ï", "ö", "ü", "ñ", "ý", "ÿ", "æ", "œ" }, extra = VK_EXTRA_OK }, |
| UI\VirtualKeyboard.lua:389 | VK:BuildHints | DISPLAY | \|cff666666•\|r | sep:SetText("\|cff666666•\|r") |
