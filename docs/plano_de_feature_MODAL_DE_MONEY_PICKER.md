# Plano de Extração e Feature: Modal de Edição de Dinheiro (`MoneyPicker`)

**Status:** Rascunho / Planejado  
**Módulo Destino:** `UI/MoneyPicker.lua`  
**Consumidores:** `UI/MailScreen.lua`, `UI/AuctionScreen.lua` (Starting Bid e Buyout Price)  
**Compatibilidade:** WoW Vanilla 1.12.1 / Lua 5.0.3 (Strict)

---

## 1. Motivação e Contexto

Atualmente, o modal de seleção e edição de valores em dinheiro (`ConsoleMode_MailMoneyModal`) reside inteiramente dentro de `UI/MailScreen.lua` (~linhas 3600–3992). Ele implementa uma roleta de 8 dígitos (4 dígitos de Ouro, 2 de Prata, 2 de Cobre) navegável via controle (D-Pad Left/Right para dígitos, Up/Down para valor 0–9).

No entanto, ele está **fortemente acoplado** ao fluxo de correspondência:
- Checa se o total excede o saldo da bolsa somado à taxa de selo (`GetPostageCopper()`).
- Alimenta diretamente os buffers do compose (`composeMoney`, EditBox 4).
- Executa preenchimento automático do assunto da carta (`AutoFillSubjectForMoney`).
- Utiliza logs e tokens de tradução específicos de correio.

Para a Casa de Leilões (`AuctionScreen.lua`), as opções **Starting Bid** (Lance Inicial) e **Buyout Price** (Compra Imediata) demandam o mesmo comportamento de roleta numérica com suporte pleno ao gamepad, sem as amarras de correio (no leilão não se exige saldo em bolsa para vender e os tetos/regras de validação são distintos).

Analogamente ao que foi feito com `UI/QuantityPicker.lua` (que atende `MailScreen`, `ContextMenu` e `AuctionScreen`), criaremos o `UI/MoneyPicker.lua` de forma agnóstica e modular.

---

## 2. Arquitetura do Componente `UI/MoneyPicker.lua`

### 2.1 Interface Pública
```lua
ConsoleMode_MoneyPicker = ConsoleMode_MoneyPicker or {}
local MP = ConsoleMode_MoneyPicker
local CM = ConsoleMode or {}
CM.MoneyPicker = MP

-- Abre o modal configurado
MP:Open({
    title       = "Definir Lance Inicial", -- Título exibido no topo do modal
    copper      = 10000,                  -- Valor inicial em copper
    maxCopper   = nil,                    -- Teto opcional (ex: saldo para correio; nil/99999999 para leilão)
    minCopper   = 1,                      -- Piso opcional (ex: 1 copper para bid de leilão, 0 para buyout/mail)
    showBalance = false,                  -- Exibe linha de saldo do jogador e taxa (específico p/ correio)
    postageCost = 30,                     -- Taxa de postagem em copper (se showBalance = true)
    onConfirm   = function(copper, ctx) end, -- Callback de confirmação (A / botão)
    onCancel    = function(ctx) end,         -- Callback de cancelamento (B / botão)
    ctx         = ctx,                    -- Contexto arbitrário repassado aos callbacks
})

-- Consultas de estado
MP:IsOpen()
MP:Close(silent)
MP:Confirm()
MP:Cancel()

-- Navegação via Gamepad
MP:Direction(direction) -- "LEFT", "RIGHT", "UP", "DOWN"
MP:Spin(delta)          -- +1 ou -1 no dígito ativo (wrap circular 0-9)
```

