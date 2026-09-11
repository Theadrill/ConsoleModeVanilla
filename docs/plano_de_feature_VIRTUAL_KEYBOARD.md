# Plano de Feature: VIRTUAL KEYBOARD — Teclado Virtual Desacoplado (ConsoleMode)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido terminantemente o uso de operadores de Lua 5.1+ (como operador de tamanho `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Arquitetura Modular Isolada (Fim do Monólito):**
>    - O `MainMenu.lua` atual tornou-se um arquivo excessivamente volumoso (+13.000 linhas).
>    - Esta feature **NÃO DEVE** ser colocada dentro de `MainMenu.lua` nem dentro de `MailScreen.lua`.
>    - O sistema nascerá como um módulo **100% independente e desacoplado**: `UI/VirtualKeyboard.lua`.
>    - Será carregado via `ConsoleModeVanilla.toc` (ANTES de `MailScreen.lua`) e NÃO requer init por evento — é um serviço sob demanda via `ConsoleMode.VirtualKeyboard`.
> 4. **Identidade Visual Rigorosa do CONSOLEMODE:**
>    - **Tipografia Nobre:** Fontes aplicadas exclusivamente via `ApplyFont()` utilizando `titleFontFile` / `headerFontFile` (`AlegreyaSans-Bold.ttf` com o mod de -9% de kerning), `bodyFontFile` (`AlegreyaSans-Bold.ttf`) e `subFontFile` (`AlegreyaSans-Medium.ttf`).
>    - **Paleta de Cores Oficial:** Dourado âmbar nobre (`|cffe09a15`), cinza suave para inativos (`|cffaaaaaa`), texto branco puro (`|cffffffff`), verde para confirmar (`|cff1eff00`) e vermelho para erros (`|cffff2020`).
>    - **Backdrops Customizados:** Fundo escurecido translúcido alpha 0.40-0.85 (`Interface\Tooltips\UI-Tooltip-Background`), borda fina (`Interface\Tooltips\UI-Tooltip-Border`), insets 2-3px.
>    - **Glifos Oficiais:** Rodapé **DEVE** usar texturas reais (`Media\Icons\Xbox\A.tga, B.tga, X.tga, Y.tga, LB.tga, RB.tga, LT.tga, RT.tga`).
> 5. **Validação de Sintaxe:** Todo `.lua` criado/alterado deve passar em `luac -p` antes de qualquer teste.
> 6. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem autorização explícita do usuário.
> 7. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem validação no jogo via `/reload` e aprovação do usuário.

---

## 1. Visão Geral

Hoje o addon **NÃO tem teclado virtual**: o único tratamento de texto é `Cursor:Click() → EditBox:SetFocus()` (`Cursor.lua:1557-1558`), e o doc do cursor cita "teclado virtual" como ideia futura não implementada. `MerchantMenu` resolve quantidade com modal numérico D-Pad (`QtyModal`), `ContextMenu` resolve split de pilha com stepper — nenhum dos dois digita texto livre.

O `MailScreen.lua` (tela de correio em construção) precisa digitar `Para / Assunto / Mensagem` 100% pelo controle, e futuras telas (busca de bags, chat, macros, config) precisarão do mesmo. A solução é um **serviço modal genérico**:

```lua
ConsoleMode.VirtualKeyboard:Open(config)  -- abre, captura input, chama callback
ConsoleMode.VirtualKeyboard:Close()       -- cancela
ConsoleMode.VirtualKeyboard:IsOpen()      -- boolean
```

Qualquer tela chama `Open({ title, initialText, maxLetters, multiLine, autoCompleteList, onConfirm, onCancel, targetEditBox })`, recebe o texto de volta em `onConfirm(text)` e continua seu fluxo sem conhecer a grade de teclas.

---

## 2. Diagrama Visual (ASCII Art)

```
┌──────────────────────────────────────────────────────────────┐
│ DESTINATÁRIO                                     [B] Fechar  │
│ Para: [ Thrall|________ ]  (buffer + cursor piscando)        │
│ Sugestões: [Thrall] [Thrallbank] [Thrulina]  (se autoComplete)│
├──────────────────────────────────────────────────────────────┤
│  [q] [w] [e] [r] [t] [y] [u] [i] [o] [p]   <- pag abc/ABC/123│
│  [a] [s] [d] [f] [g] [h] [j] [k] [l] [ç]                    │
│  [z] [x] [c] [v] [b] [n] [m] [,] [.] [@]                    │
│  [SHIFT] [ESPAÇO] [APAGAR] [123] [PT-BR] [OK]                │
├──────────────────────────────────────────────────────────────┤
│ [A] inserir • [B] apagar • [X] shift • [Y] espaço            │
│ [L1]/[R1] página • [D-Pad] navegar • [Start] confirmar       │
└──────────────────────────────────────────────────────────────┘
```

