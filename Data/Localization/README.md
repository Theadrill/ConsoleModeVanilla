# ConsoleMode - Vanilla: Localization System / Sistema de Localização

---

## English

Contribution guide for the addon's language system. Everything in this
document assumes the addon runs on **World of Warcraft 1.12.1**
(**strict Lua 5.0**).

### Adding a new language (canonical step-by-step)

The addon uses **one file per language**, all mirrored on the ptBR base.
To create a new language (example: `frFR`, French):

1. **Copy the template:** `Data/Localization/localization_TEMPLATE.lua` →
   `Data/Localization/localization_frFR.lua`.
   The template is inert (not loaded by the `.toc` nor registered); just
   copy it.
2. **Change the registration id:** in the new file, replace `"xxYY"` with
   `"frFR"` in `CM_Langs["xxYY"] = {`.
3. **Change `name` and `flag`:** `name = "Français (France)"` and
   `flag = "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_frFR.tga"`.
4. **Translate only the VALUES.** Never change key names and NEVER
   remove/add keys: keep **ALL ptBR keys** (the template already ships with
   the 711 keys of the base). The validator checks this.
5. **Drop the flag** at `Data/Localization/flag_frFR.tga` (TGA 32x32,
   power of two, same pattern as `flag_ptBR.tga` / `flag_enUS.tga`).
6. **Register 1 line** in `Data/Localization.lua`, next to the other
   `CM_RegisterLang(...)` calls (one call per language):
   ```lua
   CM_RegisterLang("frFR", "Français (France)",
       "Data\\Localization\\localization_frFR.lua",
       "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_frFR.tga")
   ```
7. **Add 1 line to the `.toc`** (`ConsoleModeVanilla.toc`), **before the
   first `UI\` line**:
   ```
   Data\Localization\localization_frFR.lua
   ```
8. **Run the validator** and expect perfect parity (zero `MISSING`/`EXTRA`):
   ```
   python3 tools/check_locales.py
   ```
9. **Run `luac -p`** on the new file (clean Lua syntax).
10. **In game:** `/reload` → `/cm lang` → pick the new language from the
    picker (or `/cm lang frFR`).

### Key convention

Format: `MODULE_SUBJECT_DETAIL` — UPPERCASE, `_` separator, **no accent
in the key** (accents only in the value). Suffix `_FMT` when the value is
passed to `format()` (contains `%s`/`%d`); the rest go straight to
`SetText`.

Prefixes in use (match the ptBR file when adding):

| Prefix | Module |
|---|---|
| `TAB_*` | MainMenu tabs |
| `SLOT_*` | Equipment / bag slots |
| `CHAR_*` | Character sheet (CharacterScreen) |
| `DETAIL_*` | Character detail cards |
| `MAIL_*` | Mailbox / composing mail |
| `MERCH_*` | Merchant / vendor / item selling |
| `VK_*` | Virtual keyboard |
| `QTY_*` | Quantity picker |
| `CTX_*` | Context menu |
| `BIND_*` | Bindings / keys |
| `SPBOOK_*` | Spellbook |
| `BAGPK_*` | Bag picker |
| `MACPK_*` | Macro picker |
| `ABPK_*` | Action bar picker |
| `CFG_*` | ConfigFrame |
| `HUD_*` | HUD / action |
| `MSG_*` | Chat messages (/cm ...) |
| `HINT_*` | Navigation hints |
| `BTN_*` | Buttons (OK/Cancel/Close/...) |
| `LANG_*` | Language system |
| `SYS_*` | GameMenu system menu |

### Golden rules

- **1 file = 1 language.** Never declare another language inside a
  language file.
- **ptBR is the complete base** and can NEVER remove a key. Every other
  language mirrors ptBR faithfully (same key set, zero less / zero more).
- **Flat table** `KEY = "value"`, one key per line, no nesting, no
  metatables, no orphan values.
- **UTF-8 without BOM**; `\n` ASCII in .lua files (accents/ç in the value
  body, never in the key).
- **`%s`/`%d`/`%%` in the value:** `%%` is a literal `%` (counts as 0
  specifier); `%s`/`%d`/`%f` must keep the SAME count as ptBR (the order
  may change — languages reorder arguments).
- **Colors `|cffRRGGBB...|r` inside the value**, never in code. The
  `|cff`/`|r` count must match ptBR.
- **Never hardcode names** of items/spells/players/gold in the value —
  use `%s` injected by the code.
- **One key = one concept** (no key reuse for different contexts).
- **Always access via `CM:T("KEY")`**, never index `CM_Langs` directly in
  UI code.

### Frozen convention (golden rule for future PRs)

> Every new UI string needs a **new key added in BOTH languages in the
> same phase** (ptBR base + enUS). No new `SetText` / `AddMessage` with
> hardcoded literal text. Adding a string in only one language breaks
> parity and makes the validator fail.

### Validation

```bash
# Key parity ptBR (base) x all languages + .toc order
python3 tools/check_locales.py

