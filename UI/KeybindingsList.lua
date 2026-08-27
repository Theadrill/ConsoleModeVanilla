--[[
    ConsoleMode - Vanilla
    UI/KeybindingsList.lua - Lista de Mapeamentos e Páginas
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.keybindingsList = CM.config.keybindingsList or {}
local KBList = CM.config.keybindingsList

KBList.frame = nil
KBList.selectedPage = 1

function KBList:Show(parent)
    if not self.frame then
        local f = CreateFrame("Frame", "ConsoleModeKeybindingsListFrame", parent)
        f:SetAllPoints(parent)
        
        local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
        title:SetText("Mapeamento de Atalhos")
        
        local desc = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        desc:SetText("Selecione uma combinacao abaixo para vincular a uma barra de acao:")
        
        self.frame = f
    end
    self.frame:Show()
end

function KBList:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
