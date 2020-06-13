--[[
	Pixel Vision 8 - Display Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

LoadScript("pixel-vision-os-item-picker-v2")
LoadScript("pixel-vision-os-color-picker-v3")
LoadScript("pixel-vision-os-sprite-picker-v4")
LoadScript("pixel-vision-os-canvas-v3")

-- Create table to store the workspace tool logic
DrawTool = {}
DrawTool.__index = DrawTool

LoadScript("code-color-editor-modal")
LoadScript("code-drop-down-menu")
LoadScript("code-color-panel")
-- LoadScript("code-color-selector")
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
        debugMode = false,
        colorOffset = 0,
        lastMode = nil
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
    DrawRect(32, 32, 128, 128, 0, DrawMode.TilemapCache)
    DrawRect(152+24, 32, 64, 128, 0, DrawMode.TilemapCache)
    DrawRect(152+24, 208, 32, 8, 0, DrawMode.TilemapCache)
    DrawRect(32, 192-8, 128, 32, 0, DrawMode.TilemapCache)
    DrawRect(8, 17, 16, 200, BackgroundColor(), DrawMode.TilemapCache)
    DrawRect(176, 16, 32, 9, BackgroundColor(), DrawMode.TilemapCache)
    DrawRect(216, 192, 32, 9, BackgroundColor(), DrawMode.TilemapCache)

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

    -- Get the target file
    local targetFile = ReadMetadata("file", nil)

    -- if(targetFile ~= nil) then

    local targetFilePath = NewWorkspacePath(targetFile)

    local colorMode = targetFilePath.EntityName == "colors.png"

    local pathSplit = string.split(targetFile, "/")

    -- Update title with file path
    self.toolTitle = pathSplit[#pathSplit - 1] .. "/" .. pathSplit[#pathSplit]
        
    print("colorMode", colorMode)


    self:CreateDropDownMenu()

    self:CreateSpritePanel()
    
    self:CreateColorPanel()

    -- self:CreatePalettePanel()

    -- self:CreateColorSelector()

    -- self:CreateCanvas()

    self:CreateToolbar()

    -- self.selectionIDLabelArgs = {coloridlabel.spriteIDs, 21, 24, coloridlabel.width, false, false, DrawMode.Tile}


    
    -- -- Restore last state
    -- local selectedSpritePage = 1
    -- local paletteColorPicker = 1

    -- if(SessionID() == ReadSaveData("sessionID", "") and self.rootDirectory == ReadSaveData("rootDirectory", "")) then

    --     selectedSpritePage = tonumber(ReadSaveData("selectedSpritePage", "1"))
    --     paletteColorPicker = tonumber(ReadSaveData("selectedPalettePage", "1"))

    -- end

    -- pixelVisionOS:OnSpritePickerPage(self.spritePickerData, selectedSpritePage)
    -- pixelVisionOS:OnColorPickerPage(self.paletteColorPickerData, paletteColorPicker)

    -- -- Setup default mode
    -- self:ChangeEditMode(SpriteMode)

    -- -- Reset the validation to update the title and set the validation flag correctly for any changes
    -- self:ResetDataValidation()

    -- -- Set the focus mode to none
    -- self:ForcePickerFocus()

    -- -- TODO only do this when it's in draw mode
    -- editorUI:SelectToggleButton(self.toolBtnData, 1)
    -- pixelVisionOS:SelectColorPickerColor(self.paletteColorPickerData, 0)
    -- pixelVisionOS:SelectSpritePickerIndex(self.spritePickerData, 0)
    
    local startSprite = 0

    if(SessionID() == ReadSaveData("sessionID", "") and self.rootDirectory == ReadSaveData("rootDirectory", "")) then
        startSprite = tonumber(ReadSaveData("selectedSprite", "0"))
        self.spriteMode = tonumber(ReadSaveData("spriteMode", "1")) - 1
        
    end

    -- Change the sprite mode
    self:OnNextSpriteSize()

    -- Select the start sprite
    self:ChangeSpriteID(startSprite)

    -- pixelVisionOS:ChangeCanvasPixelSize(self.canvasData, self.spriteMode)
    

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

    self:ResetDataValidation()

    -- Set default mode
    self:ChangeEditMode(colorMode == true and ColorMode or SpriteMode)

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

    --     -- Disable input fields
    --     -- editorUI:Enable(self.colorIDInputData, false)
    --     -- self:ToggleHexInput(false)

    --     pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)
    --     pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

    --     -- Disable all option
    --     pixelVisionOS:EnableMenuItem(AddShortcut, false)
    --     pixelVisionOS:EnableMenuItem(ClearShortcut, false)
    --     pixelVisionOS:EnableMenuItem(EditShortcut, false)
    --     pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
    --     pixelVisionOS:EnableMenuItem(BGShortcut, false)
    --     pixelVisionOS:EnableMenuItem(CopyShortcut, false)
    --     pixelVisionOS:EnableMenuItem(PasteShortcut, false)

    elseif(src.name == self.systemColorPickerData.name and self.lastMode ~= SystemColorMode) then

        -- Change the color mode to system color mode
        self.selectionMode = SystemColorMode

    --     -- Clear the picker selection
    --     pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

    --     self.selectionIDLabelArgs[1] = coloridlabel.spriteIDs
    --     -- Enable the hex input field
    --     -- self:ToggleHexInput(true)

    --     self.posScale = 1

    -- elseif(src.name == self.paletteColorPickerData.name and self.lastMode ~= PaletteMode) then

    --     -- Change the selection mode to palette mode
    --     self.selectionMode = PaletteMode

    --     pixelVisionOS:EnableMenuItem(AddShortcut, false)
    --     pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
    --     -- Clear the system color picker selection
    --     pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)

    --     -- Disable the hex input since you can't change palette colors directly
    --     -- self:ToggleHexInput(false)

    --     self.selectionIDLabelArgs[1] = paletteidlabel.spriteIDs
        
    --     self.posScale = 1

    --     -- Update menu menu items
    --     pixelVisionOS:EnableMenuItem(AddShortcut, false)
    --     pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
    --     pixelVisionOS:EnableMenuItem(EditShortcut, false)
    --     pixelVisionOS:EnableMenuItem(ClearShortcut, true)

    --     pixelVisionOS:EnableMenuItem(CopyShortcut, true)

    --     -- Only enable the paste button if there is a copyValue and we are not in palette mode
    --     pixelVisionOS:EnableMenuItem(PasteShortcut, self.copyValue ~= nil and self.usePalettes == true)


    elseif(src.name == self.spritePickerData.name and self.lastMode ~= SpriteMode) then
        self.selectionMode = SpriteMode

    --     -- Clear the system color picker selection
    --     pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)

    --     self.selectionIDLabelArgs[1] = spriteidlabel.spriteIDs

    end

    self.focusPicker = src
    
    -- Save the last mode
    self.lastMode = self.selectionMode

    -- editorUI:NewDraw("DrawSprites", self.selectionIDLabelArgs)

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

    local currentColor = Color(colorID)

    pixelVisionOS:OpenModal(self.editColorModal,
        function()

            if(self.editColorModal.selectionValue == true and currentColor ~= "#" .. self.editColorModal.colorHexInputData.text) then

                self:UpdateHexColor(self.editColorModal.colorHexInputData.text)
                
                return
            end

        end
    )

end

function DrawTool:Shutdown()

    -- TODO this is a hack since the cancel button for the model is over the canvas and is triggered when closing it

    -- Kill the canvas
    canvasData.onAction = nil

    -- Save the current session ID
    WriteSaveData("sessionID", SessionID())

    WriteSaveData("rootDirectory", self.rootDirectory)

    WriteSaveData("selectedSprite", self.spritePickerData.currentSelection)

    WriteSaveData("spriteMode", self.spriteMode)

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
