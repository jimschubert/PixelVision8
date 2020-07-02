local colorPanelID = "ColorPanelUI"

-- Now we need to create the item picker over sprite by using the color selection spriteIDs and changing the color offset
_G["itempickerover"] = {spriteIDs = selection2x2over.spriteIDs, width = selection2x2over.width, colorOffset = 0}

-- Next we need to create the item picker selected up sprite by using the color selection spriteIDs and changing the color offset
_G["itempickerselectedup"] = {spriteIDs = selection2x2selected.spriteIDs, width = selection2x2selected.width, colorOffset = 0}

function DrawTool:CreateColorPanel()

    -- Create the system color picker
    self.systemColorPickerData = pixelVisionOS:CreateColorPicker(
        {x = 32, y = 32, w = 128, h = 128}, -- Rect
        {x = 16, y = 16}, -- Tile size
        pixelVisionOS.totalSystemColors, -- Total colors, plus 1 for empty transparency color
        pixelVisionOS.systemColorsPerPage, -- total per page
        4, -- max pages
        pixelVisionOS.colorOffset, -- Color offset to start reading from
        "itempicker", -- Selection sprite name
        "System Color", -- Tool tip
        false, -- Modify pages
        true, -- Enable dragging,
        true -- drag between pages
    )

    self.bgDrawArgs =
    {
        bgflagicon.spriteIDs,
        0,
        0,
        bgflagicon.width,
        false,
        false,
        DrawMode.Sprite
    }

    self.systemColorPickerData.ctrlCopyEnabled = false

    self.systemColorPickerData.onPageAction = function(value)

        local bgColor = gameEditor:BackgroundColor()
        local bgPageID = math.ceil((bgColor + 1) / 64)

        self.showBGIcon = bgPageID == value

        self:UpdateBGIconPosition(bgColor)

    end

    self.systemColorPickerData.picker.borderOffset = 8

    -- Force the BG color to draw for the first time
    self.systemColorPickerData.onPageAction(1)

    -- Create a function to handle what happens when a color is dropped onto the system color picker
    self.systemColorPickerData.onDropTarget = function(src, dest) self:OnSystemColorDropTarget(src, dest) end

    -- Capture double click action to trigger edit
    self.systemColorPickerData.onAction = function(value, doubleClick)

        -- TODO need to look into how this is actually getting the doubleClick value
        if(doubleClick == true) then

            self:OnEditColor()

        end

    end

    -- Manage what happens when a color is selected
    self.systemColorPickerData.onRelease = function(value) self:OnSelectSystemColor(value) end

    -- Change the color in the tool
    self.systemColorPickerData.onChange = function(index, color) Color(index, color) end

    self.systemColorPickerData.onDrawColor = function(data, id, x, y)

        if(id < data.total and (id % data.totalPerPage) < data.visiblePerPage) then
            local colorID = id + data.altColorOffset

            if(Color(colorID) == self.maskColor) then
            data.canvas.DrawSprites(emptymaskcolor.spriteIDs, x, y, emptymaskcolor.width, false, false)
            else
            data.canvas.Clear(colorID, x, y, data.itemSize.x, data.itemSize.y)
            end
            
        else

            data.canvas.DrawSprites(emptycolor.spriteIDs, x, y, emptycolor.width, false, false)
            
        end

    end


end

function DrawTool:OnSelectSystemColor(value)

    -- Update menu menu items

    -- TODO need to enable this when the color editor pop-up is working
    -- pixelVisionOS:EnableMenuItem(EditShortcut, false)

    -- These are only available based on the palette mode
    -- pixelVisionOS:EnableMenuItem(AddShortcut, true)
    -- pixelVisionOS:EnableMenuItem(DeleteShortcut, true)
    -- pixelVisionOS:EnableMenuItem(BGShortcut, ("#"..colorHex) ~= pixelVisionOS.maskColor)

    -- You can only copy a color when in direct color mode
    -- pixelVisionOS:EnableMenuItem(CopyShortcut, true)

    -- Only enable the paste button if there is a copyValue and we are not in palette mode
    

    -- print("SELECT COLOR", value)
    self.lastSystemColorID = value

    -- Change the focus of the current color picker
    self:ForcePickerFocus(self.systemColorPickerData)