Comportamento: `D-Pad UP` a partir da 1ª linha de teclas salta o foco para a barra de sugestões (quando `autoCompleteList` presente); `D-Pad DOWN` volta para a grade. `[A]` na sugestão preenche o buffer imediatamente (sem fechar).

---

## 3. Arquitetura Técnica

### 3.1. Contrato público (congelado neste plano — NÃO mudar sem aditivo)
```lua
VK = ConsoleMode.VirtualKeyboard
VK:Open(config)
-- config.title: string (ex: "Destinatário", "Assunto", "Mensagem", "Buscar Item")
-- config.initialText: string ou "" (buffer pré-carregado)
-- config.maxLetters: number ou nil (clamp; ex: 64 nome, 2000 corpo)
-- config.multiLine: true/false (Y = nova linha vs espaço)
-- config.autoCompleteList: array de strings ou nil (alts, histórico, guilda)
-- config.onConfirm(text): function — OBRIGATÓRIO (salva buffer no chamador)
-- config.onCancel(): function ou nil
-- config.targetEditBox: EditBox ou nil (sync opcional via SetText, sem SetFocus forçado)
VK:Close()            -- fecha sem confirmar (dispara onCancel)
VK:IsOpen() -> bool   -- flag OR frame:IsVisible()
```

Regras:
- Singleton lazy (`frame=nil + state={...}`), molde `MerchantMenu.qtyModal/qtyModalFrame`.
- `Open` guarda `callerState + callbacks + returnButton`, valida `onConfirm` function, clampa `initialText` em `maxLetters`.
- `Confirm`: `Close()` primeiro, depois `onConfirm(text)` (molde `QtyModalConfirm` / `ContextMenu:ConfirmSplit`).
- `Close`: `Hide() + activeFrames=nil + MoveTo(returnButton se visível) + onCancel()` (molde `ContextMenu:Close` + `HideQuestDetail`).

### 3.2. Janela e camadas (molde QtyModal + ConfigFrame)
- `CreateFrame("Frame", "ConsoleMode_VirtualKeyboard", UIParent)`, `420x260 CENTER 0,40`, `FULLSCREEN_DIALOG / Level 50`, `EnableMouse(true)`, backdrop tooltip + borda ouro `1,0.82,0.2,0.95`.
- Filhos: `title(19pt)`, `previewText` (buffer + `|` cursor, 16pt, quebra se `multiLine`), `suggestRow` (até 4 botões, `Hide` se sem lista), `gridArea` (botões de tecla), `hints` rodapé estilo QtyModal.
- Cursor visual do addon continua por cima (`TOOLTIP/1000`) — intencional.
- Grade como `Button`s reais com `OnClick` (para `CollectButtons` funcionar sem exceção) + `OnEnter` seleciona (molde `MainMenu grid slots`).

### 3.3. Fiação de input (checklist exato — sem isso o modal NÃO funciona)
1. `Keybindings.lua`: inserir branch `if VirtualKeyboard:IsOpen() then VK:OnDirection/Confirm/Cancel... return end` como **primeiro** branch após `if chatActive then return end` em `CM_CursorMove`, `CM_CursorConfirm`, `CM_CursorUse` (bloqueia), `CM_CursorSecondary`, `CM_CursorCancel` — espelho exato de `IsQtyModalOpen()` (`Keybindings.lua:1037,1078,1117,1162,1213`).
2. `Cursor.lua:UpdateState (784-808)`: adicionar `VK.frame` como `modalFrame` de precedência máxima (`if VK:IsOpen() then modalFrame=VK.frame`), senão o D-Pad navega na tela de trás.
3. `Hooks.lua:CloseTopFrame (701-713)`: topo `if VK:IsOpen() then VK:Close() return true end`, antes de `DropDownList`.
4. `VK:OnDirection + StartRepeat/StopRepeat/EnsureRepeatTicker` com `initialDelay 0.35 / interval 0.12` (cópia de `MerchantMenu:2335-2377` + `Cursor.lua:25-30`); `B/backspace` usa repeat, resto passo único.
5. `chatActive`: quando VK edita buffer interno, manter `chatActive=false` (senão ele se auto-bloqueia). Só setar `true` se delegar foco físico (`targetEditBox:SetFocus()`). Fix órfão `OnChatActivated/Deactivated` entra na Fase 5.

