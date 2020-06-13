
local canvasID = "CanvasUI"

function DrawTool:CreateCanvas()
    self.showBGColor = false
    self.lastCanvasScale = 0
    self.lastCanvasSize = 0
    self.cps = gameEditor:ColorsPerSprite()

    self.canvasData = pixelVisionOS:CreateCanvas(
        {
            x = 32,
            y = 32,
            w = 128,
            h = 128
        },
        {
            x = 128,
            y = 128
        },
        1,
        self.colorOffset,
        "Draw on the canvas",
        pixelVisionOS.emptyColorID
    )

    self.canvasData.onPress = function()
            
        self:SaveCanvasState()
        -- local pixelData = editorUI:GetCanvasPixelData(canvasData)

        self.canvasData.inDrawMode = true

        -- UpdateHistory(pixelData)
    end

    editorUI.collisionManager:EnableDragging(self.canvasData, .5, "SpritePicker")

    self.canvasData.onDropTarget = function(src, dest) self:OnCanvasDrop(src, dest) end

    self.canvasData.onAction = function() self:OnSaveCanvasChanges() end

end

-- TODO need to rename this and change other UpdateCanvas function
function DrawTool:UpdateCanvasUI()

    pixelVisionOS:UpdateCanvas(self.canvasData)

    -- if(self.colorPreviewInvalid == true) then

    --     self:DrawColorPerSpriteDisplay()

    --     self:ResetColorPreviewValidation()

    -- end

end

function DrawTool:SaveCanvasState()

    --UpdateHistory(pixelVisionOS:GetCanvasPixelData(canvasData))

    -- if(self.colorPreviewInvalid == true) then

    --     self:DrawColorPerSpriteDisplay()

    --     self:ResetColorPreviewValidation()

    -- end

end

function DrawTool:ShowCanvasPanel()

    if(self.canvasPanelActive == true) then
        return
    end

    self.canvasPanelActive = true

    pixelVisionOS:RegisterUI({name = canvasID}, "UpdateCanvasUI", self)
    
    pixelVisionOS:InvalidateCanvas(self.canvasData)

    -- self:InvalidateColorPreview()
end

function DrawTool:HideCanvasPanel()

    if(self.canvasPanelActive == false) then
        return
    end

    self.canvasPanelActive = false

    pixelVisionOS:RemoveUI(canvasID)

end

function DrawTool:OnCanvasDrop(src, dest)

    if(src.name == self.spritePickerData.name) then

        self:ChangeSpriteID(src.pressSelection.index)

        -- TODO this is overkill, we just need a way to refresh the selection
        pixelVisionOS:InvalidateItemPickerDisplay(self.spritePickerData)
    end



end

function DrawTool:ToggleBackgroundColor(value)


    self.showBGColor = value

    self.canvasData.showBGColor = value

    if(self.usePalettes == true) then

        pixelVisionOS:SelectColorPage(self.paletteColorPickerData, self.paletteColorPickerData.picker.selected)

    else
        self.canvasData.emptyColorID = pixelVisionOS.emptyColorID
    end

    pixelVisionOS:InvalidateCanvas(self.canvasData)

end


function DrawTool:UpdateCanvas(value, flipH, flipV)

    flipH = flipH or false
    flipV = flipV or false

    -- Save the original pixel data from the selection
    local tmpPixelData = gameEditor:ReadGameSpriteData(value, self.spriteSize, self.spriteSize, flipH, flipV)--
    self.lastCanvasScale = Clamp(8 * (3 - self.spriteSize), 4, 16)

    self.lastCanvasSize = NewPoint(8 * self.spriteSize, 8 * self.spriteSize)

    pixelVisionOS:ResizeCanvas(self.canvasData, self.lastCanvasSize, self.lastCanvasScale, tmpPixelData)

    self.originalPixelData = {}

    -- local colorOffset = pixelVisionOS.gameColorOffset
    -- Need to loop through the pixel data and change the offset
    local total = #tmpPixelData
    for i = 1, total do

        -- TODO index the canvas colors here
        local newColor = tmpPixelData[i] - self.colorOffset

        self.originalPixelData[i] = newColor

    end

    self.lastSelection = value

    -- TODO enable this
    -- pixelVisionOS:EnableMenuItem(RevertShortcut, false)

    -- -- Only enable the clear menu when the sprite is not empty
    -- pixelVisionOS:EnableMenuItem(ClearShortcut, not self:IsSpriteEmpty(tmpPixelData))


    pixelVisionOS:EnableMenuItem(CopyShortcut, true)

    -- self:InvalidateColorPreview()

end

function DrawTool:IsSpriteEmpty(pixelData)

    local total = #pixelData

    for i = 1, total do
        if(pixelData[i] ~= -1) then
            return false
        end
    end

    return true

end

-- function DrawTool:InvalidateColorPreview()

--     self.colorPreviewInvalid = true
-- end

