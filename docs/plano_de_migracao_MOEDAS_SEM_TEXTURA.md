# Plano de Migração: Padronização de Moedas com Texto Colorido (Sem Textura)

> [!IMPORTANT]
> **LEITURA OBRIGATÓRIA ANTES DE INICIAR QUALQUER MODIFICAÇÃO:**
> Leia atentamente o arquivo [AI_CONTEXTO_ADDON_1.12.md](file:///C:/PROJETOS/ConsoleModeVanilla/AI_CONTEXTO_ADDON_1.12.md) na raiz do projeto.
> Ele contém todas as regras mandatórias do ambiente:
> - **WoW 1.12.1 / Lua 5.0.3 (Strict)** — Proibido usar operadores do Lua 5.1+ (`#t`, `//`, `~=`, bitwise).
> - **Validação:** Sempre compilar arquivos alterados com `C:\Tools\lua50\luac50.exe -p <arquivo>`.
> - **Regra de Git Push:** NUNCA fazer push sem pedido explícito do usuário.
> - **Identidade Visual:** Respeitar fontes, paleta e convenções do addon Vanilla.

---

**Status:** Concluído / Pronto para Validação In-Game  
**Objetivo:** Substituir todas as texturas de moedas (`coin_gold.tga`, `coin_silver.tga`, `coin_copper.tga`) do addon pelo método de **texto puro colorido com sufixos g/s/c** padronizado pelo `TrainerMenu.lua`.  
**Arquivos de Escopo:** `UI/AuctionScreen.lua`, `UI/MainMenu.lua`, limpeza em `UI/TrainerMenu.lua`, `UI/MerchantMenu.lua`.  
**Arquivos de Referência (já corretos):** `UI/TrainerMenu.lua`, `UI/MerchantMenu.lua`, `UI/MailScreen.lua`, `UI/MoneyPicker.lua`.

---

## 1. Motivação e O Problema do Bug de Textura

### 1.1 O Sintoma Visual
Em testes in-game, na tela de Leilão (`AuctionScreen.lua`) e no Menu Principal (`MainMenu.lua`), os ícones de prata e especialmente de bronze/cobre passam a apresentar **corrupção visual severa (ruído aleatório / estática de TV / pixels embaralhados)**. 
- O bug não acontece logo no primeiro segundo de jogo.
- Ocorre de forma intermitente durante o uso prolongado ou **após múltiplos `/reload`**.
- Se o jogo for totalmente fechado e reaberto, volta a funcionar temporariamente, mas degrada novamente após recargas de interface.

### 1.2 Causa Raiz Técnica (WoW Vanilla 1.12.1 DirectX 9)
1. **Texturas TGA Externas vs Texturas Nativas BLP**:
   - `Media\coin_gold.tga`, `Media\coin_silver.tga` e `Media\coin_copper.tga` são arquivos `.tga` descompactados customizados em disco.
   - Quando o cliente Vanilla 1.12.1 instancia dezenas de `CreateTexture` apontando para o mesmo `.tga` simultaneamente (como na tabela de leilões que possui mais de 60 widgets de moedas ativos), o gerenciador de texturas D3D do motor de jogo sofre fragmentação/corrupção de buffer na VRAM ao recarregar a interface (`/reload` ou `ReloadUI()`).
   - O reinício do jogo limpa completamente o dispositivo DirectX 9 e a memória de vídeo, mascarando o defeito temporariamente.

2. **Por que o `TrainerMenu.lua` e o `MerchantMenu.lua` NUNCA sofrem desse bug?**:
   - Ambas as telas **não usam texturas de moedas nas tabelas**.
   - Elas utilizam a função `FormatMoneyText(totalCopper)` que monta uma **string formatada colorida**:
     ```lua
     text = "|cffffd700" .. gold .. "g|r |cffc7c7cf" .. silver .. "s|r |cffeda55f" .. copper .. "c|r"
     ```
   - O texto puro é renderizado diretamente pelo motor de tipografia (`FontString`) usando a fonte do jogo.
   - **Gasto de texturas de GPU:** Zero.
   - **Risco de corrupção ou estática:** Zero.
   - **Alinhamento:** Alinha com perfeição em tabelas sem desalinhamentos de ícones.

### 1.3 A Decisão do Usuário
Para garantir consistência visual em todo o addon e eliminar definitivamente a causa da corrupção, **todas as telas devem adotar exclusivamente o método de texto colorido sem texturas**, exatamente no padrão do `TrainerMenu`.

---

## 2. Padrão de Formatação Oficial

O formato oficial a ser utilizado em todo o addon é:

```lua
-- Ouro:   #ffd700 -> |cffffd700{valor}g|r
-- Prata:  #c7c7cf -> |cffc7c7cf{valor}s|r
-- Cobre:  #eda55f -> |cffeda55f{valor}c|r
```

Exemplo:
- `104523` copper = `|cffffd70010g|r |cffc7c7cf45s|r |cffeda55f23c|r`
- `520` copper = `|cffc7c7cf5s|r |cffeda55f20c|r`
- `85` copper = `|cffeda55f85c|r`
- `0` ou nil (quando sem valor/sem buyout) = `|cff999999-|r` (ou `"-"` neutro)

---

## 3. Levantamento Completo de Ocorrências no Addon

### 3.1 Módulos que já estão no padrão correto (Referência)
* **`UI/TrainerMenu.lua`** (linhas 164–181): Implementa `TrainerMenu:FormatMoneyText(totalCopper)`. Usado em cabeçalho, serviços e carrinho.
* **`UI/TrainerMenu-STEAMDECK.lua`**: Idêntico ao TrainerMenu.
* **`UI/MerchantMenu.lua`** (linhas 155–172): Implementa `MerchantMenu:FormatMoneyText(totalCopper)`. Usado em compras, vendas, recompra e reparo.
* **`UI/MailScreen.lua`** (linhas 191–208): Implementa `MailScreen:FormatMoneyText(totalCopper)`. Usado em saldo da barra de status, anexos e logs.
* **`UI/MoneyPicker.lua`** (linhas 43–57): Implementa `FormatMoneyText(totalCopper)`. Usado no total e labels textuais ("Ouro", "Prata", "Cobre").

### 3.2 Módulos que PRECISAM de Migração

#### A. `UI/AuctionScreen.lua` (Maior Impacto — 64 ocorrências)
1. **Definições no topo (`ICONS`)** (linhas 40–42):
   - Remover `GOLD`, `SILVER`, `COPPER` apontando para `Media\coin_*.tga`.
2. **Construtor `CreateMoneyDisplay(parent, height, fontSize, align, width)`** (linhas 594–654):
   - Atualmente cria um `Frame` com 3 `Texture` (`goldIcon`, `silverIcon`, `copperIcon`), 3 `FontString` e `noneText`.
   - **Refatoração necessária:** Manter a função e o frame container (para compatibilidade com `priceDisplay:SetPoint(...)`), mas criar **apenas 1 `FontString`** (`f.text`) dentro dele com alinhamento horizontal especificado (`align` = "LEFT" ou "RIGHT").
3. **Atualizador `SetMoneyDisplay(f, totalCopper)`** (linhas 656–764):
   - Atualmente calcula separadamente, dá `Show/Hide` em cada ícone e texto e recalcula âncoras relativas via `ClearAllPoints`.
   - **Refatoração necessária:** Reduzir a lógica para simplesmente chamar `self:FormatMoney(totalCopper)` e aplicar em `f.text:SetText(...)`. Se `<= 0`, exibir `"-"`.
4. **Locais onde `CreateMoneyDisplay` / `SetMoneyDisplay` são consumidos (não quebram se mantivermos a assinatura)**:
   - **Aba BUY - Lista de Itens Agrupados:** `row.priceDisplay` (7 linhas) em `CreateItemListControls` e `UpdateItemList`.
   - **Aba BUY - Detail Card Split View:** `card.vendorDisplay` em `CreateDetailCard` e `UpdateItemCard`.
   - **Aba BUY - Top Card:** `topCard.vendorDisplay` em `CreateItemDetailControls` e `UpdateItemDetail`.
   - **Aba BUY - Sub-leilões do Item:** `row.bidDisplay` e `row.buyoutDisplay` (6 linhas) em `CreateItemDetailControls` e `UpdateItemDetail`.
   - **Aba BUY - Modal Confirm Purchase/Bid:** `modal.priceDisplay`, `modal.myMoneyDisplay`, `modal.remainingDisplay` em `CreateConfirmModal` e `OpenConfirmModal`.
   - **Aba SELL - Inventário de Bolsas:** `row.vendorDisplay` (7 linhas) em `CreateSellControls` e `UpdateSellInventory`.
   - **Aba SELL - Concorrentes:** `row.unitBidDisplay` e `row.unitBuyDisplay` (6 linhas) em `CreateSellListingControls` e `UpdateSellCompetitorsList`.
   - **Aba SELL - Formulário de Criação:** `r.moneyDisplay` (linhas 1 e 2) em `CreateSellListingControls` e `UpdateSellListingStyles`.
   - **Aba SELL - Resumo Econômico:** `sumUnitPriceDisplay`, `sumBuyoutDisplay`, `sumDepositDisplay` em `CreateSellListingControls` e `UpdateSellListingStyles`.
   - **Aba SELL - Modal Confirm Post:** `modal.unitPriceDisplay`, `modal.buyoutDisplay`, `modal.depositDisplay` em `CreateSellPostConfirmModal` e `OpenSellPostConfirmModal`.
   - **Aba MY AUCTIONS - Meus Leilões:** `row.bidDisplay` e `row.buyoutDisplay` (7 linhas) em `CreateOwnerControls` e `UpdateOwnerList`.

#### B. `UI/MainMenu.lua` (48 ocorrências)
1. **Construtor `MainMenu:CreateMoneyWidget(parent, prefix, alignRight)`** (linhas 2826–2970):
   - Atualmente cria um `Frame` com 3 texturas de moedas (`coin_copper.tga`, `coin_silver.tga`, `coin_gold.tga`) e múltiplos textos com cálculos manuais de âncoras.
   - **Refatoração necessária:** Manter a API `frame:SetAmount(amount)`, substituindo os 3 ícones e 3 textos por 1 único `FontString` com `FormatMoneyText`.
2. **Consumidores no MainMenu**:
   - `sellWidget` (linha 3081): Preço de venda no card de detalhes de itens nas bolsas.
   - `moneyWidget` (linha 3108): Exibição do dinheiro total do jogador na barra de rodapé do menu principal.

#### C. Limpeza de Constantes Não Utilizadas
- Em `UI/TrainerMenu.lua` (linhas 41–43) e `UI/MerchantMenu.lua` (linhas 38–40), remover `GOLD`, `SILVER`, `COPPER` que apontavam para `Interface\MoneyFrame\UI-...` para manter o código limpo.
- Em `Media/`: `coin_copper.tga`, `coin_silver.tga`, `coin_gold.tga` poderão ser removidos ou mantidos desvinculados.

---

## 4. Guia Passo a Passo para Implementação

### Passo 1: Refatoração em `UI/AuctionScreen.lua`

1. **Remover as constantes de textura** no topo:
   ```lua
   -- Remover de ICONS:
   -- GOLD   = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_gold.tga",
   -- SILVER = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_silver.tga",
   -- COPPER = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_copper.tga",
   ```

2. **Garantir a função `FormatMoney`** (já existente por volta da linha 575):
   ```lua
   function AuctionScreen:FormatMoney(totalCopper)
       totalCopper = totalCopper or 0
       if totalCopper < 0 then totalCopper = 0 end

       local gold   = math.floor(totalCopper / 10000)
       local silver = math.floor(math.mod(totalCopper, 10000) / 100)
       local copper = math.floor(math.mod(totalCopper, 100))

       local text = ""
       if gold > 0 then
           text = text .. "|cffffd700" .. gold .. "g|r "
       end
       if silver > 0 or gold > 0 then
           text = text .. "|cffc7c7cf" .. silver .. "s|r "
       end
       text = text .. "|cffeda55f" .. copper .. "c|r"
       return text
   end
   ```

3. **Substituir `AuctionScreen:CreateMoneyDisplay`** por:
   ```lua
   function AuctionScreen:CreateMoneyDisplay(parent, height, fontSize, align, width)
       height = height or 22
       fontSize = fontSize or 15
       align = align or "RIGHT"
       width = width or 150

       local f = CreateFrame("Frame", nil, parent)
       f:SetHeight(height)
       f:SetWidth(width)
       if parent and parent.GetFrameLevel then
           f:SetFrameLevel(parent:GetFrameLevel() + 5)
       end
       f.align = align

       local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
       text:SetAllPoints(f)
       text:SetJustifyH(align)
       text:SetJustifyV("MIDDLE")
       self:ApplyFont(text, FONTS.bodyBold, fontSize)
       f.text = text

       return f
   end
   ```

4. **Substituir `AuctionScreen:SetMoneyDisplay`** por:
   ```lua
   function AuctionScreen:SetMoneyDisplay(f, totalCopper)
       if not f or not f.text then return end

       if not totalCopper or totalCopper <= 0 then
           f.text:SetText("-")
           f.text:SetTextColor(0.60, 0.60, 0.60, 0.80)
           return
       end

       f.text:SetText(self:FormatMoney(totalCopper))
   end
   ```

*Nota:* Como todos os pontos do `AuctionScreen.lua` apenas chamam `self:CreateMoneyDisplay(...)` e `self:SetMoneyDisplay(display, amount)`, **nenhuma das 64 chamadas quebra**! O layout continua intacto e alinhado.

---

### Passo 2: Refatoração em `UI/MainMenu.lua`

1. **Atualizar `MainMenu:CreateMoneyWidget(parent, prefix, alignRight)`**:
   Substituir a criação das 3 texturas e 3 FontStrings por uma estrutura limpa com 1 `prefixText` e 1 `valueText` formatado via `FormatMoneyText`.

2. Implementar a formatação interna:
   ```lua
   local function FormatMoneyText(amount)
       amount = tonumber(amount) or 0
       if amount < 0 then amount = 0 end
       local gold = math.floor(amount / 10000)
       local silver = math.floor(math.mod(amount, 10000) / 100)
       local copper = math.floor(math.mod(amount, 100))

       local text = ""
       if gold > 0 then
           text = text .. "|cffffd700" .. gold .. "g|r "
       end
       if silver > 0 or gold > 0 then
           text = text .. "|cffc7c7cf" .. silver .. "s|r "
       end
       text = text .. "|cffeda55f" .. copper .. "c|r"
       return text
   end
   ```

3. No método `frame:SetAmount(amount)`:
   ```lua
   function frame:SetAmount(amount)
       frame.valueText:SetText(FormatMoneyText(amount))
   end
   ```

---

### Passo 3: Limpeza de Constantes Obsoletas
- Remover as entradas `GOLD`, `SILVER`, `COPPER` de `ICONS` em:
  - `UI/TrainerMenu.lua`
  - `UI/TrainerMenu-STEAMDECK.lua`
  - `UI/MerchantMenu.lua`

---

## 5. Validação e Testes

1. **Compilação Sintática Obrigatória:**
   ```powershell
   C:\Tools\lua50\luac50.exe -p UI\AuctionScreen.lua
   C:\Tools\lua50\luac50.exe -p UI\MainMenu.lua
   C:\Tools\lua50\luac50.exe -p UI\TrainerMenu.lua
   C:\Tools\lua50\luac50.exe -p UI\MerchantMenu.lua
   ```
   Todos devem retornar código de saída `0` sem qualquer warning ou erro.

2. **Teste em Jogo:**
   - Abrir a Casa de Leilão: verificar se os preços na lista de compra, detalhes e formulário de venda aparecem nítidos em `12g 34s 56c`.
   - Executar `/reload` 10 vezes seguidas no chat.
   - Confirmar que nenhuma moeda se corrompe ou vira estática.
   - Abrir o Main Menu (`Start` / `Esc`): checar se o dinheiro do jogador no rodapé e o preço de venda nos itens das bolsas aparecem perfeitamente formatados.
