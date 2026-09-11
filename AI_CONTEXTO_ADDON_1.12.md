> [!CAUTION]
> ## REGRAS PRINCIPAIS — LEITURA OBRIGATÓRIA ANTES DE QUALQUER AÇÃO
> 1. **NÃO FAZER PUSH ENQUANTO O USUÁRIO NÃO PEDIR.** Quando pedir, fazer push **UMA VEZ SÓ** e aguardar o próximo pedido explícito para fazer push de novo. Nunca fazer push automático, em sequência ou por conta própria.
> 2. **WoW VERSÃO 1.12.1 (Interface 11200) / Lua 5.0** — todo código deve ser compatível com isso. Nada de sintaxe Retail / Lua 5.1+.
> 3. **AVISO DE SEGURANÇA DO WOW:** NÃO usar / NÃO sugerir comandos, funções ou truques que possam ser flagados pelo anti-cheat / Warden (automação de input, unlock, bots, desabilitar proteção, chamar função protegida que só é permitida pela UI do WoW em combate, `CastSpellByName` automatizado, etc.). Função protegida / restrita à UI do WoW deve permanecer via UI — NÃO bypasse, NÃO desbloqueie.
> 4. **IDENTIDADE VISUAL:** Sempre manter a identidade visual do addon seguindo o MAIN MENU do WoW 1.12 — mesmo fundo, cores, fontes, layout, bordas, texturas, botões e estilo Vanilla. Nada de visual Retail / moderno / custom fora do padrão. Reutilizar templates e assets do MAIN MENU sempre que possível.

# Contexto para IA — Addon WoW 1.12 / Lua 5.0 (Turtle WoW)

> Cole este arquivo no início de qualquer conversa com IA para ela NÃO precisar redescobrir tudo do zero.

## 1. Ambiente fixo (não precisa re-verificar)

* **Jogo:** World of Warcraft 1.12.1 (cliente Vanilla, servidor Turtle WoW)
* **Linguagem:** Lua 5.0 (NÃO 5.1 / 5.4 / Retail)
* **Interface version:** `11200` no `.toc`
* **Pasta base (Linux/Steam Deck, disco NTFS):**
  `/run/media/deck/C8FE7D7FFE7D671A/Users/rodri/OneDrive/wow/turtle wow`
* **Executáveis:**
  * `VanillaFixes.exe` (87 KB, PE32 GUI) = launcher/patcher, NÃO é o WoW. Usa DXVK v2.6.1, `VfPatcher.dll`, `d3d9.dll`. Log: `VanillaFixes_d3d9.log`
  * `WoW.exe` (4.7 MB) = cliente 1.12 original
  * `turtle-wow.exe` (30 MB) = cliente Turtle WoW (usado de fato)
  * `vanilla-tweaks.exe`, `dgVoodooCpl.exe` = tweaks gráficos
* **Configs:** `WTF/Config.wtf`, `realmlist.wtf` (`apac.capycraft.io`), `main.ini` (ReShade), `dxvk.conf`
* **DLLs injetadas (`dlls.txt`):**
  ```
  nampower.dll
  SuperWoWhook.dll
  UnitXP_SP3.dll
  WoWTranslate.dll
  Interact.dll
  ```
  Isso significa: API estendida além do 1.12 puro. Sempre considerar SuperWoW + UnitXP.

## 2. Estrutura de pastas relevante

```
<turtle wow>/
  Interface/AddOns/
    aux-addon/            # AH replacement complexo (referência arquitetura)
    myAddOns/             # AddOn manager (toc 11200, xml+lua)
    Roid-Macros/          # macros com condicionais TBC no 1.12 (referência boa)
    RogueSpam/            # addon MINIMALISTA ideal p/ copiar padrão (toc 11100 mas funciona)
    SuperAPI/             # companion do mod SuperWoW, checa SUPERWOW_VERSION
    UnitXP_SP3_Addon/
    ShaguTweaks/, ShaguPlates/, pfQuest/, pfQuest-turtle/
    Bagnon/, Bagnon_Core/, Postal/, ItemRack/, SuperMacro/
    Turtle_General/, Turtle_GroupUI/, Turtle-Dragonflight/
    Blizzard_AuctionUI/ ... (arquivos .pub)
  WTF/Account/THEADRILL/Basin of Stars/<Char>/ # 9 chars: Elanah, Garthanna, Krasin, Rajabarti, Selynian, Theadrill, Thuranna, Torvanna, Verren
  WTF/Account/THEADRILL/SavedVariables/ # SavedVariables globais
```

## 3. Padrão Addon 1.12 (obrigatório seguir)

`.toc` exemplo (`Roid-Macros.toc`, `aux-addon.toc`, `myAddOns.toc`):
```
## Interface: 11200
## Title: Nome
## Notes: ...
## SavedVariables: MinhaVarGlobal
## OptionalDeps: ...
## RequiredDeps:
Arquivo.xml
Arquivo.lua
Outro.lua
```