-- function DrawTool:ResetColorPreviewValidation()
--     self.colorPreviewInvalid = false
-- end

function DrawTool:DrawColorPerSpriteDisplay()

    -- TODO create unique colors

    local pixelData = gameEditor:ReadGameSpriteData(self.spritePickerData.currentSelection, editorUI.spriteSize.x, editorUI.spriteSize.y)

    -- Clear unique color list

    local uniqueColors = {}

    -- loop through all the pixel data and look for unique colors
    for i = 1, #pixelData do

        -- Get the color id and the index if it exists in the unique color array
        local colorID = pixelData[i]

        if(colorID > - 1) then
            local index = table.indexOf(uniqueColors, colorID)

            -- If this is a new color, add it to the unique color array
            if(index == - 1) then
                table.insert(uniqueColors, colorID)
            end
        end

    end

    local backgroundSprites = {
        _G["colorbarleft"],
        _G["colorbarright"],
    }

    local totalSections = math.ceil(self.cps / 2)

    local totalColors = Clamp(#uniqueColors, 2, 16)

    -- TODO need to fix this
    if(totalColors / 2 > totalSections) then
        totalSections = totalColors / 2
    end

    for i = 1, totalSections do
        table.insert(backgroundSprites, 2, _G["colorbarmiddle"])
    end

    local totalSections = #backgroundSprites

    local maxSections = 10

    local shiftOffset = 0

    -- Pad background
    if(totalSections < maxSections) then

        local emptyTotal = maxSections - totalSections

        shiftOffset = emptyTotal * 8

        for i = 1, emptyTotal do
            table.insert(backgroundSprites, 1, _G["pagebuttonempty"])
        end

    end

    -- local startX = 144
    local nextX = 168 ---- (8 - totalSections * 8)

    for i = maxSections, 1, - 1 do

        nextX = nextX - 8

         -- TODO needs to be differed to the render queue
        editorUI:NewDraw("DrawSprites", {backgroundSprites[i].spriteIDs, nextX, 160, 1, false, false, DrawMode.TilemapCache})

    end

    local colorOffset = pixelVisionOS.colorOffset
    --
    -- if(pixelVisionOS.paletteMode) then

        colorOffset = colorOffset + 128 + ((self.paletteColorPickerData.pages.currentSelection - 1) * 16)

    -- end

    -- Shift next x over
    nextX = nextX + 4 + shiftOffset
    for i = 1, self.cps do

        local color = i <= #uniqueColors and uniqueColors[i] + colorOffset or pixelVisionOS.emptyColorID
        
        nextX = nextX + 4
        -- if(drawColor == true) then
        editorUI:NewDraw("DrawRect", {nextX, 164, 4, 4, color, DrawMode.TilemapCache})
        -- end
    end

    -- Redraw the palette label over the CPS display background
    -- if(usePalettes == true) then

        -- TODO this needs to be differed to the draw queue  
        -- Change color label to palette
        editorUI:NewDraw("DrawSprites", {gamepalettetext.spriteIDs, 32 / 8, 168 / 8, gamepalettetext.width, false, false, DrawMode.Tile})

    -- end

end

function DrawTool:OnSaveCanvasChanges()

    self.canvasData.inDrawMode = false

    -- Get the raw pixel data
    local pixelData = pixelVisionOS:GetCanvasPixelData(self.canvasData)

    -- Get the canvas size
    local canvasSize = pixelVisionOS:GetCanvasSize(self.canvasData)

    -- Get the total number of pixel
    local total = #pixelData

    -- Loop through all the pixel data
    for i = 1, total do

        -- Shift the color value based on the canvas color offset
        local newColor = pixelData[i] - self.canvasData.colorOffset

        -- Set the new pixel index value
        pixelData[i] = newColor < 0 and - 1 or newColor

    end

    -- Redraw the colors per sprite display
    -- self:InvalidateColorPreview()

    -- Update the spritePickerData
    if(self.spritePickerData.currentSelection > - 1) then
        pixelVisionOS:UpdateItemPickerPixelDataAt(self.spritePickerData, self.spritePickerData.currentSelection, pixelData, canvasSize.width, canvasSize.height)
    end

    -- Update the current sprite in the picker
    gameEditor:WriteSpriteData(self.spritePickerData.currentSelection, pixelData, self.spriteSize, self.spriteSize)

    -- Test to see if the canvas is invalid
    if(self.canvasData.invalid == true) then

        -- Invalidate the sprite tool since we change some pixel data
        self:InvalidateData()

        -- Reset the canvas invalidation since we copied it
        editorUI:ResetValidation(self.canvasData)

    end

    -- Make sure the clear button is enabled since a change has happened to the canvas
    -- pixelVisionOS:EnableMenuItem(ClearShortcut, true)
    -- pixelVisionOS:EnableMenuItem(RevertShortcut, true)

end