end

-- function DrawTool:UpdateBGIconPosition(id)

--     local pos = CalculatePosition(id % 64, 8)

--     self.BGIconX = pos.x * 16
--     self.BGIconY = pos.y * 16

-- end

function DrawTool:ShowColorPanel()
    -- print("Show")
    if(self.colorPanelActive == true) then
        return
    end

    self.colorPanelActive = true

    self:RefreshBGColorIcon()

    pixelVisionOS:RegisterUI({name = colorPanelID}, "UpdateColorPanel", self)

    pixelVisionOS:InvalidateItemPickerDisplay(self.systemColorPickerData)
    pixelVisionOS:InvalidateItemPickerPageButton(self.systemColorPickerData)
    -- TODO clear page area?

    editorUI:NewDraw("DrawSprites", {pickerbottompageedge.spriteIDs, 20, 20, pickerbottompageedge.width, false, false,  DrawMode.Tile})


end

function DrawTool:HideColorPanel()

    if(self.colorPanelActive == false) then
        return
    end

    self.colorPanelActive = false

    pixelVisionOS:RemoveUI(colorPanelID)

    -- Clear bottom of the main window
    for i = 1, 8 do
        editorUI:NewDraw("DrawSprites", {pagebuttonempty.spriteIDs, 11 + i, 20, pagebuttonempty.width, false, false,  DrawMode.Tile})
    end

    editorUI:NewDraw("DrawSprites", {canvasbottomrightcorner.spriteIDs, 20, 20, canvasbottomrightcorner.width, false, false,  DrawMode.Tile})


end

function DrawTool:UpdateColorPanel()

    pixelVisionOS:UpdateColorPicker(self.systemColorPickerData)

    -- TODO this should be put into the os DRAW queue
    if(self.showBGIcon == true) then
        editorUI:NewDraw("DrawSprites", self.bgDrawArgs)
        -- DrawSprites(bgflagicon.spriteIDs, self.systemColorPickerData.rect.x + self.BGIconX, self.systemColorPickerData.rect.y + self.BGIconY, bgflagicon.width, false, false, DrawMode.UI)
    end
end

function DrawTool:UpdateHexColor(value)

    if(self.selectionMode == PaletteMode) then
        return false
    end

    value = "#".. value


    if(value == pixelVisionOS.maskColor) then

        -- TODO this are is throwing an error
        -- print("MASK COLOR ERROR")
        pixelVisionOS:ShowMessageModal(self.toolName .." Error", self.maskColorError, 160, false)

        return false

    else

        local realColorID = self.systemColorPickerData.currentSelection + self.systemColorPickerData.altColorOffset

        local currentColor = Color(realColorID)

        -- Make sure the color isn't duplicated when in palette mode
        for i = 1, 128 do

            -- Test the new color against all of the existing system colors
            if(value == Color(pixelVisionOS.colorOffset + (i - 1))) then

                -- TODO need to move this to the config at the top
                pixelVisionOS:ShowMessageModal(self.toolName .." Error", "'".. value .."' the same as system color ".. (i - 1) ..", enter a new color.", 160, false)

                -- Exit out of the update function
                return false

            end

        end

        -- Test if the color is at the end of the picker and the is room to add a new color
        if(self.colorID == self.systemColorPickerData.total - 1 and self.systemColorPickerData.total < 255) then

            -- Select the current color we are editing
            pixelVisionOS:SelectColorPickerColor(self.systemColorPickerData, realColorID)

        end

        -- Update the editor's color
        pixelVisionOS:ColorPickerChangeColor(self.systemColorPickerData, realColorID, value)

        -- Loop through the palette color memory to remove replace all matching colors
        for i = 127, pixelVisionOS.totalColors do

            local index = (i - 1) + pixelVisionOS.colorOffset

            -- Get the current color in the tool's memory
            local tmpColor = Color(index)

            -- See if that color matches the old color
            if(tmpColor == currentColor and tmpColor ~= pixelVisionOS.maskColor) then

                -- Set the color to equal the new color
                pixelVisionOS:ColorPickerChangeColor(self.paletteColorPickerData, index, value)

            end

        end

        self:InvalidateData()

        return true
    end

