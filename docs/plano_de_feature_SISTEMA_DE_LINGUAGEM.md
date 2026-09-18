# Plano de Feature: SISTEMA DE LINGUAGEM (LOCALIZAÇÃO MODULAR POR ARQUIVO) NO CONSOLEMODE

> [!CAUTION]
> **REGRAS MANDATÓRIAS DE CONTROLE DE VERSÃO E GIT (CRÍTICO):**
> 1. **PROIBIDO QUALQUER PUSH AUTOMÁTICO:** NUNCA executar `git push` sem que o usuário dê a ordem explícita no chat.
> 2. **PROCESSO UNITÁRIO DE PUSH:** Quando o usuário autorizar ou ordenar um push, a IA deve realizar **apenas um único push** da etapa aprovada e **aguardar novas instruções** antes de realizar qualquer outra ação.
> 3. **PARADA OBRIGATÓRIA ENTRE FASES:** Ao término de cada fase, a IA deve parar imediatamente, reportar o que foi implementado e fornecer as instruções exatas de teste no jogo (`/reload`). Nenhuma linha de código da fase subsequente pode ser escrita sem o "OK" explícito do usuário.

> [!IMPORTANT]
> **ESPECIFICAÇÕES TÉCNICAS DA PLATAFORMA & DIRETRIZ ARQUITETURAL:**
> - **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Build 5875) / Turtle WoW.
> - **Versão da Linguagem Lua:** **Lua 5.0** estrito (FrameXML clássico de 2004).
>   - **PROIBIDO** o uso do operador `#table` de Lua 5.1+ (usar `table.getn(t)` ou `getn(t)`).
>   - **PROIBIDO** o uso de `continue`, `goto`, `unpack`/`table.unpack`, `gmatch` (usar `string.gfind` / `strfind`).
>   - **PROIBIDO** bitwise (`& | ~ >> <<`, `//`), `__pairs`, `require`, `Mixin`.
>   - Toda alteração deve ser validada no compilador de sintaxe (`luac -p`) antes de qualquer teste.
> - **API 1.12 PURA:** nada de `C_`, `BackdropTemplate`, `UIDropDownMenu` novo. `GetLocale()` existe na 1.12 e pode ser usado só como default inicial — a troca runtime é via SavedVariables própria.
> - **TEXTURAS 1.12:** flags somente em **TGA ou BLP**, dimensões **potência de 2** (ex. 32x32, 64x32). TGA 32-bit com alpha; caminho sempre com `\\` no `.toc`/`SetTexture` (ex. `Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_ptBR.tga`).
> - **DOCUMENTO APENAS — NENHUM CÓDIGO NESTA TAREFA:** proibido criar/editar `.lua`/`.xml`/`.toc`/`.tga` neste plano. Só este `.md`.

---

## 1. Visão Geral da Feature (nova arquitetura decidida)

Hoje o addon inteiro está com **textos hardcoded em PT** espalhados por `UI/*.lua` (`SetText(`, `AddMessage(`, tabelas `CFG.Tabs`, `MAIL_FILTERS`, hints de controle, títulos de cards). Não há nenhum sistema de locale (confirmado por varredura: único `GetLocale()` é uso pontual em `UI/MainMenu.lua:10306`, sem relação com UI do addon).

A nova arquitetura é **modular por idioma, dirigida por registro**:

1. **`Data/Localization/` (pasta nova) — um arquivo por idioma:** ex. `localization_ptBR.lua`, `localization_enUS.lua`. Cada arquivo registra **um único id** em `CM_Langs[id]` com `name`, `flag` e `strings={...}`. Cada idioma tem **sua textura de flag**: ex. `flag_ptBR.tga` ao lado do `.lua`.
2. **`Data/Localization.lua` (registro global + loader):** declara os idiomas disponíveis (id, nome, arquivo, flag), carrega na ordem certa via `.toc` e expõe a **tabela ativa de strings para o addon inteiro** (`ConsoleMode.L` + `CM:T("KEY")` com fallback). **Adicionar idioma novo = dropar 2 arquivos + 1 linha de registro** — qualquer pessoa contribui sem tocar no core.
3. **ptBR primeiro (estado atual), enUS em seguida.** O ptBR é a base completa (todas as chaves). O enUS traduz chave a chave.
4. **PASSO FINAL do plano = inclusão de mais linguagens:** template `localization_TEMPLATE.lua` + doc de como contribuir (qualquer idioma futuro segue o mesmo molde de 2 arquivos + 1 linha).

```
+==================================================================+
|            SISTEMA DE LINGUAGEM MODULAR (CM_Langs)                |
+==================================================================+
|  UI/*.lua  ----CM:T("TAB_BAGS")---->  Data/Localization.lua      |
|   (sem texto hardcoded)                (REGISTRO + LOADER)        |
|                                        CM_Langs{"ptBR","enUS",...}|
|                                        ConsoleMode.L = ativa     |
|                                             ^                    |
|                                             |                    |
|                          Data/Localization/localization_*.lua     |
|                          ptBR = base completa | enUS = override   |
|                          + flag_ptBR.tga / flag_enUS.tga          |
|  Fallback: idioma ativo ausente -> ptBR -> "CHAVE_CRUA" (nunca   |
|  nil, nunca erro de Lua)                                         |
|  Troca: ConsoleModeDB.lang (só o id) + /cm lang + picker c/flags |
|  Novo idioma = 2 arquivos novos + 1 linha no registro            |
+==================================================================+
```

**Fora de escopo:** traduzir `Data/QuestDB_ptBR.lua` (conteúdo de jogo, auto-gerado), tooltips nativas da Blizzard, nomes de talentos/magias vindos do cliente. Só strings **do addon**. Exceções deliberadas (levantadas em auditoria 100% dos arquivos): `UI/QuestItemDistributor.lua` (só `QLog`/`QDebug` internos + termos de matching de nome de item + labels internas de slot — zero texto de UI), `Logger.lua` (logs de debug com prefixo, fora da UI), `UI/BagSplit.lua` (sem nenhum `SetText`/`AddMessage`), `Bindings.xml` + `UI/MainMenu.xml` (sem texto estático), `ConsoleModeVanilla.toc` (Title/Notes da lista de addons, padrão em inglês).

---

## 2. Análise Tech-Lead (curta)

### 2.1 Prós da arquitetura por arquivo + registro