### 3.4. Layouts de tecla e mapeamento
- Páginas: `abc` (minúsculas) → `ABC` (maiúsculas) → `123` (números+pontuação) → `PT` (`ã õ ç é ê á à â ó ô í ú`).
- Fixo: `D-Pad=navega matriz`, `A=insere`, `B=backspace (hold repeat)`, `X=Shift (alterna abc/ABC)`, `Y=espaço (ou \n se multiLine)`, `L1/R1=página`, `Start=onConfirm`.
- `maxLetters`: `Insert` recusa além do limite + som de erro; `multiLine=false` recusa `\n`.
- UTF-8 ptBR: contar **bytes** com `strlen/strsub` (Lua 5.0 sem suporte a codepoint); nunca fatiar no meio de multibyte no backspace (remove último byte-sequence válido); fonte `FRIZQT__` sem glifo vira `?` — aceitar e documentar.

---

## 4. Fases Testáveis e Auditáveis (parada obrigatória entre fases)

### FASE VK-1 — Esqueleto + API + registro (sem grade, sem fiação)
**Escopo:**
- Criar `UI/VirtualKeyboard.lua` com `VK = {}`, `ConsoleMode.VirtualKeyboard = VK`, estado `{ isOpen, title, buffer, maxLetters, multiLine, autoCompleteList, onConfirm, onCancel, targetEditBox, returnButton }`.
- Implementar `Open(config)` (valida + guarda + loga), `Close()`, `IsOpen()`. `CreateUI` = stub que só cria frame vazio `FULLSCREEN_DIALOG` + title + preview. Sem grade, sem Keybindings, sem Cursor.
- Registrar no `ConsoleModeVanilla.toc` ANTES de `UI\MailScreen.lua`. Sem init por evento.
**Auditoria (você valida):**
1. `/reload` sem erro Lua.
2. `/script ConsoleMode.VirtualKeyboard:Open({title="T", initialText="ab", onConfirm=function(t) print("OK:"..t) end})` abre frame vazio com preview `ab`.
3. `IsOpen()` retorna `true`; chamar `Close()` fecha e imprime cancel (se `onCancel`).
4. `Open` sem `onConfirm` recusa com log (não quebra).
**NÃO avançar se:** qualquer erro no `/reload` ou frame não abrir/fechar.

### FASE VK-2 — Grade ABC + navegação D-Pad + inserção/confirmação
**Escopo:**
- Grade página `abc` (26 letras + espaço + backspace + OK), botões reais com `OnClick`/`OnEnter`, `OnDirection` 2D (esquerda/direita/cima/baixo com wrap), `A` insere no buffer + `UpdatePreview`, `B` backspace 1 char, `Start`/botão OK confirma (`Close + onConfirm`).
- Fiação mínima: branches em `CM_CursorMove/Confirm/Cancel` + `UpdateState` modal (itens 1-2 do §3.3). Sem autocomplete, sem páginas, sem repeat ainda.
**Auditoria:**
1. `/reload`, abrir VK via `/script`, navegar grade 100% por D-Pad (sem mouse), foco visível (highlight ouro).
2. Digitar `thrall` com `A`, apagar 1 com `B`, confirmar com `Start` → chat/log mostra `OK:thrall`.
3. `B` com buffer vazio não quebra; D-Pad na tela de trás NÃO move enquanto VK aberto.
4. Fechar com `B` longo? Não — `B` apaga; fechar via botão Fechar/Start. (Comportamento será refinado na VK-4.)
**NÃO avançar se:** D-Pad vazar para a tela de trás ou `onConfirm` não receber o texto exato.

