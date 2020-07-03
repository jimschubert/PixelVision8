--[[
	Pixel Vision 8 - Display Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

LoadScript("pixel-vision-os-item-picker-v3")
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
NoFocus, SystemColorMode, PaletteMode, SpriteMode, DrawingMode = 0, 1, 2, 3, 4

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
        lastMode = nil,
        showBGColor = false,
        panelInFocus = nil
    }

    -- Reset the undo history so it's ready for the tool
    pixelVisionOS:ResetUndoHistory(self)
  
    -- TODO need to figure out mode based on file

    -- Create a global reference of the new workspace tool
    setmetatable(_drawTool, DrawTool)

    if(_drawTool.rootDirectory ~= nil) then

        -- Load only the game data we really need
        _drawTool.success = gameEditor.Load(_drawTool.rootDirectory, {SaveFlags.System, SaveFlags.Meta, SaveFlags.Colors, SaveFlags.Sprites})

    end

    -- If data load fails
    if(_drawTool.success ~= true) then
        
        _drawTool:LoadError()

        
    else

        -- TODO need to manually load the image, display a progress bar and process each sprite
        -- local image = ReadImage(NewWorkspacePath(_drawTool.rootDirectory.."sprites.png"))

        -- local total = image.TotalSprites

        -- for i = 1, total do
        --     local id = i-1
        --     gameEditor:Sprite(id, image.GetSpriteData(id))
        -- end

        _drawTool:LoadSuccess()

        -- print("Total Sprites", image.TotalSprites)
        
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

    local targetFilePath = NewWorkspacePath(targetFile)

    local colorMode = targetFilePath.EntityName == "colors.png"

    local pathSplit = string.split(targetFile, "/")

    self.titlePath = pathSplit[#pathSplit - 1] .. "/"

    -- Update title with file path
    -- self.toolTitle =  .. pathSplit[#pathSplit]

    self:CreateDropDownMenu()

    self:CreateSpritePanel()
    
    self:CreateColorPanel()

    self:CreatePalettePanel()

    self:CreateCanvas()

    self:CreateToolbar()

    local startSprite = 0

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


    local defaultToolID = 1
    local defaultMode = colorMode == true and ColorMode or SpriteMode

    local defaultSpriteID = 0
    self.lastSystemColorID = 0
    self.lastPaletteColorID = 0

    -- TODO need to make sure we are editing the same file

    -- print("Session", SessionID(), ReadSaveData("sessionID", ""), ReadMetadata("file", nil))
    if(SessionID() == ReadSaveData("sessionID", "") and self.rootDirectory == ReadSaveData("rootDirectory", "")) then


        -- print("Restore SessionID")

        self.spriteMode = Clamp(tonumber(ReadSaveData("lastSpriteSize", "1")) - 1, 0, #self.selectionSizes)
        defaultSpriteID = tonumber(ReadSaveData("lastSpriteID", "0"))
        defaultToolID = tonumber(ReadSaveData("lastSelectedToolID", "1"))

        self.lastSystemColorID = tonumber(ReadSaveData("lastSystemColorID", "0"))
        self.lastPaletteColorID = tonumber(ReadSaveData("lastPaletteColorID", "0"))
        

        

    end

    -- Change the sprite mode
    self:OnNextSpriteSize()

    -- Select the start sprite
    self:ChangeSpriteID(startSprite)

    -- print("SCALE", self.spriteMode)
    self:ConfigureSpritePickerSelector(self.spriteMode)

    -- Set default tool
    editorUI:SelectToggleButton(self.toolBtnData, defaultToolID)

    -- Set default mode
    self:ChangeEditMode(defaultMode)
    
    self:ResetDataValidation()


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

    self.invalid = true

    self:UpdateTitle()

    pixelVisionOS:EnableMenuItem(SaveShortcut, true)

end

function DrawTool:ResetDataValidation()

    -- Only everything if it needs to be
    if(self.invalid == false)then
        return
    end

    self.invalid = false

    self:UpdateTitle()

    pixelVisionOS:EnableMenuItem(SaveShortcut, false)

end

function DrawTool:UpdateTitle()

    pixelVisionOS:ChangeTitle(self.titlePath .. self.toolTitle .. (self.invalid == true and "*" or ""), "toolbariconfile")

end

-- Changes the focus of the currently selected color picker
function DrawTool:ForcePickerFocus(src)

    -- Ignore this when the panel is already in focus
    if((self.panelInFocus ~= nil and src.name == self.panelInFocus.name) or self.ignoreFocus == true) then
        -- print("Ignore focus switch")
        return
    end

    -- TODO need to check what's in the clipboard and see if paste needs to cleared
    -- pixelVisionOS:EnableMenuItem(PasteShortcut, self.copyValue ~= nil)

    if(src.name == self.systemColorPickerData.name) then

        print("System Color picker in focus")

        -- Change the color mode to system color mode
        self.selectionMode = SystemColorMode

        -- Change sprite picker focus color
        self.spritePickerData.picker.selectedDrawArgs[1] = _G["spritepickerover"].spriteIDs

        -- Clear the palette picker selection in one one color can be selected at a time
        pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

        -- Toggle menu options
        pixelVisionOS:EnableMenuItem(CopyShortcut, false)
        pixelVisionOS:EnableMenuItem(PasteShortcut, false)
        pixelVisionOS:EnableMenuItem(ClearShortcut, false)
        pixelVisionOS:EnableMenuItem(AddShortcut, true)
        pixelVisionOS:EnableMenuItem(EditShortcut, true)
        pixelVisionOS:EnableMenuItem(DeleteShortcut, true)
        pixelVisionOS:EnableMenuItem(SetBGShortcut, true)
        
        -- Restore last system color
        if(self.lastSystemColorID ~= nil) then
            pixelVisionOS:SelectColorPickerIndex(self.systemColorPickerData, self.lastSystemColorID)
        end

    elseif(src.name == self.paletteColorPickerData.name) then

        print("Palette Color Picker in focus")

    --     -- Change the selection mode to palette mode
        self.selectionMode = PaletteMode

        pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)

        -- Change selection focus colors
        self.spritePickerData.picker.selectedDrawArgs[1] = _G["spritepickerover"].spriteIDs
        self.paletteColorPickerData.picker.selectedDrawArgs[1] = _G["itempickerselectedup"].spriteIDs

        -- Toggle menu options
        pixelVisionOS:EnableMenuItem(CopyShortcut, true)
        pixelVisionOS:EnableMenuItem(PasteShortcut, false)
        pixelVisionOS:EnableMenuItem(ClearShortcut, true)
        pixelVisionOS:EnableMenuItem(AddShortcut, true)
        pixelVisionOS:EnableMenuItem(EditShortcut, false)
        pixelVisionOS:EnableMenuItem(DeleteShortcut, true)
        pixelVisionOS:EnableMenuItem(SetBGShortcut, false)

        -- print("paletteColorPickerData sel", self.paletteColorPickerData.currentSelection)

    elseif(src.name == self.spritePickerData.name) then
        self.selectionMode = SpriteMode

        print("Sprite Picker in focus")
    --     -- Clear the system color picker selection
        pixelVisionOS:ClearItemPickerSelection(self.systemColorPickerData)

        self.spritePickerData.picker.selectedDrawArgs[1] = _G["spritepickerselectedup"].spriteIDs
        self.paletteColorPickerData.picker.selectedDrawArgs[1] = _G["itempickerover"].spriteIDs

        pixelVisionOS:EnableMenuItem(CopyShortcut, true)
        pixelVisionOS:EnableMenuItem(PasteShortcut, false)
        pixelVisionOS:EnableMenuItem(ClearShortcut, true)
        pixelVisionOS:EnableMenuItem(AddShortcut, false)
        pixelVisionOS:EnableMenuItem(EditShortcut, false)
        pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
        pixelVisionOS:EnableMenuItem(SetBGShortcut, false)

        -- print("Restore Palette", self.paletteColorPickerData.currentSelection, self.lastPaletteColorID)
        -- -- Restore palette color
        -- if(self.lastPaletteColorID ~= nil) then

        --     print("Restoring /  ", self.lastPaletteColorID)
        --     pixelVisionOS:SelectColorPickerIndex(self.paletteColorPickerData, self.lastPaletteColorID)

        -- end

    elseif(src.name == self.canvasData.name) then

        self.selectionMode = DrawingMode
        
        print("Canvas in focus now")

        self.spritePickerData.picker.selectedDrawArgs[1] = _G["spritepickerover"].spriteIDs
        self.paletteColorPickerData.picker.selectedDrawArgs[1] = _G["itempickerover"].spriteIDs

 
        pixelVisionOS:EnableMenuItem(CopyShortcut, false)
        pixelVisionOS:EnableMenuItem(PasteShortcut, false)
        pixelVisionOS:EnableMenuItem(ClearShortcut, true)
        pixelVisionOS:EnableMenuItem(AddShortcut, false)
        pixelVisionOS:EnableMenuItem(EditShortcut, false)
        pixelVisionOS:EnableMenuItem(DeleteShortcut, false)
        pixelVisionOS:EnableMenuItem(SetBGShortcut, false)

    end

    -- TODO need to check if we should clear the copy command
    self.panelInFocus = src

    -- Save the last mode
    self.lastMode = self.selectionMode
    
end


function DrawTool:OnAddDroppedColor(id, dest, color)

    local index = pixelVisionOS.colorOffset + pixelVisionOS.totalPaletteColors + (id)
    
    self:BeginUndo()
    pixelVisionOS:ColorPickerChangeColor(dest, index, color)
    self:EndUndo()

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

    -- Shutdown all the editor update and draw calls
    editorUI:Shutdown()

    -- Kill the canvas
    self.canvasData.onAction = nil

    -- Save the current session ID
    WriteSaveData("sessionID", SessionID())
    WriteSaveData("rootDirectory", self.rootDirectory)

    WriteSaveData("lastSpriteSize", self.spriteMode)
    WriteSaveData("lastSpriteID", self.spritePickerData.currentSelection)
    WriteSaveData("lastSelectedToolID", self.lastSelectedToolID)


    WriteSaveData("lastSystemColorID", self.lastSystemColorID)
    WriteSaveData("lastPaletteColorID", self.lastPaletteColorID)
    
    

    -- print("Save",self.spriteMode, self.lastSelectedToolID)

    

end