| Pró | Por quê importa |
| :--- | :--- |
| **Contribuição sem conflito** | Cada idioma é um arquivo isolado (`localization_xxYY.lua`). Dois tradutores de idiomas diferentes nunca editam o mesmo arquivo — merge limpo. O core (`Data/Localization.lua`, `Core.lua`, `UI/*`) não é tocado para adicionar idioma. |
| **Picker com flags** | Como cada entrada do registro já carrega `flag="...flag_xxYY.tga"`, o picker visual lista idiomas com ícone sem lógica ad-hoc por idioma. Idioma sem flag válida cai para ícone fallback (ver riscos). |
| **Fallback isolado por arquivo** | `CM:T(key)` resolve em 2 níveis (ativo → ptBR → chave crua) sem precisar que cada arquivo de idioma conheça os outros. Arquivo incompleto nunca quebra o addon — só exibe PT onde faltar tradução. |

### 2.2 Riscos + mitigação

| # | Risco | Mitigação |
| :--- | :--- | :--- |
| 1 | **Paridade de chaves entre arquivos** — enUS (ou futuro `xxYY`) esquece uma chave e o fallback mascara o problema silenciosamente. | **Script/harness validador de chaves ausentes** (Fase 6): ferramenta fora do jogo (`tools/` ou Lua 5.0 standalone) que carrega `localization_ptBR.lua` como referência e lista chaves ausentes/excedentes em cada idioma. Roda a cada fase de tradução; resultado anexado ao report de fase. |
| 2 | **Ordem de load no `.toc`** — se um `localization_*.lua` carregar antes do registro, `CM_Langs` é `nil` e dá erro no login. | **Registro ANTES dos arquivos de idioma, e todos ANTES de `UI/*`.** Ordem canônica no `.toc`: `Data\Localization.lua` → `Data\Localization\localization_ptBR.lua` → `Data\Localization\localization_enUS.lua` → ... → `UI\*`. Checklist de cada fase confere a ordem; `luac -p` + teste de login limpo (`/reload` sem erros) validam. |
| 3 | **Fallback precisa nunca retornar `nil`** — `SetText(nil)` quebra frame 1.12. | **Fallback ptBR → chave crua.** `CM:T(key)` retorna `strings[lang][key]`, senão `strings["ptBR"][key]`, senão a própria `key` como string. Nunca `nil`. Teste de fumaça da Fase 1 remove uma chave propositalmente (ambiente de teste) e confirma. |
| 4 | **Textura da flag pode não existir / path errado / dimensão inválida** — ícone verde/quadrado vazio no picker. | **Textura tem que existir senão ícone fallback.** Loader verifica `flag` de cada idioma; se o arquivo não existe, o picker usa textura fallback do addon (ex. `icon_outrange.tga` existente ou `Interface\\Icons\\INV_Misc_QuestionMark`). Convenção: TGA 32-bit, potência de 2 (32x32 ou 64x32), mesmo nome-base do lua. |
| 5 | **SavedVariables guarda estrutura errada** — salvar a tabela inteira de strings estoura o `.lua` salvo e dessincroniza. | **SavedVariables guarda só o id do idioma.** `ConsoleModeDB.lang = "ptBR"` (string curta). `ConsoleModeDB` já é SavedVariables global da conta no `.toc` — correto, pois idioma é preferência de conta/máquina (Steam Deck), não por personagem. Ler sempre com `ConsoleModeDB = ConsoleModeDB or {}` + default via `GetLocale()` no primeiro login. |
| 6 | **Acentos UTF-8 corrompidos** — um byte errado no arquivo do idioma quebra a exibição de todas as suas strings. | Salvar sempre **UTF-8 sem BOM**; revisar enUS (sem acento) primeiro no `/reload`; repo já usa `ç ã õ é` hardcoded sem problema — manter o mesmo encoding nos novos arquivos. |

---

## 3. Convenção (nomes, tabela, chaves, formatos, cores)

### 3.1 Nome de arquivo / id de idioma / flag

- **Id do idioma:** código estilo `GetLocale()`, case-sensitive: `ptBR`, `enUS`, `esES`, `deDE`, `frFR`... Idiomas inventados para teste seguem o mesmo formato (`xxYY`).
- **Arquivo de strings:** `Data/Localization/localization_<id>.lua` — ex. `Data/Localization/localization_ptBR.lua`.
- **Arquivo de flag:** `Data/Localization/flag_<id>.tga` — ex. `Data/Localization/flag_ptBR.tga`. Formato **TGA (32-bit com alpha) ou BLP**, dimensões **potência de 2** (recomendado 32x32 ou 64x32). O `.tga` **não** entra no `.toc` (só `.lua` entra); é referenciado pelo path na tabela.
- **Registro (1 linha por idioma)** em `Data/Localization.lua`, ex.:
  ```lua
  CM_RegisterLang("ptBR", "Data\\Localization\\localization_ptBR.lua", "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_ptBR.tga");
  -- ou entrada equivalente em tabela CM_LANG_ORDER / CM_LangsMeta
  ```
  (Forma exata da API de registro é definida na Fase 1; o contrato é: **id + path do lua + path da flag**.)

### 3.2 Formato da tabela em cada arquivo de idioma

Cada arquivo preenche **uma única entrada**, sem tocar nas outras:

```lua
-- Data/Localization/localization_ptBR.lua
CM_Langs = CM_Langs or {};
CM_Langs["ptBR"] = {
  name = "Português (Brasil)",
  flag = "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_ptBR.tga",
  strings = {
    TAB_BAGS = "Bolsas & Itens",
    CHAR_HIT_FMT = "Acerto (Hit): +%s%%",
    -- ... todas as chaves (ptBR = base completa)
  },
};
```

```lua
-- Data/Localization/localization_enUS.lua
CM_Langs = CM_Langs or {};
CM_Langs["enUS"] = {
  name = "English (US)",
  flag = "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_enUS.tga",
  strings = {
    TAB_BAGS = "Bags & Items",
    CHAR_HIT_FMT = "Hit: +%s%%",
    -- ... mesmas chaves do ptBR, traduzidas
  },
};
```

