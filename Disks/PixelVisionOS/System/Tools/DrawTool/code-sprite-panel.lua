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

    self.spritePickerData.picker.borderOffset = 8

    self.spritePickerData.onRelease = function(value) self:OnSelectSprite(value) end
    self.spritePickerData.onDropTarget = function(src, dest) self:OnSpritePickerDrop(src, dest) end

    self.spriteIDInputData = editorUI:CreateInputField({x = 176, y = 208, w = 32}, "0", "The ID of the currently selected sprite.", "number", nil, 180)
    self.spriteIDInputData.min = 0
    self.spriteIDInputData.max = gameEditor:TotalSprites() - 1
    self.spriteIDInputData.onAction = function(value) self:ChangeSpriteID(value) end
    
    self.spriteMode = 0
    self.maxSpriteSize = 4

    -- Create size button
    self.sizeBtnData = editorUI:CreateButton({x = 224, y = 200}, "sprite1x", "Pick the sprite size.")
    self.sizeBtnData.onAction = function() self:OnNextSpriteSize() end

    pixelVisionOS:RegisterUI({name = spritePanelID}, "UpdateSpritePanel", self)

end

function DrawTool:UpdateSpritePanel()

    pixelVisionOS:UpdateSpritePicker(self.spritePickerData)
    editorUI:UpdateInputField(self.spriteIDInputData)
    editorUI:UpdateButton(self.sizeBtnData)

    -- TODO need to check if the sprite panel is in focus
    if(pixelVisionOS.editingInputField ~= true and self.selectionMode == SpriteMode) then

        -- Change the scale
        if(Key(Keys.OemMinus, InputState.Released) and self.spriteMode > 1) then
            self:OnNextSpriteSize(true)
        elseif(Key(Keys.OemPlus, InputState.Released) and self.spriteMode < 4) then
            self:OnNextSpriteSize()
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

local selectionSizes = {
    NewPoint(1,1),
    NewPoint(2,1),
    NewPoint(1,2),
    NewPoint(2,2),
    NewPoint(3,3),
    NewPoint(4,4)
}

function DrawTool:OnNextSpriteSize(reverse)

    -- local lastID = tonumber(spriteIDInputData.text)

    -- Loop backwards through the button sizes
    if(Key(Keys.LeftShift) or reverse == true) then
        self.spriteMode = self.spriteMode - 1

        -- Skip 24 x 24 selections
        -- if(self.spriteMode == 3) then
        --     self.spriteMode = 2
        -- end

        if(self.spriteMode < 1) then
            self.spriteMode = #selectionSizes
        end

        -- Loop forward through the button sizes
    else
        self.spriteMode = self.spriteMode + 1

        -- Skip 24 x 24 selections
        -- if(self.spriteMode == 3) then
        --     self.spriteMode = 4
        -- end

        if(self.spriteMode > #selectionSizes) then
            self.spriteMode = 1
        end
    end

    -- Find the next sprite for the button
    local spriteName = "spritemode"..tostring(self.spriteMode)

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

    -- Need to clear any sprite data that is in the clipboard
    self.copiedSpriteData = nil
    pixelVisionOS:EnableMenuItem(PasteShortcut, false)

    editorUI:Invalidate(self.sizeBtnData)

    -- TODO need to rewire this
    -- pixelVisionOS:ChangeCanvasPixelSize(self.canvasData, self.spriteMode)

    -- -- Force the sprite editor to update to the new selection from the sprite picker
    -- self:ChangeSpriteID(self.spritePickerData.currentSelection)

    -- ClearHistory()

    -- self:InvalidateColorPreview()

    -- Get the scale from the sprite picker
    self.posScale = self.spriteMode

    -- TODO need to reindex the colors?

end

function DrawTool:ConfigureSpritePickerSelector(size)
    
    local x = selectionSizes[size].X
    local y = selectionSizes[size].Y

    local spriteName = "selection"..x.."x" .. y
    print("spriteName", size, spriteName)
    _G["spritepickerover"] = {spriteIDs = _G[spriteName .. "over"].spriteIDs, width = _G[spriteName .. "over"].width, colorOffset = 0}

    _G["spritepickerselectedup"] = {spriteIDs = _G[spriteName .. "selected"].spriteIDs, width = _G[spriteName .. "selected"].width, colorOffset = 0}

    pixelVisionOS:ChangeItemPickerScale(self.spritePickerData, size)

end

function DrawTool:ChangeSpriteID(value)

    -- Need to convert the text into a number
    value = tonumber(value)

    pixelVisionOS:SelectSpritePickerIndex(self.spritePickerData, value, false)

    editorUI:ChangeInputField(self.spriteIDInputData, self.spritePickerData.currentSelection, false)

    -- -- ClearHistory()

    -- self:UpdateCanvas(self.spritePickerData.currentSelection)

    self.spritePickerData.dragging = false

end

function DrawTool:OnSelectSprite(value)

    

    -- Reset history
    -- ClearHistory()

    -- print("Sprite", dump(gameEditor:Sprite(value)))

    -- print("test", self.spritePickerData)
    self:ForcePickerFocus(self.spritePickerData)

    -- Update the input field
    editorUI:ChangeInputField(self.spriteIDInputData, value, false)

    -- self:UpdateCanvas(value)

    -- ResetColorInvalidation()

end

function DrawTool:OnSpritePickerDrop(src, dest)

    if(dest.inDragArea == false) then
        return
    end

    -- If the src and the dest are the same, we want to swap colors
    if(src.name == dest.name) then

        -- Get the source color ID
        local srcSpriteID = src.pressSelection.index

        -- Exit this swap if there is no src selection
        if(srcSpriteID == nil) then
            return
        end

        -- Get the destination color ID
        local destSpriteID = pixelVisionOS:CalculateItemPickerPosition(src).index

        -- Make sure the colors are not the same
        if(srcSpriteID ~= destSpriteID) then

            -- Need to shift src and dest ids based onthe color offset
            -- local realSrcID = srcSpriteID-- + systemColorPickerData.colorOffset
            -- local realDestID = destSpriteID-- + systemColorPickerData.colorOffset

            -- TODO need to account for the scroll offset?
            -- print("Swap sprite", srcSpriteID, destSpriteID)

            local srcSprite = gameEditor:ReadGameSpriteData(srcSpriteID, self.spriteMode, self.spriteMode)
            local destSprite = gameEditor:ReadGameSpriteData(destSpriteID, self.spriteMode, self.spriteMode)

            -- Swap the sprite in the tool's color memory
            gameEditor:WriteSpriteData(srcSpriteID, destSprite, self.spriteMode, self.spriteMode)
            gameEditor:WriteSpriteData(destSpriteID, srcSprite, self.spriteMode, self.spriteMode)

            -- Update the pixel data in the spritePicker

            local itemSize = self.spriteMode * 8

            pixelVisionOS:UpdateItemPickerPixelDataAt(self.spritePickerData, srcSpriteID, destSprite, itemSize, itemSize)
            pixelVisionOS:UpdateItemPickerPixelDataAt(self.spritePickerData, destSpriteID, srcSprite, itemSize, itemSize)

            pixelVisionOS:InvalidateItemPickerDisplay(src)

            -- ChangeSpriteID(destSpriteID)

            self:InvalidateData()

        end
    elseif(src.name == self.systemColorPickerData.name) then

    -- Get the current color
    local colorOffset = src.pressSelection.index

    print("Color Offset", src.pressSelection.index)

    -- TODO change the offset of the sprite picker by that value

    pixelVisionOS:ChangeItemPickerColorOffset(dest, src.pressSelection.index + pixelVisionOS.colorOffset)

    end

end