### FASE VK-3 — Páginas, shift, números, PT-BR, limites, multiLine
**Escopo:**
- Páginas `abc/ABC/123/PT`, `X` alterna shift, `L1/R1` cicla páginas, `Y` espaço (`\n` se `multiLine`), `maxLetters` clamp + som erro, backspace UTF-8 seguro.
**Auditoria:**
1. Abrir com `maxLetters=5`, digitar 7 chars → para em 5 + erro sonoro.
2. `multiLine=false`: tecla `Y` insere espaço, nunca `\n`. `multiLine=true`: `Y` insere `\n`, preview quebra linha.
3. Página `PT`: inserir `ã`, `ç`, `é` sem erro Lua; backspace remove o caractere inteiro (não deixa byte órfão).
4. `X` alterna `abc↔ABC`; `L1/R1` cicla `abc→ABC→123→PT→abc`.
**NÃO avançar se:** acento quebrar buffer ou limite estourar.

### FASE VK-4 — Autocomplete genérico + hold-repeat + fechamento padrão
**Escopo:**
- `suggestRow` (até 4): filtra `autoCompleteList` por prefixo do buffer (case-insensitive, `strlower`), `D-Pad UP` da 1ª linha sobe para sugestões, `A` preenche buffer (sem fechar), `D-Pad DOWN` volta. `StartRepeat` com repeat só em `B` (apagar contínuo) e navegação direcional; `CloseTopFrame` topo + `Y` bloqueado? Não — `Y` é espaço. `B` com buffer vazio + sem sugestão = `Close` (cancel).
**Auditoria:**
1. `Open({autoCompleteList={"Thrall","Thrallbank","Jaina"}})`, digitar `t` → mostra 2 sugestões; `UP + A` na 1ª → buffer `Thrall`.
2. Segurar `B` apaga contínuo (0.35s delay, 0.12s intervalo); soltar para.
3. `Esc/B` equivalente (`CloseTopFrame`) fecha VK sem confirmar e devolve foco ao `returnButton`.
**NÃO avançar se:** sugestão não filtrar ou foco não voltar ao chamador.

### FASE VK-5 — Integração MailScreen (3 campos) + polish + chat
**Escopo:**
- `MailScreen Para`: `Open({title="Destinatário", maxLetters=64, autoCompleteList=alts+histórico})` → `onConfirm` salva `composeTo`.
- `Assunto`: `Open({title="Assunto", initialText=nomeAnexo ou "", maxLetters=64})`.
- `Mensagem`: `Open({title="Mensagem", maxLetters=2000, multiLine=true})`.
- Fix `chatActive` (hooks `ChatFrameEditBox` + `SendMail*EditBox`), sons `CheckBoxOn/Off/Close`, hints finais, `targetEditBox` sync opcional.
**Auditoria (fim-a-fim):**
1. Na mailbox: abrir `Para` → digitar prefixo → autocomplete alt → confirmar → campo mostra nome.
2. `Mensagem` multilinha com acentos → `onConfirm` preserva `\n` e `ç/ã`.
3. Teclado físico ainda funciona (foco direto dá `chatActive=true`, D-Pad não rouba).
4. Sessão completa sem erro Lua: abrir VK 3x seguidas, confirmar/cancelar alternados.
**Aceite final:** as 4 auditorias VK-1..VK-4 + esta, todas com `/reload` limpo.

---

## 5. Arquivos Impactados
- **Novo:** `UI/VirtualKeyboard.lua` (único arquivo novo desta feature).
- **Registro:** `ConsoleModeVanilla.toc` (+1 linha antes de `MailScreen.lua`).
- **Fiação (VK-2/VK-4):** `Keybindings.lua` (5 branches), `Cursor.lua` (`UpdateState`), `Hooks.lua` (`CloseTopFrame`).
- **Consumidor (VK-5):** `UI/MailScreen.lua` (3 chamadas `Open`), `Core.lua` (nada novo — VK sem init), `ConsoleModeDB` (alts + histórico, se ainda não existir).
- **Intocados:** `MainMenu.lua`, `MerchantMenu.lua`, `MailFrame` nativo (só suprimido pelo MailScreen).

---

## 6. Critérios de Aceite (resumo auditável)
1. VK-1: abre/fecha via `/script`, `IsOpen` correto, sem erro no `/reload`.
2. VK-2: digita palavra só com controle, `onConfirm` exato, sem vazamento de D-Pad.
3. VK-3: páginas/shift/limite/multilinha/acentos corretos.
4. VK-4: autocomplete filtra/seleciona, hold-repeat apaga, foco volta ao chamador.
5. VK-5: 3 campos do Mail consumindo VK de ponta a ponta + teclado físico preservado.