### 2.2 Estrutura Visual
- **Janela:** Largura 480px, Altura 330px, estrato `FULLSCREEN_DIALOG`, fundo sólido escurecido com borda dourada.
- **Reels de Dígitos:** 8 botões clicáveis e focáveis (4 Ouro, 2 Prata, 2 Cobre). D-Pad Left/Right move o foco com destaque visual (`SetBackdropBorderColor`).
- **Rótulos dos Grupos:** Ouro, Prata, Cobre com suas devidas fontes e alinhamentos.
- **Resumo Formatado:** Texto grande renderizando o valor total em moedas (`FormatMoneyText`).
- **Linha de Saldo / Aviso (Opcional):** Visível apenas quando `showBalance == true`.
- **Hints com Ícones:** `[D-Pad Esq/Dir] Dígito • [D-Pad Cima/Baixo] Girar • [A] Confirmar • [B] Cancelar`.
- **Botões Clicáveis:** Botões no rodapé com ícones `A` e `B` para suporte híbrido gamepad/mouse.

---

## 3. Onde Modificar

### 3.1 `ConsoleModeVanilla.toc`
Adicionar o novo módulo imediatamente abaixo de `UI/QuantityPicker.lua` (linha 47):
```toc
UI/QuantityPicker.lua
UI/MoneyPicker.lua
UI/MailScreen.lua
...
```

### 3.2 `UI/MailScreen.lua`
1. **Remover a criação de frame própria:** Excluir `MailScreen:CreateMoneyModalUI()`, `MailScreen:CreateMoneyModalDimmer()`, `MailScreen:MoneyModalDirection()`, `MailScreen:MoneyModalSpin()`.
2. **Refatorar `MailScreen:OpenMoneyModal()`:**
   Chamar `CM.MoneyPicker:Open(...)` passando:
   - `title = CM:T("MAIL_MONEY_TITLE")`
   - `copper = tonumber(self.composeMoney) or 0`
   - `maxCopper = self:GetPlayerCopper()`
   - `showBalance = true`
   - `postageCost = self:GetPostageCopper()`
   - `onConfirm = function(copper) ... end` (onde salva em `composeMoney`, atualiza o editbox 4 e dispara `AutoFillSubjectForMoney`).
3. **Encaminhamento de Inputs:**
   Em `MailScreen:OnDirection()`, `MailScreen:OnConfirm()`, `MailScreen:OnCancel()`, delegar para `CM.MoneyPicker` caso `CM.MoneyPicker:IsOpen()`.

### 3.3 `UI/AuctionScreen.lua`
1. **Intercepção no Formulário de Venda:**
   Ao selecionar **Row 1 (`Starting Bid`)** ou **Row 2 (`Buyout Price`)** e pressionar `(A)` ou clicar:
   - Row 1 abre `CM.MoneyPicker` configurado para Lance Inicial (piso = 1 copper, sem teto de saldo).
   - Row 2 abre `CM.MoneyPicker` configurado para Preço de Arremate (piso = 0 copper, se > 0 e < bid, ajusta bid/buyout conforme regras de consistência do AH).
2. **Encaminhamento de Inputs Gamepad:**
   Em `AuctionScreen:OnDirection()`, `AuctionScreen:OnConfirm()`, `AuctionScreen:OnCancel()`, checar `CM.MoneyPicker:IsOpen()` antes das ações padrão da janela de leilão.
3. **Atualização Visual:**
   No callback `onConfirm`, atualizar `self.sellBidPrice` ou `self.sellBuyoutPrice`, recalcular o deposit e disparar `AuctionScreen:UpdateSellListingStyles()`.

### 3.4 `Keybindings.lua`
Garantir que as funções centrais de confirmação e cancelamento chequem `CM.MoneyPicker:IsOpen()` prioritariamente, impedindo que inputs do leilão ou de outras telas vazem enquanto o seletor monetário estiver ativo.

---

## 4. Ordem de Execução Acordada com o Usuário

1. **Passo I (Imediato):** Ativar o `QuantityPicker` existente em `UI/AuctionScreen.lua` para as duas opções numéricas de venda:
   - **Row 4:** `Stack Size` (Tamanho da Pilha)
   - **Row 5:** `Number of Stacks` (Número de Pilhas)
2. **Passo II:** Testar e validar o comportamento do `QuantityPicker` no Leilão.
3. **Passo III:** Implementar a criação de `UI/MoneyPicker.lua` e a modularização nas duas telas (`MailScreen` e `AuctionScreen`).