Regras do arquivo:
1. **Um arquivo = um id.** Nunca declarar dois idiomas no mesmo arquivo; nunca editar o arquivo de outro idioma para adicionar o seu.
2. **`name`** = nome de exibição no picker e no `/cm lang` (pode ter acento/UTF-8).
3. **`flag`** = path completo da textura (string; loader resolve fallback se ausente).
4. **`strings`** = tabela plana `CHAVE = "texto"`. Sem nesting, sem metatables (Lua 5.0 simples, iterável pelo validador).
5. **Acesso sempre via `CM:T("CHAVE")`** no código (`ConsoleMode.L` é a tabela ativa resolvida no login). Nunca indexar `CM_Langs[id].strings` direto em `UI/*`.

### 3.3 Chaves (`TAB_BAGS`, `CHAR_*`...)

Formato: `MODULO_ASSUNTO_DETALHE`, MAIÚSCULAS, `_` como separador, sem acento na chave (acento só no valor).

| Prefixo | Dono | Exemplos |
| :--- | :--- | :--- |
| `TAB_*` | Abas do MainMenu | `TAB_BAGS="Bolsas & Itens"`, `TAB_CHARACTER="Personagem"`, `TAB_SPELLS="Livro de Magias"` |
| `SLOT_*` | Slots de equipamento | `SLOT_HEAD="CABEÇA"`, `SLOT_MAINHAND="MÃO DIR."` |
| `CHAR_*` | Cards da ficha | `CHAR_MELEE_TITLE`, `CHAR_HIT_FMT="Acerto (Hit): +%s%%"`, `CHAR_NO_PROF="Sem profissões"` |
| `MAIL_*` / `MERCH_*` / `VK_*` | Mail / Merchant / Teclado | `MAIL_TITLE="CORREIO"`, `MERCH_FILTER_ALL="Todos"`, `VK_BACKSPACE="APAGAR"` |
| `QTY_*` / `CTX_*` / `BIND_*` / `SYS_*` | Satélites + SYSTEM | `QTY_TITLE="Quantidade"`, `CTX_USE_EQUIP="Usar / Equipar"`, `SYS_VIDEO="Opções de Vídeo"` |
| `SPBOOK_*` / `BAGPK_*` / `MACPK_*` / `ABPK_*` | Pickers (Fase 4) | `SPBOOK_TITLE`, `BAGPK_TITLE`, `MACPK_TITLE`, `ABPK_TITLE` |
| `CFG_*` / `HUD_*` | ConfigFrame + HUD (Fase 4) | `CFG_TITLE`, `HUD_XP_RESTED` |
| `HINT_*` / `BTN_*` / `MSG_*` / `LANG_*` | Hints, botões, chat, picker (+ `Cursor`/`Hooks`/`Keybindings`/`Core` na Fase 4) | `HINT_CONFIRM="confirmar"`, `BTN_CLOSE="Sair"`, `MSG_LOADED_FMT`, `LANG_TITLE="Idioma / Language"` |

### 3.4 `format`, cores, UTF-8

1. **`format` com `%d`/`%s`, fora da tabela:** a tabela guarda o molde (`CHAR_XP_FMT="XP: %d/%d (%d%% descansado)"`), o código faz `format(CM:T("CHAR_XP_FMT"), cur, max, rested)`. Nunca `..` para montar frase traduzível. `%%` para `%` literal. Ordem de `%s/%d` pode mudar entre idiomas — ajustar os args na chamada ou criar chave `_FMT` separada; **não** contar com posicional (`%1$s` não é garantido na 1.12/Lua 5.0).
2. **Cores `|cff` dentro das strings:** `CHAR_HONOR_TITLE="|cffc03028HONRA & JXJ (PVP)|r"`. Código nunca concatena `|cff` solto — só `SetText(CM:T("..."))`. Prefixo de chat `|cff00ff00[ConsoleMode]|r` pode ficar no código; o texto após o prefixo vai na tabela.
3. **Plurais:** sem engine automática. Duas chaves quando o idioma exige: `MAIL_ITEM_ONE="%d item"` / `MAIL_ITEM_MANY="%d itens"` (enUS: `"%d item"` / `"%d items"`), com `if n==1` no código.
4. **Nomes do jogo nunca na tabela:** `UnitName`, nomes de item/magia/guilda, `"Nv "..level` — concatenados no código, fora do `CM:T`.
5. **UTF-8 sem BOM** em todos os arquivos de idioma; acento só no valor, nunca na chave.
6. **Uma chave = um conceito:** não reutilizar `BTN_CLOSE="Sair"` onde o sentido é outro (ex. `"Fechar"` do merchant vira `MERCH_CLOSE`, mesmo que hoje o texto coincida).

---

## 4. Cronograma de Fases TESTÁVEIS Passo a Passo

Cada fase gera um entregável **100% testável no jogo via `/reload`**. A IA **NÃO** avança para a fase seguinte sem a validação e autorização do usuário.

---

### 🟢 FASE 1: Registro + loader + fallback + `/cm lang` (lista do registro)
> **Objetivo observável:** Após `/reload`, o jogador digita `/cm lang` e vê a **lista de idiomas vinda do registro** (`ptBR` nesta fase); troca com `/cm lang ptBR`, dá `/reload` e o comando confirma a persistência. Nenhum texto de UI muda ainda — só a infra funciona, sem quebrar nada.

- [ ] Criar `Data/Localization.lua` (registro + loader): tabela `CM_Langs`, ordem `CM_LANG_ORDER`, função `CM:T(key)` com fallback (ativo → ptBR → chave crua, nunca `nil`), resolução de `ConsoleMode.L` no login.
- [ ] Criar `Data/Localization/localization_ptBR.lua` com **~30 chaves-piloto** (`TAB_*`, `BTN_CLOSE`, `HINT_*`, `MSG_LOADED_FMT`, `LANG_*`) + `flag_ptBR.tga` (TGA 32-bit, potência de 2) ao lado.
- [ ] Registrar no `.toc` na ordem canônica: `Data\Localization.lua` **ANTES** de `Data\Localization\localization_ptBR.lua`, ambos **ANTES** de `UI\*`.
- [ ] Inicializar `ConsoleModeDB.lang` (só o id) em `VARIABLES_LOADED` (default inicial via `GetLocale()`); implementar `/cm lang [id]` (sem arg = mostra ativo + lista do registro; com arg válido = salva + pede `/reload`; arg inválido = lista opções do registro, não lista hardcoded).
- [ ] Converter **só 2–3 strings de fumaça** (ex. mensagem `v... carregado.` do `Core.lua`) para provar o caminho; resto continua hardcoded.
- [ ] Validar sintaxe com `luac -p` em todos os arquivos tocados; validar que a flag aparece (ou fallback, se a TGA ainda não existir).
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):** jogador roda `/cm lang`, `/cm lang ptBR`, `/reload`, `/cm lang` de novo e confirma persistência + lista vinda do registro + zero erros de Lua. Sem "OK", Fase 2 não começa.

