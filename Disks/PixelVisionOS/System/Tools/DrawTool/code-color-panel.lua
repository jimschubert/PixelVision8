local colorPanelID = "ColorPanelUI"

-- Now we need to create the item picker over sprite by using the color selection spriteIDs and changing the color offset
_G["itempickerover"] = {spriteIDs = colorselection.spriteIDs, width = colorselection.width, colorOffset = 28}

-- Next we need to create the item picker selected up sprite by using the color selection spriteIDs and changing the color offset
_G["itempickerselectedup"] = {spriteIDs = colorselection.spriteIDs, width = colorselection.width, colorOffset = (_G["itempickerover"].colorOffset + 2)}


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

    -- Force the BG color to draw for the first time
    self.systemColorPickerData.onPageAction(1)

    -- Create a function to handle what happens when a color is dropped onto the system color picker
    self.systemColorPickerData.onDropTarget = function(src, dest) self:OnSystemColorDropTarget(src, dest) end

    -- Manage what happens when a color is selected
    self.systemColorPickerData.onPress = function(value)

        -- Call the OnSelectSystemColor method to update the fields
        self:OnSelectSystemColor(value)

        -- -- Change the focus of the current color picker
        self:ForcePickerFocus(self.systemColorPickerData)
    end

    self.systemColorPickerData.onAction = function(value, doubleClick)

        if(doubleClick == true and self.canEdit == true) then

            self:OnEditColor()

        end

    end

    self.systemColorPickerData.onChange = function(index, color)
    
        print("Color Change", index, color)
        Color(index, color)

        -- TODO need to go through all of the colors and make sure they are unique

    end

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

-- function DrawTool:UpdateBGIconPosition(id)

--     local pos = CalculatePosition(id % 64, 8)

--     self.BGIconX = pos.x * 16
--     self.BGIconY = pos.y * 16

-- end

function DrawTool:ShowColorPanel()
    print("Show")
    if(self.colorPanelActive == true) then
        return
    end

    self.colorPanelActive = true

    self:RefreshBGColorIcon()

    pixelVisionOS:RegisterUI({name = colorPanelID}, "UpdateColorPanel", self)

    pixelVisionOS:InvalidateItemPickerDisplay(self.systemColorPickerData)
    pixelVisionOS:InvalidateItemPickerPageButton(self.systemColorPickerData)
    -- TODO clear page area?

end

function DrawTool:HideColorPanel()

    if(self.colorPanelActive == false) then
        return
    end

    self.colorPanelActive = false

    pixelVisionOS:RemoveUI(colorPanelID)

end

function DrawTool:UpdateColorPanel()

    pixelVisionOS:UpdateColorPicker(self.systemColorPickerData)

    -- TODO this should be put into the os DRAW queue
    if(self.showBGIcon == true) then
        editorUI:NewDraw("DrawSprites", self.bgDrawArgs)
        -- DrawSprites(bgflagicon.spriteIDs, self.systemColorPickerData.rect.x + self.BGIconX, self.systemColorPickerData.rect.y + self.BGIconY, bgflagicon.width, false, false, DrawMode.UI)
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
        if(realSrcID ~= realDestID) then

            

            -- Get the src and dest color hex value
            local srcColor = Color(realSrcID)
            local destColor = src.copyDrag == true and srcColor or Color(realDestID)
            
            if(Key(Keys.LeftControl) == true or Key(Keys.RightControl) == true) then
                print("Copy")
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

            pixelVisionOS:DisplayMessage("Color ID '"..srcColor.."' was swapped with Color ID '"..destColor .."'", 5)

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