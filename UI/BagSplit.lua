-- ============================================================================
-- ConsoleModeVanilla - UI/BagSplit.lua
-- Divisor assincrono de pilhas (bag -> slot vazio), sem sair da tela atual.
-- Uso: BagSplit:Start(bag, slot, qty, cbs) divide qty num slot vazio e avisa
-- via cbs.onDone(newBag, newSlot, qty, ctx) ou cbs.onFail(reason, ctx).
-- ASSINCRONO: leituras de bolsa no mesmo frame da mutacao nao sao confiaveis
-- neste cliente; cada passo e verificado 1s depois (bomba OnUpdate propria).
-- Falha em qualquer passo devolve o cursor e aborta sem mexer em nada.
-- Modulo sem dependencia de sessao (mail/main menu): so APIs de bolsa.
-- Compativel com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW).
-- ============================================================================

ConsoleMode_BagSplit = ConsoleMode_BagSplit or {}
local BagSplit = ConsoleMode_BagSplit
local CM = ConsoleMode or {}
CM.BagSplit = BagSplit

BagSplit.op = nil

function BagSplit:IsBusy()
    return self.op ~= nil
end

function BagSplit:Cancel()
    self.op = nil
end

function BagSplit:CursorHoldsItem()
    if CursorHasItem then
        local ok, v = pcall(CursorHasItem)
        if ok and v then return true end
    end
    if CursorHasMoney then
        local ok2, v2 = pcall(CursorHasMoney)
        if ok2 and v2 then return true end
    end
    return false
end

function BagSplit:ReadBagCount(bag, slot)
    if not GetContainerItemInfo then return nil end
    local ok, _, c = pcall(GetContainerItemInfo, bag, slot)
    if ok and tonumber(c) then return tonumber(c) end
    return nil
end

-- Primeiro slot vazio das bolsas (0-4). Retorna bag, slot ou nil, nil.
function BagSplit:FindEmptyBagSlot()
    if not GetContainerNumSlots or not GetContainerItemLink then
        return nil, nil
    end
    for bag = 0, 4 do
        local okS, numSlots = pcall(GetContainerNumSlots, bag)
        numSlots = tonumber(numSlots) or 0
        if okS and numSlots > 0 then
            for slot = 1, numSlots do
                local okL, link = pcall(GetContainerItemLink, bag, slot)
                if okL and not link then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

-- Inicia a divisao. Retorna true (op em andamento, fim via callbacks) ou
-- false + motivo (falha imediata, nada mexido). cbs = { onDone, onFail, ctx }.
function BagSplit:Start(bag, slot, qty, cbs)
    if self.op then
        return false, "divisao ja em andamento"
    end
    qty = tonumber(qty) or 0
    if bag == nil or slot == nil or qty < 1 then
        return false, "slot ou quantidade invalidos"
    end
    if SplitContainerItem == nil or PickupContainerItem == nil then
        return false, "API de bolsas ausente"
    end
    if self:CursorHoldsItem() then
        return false, "cursor ocupado"
    end
    local mx = self:ReadBagCount(bag, slot)
    if mx == nil or mx < 1 then
        return false, "slot vazio ou ilegivel"
    end
    if qty >= mx then
        return false, "quantidade e a pilha cheia"
    end
    local eb, es = self:FindEmptyBagSlot()
    if eb == nil then
        return false, "sem espaco na bolsa p/ dividir"
    end
    cbs = cbs or {}
    pcall(SplitContainerItem, bag, slot, qty)
    if not self:CursorHoldsItem() then
        return false, "item nao saiu da bolsa"
    end
    local t0 = nil
    if GetTime then
        local okT, now = pcall(GetTime)
        if okT and type(now) == "number" then t0 = now end
    end
    self.op = {
        bag = bag, slot = slot, qty = qty, mx = mx,
        eb = eb, es = es, cbs = cbs,
        phase = "verify", t0 = t0, at = t0 and (t0 + 1) or nil,
    }
    return true
end

function BagSplit:RecoverCursor(op)
    if not op then return end
    if not self:CursorHoldsItem() then return end
    -- Devolve ao original se vazio, senao ao slot reserva; nunca deleta.
    local destBag, destSlot = op.eb, op.es
    if GetContainerItemLink then
        local okL, link = pcall(GetContainerItemLink, op.bag, op.slot)
        if okL and not link then
            destBag, destSlot = op.bag, op.slot
        end
    end
    pcall(PickupContainerItem, destBag, destSlot)
end

function BagSplit:FailOp(reason)
    local op = self.op
    self.op = nil
    if op and op.cbs and op.cbs.onFail then
        pcall(op.cbs.onFail, reason, op.cbs.ctx)
    end
end

function BagSplit:OnUpdate()
    local op = self.op
    if not op then return end
    if not GetTime then
        self.op = nil
        return
    end
    local okT, now = pcall(GetTime)
    if not okT or type(now) ~= "number" then return end
    if op.at == nil then
        op.at = now + 1
    end
    if op.t0 and type(op.t0) == "number" and (now - op.t0) > 10 then
        self:RecoverCursor(op)
        self:FailOp("divisao expirou (10s)")
        return
    end
    if type(op.at) == "number" and now < op.at then return end
    if op.phase == "verify" then
        -- Resto no original deve ser mx-qty (leitura fresca, 1s depois).
        local rem = self:ReadBagCount(op.bag, op.slot)
        if rem == (op.mx - op.qty) and self:CursorHoldsItem() then
            pcall(PickupContainerItem, op.eb, op.es)
            if self:CursorHoldsItem() then
                self:RecoverCursor(op)
                self:FailOp("deposito falhou (recoloque o cursor)")
                return
            end
            op.phase = "verify2"
            op.at = now + 1
            return
        end
        self:RecoverCursor(op)
        self:FailOp("resto x" .. tostring(rem) .. ", esperado x" .. (op.mx - op.qty))
        return
    end
    if op.phase == "verify2" then
        local got = self:ReadBagCount(op.eb, op.es)
        local cbs = op.cbs
        self.op = nil
        if got == op.qty and not self:CursorHoldsItem() then
            if cbs and cbs.onDone then
                pcall(cbs.onDone, op.eb, op.es, op.qty, cbs.ctx)
            end
            return
        end
        if cbs and cbs.onFail then
            pcall(cbs.onFail, "pilha nova com x" .. tostring(got) .. " (esperado x" .. op.qty .. ")", cbs.ctx)
        end
        return
    end
    self.op = nil
end

local pump = CreateFrame("Frame", "ConsoleMode_BagSplitPump")
pump:SetScript("OnUpdate", function()
    local bs = ConsoleMode_BagSplit
    if bs and bs.OnUpdate then
        bs:OnUpdate()
    end
end)