---

### 🟢 FASE 2: Extração ptBR — CharacterScreen (maior volume, módulo isolado)
> **Objetivo observável:** Aba Personagem abre normal após `/reload`, com **todos os cards em PT via `CM:T`** (visualmente idêntico a antes). Nenhum outro módulo muda.

- [ ] Catalogar todas as ~150 strings de `UI/CharacterScreen.lua` em chaves `CHAR_*` (ver §3.3); mover textos para `strings` de `localization_ptBR.lua` (ptBR segue como base completa deste módulo).
- [ ] Trocar cada `SetText("...")` por `SetText(CM:T("CHAR_..."))`; formatos viram `format(CM:T("CHAR_X_FMT"), ...)`; cores `|cff...|r` dentro do valor.
- [ ] Não tocar em `MainMenu/Mail/Merchant/VirtualKeyboard` nesta fase.
- [ ] Validar com `luac -p`; rodar validador de paridade (só ptBR existe — deve reportar zero ausências contra si mesmo).
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):** jogador compara a ficha com buff (ex. Grito de Batalha), equipa/desequipa arma e confirma números/cores/bônus idênticos ao pré-conversão, sem erros.

---

### 🟢 FASE 3: Extração ptBR — MainMenu (abas, slots, headers, DetailCard, SYSTEM)
> **Objetivo observável:** Menu principal abre com as 6 abas, slots de equipamento (`CABEÇA`…`ALCANCE`), headers (`STATUS`, `COMPARAÇÃO`, `BUFFS ATIVOS`) e DetailCard em PT via tabela; navegação `[LB]/[RB]` + D-Pad intacta.

- [ ] Chaves `TAB_*` (`TAB_BAGS`, `TAB_CHARACTER`, `TAB_TALENTS`, `TAB_SPELLS`, `TAB_QUESTS`, `TAB_SYSTEM`), `SLOT_*` (`SLOT_HEAD`, `SLOT_NECK`…), `SYS_*` (sub-abas `GAME_MENU`/`ADDON_CFG`, títulos `Opções de Vídeo/Som/Interface…`), `DETAIL_*`, `HINT_*` do footer → `localization_ptBR.lua`.
- [ ] Tabelas `CFG.Tabs.list`, `CFG.Equipment`, filtros (`Todos/Equipamentos/Consumíveis/Materiais/Diversos`) passam a referenciar `CM:T(...)` na construção.
- [ ] Validar com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):** jogador percorre as 6 abas via `[LB]/[RB]`, inspeciona item/buff/talento e confirma textos PT + zero regressão de navegação.

---

### 🟢 FASE 4: Extração ptBR — Mail + Merchant + VirtualKeyboard (+ satélites)
> **Objetivo observável:** Correio, loja do vendedor e teclado virtual operam 100% em PT via tabela: inbox/detalhe/envio, catálogo/filtros/compra-venda, teclas `APAGAR/OK/ESPAÇO` e hints; idem `QuantityPicker` (`Quantidade/Confirmar/Cancelar`), `ContextMenu` e `KeybindingsList`.

- [ ] Chaves `MAIL_*` (`MAIL_TITLE`, `MAIL_INBOX`, `MAIL_DETAIL`, `MAIL_EMPTY`, `MAIL_COMING_SOON`…), `MERCH_*` (`MERCH_TITLE`, `MERCH_FILTER_ALL/EQUIP/CONSUM/JUNK/BUYBACK`, `MERCH_BUY_ONCE`, `MERCH_QTY_SELL`…), `VK_*` (`VK_BACKSPACE`, `VK_OK`, `VK_SPACE`, `VK_HINT_INSERT/CLOSE/DELETE/CAPS/PAGE`…) → `localization_ptBR.lua`.
- [ ] Satélites no mesmo lote: `QTY_*`, `CTX_*`, `BIND_*` (evita varredura residual posterior). Mensagens `AddMessage` destes módulos via `CM:T`.
- [ ] Pickers no mesmo lote: `SpellbookPicker`, `BagPicker`, `MacroPicker`, `ActionBarPicker` (prefixos `SPBOOK_*`, `BAGPK_*`, `MACPK_*`, `ABPK_*`), `ConfigFrame` (`CFG_*`), frames de HUD (`XPBar`/`ActionHUD`/`PlayerFrame`/`TargetFrame`, prefixo `HUD_*`) e mensagens de `Cursor.lua`/`Hooks.lua`/`Keybindings.lua` (`MSG_*`).
- [ ] `Core.lua`: converter TODAS as mensagens `/cm` restantes (ajuda, status, debug, erros) para `MSG_*` — fecha 100% do addon (a Fase 1 converteu só as de fumaça).
- [ ] Varredura `rg 'SetText\(\s*"' UI Core.lua Keybindings.lua Cursor.lua Hooks.lua` deve retornar só exceções justificadas (texto do jogo, `""`, `" "`, números).
- [ ] Validar com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):** jogador recebe/envia carta, compra/vende item, digita nome no teclado virtual e confirma todos os textos PT sem erros.

---

### 🟢 FASE 5: Picker visual com flags + tradução enUS completa
> **Objetivo observável:** Com `/cm lang enUS` + `/reload`, **o addon inteiro aparece em inglês**; o **picker visual lista ptBR + enUS com as flags** (`flag_ptBR.tga`, `flag_enUS.tga`) e trocar por ele equivale ao comando. Voltar com `/cm lang ptBR` + `/reload` restaura o PT idêntico.

