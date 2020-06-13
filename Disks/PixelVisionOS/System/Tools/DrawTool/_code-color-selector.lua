-- local colorSelectorID = "ColorSelectorUI"

-- function DrawTool:CreateColorSelector()

--     self.maskColorError = "This color is reserved for transparency and can not be assigned to a system color."

--     -- Create an input field for the currently selected color ID
--     self.colorIDInputData = editorUI:CreateInputField({x = 176, y = 208, w = 32}, "0", "The ID of the currently selected color.", "number", "input", 180)

--     -- The minimum value is always 0 and we'll set the maximum value based on which color picker is currently selected
--     self.colorIDInputData.min = 0

--     -- Map the on action to the ChangeColorID method
--     self.colorIDInputData.onAction = function(value) self:ChangeColorID(value) end

--     pixelVisionOS:RegisterUI({name = colorSelectorID}, "UpdateColorSelector", self)

-- end

-- function DrawTool:UpdateColorSelector()

--     editorUI:UpdateInputField(self.colorIDInputData)
    
-- end

-- -- Manages selecting the correct color from a picker based on a change to the color id field
-- function DrawTool:ChangeColorID(value)

--     value = tonumber(value)

--     -- Check to see what mode we are in
--     if(self.selectionMode == SystemColorMode) then

--         -- Select the new color id in the system color picker
--         pixelVisionOS:SelectColorPickerColor(self.systemColorPickerData, value)

--     elseif(self.selectionMode == PaletteMode) then

--         -- Select the new color id in the palette color picker
--         pixelVisionOS:SelectColorPickerColor(self.paletteColorPickerData, value)

--     end

-- end



-- -- This is called when the picker makes a selection
