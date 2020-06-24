local palettePanelID = "PalettePanelUI"

function DrawTool:CreatePalettePanel()

    -- local totalColors = pixelVisionOS.totalSystemColors
    -- local totalPerPage = 16--pixelVisionOS.systemColorsPerPage
    -- local maxPages = 16
    -- self.colorOffset = pixelVisionOS.colorOffset

    self.paletteLabelArgs = {gamecolortext.spriteIDs, 4, 21, gamecolortext.width, false, false, DrawMode.Tile}
    
    -- Create the palette color picker
    self.paletteColorPickerData = pixelVisionOS:CreateColorPicker(
        {x = 32, y = 184, w = 128, h = 32},
        {x = 16, y = 16},
        pixelVisionOS.totalPaletteColors,
        pixelVisionOS.colorsPerSprite, -- Total per page
        8, -- Max pages
        pixelVisionOS.colorOffset + 128,
        "itempicker",
        "Select palette color ",
        false,
        true,
        false
    )

    self.paletteColorPickerData.picker.borderOffset = 8

    -- TODO this shouldn't have to be called?
    pixelVisionOS:RebuildColorPickerCache(self.paletteColorPickerData)

    -- print("paletteColorPickerData")
    self.paletteColorPickerData.onAction = function(value, doubleClick)

        if(doubleClick == true and self.canEdit == true) then

            -- editorUI:ToggleButton(self.modeButton, not self.modeButton.value)
            self:ChangeEditMode(not self.modeButton.selected)
            -- TODO find and select color in picker
            return
        end

        self:ForcePickerFocus(self.paletteColorPickerData)
        
        -- Force value to be in palette mode
        value = self.paletteColorPickerData.picker.selected


        self.lastColorID = value

        print("Brush Color", value, self.paletteColorPickerData.pages.currentSelection - 1)

        -- Set the canvas brush color
        pixelVisionOS:CanvasBrushColor(self.canvasData, value)

    end

    self.paletteColorPickerData.onDropTarget = function(src, dest) self:OnPalettePickerDrop(src, dest) end
    
    -- if(self.usePalettes == true) then
        -- Force the palette picker to only display the total colors per sprite
    self.paletteColorPickerData.visiblePerPage = pixelVisionOS.paletteColorsPerPage

    pixelVisionOS:OnColorPickerPage(self.paletteColorPickerData, 1)
    -- else

    -- end

    -- Wire up the picker to change the color offset of the sprite picker
    self.paletteColorPickerData.onPageAction = function(value)

        
        -- If we are not in palette mode, don't change the sprite color offset
        -- if(self.usePalettes == true) then
            
            local pageOffset = ((value - 1) * 16)

            -- Calculate the new color offset
            local newColorOffset = pixelVisionOS.colorOffset + pixelVisionOS.totalPaletteColors + pageOffset

            pixelVisionOS:ChangeItemPickerColorOffset(self.spritePickerData, newColorOffset)

            -- Update the canvas color offset
            self.canvasData.colorOffset = newColorOffset

            pixelVisionOS:InvalidateItemPickerDisplay(self.spritePickerData)

            self:UpdateCanvas(self.lastSelection)

            -- Need to reselect the current color in the new palette if we are in draw mode
            if(self.canvasData.tool ~= "eraser" or self.canvasData.tool ~= "eyedropper") then

                self.lastColorID = Clamp(self.lastColorID, 0, 15)

                pixelVisionOS:SelectColorPickerColor(self.paletteColorPickerData, self.lastColorID + pageOffset)

                pixelVisionOS:CanvasBrushColor(self.canvasData, self.lastColorID)
                -- pixelVisionOS:SelectItemPickerIndex(paletteColorPickerData, lastColorID + pageOffset, true, false)

            end

            -- Make sure we shift the colors by the new page number
            -- self:InvalidateColorPreview()

        -- end

    end

    self.paletteColorPickerData.onDrawColor = function(data, id, x, y)

        if(id < data.total and (id % data.totalPerPage) < data.visiblePerPage) then
            local colorID = id + data.altColorOffset
            
            if(Color(colorID) == pixelVisionOS.maskColor) then
                data.canvas.DrawSprites(emptymaskcolor.spriteIDs, x, y, emptymaskcolor.width, false, false)
            else
                data.canvas.Clear(colorID, x, y, data.itemSize.x, data.itemSize.y)
            end
            
        else
            data.canvas.DrawSprites(emptycolor.spriteIDs, x, y, emptycolor.width, false, false)
        end

    end

    self.paletteColorPickerData.onChange = function(index, color)
    
        Color(index, color)

    end

    self:DrawPalettePanelLabel()

    pixelVisionOS:RegisterUI({name = palettePanelID}, "UpdatePalettePanel", self)

end

function DrawTool:DrawPalettePanelLabel()

    -- if(self.usePalettes == true) then
        
        self.paletteLabelArgs[1] = gamepalettetext.spriteIDs
        self.paletteLabelArgs[4] = gamepalettetext.width

    -- else

        -- self.paletteLabelArgs[1] = gamecolortext.spriteIDs
        -- self.paletteLabelArgs[4] = gamecolortext.width

    -- end

    editorUI:NewDraw("DrawSprites", self.paletteLabelArgs)
end

function DrawTool:UpdatePalettePanel()

    pixelVisionOS:UpdateColorPicker(self.paletteColorPickerData)

    if(self.canvasData.tool == "eyedropper" and self.canvasData.inFocus and MouseButton(0)) then

        local colorID = self.canvasData.overColor

        -- Only update the color selection when it's new
        if(colorID ~= self.lastColorID) then

            self.lastColorID = colorID

            if(colorID < 0) then

                pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

                -- Force the lastColorID to be back in range so there is a color to draw with
                self.lastColorID = -1

            else

                pixelVisionOS:CanvasBrushColor(self.canvasData, self.lastColorID)

                local selectionID = lastColorID

                -- Check to see if in palette mode
                -- if(usePalettes == true) then
                local pageOffset = ((self.paletteColorPickerData.pages.currentSelection - 1) * 16)

                selectionID = Clamp(self.lastColorID, 0, 15) + pageOffset
                    -- pixelVisionOS:SelectColorPickerColor(paletteColorPickerData, Clamp(lastColorID, 0, 15) + pageOffset)
                -- end
                -- else
                pixelVisionOS:SelectColorPickerColor(self.paletteColorPickerData, selectionID)

                -- end


                -- Select the


            end

        end

    end

end

function DrawTool:OnPalettePickerDrop(src, dest)
    
    if(src.name == self.systemColorPickerData.name) then

        -- Get the index and add 1 to offset it correctly
        local id = pixelVisionOS:CalculateItemPickerPosition(dest).index

        -- Get the correct hex value
        local srcHex = Color(src.pressSelection.index + src.altColorOffset)

        self:OnAddDroppedColor(id, dest, srcHex)
        
    else
        
        self:OnSystemColorDropTarget(src, dest)

    end

end