- [ ] Criar `Data/Localization/localization_enUS.lua` (mesmas chaves do ptBR, traduzidas — nenhuma chave só-ptBR restante) + `flag_enUS.tga` (TGA/BLP, potência de 2); adicionar **1 linha de registro** em `Data/Localization.lua` + 1 linha no `.toc` (após o ptBR, antes de `UI\*`).
- [ ] Revisar formatos: ordem de `%s/%d` pode mudar no inglês — ajustar args na chamada ou chaves `_FMT` separadas (sem posicional).
- [ ] Construir o **picker visual de idioma com flags**: lista iterada do registro (`CM_LANG_ORDER` + `CM_Langs[id].name/.flag`), ícone fallback se a TGA faltar, navegação por controle, seleção salva `ConsoleModeDB.lang` + pede `/reload`.
- [ ] **Botão-flag no header do MainMenu (requisito do usuário):** no canto superior esquerdo, na mesma linha do `MENU PRINCIPAL`, exibir a flag do idioma ativo (`CM_Langs[ativo].flag` + fallback); navegável por hover/controle e **clicável com o mouse** → abre o picker de idioma (mesma ação do picker da Fase 5). Tooltip/hint com o nome do idioma (`LANG_*`). Identidade Vanilla preservada (tamanho/discreto na linha do header).
- [ ] Validar com `luac -p` + validador de paridade ptBR↔enUS (zero ausências).
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):** jogador percorre os testes das Fases 2–4 nos dois idiomas (via comando E via picker), confirma flags visíveis e aprova a tradução (ou lista correções).

---

### 🟢 FASE 6: Validador de paridade + doc de contribuição
> **Objetivo observável:** O validador roda fora do jogo e aponta **zero chaves ausentes/excedentes** entre ptBR (referência) e enUS; o doc de contribuição existe e uma pessoa leiga consegue seguir sem tocar no core.

- [ ] Entregar o **script/harness validador de chaves ausentes** (ex. `tools/check_locales.lua` ou `.py`): carrega ptBR como referência, compara cada `localization_<id>.lua`, reporta `MISSING:` (no idioma, presente no ptBR) e `EXTRA:` (no idioma, ausente no ptBR). Funciona com N idiomas (não só 2).
- [ ] Teste de fumaça enUS com chaves propositalmente removidas (ambiente de teste) confirma fallback ptBR → chave crua sem `nil`.
- [ ] Escrever/atualizar o **doc de como contribuir** (seção neste plano + futuro `Data/Localization/README.md` ou `localization_TEMPLATE.lua` comentado): onde dropar os 2 arquivos, qual linha adicionar no registro/`.toc`, convenção de chaves, como rodar o validador.
- [ ] Congelar convenção: nenhuma string nova de UI sem chave (regra para PRs futuros).
- [ ] Validar com `luac -p` final.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 6):** jogador roda o validador (ver zero diffs), faz o tour completo nos dois idiomas e homologa o sistema + doc.

---

### 🟢 FASE 7: Tradução Integral do Conteúdo do Jogo (GamePT Master Architecture)
> **Objetivo observável:** Tradução completa e contextual em Português Brasileiro (ptBR) de todo o conteúdo exibido pelo ConsoleModeVanilla: Perícias/Idiomas, Talentos (nomes e descrições completas com ranks), Magias/Habilidades (Spellbook e pickers da barra de ação), Auras/Buffs e Termos de Itens/Tooltips.
>
> **Diretriz de Qualidade Inegociável:** Tradução contextual fluente com padrão de RPG brasileiro oficial (vocabulário Blizzard pt-BR), sem traduções mecânicas/robóticas.
>
> **Decisão Arquitetural do Tech Lead — Motor Híbrido em Camadas (Tiered Translation Engine):**
> Para contornar os limites rígidos do WoW 1.12.1 (Lua 5.0, 32-bit, limite de heap e risco de *Garbage Collector Stalls*) e garantir imunidade a patches de rebalanceamento do Turtle WoW (que alteram números e fórmulas mantendo a gramática base):
> 1. **Camada 1 (Dicionário Nominal O(1)):** Lookup exato para nomes próprios de perícias, talentos, magias e auras.
> 2. **Camada 2 (Templates Regex com Preservação de Valores):** Motor dinâmico que captura os valores numéricos reais (`%d+`, `[%d%.]+`) calculados pelo cliente/servidor e os injeta nos moldes sintáticos em português. Exemplo: *"Increases critical strike chance by 5%"* $\rightarrow$ extrai `5` e gera *"Aumenta a chance de acerto crítico em 5%"*. Se um patch alterar para 6%, a tradução reflete 6% instantaneamente sem necessidade de manutenção.
> 3. **Camada 3 (Tabela de Exceções Autorais):** Dicionário para habilidades narrativas ou mecânicas complexas que fogem aos padrões reutilizáveis.
> 4. **Camada 4 (Fallback Seguro):** Qualquer texto não mapeado permanece no original em inglês, garantindo **zero falhas de UI, zero telas em branco e zero taint no motor de combate**.

---

#### Status Atual de Execução da Fase 7
- [x] **Etapa 0 (Acessores Core & Validador):** Implementados em `Data/Localization.lua` (`GamePT_Skill`, `GamePT_Rank`, `GamePT_Spell`, `GamePT_Talent`, `GamePT_Buff`) e suporte no `tools/check_locales.py`. (Commit `8561471`).
- [x] **Bloco 1 (Perícias & Idiomas):** 102 entradas em `Data/Localization/localization_ptBR.lua` integradas visualmente em `UI/CharacterScreen.lua`. Testado no jogo, commitado e enviado ao repo remoto (`8561471`).
- [x] **Bloco 2 (Nomes de Talentos):** 1.280 entradas (432 coordenadas canônicas das 9 classes + 848 nomes nominais) em `localization_ptBR.lua` com fallback resiliente em `Data/Localization.lua` e renderização no `card.titleText` de `UI/MainMenu.lua`. Concluído e validado.

---

#### Roadmap da Tradução Integral do MainMenu (Fases 7.1 a 7.5)
> **Princípio Fundamental:** NENHUM texto em inglês deve restar dentro do MainMenu do ConsoleModeVanilla. Se aparece no MainMenu (seja descrição de magia, item na bag, talento ou atributo), deve ser 100% traduzido para o Português Brasileiro (ptBR).

```text
[Fase 7.1: Descrições Dinâmicas & Catálogo Base de Talentos] (Concluída)
       │
       ▼
[Fase 7.2: Motor Semântico de Valores, Preservação de Ranges & Requisitos] (Concluída)
       │
       ▼
[Fase 7.3: Grimório & Magias — Nomes, Graus, Atributos E DESCRIÇÕES COMPLETAS] (EM ANDAMENTO: Módulo de Descrições)
       │
       ▼
[Fase 7.4: Motor de Auras & Efeitos (Buffs / Debuffs)] (Preparada)
       │
       ▼
[Fase 7.5: Bolsas & Equipamentos — TUDO NA BAG (Nomes, Tipos, Stats, Uso, Equipar e Tooltips)]
```

