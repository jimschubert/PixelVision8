--[[
	Pixel Vision 8 - Display Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

LoadScript("sb-sprites")
LoadScript("pixel-vision-os-item-picker-v1")
LoadScript("pixel-vision-os-color-picker-v3")
LoadScript("pixel-vision-os-sprite-picker-v3")
LoadScript("pixel-vision-os-canvas-v3")

-- Create table to store the workspace tool logic
DrawTool = {}
DrawTool.__index = DrawTool

LoadScript("code-color-editor-modal")
LoadScript("code-drop-down-menu")
LoadScript("code-color-panel")
LoadScript("code-color-selector")
LoadScript("code-palette-panel")
LoadScript("code-sprite-panel")
LoadScript("code-canvas-panel")
LoadScript("code-toolbar")

-- Create some Constants for the different color modes
NoColorMode, SystemColorMode, PaletteMode, SpriteMode, DrawingMode = 0, 1, 2, 3, 4

function DrawTool:Init()

    -- Create a new table for the instance with default properties
    local _drawTool = {
        toolName = "Draw Tool",
        runnerName = SystemName(),
        rootPath = ReadMetadata("RootPath", "/"),
        rootDirectory = ReadMetadata("directory", nil),
        invalid = true,
        success = false,
        canEdit = EditColorModal ~= nil,
        debugMode = true,
        colorOffset = 0
    }

    -- Reset the undo history so it's ready for the tool
    pixelVisionOS:ResetUndoHistory(self)
  
    -- TODO need to figure out mode based on file

    -- Create a global reference of the new workspace tool
    setmetatable(_drawTool, DrawTool)

    if(_drawTool.rootDirectory ~= nil) then

        -- Load only the game data we really need
        _drawTool.success = gameEditor.Load(_drawTool.rootDirectory, {SaveFlags.System, SaveFlags.Meta, SaveFlags.Colors, SaveFlags.ColorMap, SaveFlags.Sprites})

    end

    -- If data load fails
    if(_drawTool.success ~= true) then
        
        _drawTool:LoadError()

    else

        _drawTool:LoadSuccess()
        
    end
  
    -- Change the title
    -- pixelVisionOS:ChangeTitle(_drawTool.toolName, "toolbaricontool")
    -- _drawTool:OnInit()

    return _drawTool
  
end

function DrawTool:LoadError()

    -- Left panel
    DrawRect(8, 32, 128, 128, 0, DrawMode.TilemapCache)
    DrawRect(152, 32, 96, 128, 0, DrawMode.TilemapCache)
    DrawRect(152, 208, 24, 8, 0, DrawMode.TilemapCache)
    DrawRect(200, 208, 48, 8, 0, DrawMode.TilemapCache)
    DrawRect(136, 164, 3, 9, BackgroundColor(), DrawMode.TilemapCache)
    DrawRect(248, 180, 3, 9, BackgroundColor(), DrawMode.TilemapCache)
    DrawRect(136, 220, 3, 9, BackgroundColor(), DrawMode.TilemapCache)

    pixelVisionOS:ChangeTitle(self.toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(self.toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
        function()
            QuitCurrentTool()
        end
    )

end

function DrawTool:LoadSuccess()

    -- Everything loaded so finish initializing the tool
    
    -- The first thing we need to do is rebuild the tool's color table to include the game's system and game colors.
    pixelVisionOS:ImportColorsFromGame()

    self.totalColors = pixelVisionOS.totalSystemColors

    -- Get the palette mode
    self.usePalettes = pixelVisionOS.paletteMode

    if(self.usePalettes == true) then

        -- Change the total colors when in palette mode
        self.totalColors = 128
        self.colorOffset = self.colorOffset + 128

    end

    -- Split the root directory path
    local pathSplit = string.split(self.rootDirectory, "/")

    -- save the title with file path
    self.toolTitle = pathSplit[#pathSplit] .. "/colors.png"


    self:CreateDropDownMenu()

    self:CreateSpritePanel()
    
    self:CreateColorPanel()

    self:CreatePalettePanel()

    self:CreateColorSelector()

    self:CreateCanvas()

    self:CreateToolbar()

    self.selectionIDLabelArgs = {coloridlabel.spriteIDs, 21, 24, coloridlabel.width, false, false, DrawMode.Tile}


    
    -- Restore last state
    local selectedSpritePage = 1
    local paletteColorPicker = 1

    if(SessionID() == ReadSaveData("sessionID", "") and self.rootDirectory == ReadSaveData("rootDirectory", "")) then

        selectedSpritePage = tonumber(ReadSaveData("selectedSpritePage", "1"))
        paletteColorPicker = tonumber(ReadSaveData("selectedPalettePage", "1"))

    end

    pixelVisionOS:OnSpritePickerPage(self.spritePickerData, selectedSpritePage)
    pixelVisionOS:OnColorPickerPage(self.paletteColorPickerData, paletteColorPicker)

    -- Setup default mode
    self:ChangeEditMode(SpriteMode)

    -- Reset the validation to update the title and set the validation flag correctly for any changes
    self:ResetDataValidation()

    -- Set the focus mode to none
    self:ForcePickerFocus()

    -- TODO only do this when it's in draw mode
    editorUI:SelectToggleButton(self.toolBtnData, 1)
    pixelVisionOS:SelectColorPickerColor(self.paletteColorPickerData, 0)
    pixelVisionOS:SelectSpritePickerIndex(self.spritePickerData, 0)
    
    local startSprite = 0

    if(SessionID() == ReadSaveData("sessionID", "") and self.rootDirectory == ReadSaveData("rootDirectory", "")) then
        startSprite = tonumber(ReadSaveData("selectedSprite", "0"))
        self.spriteSize = tonumber(ReadSaveData("spriteSize", "1")) - 1
        self:OnNextSpriteSize()
    end

    self:ChangeSpriteID(startSprite)

    pixelVisionOS:ChangeCanvasPixelSize(self.canvasData, self.spriteSize)
    

    if(self.debugMode == true) then
        self.colorMemoryCanvas = NewCanvas(8, TotalColors() / 8)

        local pixels = {}
        for i = 1, TotalColors() do
            local index = i - 1
            table.insert(pixels, index)
        end

        self.colorMemoryCanvas:SetPixels(pixels)

        pixelVisionOS:RegisterUI({name = "DebugPanel"}, "DrawDebugPanel", self)
    end

end

function DrawTool:Update(timeDelta)

  

end

function DrawTool:DrawDebugPanel()
    self.colorMemoryCanvas:DrawPixels(256 - (8 * 3) - 2, 12, DrawMode.UI, 3)
end

function DrawTool:InvalidateData()

    -- Only everything if it needs to be
    if(self.invalid == true)then
        return
    end

    pixelVisionOS:ChangeTitle(self.toolTitle .."*", "toolbariconfile")

    self.invalid = true

    pixelVisionOS:EnableMenuItem(SaveShortcut, true)

end

function DrawTool:ResetDataValidation()

    -- Only everything if it needs to be
    if(self.invalid == false)then
        return
    end

    pixelVisionOS:ChangeTitle(self.toolTitle, "toolbariconfile")
    self.invalid = false

    pixelVisionOS:EnableMenuItem(SaveShortcut, false)

end

-- Changes the focus of the currently selected color picker
function DrawTool:ForcePickerFocus(src)

    
   
    -- Only one picker can be selected at a time so remove the selection from the opposite one.
    if(src == nil) then

        -- Save the mode
        self.selectionMode = NoColorMode

        -- Disable input fields
        -- editorUI:Enable(self.colorIDInputData, false)
        -- self:ToggleHexInput(false)

        pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)
        pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

        -- Disable all option
        pixelVisionOS:EnableMenuItem(AddShortcut, false)
        pixelVisionOS:EnableMenuItem(ClearShortcut, false)
        pixelVisionOS:EnableMenuItem(EditShortcut, false)
        pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
        pixelVisionOS:EnableMenuItem(BGShortcut, false)
        pixelVisionOS:EnableMenuItem(CopyShortcut, false)
        pixelVisionOS:EnableMenuItem(PasteShortcut, false)

    elseif(src.name == self.systemColorPickerData.name and self.lastMode ~= SystemColorMode) then

        -- Change the color mode to system color mode
        self.selectionMode = SystemColorMode

        -- Clear the picker selection
        pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

        self.selectionIDLabelArgs[1] = coloridlabel.spriteIDs
        -- Enable the hex input field
        -- self:ToggleHexInput(true)

        self.posScale = 1

    elseif(src.name == self.paletteColorPickerData.name and self.lastMode ~= PaletteMode) then

        -- Change the selection mode to palette mode
        self.selectionMode = PaletteMode

        pixelVisionOS:EnableMenuItem(AddShortcut, false)
        pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
        -- Clear the system color picker selection
        pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)

        -- Disable the hex input since you can't change palette colors directly
        -- self:ToggleHexInput(false)

        self.selectionIDLabelArgs[1] = paletteidlabel.spriteIDs
        
        self.posScale = 1

    elseif(src.name == self.spritePickerData.name and self.lastMode ~= SpriteMode) then
        print("Focus", src == nil and "none" or src.name)
        self.selectionMode = SpriteMode

        -- Clear the system color picker selection
        pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)

        self.selectionIDLabelArgs[1] = spriteidlabel.spriteIDs

    end

    self.focusPicker = src
    
    -- Save the last mode
    self.lastMode = self.selectionMode

    editorUI:NewDraw("DrawSprites", self.selectionIDLabelArgs)

end


function DrawTool:OnAddDroppedColor(id, dest, color)

    local index = pixelVisionOS.colorOffset + pixelVisionOS.totalPaletteColors + (id)

    pixelVisionOS:ColorPickerChangeColor(dest, index, color)

    self:InvalidateData()

end

function DrawTool:OnEditColor()

    local colorID = self.systemColorPickerData.currentSelection + self.systemColorPickerData.altColorOffset

    if(self.editColorModal == nil) then
        self.editColorModal = EditColorModal:Init(editorUI, pixelVisionOS.maskColor)
    end

    -- TODO need to get the currently selected color
    self.editColorModal:SetColor(colorID)

    pixelVisionOS:OpenModal(self.editColorModal,
        function()

            if(self.editColorModal.selectionValue == true) then

                self:UpdateHexColor(self.editColorModal.colorHexInputData.text)
                
                return
            end

        end
    )

end

function DrawTool:TogglePaletteMode(value, callback)

    local data = self.paletteColorPickerData

    if(value == true) then

        -- If we are not using palettes, we need to warn the user before activating it

        pixelVisionOS:ShowMessageModal("Activate Palette Mode", "Do you want to activate palette mode? This will split color memory in half and allocate 128 colors to the system and 128 to palettes. The sprites will also be reindexed to the first palette. Saving will rewrite the 'sprite.png' file. This can not be undone.", 160, true,
            function()
                if(pixelVisionOS.messageModal.selectionValue == true) then

                    -- TODO this is a big change, do we want to allow undoing it?
                    -- self:BeginUndo()

                    -- Clear any colors in the clipboard
                    self.copyValue = nil

                    local oldCPS = gameEditor:ColorsPerSprite()

                    -- Cop the colors to memory
                    pixelVisionOS:CopyToolColorsToGameMemory()

                    -- Update the palette mode in the meta data
                    gameEditor:WriteMetadata("paletteMode", "true")

                    -- TODO this can be done here instead of with the game editor.
                    -- Reindex the sprites so they will work in palette mode
                    gameEditor:ReindexSprites()

                    local defaultColor = gameEditor:Color(0)

                    -- Set default color for the rest of the palettes
                    for i = 1, 7 do
                        local offset = PaletteOffset( i )
                        for j = 0, 15 do
                            gameEditor:Color( offset + j, defaultColor )
                        end
                    end

                    -- Import the colors again
                    pixelVisionOS:ImportColorsFromGame()

                    -- Update the system color picker to match the new total colors
                    pixelVisionOS:ChangeColorPickerTotal(self.systemColorPickerData, pixelVisionOS.totalSystemColors)

                    -- Make GPU chip custom if CPS changed
                    if(gameEditor:ColorsPerSprite() ~= oldCPS) then
                        gameEditor:WriteMetadata("gpuChip", "Custom")
                    end

                    self.spritesInvalid = true

                    -- TODO this needs to be routed to the Sprite Picker and clear the cache
                    pixelVisionOS:ChangeItemPickerColorOffset(self.spritePickerData, pixelVisionOS.colorOffset + 128)

                    pixelVisionOS:RebuildSpritePickerCache(self.spritePickerData)

                    -- Redraw the sprite picker to they will display the correct colors
                    -- pixelVisionOS:InvalidateItemPickerDisplay(spritePickerData)

                    -- Clear focus
                    self:ForcePickerFocus()

                    -- Redraw the UI
                    pixelVisionOS:RebuildColorPickerCache(self.systemColorPickerData)
                    -- pixelVisionOS:SelectColorPage(systemColorPickerData, 1)

                    -- Update the palette picker
                    self.paletteColorPickerData.total = 128
                    self.paletteColorPickerData.altColorOffset = pixelVisionOS.colorOffset + 128

                    -- Force the palette picker to only display the total colors per sprite
                    self.paletteColorPickerData.visiblePerPage = gameEditor:ColorsPerSprite()

                    self.pixelVisionOS:RebuildColorPickerCache(self.paletteColorPickerData)

                    -- Set use palettes to true
                    self.usePalettes = true



                    -- Invalidate the data so the tool can save
                    self:InvalidateData()

                    -- Trigger any callback after this is done
                    if(callback ~= nil) then
                        callback()
                    end

                    -- self:EndUndo()

                end

            end
        )


    else

        pixelVisionOS:ShowMessageModal("Disable Palette Mode", "Disabling the palette mode will return the game to 'Direct Color Mode'. Sprites will only display if they can match their colors to 'color.png' file. This process will also remove the palette colors and restore the system colors to support 256.", 160, true,
            function()
                if(pixelVisionOS.messageModal.selectionValue == true) then

                    self.usePalettes = false

                    -- Copy the colors to memory
                    pixelVisionOS:CopyToolColorsToGameMemory()

                    -- Update the palette mode in the meta data
                    gameEditor:WriteMetadata("paletteMode", "false")

                    -- Get the game colors
                    local oldColors = gameEditor:Colors()

                    local tmpIndex = 0

                    -- Copy the first palette to the top of the color table
                    for i = 1, 16 do
                        gameEditor:Color(tmpIndex, oldColors[i + 128])
                        tmpIndex = tmpIndex + 1
                    end

                    -- Copy the old system colors over after the first palette
                    for i = 1, 128 do
                        gameEditor:Color(16 + (i - 1), oldColors[i])
                    end

                    -- Import the colors again
                    pixelVisionOS:ImportColorsFromGame()

                    -- Redraw the sprite picker
                    self.spritePickerData.colorOffset = pixelVisionOS.colorOffset
                    pixelVisionOS:InvalidateItemPickerDisplay(self.spritePickerData)

                    pixelVisionOS:RebuildColorPickerCache(self.systemColorPickerData)

                    pixelVisionOS:RemoveColorPicker(self.paletteColorPickerData)

                    self.systemColorPickerData.lastSelectedPage = 1

                    -- Clear focus
                    self:ForcePickerFocus()

                    self:InvalidateData()
                    -- Update the game editor palette modes
                    -- gameEditor:PaletteMode(usePalettes)

                    -- TODO remove color pages

                    if(callback ~= nil) then
                        callback()
                    end

                end

            end
        )

    end


end

function DrawTool:Shutdown()

    -- TODO this is a hack since the cancel button for the model is over the canvas and is triggered when closing it

    -- Kill the canvas
    canvasData.onAction = nil

    -- Save the current session ID
    WriteSaveData("sessionID", SessionID())

    WriteSaveData("rootDirectory", self.rootDirectory)

    WriteSaveData("selectedSprite", self.spritePickerData.currentSelection)

    WriteSaveData("spriteSize", self.spriteSize)

    --     -- Save the current session ID
--     WriteSaveData("sessionID", SessionID())

--     WriteSaveData("rootDirectory", rootDirectory)

    -- if(systemColorPickerData ~= nil) then
    --     WriteSaveData("selectedSpritePage", spritePickerData.pages.currentSelection)
    -- end
    if(paletteColorPickerData ~= nil) then
        WriteSaveData("selectedPalettePage", self.paletteColorPickerData.pages.currentSelection)
    end

    editorUI:Shutdown()

    -- TODO need to add selected tool, color and color page

end
