local colorSelectorID = "ColorSelectorUI"

function DrawTool:CreateColorSelector()

    self.maskColorError = "This color is reserved for transparency and can not be assigned to a system color."

    -- Create an input field for the currently selected color ID
    self.colorIDInputData = editorUI:CreateInputField({x = 176, y = 208, w = 32}, "0", "The ID of the currently selected color.", "number", "input", 180)

    -- The minimum value is always 0 and we'll set the maximum value based on which color picker is currently selected
    self.colorIDInputData.min = 0

    -- Map the on action to the ChangeColorID method
    self.colorIDInputData.onAction = function(value) self:ChangeColorID(value) end

    -- Create a hex color input field
    self.colorHexInputData = editorUI:CreateInputField({x = 200, y = 208, w = 48}, "FF00FF", "Hex value of the selected color.", "hex", "input", 180)

    self.colorHexInputData.forceCase = "upper"
    -- -- Call the UpdateHexColor function when a change is made
    self.colorHexInputData.onAction = function(value) self:UpdateHexColor(value) end

    pixelVisionOS:RegisterUI({name = colorSelectorID}, "UpdateColorSelector", self)

end

function DrawTool:UpdateColorSelector()

    editorUI:UpdateInputField(self.colorIDInputData)
    -- editorUI:UpdateInputField(self.colorHexInputData)

end

-- Manages selecting the correct color from a picker based on a change to the color id field
function DrawTool:ChangeColorID(value)

    value = tonumber(value)
    -- print("Change Color ID", value)
    -- Check to see what mode we are in
    if(self.selectionMode == SystemColorMode) then

        -- Select the new color id in the system color picker
        pixelVisionOS:SelectColorPickerColor(self.systemColorPickerData, value)

    elseif(self.selectionMode == PaletteMode) then

        -- Select the new color id in the palette color picker
        pixelVisionOS:SelectColorPickerColor(self.paletteColorPickerData, value)

    end

end

function DrawTool:UpdateHexColor(value)

    if(self.selectionMode == PaletteMode) then
        return false
    end

    value = "#".. value


    if(value == pixelVisionOS.maskColor) then

        pixelVisionOS:ShowMessageModal(self.toolName .." Error", self.maskColorError, 160, false)

        return false

    elseif(value ~= "#"..self.colorHexInputData.text) then

        local realColorID = self.systemColorPickerData.currentSelection + self.systemColorPickerData.altColorOffset

        local currentColor = Color(realColorID)

        -- Make sure the color isn't duplicated when in palette mode
        for i = 1, 128 do

            -- Test the new color against all of the existing system colors
            if(value == Color(pixelVisionOS.colorOffset + (i - 1))) then

                -- TODO need to move this to the config at the top
                pixelVisionOS:ShowMessageModal(self.toolName .." Error", "'".. value .."' the same as system color ".. (i - 1) ..", enter a new color.", 160, false,
                    -- Make sure we restore the color value after the modal closes
                    function()

                        -- Change the color back to the original value in the input field
                        editorUI:ChangeInputField(self.colorHexInputData, currentColor:sub(2, - 1), false)

                    end
                )

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

        -- After updating the color, check to see if in palette mode and replace all matching colors in the palettes
        if(self.usePalettes == true) then

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

        end

        self:InvalidateData()

        return true
    end

end

-- This is called when the picker makes a selection
function DrawTool:OnSelectSystemColor(value)

    -- Calculate the color ID from the picker
    -- local colorID = pixelVisionOS:CalculateRealColorIndex(systemColorPickerData, value)

    -- Update the ID input field's max value from the OS's system color total
    self.colorIDInputData.max = pixelVisionOS.totalSystemColors - 1

    -- Enable the color id input field
    editorUI:Enable(self.colorIDInputData, true)

    -- Update the color id field
    editorUI:ChangeInputField(self.colorIDInputData, tostring(value), false)

    -- Enable the hex input field
    -- self:ToggleHexInput(true)

    -- Get the current hex value of the selected color
    local colorHex = Color(value + self.systemColorPickerData.altColorOffset):sub(2, - 1)

    if(self.lastSelection ~= value) then

        self.lastSelection = value
        self.lastColor = colorHex

    end

    -- Update the selected color hex value
    editorUI:ChangeInputField(self.colorHexInputData, colorHex, false)

    -- Update menu menu items

    -- TODO need to enable this when the color editor pop-up is working
    pixelVisionOS:EnableMenuItem(EditShortcut, self.canEdit)

    -- These are only available based on the palette mode
    pixelVisionOS:EnableMenuItem(AddShortcut, self.canEdit)
    pixelVisionOS:EnableMenuItem(DeleteShortcut, self.canEdit)
    pixelVisionOS:EnableMenuItem(BGShortcut, ("#"..colorHex) ~= pixelVisionOS.maskColor)

    -- You can only copy a color when in direct color mode
    pixelVisionOS:EnableMenuItem(CopyShortcut, true)

    -- Only enable the paste button if there is a copyValue and we are not in palette mode
    pixelVisionOS:EnableMenuItem(PasteShortcut, self.copyValue ~= nil and self.usePalettes == false)

end

-- function DrawTool:ToggleHexInput(value)

--     editorUI:Enable(self.colorHexInputData, value)

--     DrawText("#", 24, 26, DrawMode.Tile, "input", value and self.colorHexInputData.highlighterTheme.text or self.colorHexInputData.highlighterTheme.disabled)

--     if(value == false) then
--         -- Clear values in fields
--         -- Update the color id field
--         editorUI:ChangeInputField(self.colorIDInputData, - 1, false)

--         -- Update the color id field
--         editorUI:ChangeInputField(self.colorHexInputData, string.sub(pixelVisionOS.maskColor, 2, 7), false)
--     end

-- end