> [!CAUTION]
> ## REGRAS PRINCIPAIS — LEITURA OBRIGATÓRIA ANTES DE QUALQUER AÇÃO
> 1. **NÃO FAZER PUSH ENQUANTO O USUÁRIO NÃO PEDIR.** Quando pedir, fazer push **UMA VEZ SÓ** e aguardar o próximo pedido explícito para fazer push de novo. Nunca fazer push automático, em sequência ou por conta própria.
> 2. **WoW VERSÃO 1.12.1 (Interface 11200) / Lua 5.0** — todo código deve ser compatível com isso. Nada de sintaxe Retail / Lua 5.1+.
> 3. **AVISO DE SEGURANÇA DO WOW:** NÃO usar / NÃO sugerir comandos, funções ou truques que possam ser flagados pelo anti-cheat / Warden (automação de input, unlock, bots, desabilitar proteção, chamar função protegida que só é permitida pela UI do WoW em combate, `CastSpellByName` automatizado, etc.). Função protegida / restrita à UI do WoW deve permanecer via UI — NÃO bypasse, NÃO desbloqueie.
> 4. **IDENTIDADE VISUAL:** Sempre manter a identidade visual do addon seguindo o MAIN MENU do WoW 1.12 — mesmo fundo, cores, fontes, layout, bordas, texturas, botões e estilo Vanilla. Nada de visual Retail / moderno / custom fora do padrão. Reutilizar templates e assets do MAIN MENU sempre que possível.
> 5. **TOOLCHAIN LUA 5.0 (checagem imediata após ler este arquivo):** verificar na máquina atual se o validador é o Lua 5.0 de verdade (`C:\Tools\lua50\luac50.exe -v` deve responder `Lua 5.0.3`). Se `luac -v` responder 5.1/5.2/5.3/5.4, NÃO validar nada com ele (ele aceita `#t`, `//`, `goto`, bitwise — tudo que quebra no 1.12). Baixar o repo privado [lua-5.0](https://github.com/Theadrill/lua-5.0) (release `v5.0.3-win64-tcc`), extrair `lua50.exe`/`luac50.exe` para `C:\Tools\lua50`, remover o Lua posterior do PATH e registrar `LUAC`/`LUAC50` apontando para `C:\Tools\lua50\luac50.exe`. Se não conseguir verificar sozinho, PERGUNTAR ao usuário antes de seguir.

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
  VanillaHelpers.dll
  ClassicAPI.dll
  ```
  Isso significa: API estendida além do 1.12 puro. Sempre considerar SuperWoW + UnitXP + VanillaHelpers + ClassicAPI.
* **WoWTranslate.dll — ESCOPO LIMITADO (regra):** traduz **APENAS mensagens do CHAT** quando jogando no servidor chinês (Capycraft). **NÃO traduz NADA do cliente** (nomes de itens/magias/talentos/NPCs/zonas, tooltips, UI). **NÃO DEPENDER DE WOWTRANSLATE para nada** — todo texto exibido pelo addon deve vir do nosso sistema de localização (`CM:T()` + packs) ou da API do jogo em inglês.

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

## 4b. Toolchain Lua 5.0 — validador verdadeiro (OBRIGATÓRIO antes de validar qualquer `.lua`)

* O `luac` que vem no PATH (Lua 5.4.x) **NÃO serve**: ele passa silencioso em `#t`, `//`, `goto`, `& | ~ >> <<` — tudo que quebra no cliente 1.12. Prova real: `luac 5.4 -p` aprova `local n = #t`; o 5.0 rejeita com `unexpected symbol near '#'`.
* Validador oficial: `C:\Tools\lua50\luac50.exe -p <arquivo>` (Lua 5.0.3, exit 0 = OK). Variáveis de ambiente `LUAC`/`LUAC50` apontam para ele.
* Se a máquina atual NÃO tem `C:\Tools\lua50\luac50.exe`: baixar o repo privado [Theadrill/lua-5.0](https://github.com/Theadrill/lua-5.0) (release `v5.0.3-win64-tcc` → `lua-5.0.3-win64-tcc.zip`), extrair para `C:\Tools\lua50`, remover o Lua posterior do PATH e registrar `LUAC`/`LUAC50`. Rebuild reproduzível: `tools\build-win-tcc.ps1` dentro do repo. Se não der para resolver sozinho, PERGUNTAR ao usuário qual `luac` usar — nunca validar com 5.1+ em silêncio.

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

## 8. Integração com CapycraftDB (Banco de Dados Offline & ETL)

* **Repositório Irmão:** [CapycraftDB](https://github.com/Theadrill/CapycraftDB) (geralmente localizado na pasta irmã `../CapycraftDB`, ex.: `C:\PROJETOS\CapycraftDB`).
* **Papel do CapycraftDB:** É o Data Lake e compilador ETL offline (em Python) que extrai dados oficiais do Turtle WoW 1.18.1 (`db.capycraft.org`) e compila para arquivos Lua 5.0 leves e otimizados para o `ConsoleModeVanilla`.
* **Arquivos Entregues ao Addon (em `ConsoleModeVanilla/Data/`):**
  * `Data/CityServicesDB.lua`: Tabela `ConsoleMode_CityServices` com todos os serviços e NPCs legítimos das capitais (Ironforge, Stormwind, Orgrimmar, Undercity), com coordenadas exatas (0-100) do mapa da cidade e categorias (`BANK`, `AUCTION`, `FLIGHT`, `INN`, `PROF_*`, `TRAINER_*`).
  * `Data/NPCs/`: `NPC_Core.lua` (API rápida `ConsoleMode:GetNPCData(id)`), `NPC_Data_Kalimdor.lua`, `NPC_Data_EasternKingdoms.lua`, `NPC_Data_CustomTurtle.lua`.
  * `Data/Locales/ptBR/NPC.lua`: Dicionário oficial Blizzlike pt-BR por ID de NPC consumido por `ConsoleMode:GetNPCDisplayName(id, enUS)` e `ConsoleMode:GetNPCRole(id, enUS)`.
* **Consumo na UI (`UI/MainMenu.lua`):**
  * Na função `MainMenu:UpdateNPCServicePins(mapCanvas)`: **Zero dependência de `pfDB`/`pfQuest` nas capitais**. O mapa detecta a cidade via `cityKey` e plota até 200 pins de serviços e até 160 botões interativos na lista lateral (`npcListPanel`) com scroll dinâmico, highlight 3x ao hover e centralização de câmera ao clique.
* **Fluxo de Atualização entre Máquinas:**
  * O cache bruto com 84.152 arquivos JSON do CapycraftDB está salvo no GitHub Release `v1.0-cache` do repositório `CapycraftDB`.
  * Ao clonar em uma máquina nova: basta rodar `python tools/download_cache.py` dentro da pasta `CapycraftDB` para restaurar todo o data lake offline, e `python tools/export_to_addon.py` caso queira recompilar e injetar novas versões no `ConsoleModeVanilla`.

---

> [!CAUTION]
> ## REGRAS FINAIS — RECONFIRMAR NO FIM
> 1. **NÃO FAZER PUSH ENQUANTO O USUÁRIO NÃO PEDIR.** Quando pedir, fazer push **UMA VEZ SÓ** e aguardar o próximo pedido explícito para fazer push de novo.
> 2. **WoW VERSÃO 1.12.1 (Interface 11200) / Lua 5.0** — manter compatibilidade total.
> 3. **AVISO DE SEGURANÇA DO WOW:** NÃO usar comandos que possam flagar a segurança do WoW. Comando / função que só é permitido pela UI do WoW deve continuar desabilitado para automação — NÃO reabilitar, NÃO bypassear proteção, NÃO automatizar cast / movimento / input.

---

## CONVERSA INICIAL PARA NÃO PRECISAR FICAR DIGITANDO TUDO DE NOVO

> Cole este bloco no início de qualquer nova conversa para restaurar o contexto completo sem precisar redescobrir nada.
> O plano/documento da sessão é sempre apontado no prompt — nunca está fixo aqui.

**Prompt de abertura:**
> "Estamos trabalhando no addon de WoW. Leia `AI_CONTEXTO_ADDON_1.12.md` para entender o addon e fixar as regras na memória. Depois leia o plano/documento indicado neste prompt para ter o contexto da frente de trabalho atual. Apresente o que entendeu e aguarde."

---

### O que a IA deve entender ao ler este arquivo (+ o plano apontado no prompt)

#### O Addon
**ConsoleModeVanilla** — interface de console/gamepad para WoW 1.12.1 (Turtle WoW). Lua 5.0 estrito, identidade visual do Main Menu Vanilla, sem API Retail.

#### Feature de Mail (concluída)
Tela de correio completa (`UI/MailScreen.lua`) com inbox + painel de detalhe, tela de composição com inventário lateral, VirtualKeyboard desacoplado (`UI/VirtualKeyboard.lua`) com autocomplete, seletor de dinheiro estilo "alarme" (reels por dígito), fila serializada por eventos.

#### Refatoração Missões & Mapa (100% CONCLUÍDA E HOMOLOGADA)
- **Fase 1 (Modal de Leitura):** Leitura nobre em pergaminho (`questDetailOverlay`), botões `[X] Rastrear` e `[B] Sair`, abandono seguro com `[Y]` (`StaticPopup_Show`).
- **Fase 2 (Pool Fixo):** Pools pré-alocados para Zonas (32) e NPCs (24), eliminação completa de `buttons = {}` e zero garbage collection em runtime.
- **Fase 3 (Navegação Espacial):** D-Pad direcional fluido `QMISSOES ⇄ QNAV ⇄ QNPCS`.
- **Fase 4 (Seleção de Zonas/Instâncias):** Suporte completo à sub-zona `QZONAS` com níveis `(min-max)` e instâncias contextuais.
- **Fase 5 (Mecânicas de Mapa & Regressão):** L-Stick pan livre contínuo, zoom via gatilhos `[LT]/[RT]`, sublinhado dourado estável, auto-foco preservado e inter-abas 100% sincronizado.

#### Tela de Configurações & Sistema (`SYSTEM`) — histórico
- **Sub-Aba 1: MENU DO JOGO (`GAME_MENU`):** Opções clássicas do cliente WoW (Vídeo, Áudio, Interface, Macros, Atalhos, Ajuda, Logout, Sair) + botões de Addons de terceiros com ícones temáticos, DetailCard descritivo e disparo seguro de janelas Blizzard.
- **Sub-Aba 2: CONFIGURAÇÕES DO ADDON (`ADDON_CFG`):** Central de ajustes do ConsoleMode com widgets interativos D-Pad: Toggles com `[A]`, Sliders com `[LEFT/RIGHT]`, Botões de Ação, e Mapeador de Binds integrado (`SYS_BINDS`).
- **Roteador D-Pad (`MainMenuNav.lua`):** Zonas `SYS_SUBTABS`, `SYS_GAMEMENU`, `SYS_ADDONCFG`, `SYS_BINDS`, alternância rápida via `[LT]/[RT]`.

#### Regras inegociáveis (resumo executivo)
1. **PUSH SOMENTE quando o usuário pedir, uma vez só. É a regra mais importante.**
2. Lua 5.0 estrito — proibido `#t`, `continue`, `goto`, `table.unpack`, `gmatch`, bitwise.
3. API WoW 1.12 puro — nada de `C_`, `Mixin`, `BackdropTemplate`.
4. `luac50 -p` (`C:\Tools\lua50\luac50.exe`, Lua 5.0.3 real — NUNCA o 5.4 do PATH) em todo arquivo alterado — zero erros antes de qualquer teste.
5. Zero taint — nenhuma função protegida chamada de dentro de stack de input do gamepad.
6. Pool fixo — frames criados uma vez no `CreateUI`, nunca destruídos.
7. Identidade visual Vanilla intocável.
8. Mecânicas do mapa intocáveis — L-Stick pan, LT/RT zoom, auto-scroll cancela ao mover analógico.
9. Parada obrigatória ao fim de cada fase para `/reload` e validação no jogo antes de commit.
10. **NÃO DEPENDER DE WOWTRANSLATE para nada** — ele só traduz o chat no servidor chinês; o cliente é 100% inglês. Todo PT visível sem o Localization instalado é bug nosso (string hardcoded ou tabela sem chave).

#### Modo de operação
A IA atua como **tech leader**: não coda diretamente, **orquestra agentes** (senior programmers). Ao fim de cada fase, valida o trabalho dos agentes e passa ao usuário o que é esperado acontecer no jogo para ele validar. Sem commit, sem push antes da aprovação.
