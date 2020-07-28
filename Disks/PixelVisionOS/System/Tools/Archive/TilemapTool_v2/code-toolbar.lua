--[[
	Pixel Vision 8 - Draw Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

SpriteMode, ColorMode = 0, 1

local toolbarID = "ToolBarUI"

local tools = {"pointer", "pen", "eraser", "fill"}
local toolKeys = {Keys.v, Keys.P, Keys.E, Keys.F}

local pos = NewPoint(8, 56)

function TilemapTool:CreateToolbar()

    self.lastSelectedToolID = 1

    -- Labels for mode changes
    self.editorLabelArgs = {nil, 4, 2, nil, false, false, DrawMode.Tile}

    
    
    self.toolBtnData = editorUI:CreateToggleGroup()
    self.toolBtnData.onAction = function(value) self:OnSelectTool(value) end

    local offsetY = 0

    -- Build tools
    for i = 1, #tools do
        local offsetX = ((i - 1) * 16) + 160
        local rect = {x = offsetX, y = 56, w = 16, h = 16}
        editorUI:ToggleGroupButton(self.toolBtnData, rect, tools[i], "Select the '" .. tools[i] .. "' (".. tostring(toolKeys[i]) .. ") tool.")

        table.insert(self.enabledUI, self.toolBtnData.buttons[i])
        
    end

    pixelVisionOS:RegisterUI({name = toolbarID}, "UpdateToolbar", self)

end

function TilemapTool:UpdateToolbar()

    editorUI:UpdateToggleGroup(self.toolBtnData)
   
    if(Key(Keys.LeftControl) == false and Key(Keys.RightControl) == false) then

        for i = 1, #toolKeys do
            if(Key(toolKeys[i], InputState.Released)) then
                editorUI:SelectToggleButton(self.toolBtnData, i)
                break
            end
        end
    end

end

function TilemapTool:ToggleToolBar(value)

    if(value == false) then

        -- Force the current selection to be enabled so it will display the disabled graphic
        self.toolBtnData.buttons[self.lastSelectedToolID].enabled = true

        editorUI:ClearGroupSelections(self.toolBtnData)
    end

    -- Loop through all of the buttons and toggle them
    for i = 1, #self.toolBtnData.buttons do
        editorUI:Enable(self.toolBtnData.buttons[i], value)
    end

    editorUI:Enable(self.flipHButton, value)
    editorUI:Enable(self.flipVButton, value)

    if(value == true and self.lastSelectedToolID ~= nil) then

        -- Restore last selection
        editorUI:SelectToggleButton(self.toolBtnData, self.lastSelectedToolID, true)

    end

end

function TilemapTool:OnSelectTool(value)


    -- Save the current tool selection ID
    self.lastSelectedToolID = Clamp(value, 1, #tools)
    
    self.toolMode = value

    -- Clear the last draw id when switching modes
    self.lastDrawTileID = -1

    self.lastSpriteSize = self.spriteSize

    --local lastID = spritePickerData.currentSelection

    if(self.toolMode == 1) then

        -- Clear the sprite picker and tilemap picker
        pixelVisionOS:ClearItemPickerSelection(self.tilePickerData)

    elseif(self.toolMode == 2 or self.toolMode == 3) then

        -- Clear any tilemap picker selection
        pixelVisionOS:ClearItemPickerSelection(self.tilePickerData)

    end

    pixelVisionOS:ChangeTilemapPickerMode(self.tilePickerData, self.toolMode)

end
