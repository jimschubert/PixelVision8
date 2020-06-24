SpriteMode, ColorMode = 0, 1

local toolbarID = "ToolBarUI"

local tools = {"pen", "line", "box", "circle", "eyedropper", "fill", "select"}

local toolKeys = {Keys.P, Keys.L, Keys.B, Keys.C, Keys.I, Keys.F, Keys.M}

local pos = NewPoint(8, 56)

function DrawTool:CreateToolbar()

    self.lastSelectedToolID = nil

    -- Labels for mode changes
    self.editorLabelArgs = {nil, 4, 2, nil, false, false, DrawMode.Tile}

    -- Add the eraser if we are in direct color mode
    table.insert(tools, 2, "eraser")
    table.insert(toolKeys, 2, Keys.E)

    self.lastColorID = 0

    self.modeButton = editorUI:CreateToggleButton({x=pos.X, y=pos.y - 32}, "editormode", "Change into color edit mode.")
    self.modeButton.onAction = function(value) self:ChangeEditMode(value) end

    self.toolBtnData = editorUI:CreateToggleGroup()
    self.toolBtnData.onAction = function(value) self:OnSelectTool(value) end

    local offsetY = 0

    -- Build tools
    for i = 1, #tools do
        offsetY = ((i - 1) * 16) + pos.Y
        local rect = {x = pos.X, y = offsetY, w = 16, h = 16}
        editorUI:ToggleGroupButton(self.toolBtnData, rect, tools[i], "Select the '" .. tools[i] .. "' (".. tostring(toolKeys[i]) .. ") tool.")
    end

    self.flipHButton = editorUI:CreateButton({x = pos.X, y = offsetY + 16 + 8, w = 16, h = 16}, "hflip", "Preview the sprite flipped horizontally.")

    self.flipHButton.onAction = function(value)
        -- Save the new pixel data to history
        self:SaveCanvasState()

        -- Update the canvas and flip the H value
        self:UpdateCanvas(self.lastSelection, true, false)

        -- Save the new pixel data back to the sprite chip
        self:OnSaveCanvasChanges()

    end

    self.flipVButton = editorUI:CreateButton({x = pos.X, y = offsetY + 32 + 8, w = 16, h = 16}, "vflip", "Preview the sprite flipped vertically.")

    self.flipVButton.onAction = function(value)
        
        -- Save the new pixel data to history
        self:SaveCanvasState()

        -- Update the canvas and flip the H value
        self:UpdateCanvas(self.lastSelection, false, true)
        
        -- Save the new pixel data back to the sprite chip
        self:OnSaveCanvasChanges()

    end

    pixelVisionOS:RegisterUI({name = toolbarID}, "UpdateToolbar", self)

end

function DrawTool:UpdateToolbar()

    editorUI:UpdateToggleGroup(self.toolBtnData)
    editorUI:UpdateButton(self.flipHButton)
    editorUI:UpdateButton(self.flipVButton)
    editorUI:UpdateButton(self.modeButton)

    -- if(spriteIDInputData.editing == false) then

        if(Key(Keys.LeftControl) == false and Key(Keys.RightControl) == false) then

            for i = 1, #toolKeys do
                if(Key(toolKeys[i], InputState.Released)) then
                    editorUI:SelectToggleButton(self.toolBtnData, i)
                    break
                end
            end
        end

    -- end
end


function DrawTool:ChangeEditMode(value)

    local mode = value and ColorMode or SpriteMode
    
    if(mode == self.mode) then
        return
    end

    self.mode = mode

    -- Clear bottom of the main window
    for i = 1, 8 do
        editorUI:NewDraw("DrawSprites", {pagebuttonempty.spriteIDs, 10 + i, 20, pagebuttonempty.width, false, false,  DrawMode.Tile})
    end

    if(self.mode == ColorMode) then

        
        -- Make sure the mode button is selected
        if(self.modeButton.selected == false) then
            editorUI:ToggleButton(self.modeButton, true, false)
        end


        self:ShowColorPanel()
        self:HideCanvasPanel()
        -- -- Disable sprite selector
        -- -- Disable the tools
        -- -- Invalidate the color picker
        -- editorUI:NewDraw("DrawSprites", {pickerbottompageedge.spriteIDs, 20, 20, pickerbottompageedge.width, false, false,  DrawMode.Tile})

        self:ToggleToolBar(false)

        self.editorLabelArgs[1] = systemcolorlabel.spriteIDs
        self.editorLabelArgs[4] = systemcolorlabel.width

        pixelVisionOS:EnableItemPicker(self.spritePickerData, false, true)

        self.lastSpriteSelection = self.spritePickerData.currentSelection

        pixelVisionOS:ClearItemPickerSelection(self.spritePickerData)

        editorUI:Enable(self.sizeBtnData,false)
        editorUI:Enable(self.spriteIDInputData,false)
        editorUI:ChangeInputField(self.spriteIDInputData, "", false)

    elseif(self.mode == SpriteMode) then
        
        -- Make sure the mode button is selected
        if(self.modeButton.selected == true) then
            editorUI:ToggleButton(self.modeButton, false, false)
        end

        self:HideColorPanel()
        self:ShowCanvasPanel()
        -- -- Enable sprite selection
        -- -- Enable the tools
        -- -- Invalidate the canvs

        self:ToggleToolBar(true)

        self.editorLabelArgs[1] = spriteeditorlabel.spriteIDs
        self.editorLabelArgs[4] = spriteeditorlabel.width


        -- The sprite picker shouldn't be selectable on this screen but you can still change pages
        pixelVisionOS:EnableItemPicker(self.spritePickerData, true, true)

        editorUI:Enable(self.sizeBtnData, true)
        editorUI:Enable(self.spriteIDInputData, true)

        editorUI:ChangeInputField(self.spriteIDInputData, self.lastSpriteSelection)


        if(self.lastSpriteSelection ~= nil) then
            pixelVisionOS:SelectSpritePickerIndex(self.spritePickerData, self.lastSpriteSelection)
        end

    end

    editorUI:NewDraw("DrawSprites", self.editorLabelArgs)

