--[[
    ConsoleMode - Vanilla
    UI/ActionBarPicker.lua - Mapeador Visual Interativo de Barras de Ação
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.picker = CM.config.picker or {}
local Picker = CM.config.picker

Picker.active = false
Picker.targetBinding = nil

function Picker:Start(targetBinding)
    self.active = true
    self.targetBinding = targetBinding
    CM.logger:Log("ActionBar Picker ativado para: " .. tostring(targetBinding))
end

function Picker:Stop()
    self.active = false
    self.targetBinding = nil
end
