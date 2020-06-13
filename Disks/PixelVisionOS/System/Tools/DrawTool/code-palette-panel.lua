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
        self.totalColors,
        pixelVisionOS.colorsPerSprite, -- Total per page
        8, -- Max pages
        pixelVisionOS.colorOffset + 128,
        "itempicker",
        self.usePalettes == true and "Select palette color " or "Select system color ",
        false,
        true,
        true
    )

    -- TODO this shouldn't have to be called?
    pixelVisionOS:RebuildColorPickerCache(self.paletteColorPickerData)

    -- print("paletteColorPickerData")
    self.paletteColorPickerData.onAction = function(value, doubleClick)

        if(doubleClick == true and self.canEdit == true) then

            editorUI:ToggleButton(self.modeButton, true)
            self:ChangeEditMode(ColorMode)
            -- TODO find and select color in picker
            return
        end

        self:ForcePickerFocus(self.paletteColorPickerData)

        self:OnSelectPaletteColor(value)

        -- tmpColor = tmpColor + PaletteOffset(paletteColorPickerData.pages.currentSelection - 1)


        -- TODO if in draw mode
        -- if we are in palette mode, just get the currents selection. If we are in direct color mode calculate the real color index
        -- if(self.usePalettes) then
            value =  value + PaletteOffset(self.paletteColorPickerData.pages.currentSelection - 1)

            
        -- end

        -- Make sure if we select the last color, we mark it as the mask color
        -- if(value == self.paletteColorPickerData.total) then
        --     value = -1
        -- end

        print("Brush Color", value)

        self.lastColorID = value

        local enableCanvas = true

        editorUI:Enable(self.canvasData, enableCanvas)

        -- Set the canvas brush color
        pixelVisionOS:CanvasBrushColor(self.canvasData, value)

    end

    self.paletteColorPickerData.onDropTarget = function(src, dest) self:OnPalettePickerDrop(src, dest) end
    
    if(self.usePalettes == true) then
        -- Force the palette picker to only display the total colors per sprite
        self.paletteColorPickerData.visiblePerPage = pixelVisionOS.paletteColorsPerPage

        pixelVisionOS:OnColorPickerPage(self.paletteColorPickerData, 1)
    else

    end

    -- Wire up the picker to change the color offset of the sprite picker
    self.paletteColorPickerData.onPageAction = function(value)

        
        -- If we are not in palette mode, don't change the sprite color offset
        -- if(self.usePalettes == true) then
            
            local pageOffset = ((value - 1) * 16)

            -- Calculate the new color offset
            local newColorOffset = pixelVisionOS.colorOffset + pixelVisionOS.totalPaletteColors + pageOffset

            pixelVisionOS:ChangeItemPickerColorOffset(self.spritePickerData, newColorOffset)

            -- Update the canvas color offset
            -- self.canvasData.colorOffset = newColorOffset

            -- pixelVisionOS:InvalidateItemPickerDisplay(self.spritePickerData)

            -- self:UpdateCanvas(self.lastSelection)

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

            if(Color(colorID) == self.maskColor) then
            data.canvas.DrawSprites(emptymaskcolor.spriteIDs, x, y, emptymaskcolor.width, false, false)
            else
            data.canvas.Clear(colorID, x, y, data.itemSize.x, data.itemSize.y)
            end
            
        else

            data.canvas.DrawSprites(emptycolor.spriteIDs, x, y, emptycolor.width, false, false)
            
        end

    end

    self:DrawPalettePanelLabel()

    pixelVisionOS:RegisterUI({name = palettePanelID}, "UpdatePalettePanel", self)

end

function DrawTool:DrawPalettePanelLabel()

    if(self.usePalettes == true) then
        
        self.paletteLabelArgs[1] = gamepalettetext.spriteIDs
        self.paletteLabelArgs[4] = gamepalettetext.width

    else

        self.paletteLabelArgs[1] = gamecolortext.spriteIDs
        self.paletteLabelArgs[4] = gamecolortext.width

    end

    editorUI:NewDraw("DrawSprites", self.paletteLabelArgs)
end

function DrawTool:UpdatePalettePanel()

    pixelVisionOS:UpdateColorPicker(self.paletteColorPickerData)

end

function DrawTool:OnPalettePickerDrop(src, dest)
    -- print("Palette Picker On Drop", src.name, dest.name)

    -- Two modes, accept colors from the system color picker or swap colors in the palette

    if(src.name == self.systemColorPickerData.name) then

        -- print("copy colors")
        -- -- Get the index and add 1 to offset it correctly
        local id = pixelVisionOS:CalculateItemPickerPosition(dest).index

        -- -- Get the correct hex value
        local srcHex = Color(src.pressSelection.index + src.altColorOffset)

        -- -- print("srcHex", srcHex, "id", id, "ColorID", (src.pressSelection.index + src.altColorOffset))

        -- if(self.usePalettes == false) then

        --     if(self.canEdit == true) then
        --         -- We want to manually toggle the palettes before hand so we can add the first color before calling the AddPalettePage()
        --         self:TogglePaletteMode(true, function() self:OnAddDroppedColor(id, dest, srcHex) end)
        --     end

        -- else
        --     self:BeginUndo()
            self:OnAddDroppedColor(id, dest, srcHex)
        --     self:EndUndo()
        -- end
    else
        -- print("Swap colors")

        self:OnSystemColorDropTarget(src, dest)

    end

end

function DrawTool:OnSelectPaletteColor(value)

    -- local colorID = pixelVisionOS:CalculateRealColorIndex(paletteColorPickerData, value)

    self.colorIDInputData.max = 256

    -- Disable the hex input field
    -- self:ToggleHexInput(false)
    editorUI:Enable(self.colorIDInputData, false)

    editorUI:ChangeInputField(self.colorIDInputData, tostring(value + 128), false)
    
end