---

#### Status Atual de Execução da Fase 7
- [x] **Etapa 0 (Acessores Core & Validador):** Implementados em `Data/Localization.lua` (`GamePT_Skill`, `GamePT_Rank`, `GamePT_Spell`, `GamePT_Talent`, `GamePT_Buff`) e suporte no `tools/check_locales.py`. (Commit `8561471`).
- [x] **Bloco 1 (Perícias & Idiomas):** 102 entradas em `Data/Localization/localization_ptBR.lua` integradas visualmente em `UI/CharacterScreen.lua`. Testado no jogo, commitado e enviado ao repo remoto (`8561471`).
- [x] **Bloco 2 (Nomes de Talentos):** 1.280 entradas (432 coordenadas canônicas das 9 classes + 848 nomes nominais) em `localization_ptBR.lua` com fallback resiliente em `Data/Localization.lua` e renderização no `card.titleText` de `UI/MainMenu.lua`. Concluído e validado.
- [x] **Fase 7.1 (Módulo 1 — Descrições Dinâmicas & Catálogo Base de Talentos):** Criação de `Data/TalentDescriptions_ptBR.lua` com catálogo base dos 460 talentos do cliente, agregação de linhas de quebra física de tooltips e modal de inspeção/comparação com [A]. Concluído (Commits `4a0d743` e `0ff81a0`).
- [x] **Fase 7.2 (Motor Semântico de Ranges & Coloração Fiel de Requisitos):** Implementação de `GamePT_ExtractNumbersWithRanges`, paridade estrita de placeholders, captura de cor nativa de requisitos via `GetTextColor()` e sincronização com Turtle WoW. Concluído e testado no jogo (Commit `f9f6f4d`).
- [x] **Fase 7.3B (Grimório — Motor de Descrições Dinâmicas de Feitiços):** Criação de `Data/SpellDescriptions_ptBR.lua` e `CM:GamePT_SpellDesc` para traduzir o texto descritivo do efeito de feitiços de classe, raciais e gerais, preservando números reais de dano, cura e duração capturados do tooltip. Integrado em `card:ShowSpell` de `UI/MainMenu.lua`.
- [x] **Fase 7.4 (Motor de Auras & Efeitos - Buffs / Debuffs):** 156 auras e efeitos em `CM_Langs["ptBR"].game.buffs` com fallback inteligente para `GamePT_Spell`. Integrado no PlayerFrame e MainMenu.
- [x] **Fase 7.5 (Bolsas & Equipamentos — TUDO NA BAG):** Tradução total no `card:ShowItem`:
  1. `GamePT_Item`: Catálogo com 176 itens clássicos em `CM_Langs["ptBR"].game.items`.
  2. `GamePT_EquipLoc`: Mapeamento de 28 slots de equipamento Blizzard (INVTYPE_* e texto).
  3. `GamePT_ItemSubType`: Mapeamento de todos os tipos e subtipos de armas, armaduras, consumíveis e bolsas.
  4. `GamePT_ItemStat`: Motor regex dinâmico para linhas de dano, velocidade, armadura, bloqueio, atributos (+X Força, +Y Vigor...), resistências, durabilidade, requisitos de nível/classe/raça/profissão, vínculos ("Vinculado" / "Único") e efeitos de Uso/Equipar. Zero inglês remanescente na bolsa.

---

### 🟢 Status da Cobertura de 100% do MainMenu (REVISADO — auditoria pós-Turtle):
- [x] **Aba 1 (Bolsas / Bags — NOMES):** Nomes de itens por ID via `Data/ItemDB_ptBR.lua` (24.542 itens, `tools/build_itemdb.py`, Turtle vence vanilla). Slots, subtipos, preço de venda, footer OK.
- [ ] **Aba 1 (Bolsas / Bags — DESCRIÇÕES/USO):** `GamePT_ItemStat` cobre só padrões genéricos (poção/comida/stats). Textos de USO de itens de missão (frases únicas de lore) permanecem em inglês. Requer Fase 8 (ItemDescDB).
- [x] **Aba 2 (Feitiços / Spells — NOMES/ranks/atributos):** Nomes, graus, escolas, custo/tempo/alcance/recarga OK.
- [ ] **Aba 2 (Feitiços / Spells — DESCRIÇÕES):** `SpellDescriptions_ptBR.lua` cobre subset via regex exato do inglês; resto cai em `TranslateUniversal` parcial. Requer Fase 8 (SpellDescDB).
- [x] **Aba 3 (Talentos / Talents):** Títulos, ranks, requisitos de pontos por árvore, textos descritivos dinâmicos com preservação de ranges.
- [x] **Aba 4 (Personagem / Character):** Atributos primários, resistências, perícias e idiomas.
- [x] **Aba 5 (Missões / Quests):** Tradução contextual conectada a QuestDB / pfQuest.
- [x] **Aba 6 (Sistema / System):** Todas as opções e textos de configuração em português.

---

---

