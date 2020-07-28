--[[
	Pixel Vision 8 - Tilemap Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

-- Global UI used by this tool
LoadScript("pixel-vision-os-item-picker-v3")
LoadScript("pixel-vision-os-color-picker-v3")
LoadScript("pixel-vision-os-sprite-picker-v4")
LoadScript("pixel-vision-os-progress-modal-v2")
LoadScript("pixel-vision-os-progress-modal-v2")
LoadScript("pixel-vision-os-tilemap-picker-v2")

-- Create table to store the workspace tool logic
TilemapTool = {}
TilemapTool.__index = TilemapTool

-- Custom code used by this tool
LoadScript("pixel-vision-os-file-modal-v1")
LoadScript("code-drop-down-menu")
LoadScript("code-sprite-panel")
LoadScript("code-palette-panel")
LoadScript("code-tilemap-panel")
LoadScript("code-toolbar")

TileMode, FlagMode = 1, 2

function TilemapTool:Init()

    -- Create a new table for the instance with default properties
    local _tilemapTool = {
        toolName = "Tilemap Tool",
        runnerName = SystemName(),
        rootPath = ReadMetadata("RootPath", "/"),
        rootDirectory = ReadMetadata("directory", nil),
        invalid = true,
        success = false,
        colorOffset = 0,
        lastMode = nil,
        showBGColor = false,
        panelInFocus = nil,
        viewport = {x = 8, y = 80, w = 224, h = 128},
        lastBGState = false,
        uiLock = false,
        enabledUI = {},
        mode = nil
    }

    -- Reset the undo history so it's ready for the tool
    pixelVisionOS:ResetUndoHistory(self)

    -- Create a global reference of the new workspace tool
    setmetatable(_tilemapTool, TilemapTool)

    if(_tilemapTool.rootDirectory ~= nil) then

        -- These are the default files the tool will load
        local flags = {SaveFlags.System, SaveFlags.Meta, SaveFlags.Colors, SaveFlags.Sprites, SaveFlags.Tilemap}
    
        -- TODO need to look for custom flag sprites

        -- Load only the game data we really need
        _tilemapTool.success = gameEditor.Load(_tilemapTool.rootDirectory, flags)
        
    end

    if(_tilemapTool.success ~= true) then

        -- Display the load error
        _tilemapTool:LoadError()

    else

        -- The first thing we need to do is rebuild the tool's color table to include the game's system and game colors.
        pixelVisionOS:ImportColorsFromGame()

        -- Create the title
        _tilemapTool:UpdateTitle()
        
        -- Reset the validation now that the title has been updated
        --_tilemapTool:ResetDataValidation()
        
        -- Save the current map size
        _tilemapTool.mapSize = gameEditor:TilemapSize()

        -- Calculate the size the map should be to work correctly in the tool
        local targetSize = NewPoint(math.ceil(_tilemapTool.mapSize.x / 4) * 4, math.ceil(_tilemapTool.mapSize.y / 4) * 4)

        -- Test to see if the size is correct
        if(_tilemapTool.mapSize.x ~= targetSize.x or _tilemapTool.mapSize.y ~= targetSize.y) then

            pixelVisionOS:ShowMessageModal(_tilemapTool.toolName .. " Warning", "The tilemap will be resized from ".. _tilemapTool.mapSize.x .."x" .. _tilemapTool.mapSize.y .." to ".. targetSize.x .. "x" .. targetSize.y .. " in order for it to work in this editor. When you save the new map size will be applied to the game's data file.", 160, true,
                function()
                    if(pixelVisionOS.messageModal.selectionValue == true) then

                        _tilemapTool.mapSize.x = targetSize.x
                        _tilemapTool.mapSize.y = targetSize.y

                        gameEditor:TilemapSize(_tilemapTool.mapSize.x, _tilemapTool.mapSize.y)
                        _tilemapTool:LoadSuccess()

                        _tilemapTool:InvalidateData()

                    else
                        
                        -- Set the load value to false so the state is not saved
                        _tilemapTool.success = false
                        
                        -- Quit out of the tool
                        QuitCurrentTool()
                        
                    end
                end,
                "yes" -- use the yes/no buttons
            )
        else
            
            -- Kick off the new part of the tool's boot process
            _tilemapTool:LoadSuccess()
            
        end 
    end

    -- Return the draw tool data
    return _tilemapTool
    
end

function TilemapTool:LoadError()

    pixelVisionOS:ChangeTitle(self.toolName, "toolbaricontool")

    pixelVisionOS:ShowMessageModal(self.toolName .. " Error", "The tool could not load without a reference to a file to edit.", 160, false,
            function()
                QuitCurrentTool()
            end
    )

end

function TilemapTool:LoadSuccess()
    
    -- Import colors from the game so the colors and sprites display correctly
    pixelVisionOS:ImportColorsFromGame()
        
    -- Create the drop down menu
    self:CreateDropDownMenu()
    
    -- Create a new sprite panel and the size button
    self:CreateSpritePanel()
    
    -- Create the color palette
    self:CreatePalettePanel()
    
    -- Create the tilemap panel
    self:CreateTilemapPanel()
    
    -- Create the toolbar
    self:CreateToolbar()

    if(gameEditor:Name() == ReadSaveData("editing", "undefined")) then
        self.lastSystemColorSelection = tonumber(ReadSaveData("systemColorSelection", "0"))
        
        -- TODO need to restore  previous values
        -- lastTab = tonumber(ReadSaveData("tab", "1"))
        -- lastSelection = tonumber(ReadSaveData("selected", "0"))
    end


    local defaultToolID = 1
    local defaultMode = TileMode

    self.lastSpriteID = 0
    self.lastFlagID = 0
    self.lastPaletteColorID = 0

    if(SessionID() == ReadSaveData("sessionID", "") and self.rootDirectory == ReadSaveData("rootDirectory", "")) then

        self.spriteMode = Clamp(tonumber(ReadSaveData("lastSpriteSize", "1")) - 1, 0, #self.selectionSizes)
        self.lastSpriteID = tonumber(ReadSaveData("lastSpriteID", "0"))
        defaultToolID = tonumber(ReadSaveData("lastSelectedToolID", "1"))

        self.lastPaletteColorID = tonumber(ReadSaveData("lastPaletteColorID", "0"))

        defaultMode = tonumber(ReadSaveData("lastMode", "1"))
    end

    -- Change the sprite mode
    self:OnNextSpriteSize()

    -- Select the start sprite
    self:ChangeSpriteID(self.lastSpriteID)

    -- print("SCALE", self.spriteMode)
    self:ConfigureSpritePickerSelector(self.spriteMode)

    -- Set default tool
    editorUI:SelectToggleButton(self.toolBtnData, defaultToolID)

    -- Set default mode
    --self:ChangeEditMode(defaultMode)
    
    self:ResetDataValidation()
    
end

function TilemapTool:ForcePickerFocus(src)

    -- Ignore this when the panel is already in focus
    if((self.panelInFocus ~= nil and src.name == self.panelInFocus.name) or self.ignoreFocus == true) then
        -- print("Ignore focus switch")
        return
    end
    
    -- TODO change states based on the focus 
end

function TilemapTool:InvalidateData()

    -- Only everything if it needs to be
    if(self.invalid == true)then
        return
    end

    pixelVisionOS:ChangeTitle(self.toolTitle .."*", "toolbariconfile")

    pixelVisionOS:EnableMenuItem(SaveShortcut, true)

    invalid = true

end

function TilemapTool:ResetDataValidation()

    -- Only everything if it needs to be
    if(self.invalid == false)then
        return
    end

    pixelVisionOS:ChangeTitle(self.toolTitle, "toolbariconfile")

    pixelVisionOS:EnableMenuItem(SaveShortcut, false)

    if(tilePickerData ~= nil) then
        self.tilePickerData.mapInvalid = false
    end

    invalid = false

end

function TilemapTool:UpdateTitle()
    local pathSplit = string.split(self.rootDirectory, "/")

    -- TODO need to load the correct file here

    local fileName = ReadMetadata("fileName")

    -- Need to make sure we show the right extenstion since json files are loaded before png if one exists even though the tool will see it as a png.
    if(PathExists(NewWorkspacePath(self.rootDirectory).AppendFile("tilemap.json")) and string.ends(fileName, "png")) then

        -- Rewrite the extension
        fileName = string.split(fileName, ".")[1] .. ".json"

    end

    -- Update title with file path
    self.toolTitle = pathSplit[#pathSplit] .. "/" .. fileName

end

function TilemapTool:Shutdown()

    -- Shutdown all the editor update and draw calls
    editorUI:Shutdown()

    -- Save the state of the tool if it was correctly loaded
    if(self.success == true) then
        -- Save the current session ID
        WriteSaveData("sessionID", SessionID())
        WriteSaveData("rootDirectory", self.rootDirectory)

        WriteSaveData("lastSpriteSize", self.spriteMode)
        WriteSaveData("lastSpriteID", self.spritePickerData.currentSelection)
        print("self.spritePickerData.currentSelection", self.spritePickerData.currentSelection)
        WriteSaveData("lastSelectedToolID", self.lastSelectedToolID)

        WriteSaveData("lastMode", self.mode)
        WriteSaveData("lastPaletteColorID", self.lastPaletteColorID)
    end
    
end