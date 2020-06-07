local spritePanelID = "SpritePanelUI"

function DrawTool:CreateSpritePanel()

    self:ConfigureSpritePickerSelector(1)

    self.newPos = NewPoint()
    self.posScale = 1
    
    -- Get sprite texture dimensions
    local totalSprites = gameEditor:TotalSprites()

    -- This is fixed size at 16 cols (128 pixels wide)
    local spriteColumns = 16
    local spriteRows = math.ceil(totalSprites / 16)

    self.spritePickerData = pixelVisionOS:CreateSpritePicker(
        {x = 176, y = 32, w = 64, h = 128 },
        {x = 8, y = 8},
        spriteColumns,
        spriteRows,
        pixelVisionOS.colorOffset,
        "spritepicker",
        "Pick a sprite",
        true,
        "SpritePicker"
    )

    self.spritePickerData.onRelease = function(value) self:OnSelectSprite(value) end
    self.spritePickerData.onDropTarget = function(src, dest) self:OnSpritePickerDrop(src, dest) end

    -- The sprite picker shouldn't be selectable on this screen but you can still change pages
    -- pixelVisionOS:EnableItemPicker(self.spritePickerData, false, true)

    self.spriteSize = 1
    self.maxSpriteSize = 4

    -- Create size button
    self.sizeBtnData = editorUI:CreateButton({x = 224, y = 200}, "sprite1x", "Pick the sprite size.")
    self.sizeBtnData.onAction = function() self:OnNextSpriteSize() end

    pixelVisionOS:RegisterUI({name = spritePanelID}, "UpdateSpritePanel", self)

end

function DrawTool:UpdateSpritePanel()

    pixelVisionOS:UpdateSpritePicker(self.spritePickerData)
    editorUI:UpdateButton(self.sizeBtnData)

    if(self.colorPreviewInvalid == true) then

        -- TODO need to rewire this
        -- self:DrawColorPerSpriteDisplay()

        -- self:ResetColorPreviewValidation()

    end

    -- TODO need to check if the sprite panel is in focus
    if(self.colorIDInputData.editing == false) then

        if(self.selectionMode == SpriteMode) then
            -- Change the scale
            if(Key(Keys.OemMinus, InputState.Released) and self.spriteSize > 1) then
                self:OnNextSpriteSize(true)
            elseif(Key(Keys.OemPlus, InputState.Released) and self.spriteSize < 4) then
                self:OnNextSpriteSize()
            end

        end

        -- Create a new point to see if we need to change the sprite position
        self.newPos.X = 0
        self.newPos.Y = 0

        -- Offset the new position by the direction button
        if(Key(Keys.Up, InputState.Released)) then
            self.newPos.y = -1 * self.posScale
        elseif(Key(Keys.Right, InputState.Released)) then
            self.newPos.x = 1 * self.posScale
        elseif(Key(Keys.Down, InputState.Released)) then
            self.newPos.y = 1 * self.posScale
        elseif(Key(Keys.Left, InputState.Released)) then
            self.newPos.x = -1 * self.posScale
        end

        -- Test to see if the new position has changed
        if(self.newPos.x ~= 0 or self.newPos.y ~= 0) then

            local curPos = CalculatePosition(self.focusPicker.currentSelection, self.focusPicker.columns)

            self.newPos.x = Clamp(curPos.x + self.newPos.x, 0, self.focusPicker.columns - 1)
            self.newPos.y = Clamp(curPos.y + self.newPos.y, 0, self.focusPicker.rows - 1)

            local newIndex = CalculateIndex(self.newPos.x, self.newPos.y, self.focusPicker.columns)

            self:ChangeSpriteID(newIndex)

        end

    end

end

function DrawTool:OnNextSpriteSize(reverse)

    -- local lastID = tonumber(spriteIDInputData.text)

    -- Loop backwards through the button sizes
    if(Key(Keys.LeftShift) or reverse == true) then
        self.spriteSize = self.spriteSize - 1

        -- Skip 24 x 24 selections
        if(self.spriteSize == 3) then
            self.spriteSize = 2
        end

        if(self.spriteSize < 1) then
            self.spriteSize = self.maxSpriteSize
        end

        -- Loop forward through the button sizes
    else
        self.spriteSize = self.spriteSize + 1

        -- Skip 24 x 24 selections
        if(self.spriteSize == 3) then
            self.spriteSize = 4
        end

        if(self.spriteSize > self.maxSpriteSize) then
            self.spriteSize = 1
        end
    end

    -- Find the next sprite for the button
    local spriteName = "sprite"..tostring(self.spriteSize).."x"

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

    self:ConfigureSpritePickerSelector(self.spriteSize)

    -- Need to clear any sprite data that is in the clipboard
    self.copiedSpriteData = nil
    pixelVisionOS:EnableMenuItem(PasteShortcut, false)

    editorUI:Invalidate(self.sizeBtnData)

    -- TODO need to rewire this
    pixelVisionOS:ChangeCanvasPixelSize(self.canvasData, self.spriteSize)

    -- Force the sprite editor to update to the new selection from the sprite picker
    self:ChangeSpriteID(self.spritePickerData.currentSelection)

    -- ClearHistory()

    self:InvalidateColorPreview()

    -- Get the scale from the sprite picker
    self.posScale = self.spriteSize

    -- TODO need to reindex the colors?

end

function DrawTool:ConfigureSpritePickerSelector(size)

    _G["spritepickerover"] = {spriteIDs = _G["spriteselection"..tostring(size) .."x"].spriteIDs, width = _G["spriteselection"..tostring(size) .."x"].width, colorOffset = 28}

    _G["spritepickerselectedup"] = {spriteIDs = _G["spriteselection"..tostring(size) .."x"].spriteIDs, width = _G["spriteselection"..tostring(size) .."x"].width, colorOffset = (_G["spritepickerover"].colorOffset + 2)}

    pixelVisionOS:ChangeItemPickerScale(self.spritePickerData, size)

end

function DrawTool:ChangeSpriteID(value)

    -- Need to convert the text into a number
    value = tonumber(value)

    pixelVisionOS:SelectSpritePickerIndex(self.spritePickerData, value, false)

    -- -- TODO need to rewire this
    -- -- editorUI:ChangeInputField(self.spriteIDInputData, spritePickerData.currentSelection, false)

    -- -- ClearHistory()

    self:UpdateCanvas(self.spritePickerData.currentSelection)

    self.spritePickerData.dragging = false

end

function DrawTool:OnSelectSprite(value)

    -- Reset history
    -- ClearHistory()

    -- print("test", self.spritePickerData)
    self:ForcePickerFocus(self.spritePickerData)

    -- Update the input field
    editorUI:ChangeInputField(self.colorIDInputData, value, false)

    self:UpdateCanvas(value)

    -- ResetColorInvalidation()

end