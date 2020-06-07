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
        16, -- Total per page
        16, -- Max pages
        pixelVisionOS.colorOffset,
        "itempicker",
        self.usePalettes == true and "Select palette color " or "Select system color ",
        false,
        true,
        true
    )

    -- TODO this shouldn't have to be called?
    pixelVisionOS:RebuildColorPickerCache(self.paletteColorPickerData)

    print("paletteColorPickerData")
    self.paletteColorPickerData.onAction = function(value)
        self:ForcePickerFocus(paletteColorPickerData)

        self:OnSelectPaletteColor(value)

        -- TODO if in draw mode
        -- if we are in palette mode, just get the currents selection. If we are in direct color mode calculate the real color index
        if(self.usePalettes) then
            value = self.paletteColorPickerData.picker.selected
        end

        -- Make sure if we select the last color, we mark it as the mask color
        if(value == self.paletteColorPickerData.total) then
            value = -1
        end

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

        -- pixelVisionOS:ChangeItemPickerColorOffset(self.spritePickerData, pixelVisionOS.colorOffset + pixelVisionOS.totalPaletteColors + ((value - 1) * 16))

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

        -- Get the index and add 1 to offset it correctly
        local id = pixelVisionOS:CalculateItemPickerPosition(dest).index

        -- Get the correct hex value
        local srcHex = Color(src.pressSelection.index + src.altColorOffset)

        -- print("srcHex", srcHex, "id", id, "ColorID", (src.pressSelection.index + src.altColorOffset))

        if(self.usePalettes == false) then

            if(self.canEdit == true) then
                -- We want to manually toggle the palettes before hand so we can add the first color before calling the AddPalettePage()
                self:TogglePaletteMode(true, function() self:OnAddDroppedColor(id, dest, srcHex) end)
            end

        else
            self:BeginUndo()
            self:OnAddDroppedColor(id, dest, srcHex)
            self:EndUndo()
        end
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

    local colorHex = Color(value + self.paletteColorPickerData.altColorOffset):sub(2, - 1)

    -- Update the selected color hex value
    editorUI:ChangeInputField(self.colorHexInputData, colorHex, false)

    -- Update menu menu items
    pixelVisionOS:EnableMenuItem(AddShortcut, false)
    pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
    pixelVisionOS:EnableMenuItem(EditShortcut, false)
    pixelVisionOS:EnableMenuItem(ClearShortcut, true)

    pixelVisionOS:EnableMenuItem(CopyShortcut, true)

    -- Only enable the paste button if there is a copyValue and we are not in palette mode
    pixelVisionOS:EnableMenuItem(PasteShortcut, self.copyValue ~= nil and self.usePalettes == true)

end