end

function DrawTool:OnSystemColorDropTarget(src, dest)

    -- If the src and the dest are the same, we want to swap colors
    if(src.name == dest.name) then

        -- Get the source color ID
        local srcPos = src.pressSelection

        -- Get the destination color ID
        local destPos = pixelVisionOS:CalculateItemPickerPosition(src)

        -- Need to shift src and dest ids based on the color offset
        local realSrcID = srcPos.index + src.altColorOffset
        local realDestID = destPos.index + dest.altColorOffset

        -- Make sure the colors are not the same
        if(realSrcID ~= realDestID and destPos.index < dest.total) then

            -- Get the src and dest color hex value
            local srcColor = Color(realSrcID)
            local destColor = src.copyDrag == true and srcColor or Color(realDestID)
            
            if(Key(Keys.LeftControl) == true or Key(Keys.RightControl) == true) then
                -- print("Copy")
            end

            -- Make sure we are not moving a transparent color
            if(srcColor == pixelVisionOS.maskColor or destColor == pixelVisionOS.maskColor) then

                if(self.usePalettes == true and dest.name == self.systemColorPickerData.name) then

                    pixelVisionOS:ShowMessageModal(self.toolName .." Error", "You can not replace the last color which is reserved for transparency.", 160, false)

                    return

                end

            end

            self:BeginUndo()
            
            -- Swap the colors in the tool's color memory
            pixelVisionOS:ColorPickerChangeColor(dest, realSrcID, destColor)
            pixelVisionOS:ColorPickerChangeColor(dest, realDestID, srcColor)

            -- Update just the colors that changed
            local srcPixelData = pixelVisionOS:ReadItemPickerOverPixelData(src, srcPos.x, srcPos.y)

            local destPixelData = pixelVisionOS:ReadItemPickerOverPixelData(dest, destPos.x, destPos.y)

            src.canvas.SetPixels(srcPos.x, srcPos.y, src.itemSize.x, src.itemSize.y, srcPixelData)

            pixelVisionOS:InvalidateItemPickerDisplay(src)

            src.canvas.SetPixels(destPos.x, destPos.y, dest.itemSize.x, dest.itemSize.y, destPixelData)
            -- Redraw the color page
            pixelVisionOS:InvalidateItemPickerDisplay(dest)

            pixelVisionOS:DisplayMessage("Color ID '"..realSrcID.."' was swapped with Color ID '"..realDestID .."'", 5)

            self:EndUndo()

            -- Invalidate the data so the tool can save
            self:InvalidateData()

        end

    end

end

function DrawTool:RefreshBGColorIcon()
    
    -- Correct the BG color if needed
    if(gameEditor:BackgroundColor() >= pixelVisionOS.totalSystemColors) then

        gameEditor:BackgroundColor(pixelVisionOS.totalSystemColors - 1)

    end

    self:UpdateBGIconPosition(gameEditor:BackgroundColor())

end

function DrawTool:UpdateBGIconPosition(id)

    local pos = CalculatePosition(id % 64, 8)


    self.bgDrawArgs[2] = self.systemColorPickerData.rect.x + (pos.x * 16)
    self.bgDrawArgs[3] = self.systemColorPickerData.rect.y + (pos.y * 16)
    -- self.BGIconX = pos.x * 16
    -- self.BGIconY = pos.y * 16

end