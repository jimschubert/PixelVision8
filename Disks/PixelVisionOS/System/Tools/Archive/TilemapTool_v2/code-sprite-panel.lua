--[[
	Pixel Vision 8 - Draw Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

local spritePanelID = "SpritePanelUI"

function TilemapTool:CreateSpritePanel()
   
    self.colorLayerTime = 0
    self.colorLayerDelay = 500
    self.showIsolatedColor = false
    self.sizeDisplayText = ""
    
    self.selectionSizes = {
        {x = 1, y = 1, scale = 16},
        --{x = 1, y = 2, scale = 8},
        --{x = 2, y = 1, scale = 8},
        {x = 2, y = 2, scale = 8},
        -- {x = 3, y = 3, scale = 4},
        {x = 4, y = 4, scale = 4}
    }

    -- TODO may need to move this down?
    self:ConfigureSpritePickerSelector(1)

    self.newPos = NewPoint()
    
    -- Get sprite texture dimensions
    local totalSprites = gameEditor:TotalSprites()

    -- This is fixed size at 16 cols (128 pixels wide)
    local spriteColumns = 16
    local spriteRows = math.ceil(totalSprites / 16)

    self.spritePickerData = pixelVisionOS:CreateSpritePicker(
        {x = 8, y = 24, w = 128, h = 32 },
        {x = 8, y = 8},
        spriteColumns,
        spriteRows,
        pixelVisionOS.colorOffset,
        "spritepicker",
        "Pick a sprite",
        false,
        "SpritePicker"
    )

    self.spritePickerData.picker.borderOffset = 8

    self.spritePickerData.onAction = function(value) self:ChangeSpriteID(value) end
    --self.spritePickerData.onPress = function(value) self:OnSelectSprite(value) end
    
    --self.spritePickerData.onDropTarget = function(src, dest) self:OnSpritePickerDrop(src, dest) end

    self.spriteMode = 0
    self.maxSpriteSize = #self.selectionSizes

    -- Create size button
    self.sizeBtnData = editorUI:CreateButton({x = 160, y = 24}, "spritemode1x1", "Pick the sprite size.")
    self.sizeBtnData.onAction = function() self:OnNextSpriteSize() end

    -- Add the size button to the list of enabled UI
    table.insert(self.enabledUI, self.sizeBtnData)
    
    pixelVisionOS:RegisterUI({name = spritePanelID}, "UpdateSpritePanel", self)

end

function TilemapTool:UpdateSpritePanel()

    pixelVisionOS:UpdateSpritePicker(self.spritePickerData)
    --editorUI:UpdateInputField(self.spriteIDInputData)
    editorUI:UpdateButton(self.sizeBtnData)

    -- TODO need to check if the sprite panel is in focus
    if(self.selectionMode == SpriteMode) then

        -- Change the scale
        if(Key(Keys.OemMinus, InputState.Released) and self.spriteMode > 1) then
            self:OnNextSpriteSize(true)
        elseif(Key(Keys.OemPlus, InputState.Released) and self.spriteMode < self.maxSpriteSize) then
            self:OnNextSpriteSize()
        end

        -- Create a new point to see if we need to change the sprite position
        self.newPos.X = 0
        self.newPos.Y = 0

        -- Offset the new position by the direction button
        if(Key(Keys.Up, InputState.Released)) then
            self.newPos.y = -1 * self.selectionSize.y
        elseif(Key(Keys.Right, InputState.Released)) then
            self.newPos.x = 1 * self.selectionSize.x
        elseif(Key(Keys.Down, InputState.Released)) then
            self.newPos.y = 1 * self.selectionSize.y
        elseif(Key(Keys.Left, InputState.Released)) then
            self.newPos.x = -1 * self.selectionSize.x
        end

        -- Test to see if the new position has changed
        if(self.newPos.x ~= 0 or self.newPos.y ~= 0) then

            local curPos = CalculatePosition(self.panelInFocus.currentSelection, self.panelInFocus.columns)

            self.newPos.x = Clamp(curPos.x + self.newPos.x, 0, self.panelInFocus.columns - 1)
            self.newPos.y = Clamp(curPos.y + self.newPos.y, 0, self.panelInFocus.rows - 1)

            local newIndex = CalculateIndex(self.newPos.x, self.newPos.y, self.panelInFocus.columns)

            self:ChangeSpriteID(newIndex)

        end

    end

    --if(self.lastSpriteOffset ~= self.spritePickerData.colorOffset) then
    --    self.lastSpriteOffset = self.spritePickerData.colorOffset
    --    self.offsetDisplayText = string.format("OFFSET %03d", self.lastSpriteOffset - pixelVisionOS.colorOffset)
    --end
    --
    --editorUI:NewDraw("DrawText", {self.offsetDisplayText, self.spritePickerData.rect.x + self.spritePickerData.rect.w - (#self.offsetDisplayText*4), self.spritePickerData.rect.y - 16, DrawMode.Sprite, "medium", 6, -4})

    --if(self.lastSpriteSize ~= self.selectionSizes[self.spriteMode]) then
    --    self.lastSpriteSize = self.selectionSizes[self.spriteMode]
    --    self.sizeDisplayText = string.format("%02dx%02d", self.lastSpriteSize.x * editorUI.spriteSize.x, self.lastSpriteSize.y * editorUI.spriteSize.y)
    --end
    --
    ---- TODO for some reason this is not working
    --editorUI:NewDraw("DrawText", {self.sizeDisplayText, 160, 24 +  16, DrawMode.Sprite, "medium", 6, -4 })

end



function TilemapTool:OnNextSpriteSize(reverse)

    -- Loop backwards through the button sizes
    if(Key(Keys.LeftShift) or reverse == true) then
        self.spriteMode = self.spriteMode - 1

        if(self.spriteMode < 1) then
            self.spriteMode = #self.selectionSizes
        end

    else
        self.spriteMode = self.spriteMode + 1

        if(self.spriteMode > #self.selectionSizes) then
            self.spriteMode = 1
        end
    end

    -- Find the next sprite for the button
    local spriteName = "spritemode"..self.selectionSizes[self.spriteMode].x.."x" .. self.selectionSizes[self.spriteMode].y

    -- Change sprite button graphic
    self.sizeBtnData.cachedSpriteData = {
        up = _G[spriteName .. "up"],
        down = _G[spriteName .. "down"] ~= nil and _G[spriteName .. "down"] or _G[spriteName .. "selectedup"],
        over = _G[spriteName .. "over"],
        selectedup = _G[spriteName .. "selectedup"],
        selectedover = _G[spriteName .. "selectedover"],
        selecteddown = _G[spriteName .. "selecteddown"] ~= nil and _G[spriteName .. "selecteddown"] or _G[spriteName .. "selectedover"],
        disabled = _G[spriteName .. "disabled"],
        empty = _G[spriteName .. "empty"] -- used to clear the sprites
    }

    self:ConfigureSpritePickerSelector(self.spriteMode)

    editorUI:Invalidate(self.sizeBtnData)

    -- Force the sprite editor to update to the new selection from the sprite picker
    self:ChangeSpriteID(self.spritePickerData.currentSelection)

    -- TODO need to wire up tilemap picker
    -- Reset the flag preview
    --pixelVisionOS:ChangeTilemapPaintFlag(self.tilePickerData, self.tilePickerData.paintFlagIndex)

end

function TilemapTool:ConfigureSpritePickerSelector(size)
    
    self.selectionSize = self.selectionSizes[size]

    local x = self.selectionSize.x
    local y = self.selectionSize.y

    local spriteName = "selection"..x.."x" .. y
    
    _G["spritepickerover"] = {spriteIDs = _G[spriteName .. "over"].spriteIDs, width = _G[spriteName .. "over"].width, colorOffset = 0}

    -- local state = self.selectionMode == SpriteMode and "selected" or "over"

    _G["spritepickerselectedup"] = {spriteIDs = _G[spriteName .. "selected"].spriteIDs, width = _G[spriteName .. "selected"].width, colorOffset = 0}

    pixelVisionOS:ChangeItemPickerScale(self.spritePickerData, size, self.selectionSize)

    --if(self.tilePickerData ~= nil) then
    --    pixelVisionOS:ChangeItemPickerScale(self.tilePickerData, size)
    --end

end

function TilemapTool:ChangeSpriteID(value)

    -- Need to convert the text into a number
    value = tonumber(value)

    pixelVisionOS:SelectSpritePickerIndex(self.spritePickerData, value, false)

    self:ForcePickerFocus(self.spritePickerData)

    if(self.mode ~= TileMode) then

        -- TODO Need to finish wiring this up
        self:ChangeEditMode(TileMode)
        
    end

    --if(self.tilePickerData ~= nil) then
    --    pixelVisionOS:ChangeTilemapPaintSpriteID(self.tilePickerData, self.spritePickerData.pressSelection.index)
    --end
end
--
--function OnSelectSprite(value)
--
--    pixelVisionOS:ChangeTilemapPaintSpriteID(tilePickerData, spritePickerData.pressSelection.index)
--
--end