### 🟢 FASE 8: Descrições Completas por ID — Fonte da Verdade EN Offline & Retradução Humana Blizzlike
> **Diagnóstico Crítico da Falha do Modelo Anterior (18/09):**
> O modelo anterior tentou retraduzir em lotes automáticos gigantescos usando scripts com `zip(batch, pts)` em arquivos de texto soltos, resultando em:
> 1. **Resumos Telegráficos Artificiais / "Estilo SMS":** Abreviações bizarras como `"Arma com fogo: 5.5~16.8 por golpe conforme velocidade. Lenta bate mais. 1 hora."`, `"Totem 5 por 45 s; lentidão a até 10 m."`, `"Arma: +79 poder e +35% ameaça por 1 hora."`, `"Pet +60 vida."`, destruindo a imersão e clareza do jogo.
> 2. **Bug Grave de Dessincronização de Linhas:** Deslocamento de índices ao ler arquivos `.txt` (ex.: `rw16_pt.txt` com 205 linhas para 200 blocos), fazendo com que magias recebessem traduções completamente erradas (ex.: `Death Touch` de GM recebeu a tradução de resistência à sombra com reflexão).
> 3. **Corrupção de Fórmulas e Placeholders (`$`):** Ao omitir ou mover posições sintáticas dos marcadores `$s1`, `$d`, `$a1`, as fórmulas dinâmicas injetadas pelo runtime geraram números desconexos no tooltip.
>
> **Diretrizes Irrevogáveis da Retradução:**
> - **Escrita Natural e Fluente (Padrão Blizzard pt-BR):** Texto narrativo e claro como se um jogador humano estivesse lendo a descrição oficial da Blizzard (ex.: *"Encanta a arma do Xamã com fogo. Cada golpe causa de $s1 a $s2 de dano de Fogo adicional, com base na velocidade da arma. Armas mais lentas causam mais dano de fogo por golpe. Dura 1 hora."*).
> - **Imunidade a Dessincronização:** Mapeamento explícito via dicionários JSON indexados diretamente pela chave original em inglês (`{"EN_ORIGINAL": "PT_HUMANO"}`), eliminando qualquer risco de deslocamento de índices.
> - **Preservação Obrigatória de Placeholders:** Todo marcador de valor (`$s1`, `$s2`, `$d`, `$a1`, `$o1`, etc.) deve ser mantido estritamente no local sintático correto para renderização no motor do WoW 1.12.
>
> **Estratégia de Execução (Abordagem 1 — Decisão Acordada):**
> 1. **Fase 8.A (Spellbook de Jogadores — Foco Imediato):** Retradução completa dos ~1.200 templates canônicos que compõem o Grimório das 9 classes de jogadores, talentos, raciais, perícias, magias de pet e profissões. Permite teste e homologação imediata no controle sem queimar a cota da sessão em magias de monstros.
> 2. **Fase 8.B (Itens, Consumíveis & Equipamentos):** Retradução dos templates de encantamentos, elixires, poções e efeitos de itens.
> 3. **Fase 8.C (Cauda de Monstros & NPCs):** Retradução sistemática da cauda de chefes de raide, monstros e mecânicas internas.
>
> **Parada Crítica:** Ao término da Fase 8.A, parada imediata para validação no jogo (`/reload`), conferência de gastos de tokens e homologação do usuário antes de avançar para as etapas subsequentes.

#### 8.0 Levantamento de fontes (sem char high-level, sem servidor, tudo offline)

| # | Dado | Fonte da verdade EN | PT existente | Formato |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Nome de item (24.542) | `pfQuest/db/enUS/items.lua` (17.712) + `pfQuest-turtle/db/enUS/items-turtle.lua` (8.294) | `pfQuest/db/ptBR/items.lua` + `pfQuest-turtle/db/ptBR/items-turtle.lua` | `[id]="Nome"` — **PRONTO** (`Data/ItemDB_ptBR.lua`, `tools/build_itemdb.py`) |
| 2 | Descrição/USO de item (tooltip completo) | `kofoednielsen/twow-items` (pipeline `ItemTooltipLogger`: varre IDs 0–120000 e grava tooltip EN completo por item, incl. linhas `Use:` de quest) — alternativa: `item_template` do core VMaNGOS | A traduzir (autoral, com placeholders de número preservados) | `[id]={ use="...", equip="..." }` — **A FAZER** (`Data/ItemDescDB_ptBR.lua`, `tools/build_itemdescdb.py`) |
| 3 | Nome de spell | `Spells.lua` atual (852) + DBC Turtle (26.321 via patch local) | `Spells.lua` PT atual | `[lower(en)]="PT"` + SpellDescDB |
| 4 | Descrição de spell (template canônico) | `Spell.dbc` extraído **do próprio client** via `mpyq` (`tools/parse_spell_dbc.py` dual-layout 162/173; merge snapshot+patch-7, patch vence) | Autoral em `tools/spell_pt_authoral.json` com reestruturação humana em lote por classe/jogador | **EM ANDAMENTO** (`Data/SpellDescDB_ptBR.lua`, 26.321 spells, templates de jogadores em revisão) |

#### 8.1 Pipeline Robusto de Retradução Humana
- [x] Diagnóstico completo de anomalias telegráficas e dessincronizações nos lotes anteriores.
- [ ] Construção do catálogo de templates do Spellbook de Jogador (~1.200 templates prioritários).
- [ ] Retradução contextual humana blizzlike item a item (Fase 8.A).
- [ ] Validador de consistência de variáveis (`tools/validate_spell_vars.py`) assegurando integridade dos marcadores `$`.
- [ ] Rebuild de `Data/SpellDescDB_ptBR.lua` e conferência via `/reload` e `/cm spelldbg`.

#### 8.2 Runtime (Lua 5.0, 1.12 puro)
- [x] `GamePT_SpellDesc` passo `descDBEntry` (`ByKey["nome|grau"]` + alias `"nome|"` p/ tooltip sem rank) com PT autoral e injeção ordenada de números nos `$`; templates legados mantidos; **fallback Universal removido do corpo — EN íntegro**; sem entrada no DBC, nome+texto vão p/ `ConsoleModeDB.spellMissing` (cap 60) — `/cm spellmissing`, diagnóstico `/cm spelldbg`.
- [x] `.toc`: `SpellDescDB` + `SpellDescriptions` + `TalentDescriptions`.
- [ ] `GamePT_ItemDesc(itemID)` + `card:ShowItem` p/ linhas `Uso/Equipar` quando o DB existir.

#### 8.3 Validação e Parada Crítica
- [ ] `luac -p` em todos os arquivos tocados.
- **🛑 PARADA CRÍTICA:** Validação visual in-game via `/reload` pelo usuário no Grimório do jogador (ex.: Arma de Labaredas, Totens, Choque, etc.) confirmando escrita natural, fluente e sem resumos telegráficos.

---

### 🟢 FASE FINAL: Inclusão de mais linguagens (template + idioma de prova)
> **Objetivo observável:** Qualquer pessoa adiciona um idioma novo **sem tocar no core** (só 2 arquivos + 1 linha de registro + 1 linha no `.toc`) e ele **aparece automaticamente** no `/cm lang` e no picker com sua flag.

Passo a passo canônico de adicionar um idioma (ex. `esES`):