* Ordem no `.toc` importa — carrega sequencial.
* `RogueSpam.xml` + `RogueSpam.lua` = modelo mais simples: `SlashCmdList`, `DEFAULT_CHAT_FRAME:AddMessage`, filtro de `ERR_*`.
* `myAddOns.toc` usa `Localization.lua` + `myGameMenuButtonAddOns.xml` + `myAddOnsFrame.xml`.
* `Roid-Macros` usa `Widgets.xml`, `Core.lua` com `Roids = _G.Roids or {}` para não poluir global, `ChatFrameEditBox:SetText + ChatEdit_SendText`.
* `aux-addon` usa `libs/package.lua`, `libs/T.lua`, `libs/ChatThrottleLib.lua` — padrão p/ addons grandes.

## 4. Restrições Lua 5.0 (NÃO usar sintaxe moderna)

* NÃO usar: `require`, `goto`, `//`, `& | ~ >> <<`, `#t` p/ tudo, `gmatch` (usar `string.gfind` / `strfind`), `pairs` com `__pairs`, `table.unpack` (usar `unpack`), bitwise, `continue`.
* USAR: `table.getn(t)`, `table.foreach`, `getglobal("Nome"..i)`, `this`, `event`, `arg1...`, `string.gfind`, `gsub`, `strfind(s, "item:(%d+)")`.
* Globals do WoW 1.12: `DEFAULT_CHAT_FRAME`, `UIParent`, `SlashCmdList["NOME"]`, `SLASH_NOME1 = "/cmd"`, `CreateFrame("Frame",...)`, `getglobal`, `UnitName("player")`, etc.
* `this` e `event` são implícitos em scripts XML (`OnEvent`, `OnLoad`).

## 5. API estendida Turtle / SuperWoW (quando permitido)

* `SuperAPI/SuperAPI.lua` começa com:
  ```lua
  if not SUPERWOW_VERSION then DEFAULT_CHAT_FRAME:AddMessage("No SuperWoW detected"); return end
  ```
* Fornece: `SetMouseoverUnit(unit)`, `SpellInfo(id)`, `GetSpellName`, links `enchant:ID`, charges em bags, `SUPERAPI_ContainerItemsTable`, hooks em `SetItemRef`, `SpellButton_OnClick`, `UnitFrame_OnEnter/OnLeave`.
* `README SuperAPI`: autoloot, clickthrough, FoV, GUID no combat log, bubbles.
* `Roid-Macros`: condicionais estilo TBC (`Conditionals.lua`, `ExtensionsManager.lua`, `Extensions/Mouseover/*`, `Extensions/Tooltip/*`).
* Regra: perguntar sempre — **1.12 puro ou pode usar SuperWoW/UnitXP?** Se puro, NÃO chamar `SUPERWOW_VERSION`, `SetMouseoverUnit`, `SpellInfo`, etc.

## 6. Como trabalhar (instrução para IA)

1. Nunca assumir Retail API (`C_`, `Mixin`, `BackdropTemplate`, `UIDropDownMenu` novo). Sempre estilo 1.12.
2. Antes de editar, ler `.toc` do addon alvo para saber ordem de load.
3. Para addon novo: criar pasta `Interface/AddOns/MeuAddon/` com `MeuAddon.toc (11200)` + `MeuAddon.lua` (+ `.xml` só se precisar de frames).
4. Testar mentalmente em Lua 5.0. Se usar função nova, avisar que quebra em 1.12.
5. SavedVariables: declarar no `.toc`, debugar em `WTF/Account/THEADRILL/.../SavedVariables.lua`.
6. Não re-listar `Interface/AddOns` do zero — usar lista da seção 2 a menos que o usuário peça.

## 7. Próximo ajuste (preencher a cada tarefa)

* **Addon alvo:** (ex: `RogueSpam` / novo `MeuAddon`)
* **Modo:** [ ] 1.12 puro / [ ] pode usar SuperWoW
* **Objetivo:** descrever aqui

---
> [!CAUTION]
> ## REGRAS FINAIS — RECONFIRMAR NO FIM
> 1. **NÃO FAZER PUSH ENQUANTO O USUÁRIO NÃO PEDIR.** Quando pedir, fazer push **UMA VEZ SÓ** e aguardar o próximo pedido explícito para fazer push de novo.
> 2. **WoW VERSÃO 1.12.1 (Interface 11200) / Lua 5.0** — manter compatibilidade total.
> 3. **AVISO DE SEGURANÇA DO WOW:** NÃO usar comandos que possam flagar a segurança do WoW. Comando / função que só é permitido pela UI do WoW deve continuar desabilitado para automação — NÃO reabilitar, NÃO bypassear proteção, NÃO automatizar cast / movimento / input.