# Clean Lua syntax on everything you changed
luac -p Data/Localization/localization_xxYY.lua
```

Canonical `.toc` order (check it if you touch the `.toc`):

```
Data\Localization.lua
Data\Localization\localization_ptBR.lua
Data\Localization\localization_enUS.lua
Data\Localization\localization_frFR.lua   <- new languages before UI\
UI\...
```

Future Phase 7: the `game = { skills, talents, spells, buffs }` section
goes into the SAME language table, next to `strings`, and is optional per
language (enUS does not need it — the client is already EN).

---

## Português

Guia de contribuição para o sistema de idiomas do addon. Todo o conteúdo
deste documento assume que o addon roda em **World of Warcraft 1.12.1**
(**Lua 5.0 estrito**).

### Como adicionar um idioma novo (passo a passo canônico)

O addon usa **um arquivo por idioma**, todos espelhados na base ptBR.
Para criar um idioma novo (exemplo: `frFR`, Francês):

1. **Copie o molde:** `Data/Localization/localization_TEMPLATE.lua` →
   `Data/Localization/localization_frFR.lua`.
   O molde é inerte (não é carregado pelo `.toc` nem registrado); faça
   apenas a cópia.
2. **Troque o id do registro:** no arquivo novo, substitua `"xxYY"` por
   `"frFR"` em `CM_Langs["xxYY"] = {`.
3. **Troque `name` e `flag`:** `name = "Français (France)"` e
   `flag = "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_frFR.tga"`.
4. **Traduza somente os VALORES.** NUNCA mude nomes de chave e NUNCA
   remova/adicione chave: mantenha **TODAS as chaves do ptBR** (o molde
   já vem com as 711 chaves da base). O validador checa isso.
5. **Drope a bandeira** em `Data/Localization/flag_frFR.tga` (TGA 32x32,
   potência de 2, mesmo padrão das `flag_ptBR.tga` / `flag_enUS.tga`).
6. **Registre 1 linha** em `Data/Localization.lua`, junto das demais
   chamadas `CM_RegisterLang(...)` (uma chamada por idioma):
   ```lua
   CM_RegisterLang("frFR", "Français (France)",
       "Data\\Localization\\localization_frFR.lua",
       "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_frFR.tga")
   ```
7. **Adicione 1 linha ao `.toc`** (`ConsoleModeVanilla.toc`), **antes da
   primeira linha `UI\`**:
   ```
   Data\Localization\localization_frFR.lua
   ```
8. **Rode o validador** e espere paridade perfeita (zero `MISSING`/`EXTRA`):
   ```
   python3 tools/check_locales.py
   ```
9. **Rode `luac -p`** no arquivo novo (sintaxe Lua limpa).
10. **No jogo:** `/reload` → `/cm lang` → escolha o novo idioma no picker
    (ou `/cm lang frFR`).

### Convenção de chaves

Formato: `MODULO_ASSUNTO_DETALHE` — MAIÚSCULAS, separador `_`, **sem
acento na chave** (acento só no valor). Sufixo `_FMT` quando o valor for
passado a `format()` (contém `%s`/`%d`); demais vão direto ao `SetText`.

Prefixos em uso (ajuste ao arquivo ptBR ao adicionar):

| Prefixo | Módulo |
|---|---|
| `TAB_*` | Abas do MainMenu |
| `SLOT_*` | Slots de equipamento / bolsas |
| `CHAR_*` | Ficha do personagem (CharacterScreen) |
| `DETAIL_*` | Cards de detalhe da ficha |
| `MAIL_*` | Caixa de correio / redação de carta |
| `MERCH_*` | Mercador / vendedor / venda de itens |
| `VK_*` | Teclado virtual |
| `QTY_*` | Seletor de quantidade |
| `CTX_*` | Menu de contexto |
| `BIND_*` | Bindings / teclas |
| `SPBOOK_*` | Spellbook (livro de magias) |
| `BAGPK_*` | Picker de bolsas |
| `MACPK_*` | Picker de macros |
| `ABPK_*` | Picker de action bar |
| `CFG_*` | ConfigFrame |
| `HUD_*` | HUD / ação |
| `MSG_*` | Mensagens de chat (/cm ...) |
| `HINT_*` | Hints de navegação |
| `BTN_*` | Botões (OK/Cancelar/Sair/...) |
| `LANG_*` | Sistema de idioma |
| `SYS_*` | Menu de sistema (GameMenu) |

### Regras de ouro

- **1 arquivo = 1 idioma.** Nunca declare outro idioma dentro de um
  arquivo de idioma.
- **ptBR é a base completa** e NUNCA pode remover chave. Todos os demais
  idiomas espelham ptBR fielmente (mesmo conjunto de chaves, zero a menos
  / zero a mais).
- **Tabela plana** `CHAVE = "valor"`, uma chave por linha, sem nesting,
  sem metatables, sem valores órfãos.
- **UTF-8 sem BOM**; `\n` ASCII em arquivos .lua (acentos/ç no corpo do
  valor, nunca na chave).
- **`%s`/`%d`/`%%` no valor:** `%%` é `%` literal (conta como 0
  especificador); `%s`/`%d`/`%f` devem manter a MESMA contagem do ptBR
  (a ordem pode mudar — idiomas reordenam argumentos).
- **Cores `|cffRRGGBB...|r` dentro do valor**, nunca no código. Contagem
  de `|cff`/`|r` deve casar com o ptBR.
- **Nunca fixe nomes** de item/magia/personagem/ouro no valor — use `%s`
  injetado pelo código.
- **Uma chave = um conceito** (sem reuso de chave para contexts
  diferentes).
- **Acesso sempre via `CM:T("CHAVE")`,** nunca indexar `CM_Langs` direto
  no código de UI.

### Convenção congelada (regra de ouro para PRs futuros)

> Toda string nova de UI precisa de **chave nova adicionada nas DUAS
> línguas na mesma fase** (ptBR base + enUS). Nenhum `SetText` /
> `AddMessage` com texto literal hardcoded novo. Quem adicionar uma
> string em somente um idioma quebra a paridade e o validador falha.

### Validação

```bash
# Paridade de chaves ptBR (base) x todos os idiomas + ordem do .toc
python3 tools/check_locales.py

# Sintaxe Lua limpa em tudo que foi alterado
luac -p Data/Localization/localization_xxYY.lua
```

Ordem canônica do `.toc` (confira se mexer nele):

```
Data\Localization.lua
Data\Localization\localization_ptBR.lua
Data\Localization\localization_enUS.lua
Data\Localization\localization_frFR.lua   <- novos idiomas antes de UI\
UI\...
```

Fase 7 (futura): seção `game = { skills, talents, spells, buffs }` entra
na MESMA tabela do idioma, ao lado de `strings`, e é opcional por idioma
(enUS não precisa — o cliente já é EN).