1. Copiar `Data/Localization/localization_TEMPLATE.lua` para `Data/Localization/localization_esES.lua`.
2. Trocar o id no cabeçalho (`CM_Langs["esES"]`), `name="Español (España)"`, `flag=...flag_esES.tga`, traduzir cada valor de `strings` (manter todas as chaves do ptBR, na mesma ordem para diff fácil).
3. Dropar `Data/Localization/flag_esES.tga` (TGA 32-bit ou BLP, potência de 2, ex. 32x32) ao lado do `.lua`.
4. Adicionar **1 linha de registro** em `Data/Localization.lua` (`CM_RegisterLang("esES", ...)` ou entrada na tabela de ordem — conforme API da Fase 1).
5. Adicionar **1 linha no `.toc`** (`Data\Localization\localization_esES.lua`) após o enUS e antes de `UI\*`.
6. Rodar o validador da Fase 6 (esperado: zero `MISSING`/`EXTRA`); `luac -p` nos arquivos novos.
7. No jogo: `/reload` → `/cm lang` lista `esES` → `/cm lang esES` → `/reload` → addon em espanhol; picker mostra a flag nova.

- [ ] Entregar `Data/Localization/localization_TEMPLATE.lua` (cabeçalho comentado com este passo a passo + todas as chaves do ptBR com valores vazios/`TODO` ou copiados do ptBR para traduzir).
- [ ] **Teste de prova (testável):** dropar arquivo fake `localization_xxYY.lua` (ex. 5 chaves traduzidas como `XX`, resto copiado do ptBR) + `flag_xxYY.tga` (cópia de outra flag) + 1 linha de registro; `/reload` → `xxYY` **aparece no picker e no `/cm lang`**; fallback cobre as chaves não traduzidas; remover o fake após o teste (ou manter como exemplo, decisão do usuário).
- [ ] Validar com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE FINAL):** jogador executa o teste `xxYY` de ponta a ponta e confirma que adicionar idioma é realmente "2 arquivos + 1 linha", sem regressão nos idiomas existentes.

---

## 5. Estrutura Final de Arquivos / Pastas

```
Interface/AddOns/ConsoleModeVanilla/
├── ConsoleModeVanilla.toc          <-- ordem: Data\Localization.lua
│                                       -> Data\Localization\localization_ptBR.lua
│                                       -> Data\Localization\localization_enUS.lua
│                                       -> (futuros localization_xxYY.lua, um por linha)
│                                       -> ANTES de UI\*
├── Core.lua                        <-- mensagens /cm + MSG_* via CM:T; init de ConsoleModeDB.lang (só id)
├── Data/
│   ├── Localization.lua            <-- REGISTRO GLOBAL + LOADER (ids, nomes, flags, CM:T, fallback)
│   ├── Localization/               <-- PASTA (um par de arquivos por idioma)
│   │   ├── localization_ptBR.lua   <-- CM_Langs["ptBR"] = { name, flag, strings={...} }
│   │   │                              + seção game={skills,talents,spells,buffs} (Fase 7)
│   │   │                              (base completa: UI + conteúdo do jogo)
│   │   ├── flag_ptBR.tga           <-- bandeira PT-BR (TGA 32-bit / BLP, potência de 2)
│   │   ├── localization_enUS.lua   <-- CM_Langs["enUS"] = { name, flag, strings={...} } (Fase 5)
│   │   ├── flag_enUS.tga           <-- bandeira EN-US (Fase 5)
│   │   ├── localization_TEMPLATE.lua <-- molde para novos idiomas (Fase FINAL)
│   │   ├── localization_xxYY.lua   <-- (só no teste de prova da Fase FINAL, removível)
│   │   ├── flag_xxYY.tga           <-- (só no teste de prova da Fase FINAL, removível)
│   │   └── ...                     <-- futuros: localization_esES.lua + flag_esES.tga, etc.
│   ├── GamePT.lua                  <-- REMOVIDO do desenho (Fase 7 usa seção game={} dentro
│   │                               de cada localization_<id>.lua: UM arquivo por idioma, sem exceção)
│   └── QuestDB_ptBR.lua            <-- intocado (conteúdo de jogo, fora de escopo)
├── UI/
│   ├── CharacterScreen.lua         <-- Fase 2: CHAR_* (todos os SetText)
│   ├── MainMenu.lua                <-- Fase 3: TAB_*/SLOT_*/SYS_*/DETAIL_*
│   ├── MainMenuNav.lua             <-- Fase 3: hints de navegação
│   ├── MailScreen.lua              <-- Fase 4: MAIL_*
│   ├── MerchantMenu.lua            <-- Fase 4: MERCH_*
│   ├── VirtualKeyboard.lua         <-- Fase 4: VK_*
│   ├── QuantityPicker.lua          <-- Fase 4: QTY_*
│   ├── ContextMenu.lua             <-- Fase 4: CTX_*
│   ├── KeybindingsList.lua         <-- Fase 4: BIND_*
│   └── ...                         <-- todo SetText/AddMessage visível via CM:T; picker de idioma (Fase 5)
├── tools/
│   └── check_locales.*             <-- validador de paridade ptBR↔todos (Fase 6)
└── docs/
    └── plano_de_feature_SISTEMA_DE_LINGUAGEM.md <-- este documento
```

**Regra de ouro da contribuição:** idioma novo = **2 arquivos novos** (`localization_xxYY.lua` + `flag_xxYY.tga`) + **1 linha no registro** (`Data/Localization.lua`) + **1 linha no `.toc`**. Nada no core, nada em `UI/*`.

---

> [!CAUTION]
> **LEMBRETE MANDATÓRIO FINAL:**
> - **NÃO FAZER PUSH SEM ORDEM EXPLÍCITA DO USUÁRIO NO CHAT.**
> - **QUANDO O USUÁRIO ORDENAR O PUSH, FAZER APENAS UMA VEZ E AGUARDAR ANTES DE QUALQUER NOVO PASSO.**
> - **PARADA CRÍTICA ENTRE FASES:** cada fase só começa após o "OK" do teste `/reload` da fase anterior.
> - **Lua 5.0 + API 1.12 + `luac -p` em toda fase, sem exceção.**
> - **Texturas 1.12:** só TGA/BLP em potência de 2; flag ausente = ícone fallback, nunca erro.
> - **SavedVariables guarda só o id** (`ConsoleModeDB.lang = "ptBR"`); registro ANTES dos idiomas no `.toc`, idiomas ANTES de `UI/*`.