end

function DrawTool:ToggleToolBar(value)

    if(value == false and self.toolBtnData.currentSelection > 0) then

        -- Save the current tool selection ID
        self.lastSelectedToolID = self.toolBtnData.currentSelection

        -- Force the current selection to be enabled so it will display the disabled graphic
        self.toolBtnData.buttons[self.lastSelectedToolID].enabled = true

        editorUI:ClearGroupSelections(self.toolBtnData)
    end

    -- Loop through all of the buttons and toggle them
    for i = 1, #self.toolBtnData.buttons do
        editorUI:Enable(self.toolBtnData.buttons[i], value)
    end

    editorUI:Enable(self.flipHButton, value)
    editorUI:Enable(self.flipVButton, value)

    if(value == true and self.lastSelectedToolID ~= nil) then
        
        -- print("self.lastSelectedToolID", self.lastSelectedToolID)
        
        -- Restore last selection
        editorUI:SelectToggleButton(self.toolBtnData, self.lastSelectedToolID, false)

        -- Clear the last selection 
        self.lastSelectedToolID = nil

    end

end

function DrawTool:OnSelectTool(value)

    local toolName = tools[value]

    pixelVisionOS:ChangeCanvasTool(self.canvasData, toolName)

    -- We disable the color selection when switching over to the eraser
    if(toolName == "eraser") then

        --  Clear the current color selection
        pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

        -- Disable the color picker
        pixelVisionOS:EnableItemPicker(self.paletteColorPickerData, false)

        -- Make sure the canvas is enabled
        editorUI:Enable(self.canvasData, true)

        -- ResetColorInvalidation()

    else

        -- Change to fill mode if shift is down
        if(Key(Keys.LeftShift) or Key(Keys.RightShift)) then

            self:ToggleFill(true)

        else

            self:ToggleFill(false)

        end

        -- print("Fill", self.canvasData.fill)

        -- We need to restore the color when switching back to a new tool

        -- Make sure the last color is in range
        if(self.lastColorID == nil or self.lastColorID == -1) then

            -- For palette mode, we set the color to the last color per sprite but for direct color mode we set it to the last system color
            self.lastColorID = 0

        end

        
        -- Enable co
        pixelVisionOS:EnableItemPicker(self.paletteColorPickerData, true)

        -- Need to find the right color if we are in palette mode
        -- if(self.usePalettes == true) then

            -- Need to offset the last color id by the current palette page
            -- self.lastColorID = self.lastColorID + ((self.paletteColorPickerData.pages.currentSelection - 1) * 16)

        -- end

        print("restore color", self.lastColorID)

        pixelVisionOS:SelectItemPickerIndex(self.paletteColorPickerData, self.lastColorID)

    end

end

function DrawTool:ToggleFill(value)
    
    -- TODO need to change the value of the canvas
    

    local boxButton = self.toolBtnData.buttons[4]
    local circleButton = self.toolBtnData.buttons[5]

    local resetBoxButton = false
    local resetCircleButton = false

    if(self.canvasData.tool == "box") then
        
        boxButton.spriteName = "box" .. (value == true and "fill" or "")
        editorUI:RebuildSpriteCache(boxButton)

        resetCircleButton = true

    elseif(self.canvasData.tool == "circle") then
        
        circleButton.spriteName = "circle" .. (value == true and "fill" or "")
        editorUI:RebuildSpriteCache(circleButton)

        resetBoxButton = true
    else
        
        resetBoxButton = true
        resetCircleButton = true
        
        -- Reset the fill value regardless of the value
        value = false
    end

    if(boxButton.spriteName == "boxfill" and resetBoxButton == true) then
        boxButton.spriteName = "box"
        editorUI:RebuildSpriteCache(boxButton)
    end

    if(circleButton.spriteName == "circlefill"  and resetCircleButton == true) then
        circleButton.spriteName = "circle"
        editorUI:RebuildSpriteCache(circleButton)
    end

    pixelVisionOS:ToggleCanvasFill(self.canvasData, value)
    

    -- TODO set fill to match the brush color

    -- pixelVisionOS:ToggleCanvasFill(self.canvasData, false)

end