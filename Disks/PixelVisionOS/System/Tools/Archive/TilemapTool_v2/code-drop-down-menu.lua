--[[
	Pixel Vision 8 - Tilemap Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

-- TODO This needs to be changed to names
SaveShortcut = 5
UndoShortcut = 7
RedoShortcut = 8 
CopyShortcut = 9 
PasteShortcut = 10 
BGColorShortcut = 18

function TilemapTool:CreateDropDownMenu()

    -- Get a list of all the editors
    local editorMapping = pixelVisionOS:FindEditors()

    -- Find the json editor
    self.spriteEditorPath = editorMapping["sprites"]

    local menuOptions =
    {
        -- About ID 1
        {name = "About", action = function() pixelVisionOS:ShowAboutModal(self.toolName) end, toolTip = "Learn about PV8."},
        {divider = true},
        {name = "Edit Sprites", enabled = spriteEditorPath ~= nil, action = OnEditSprites, toolTip = "Open the sprite editor."},
        {name = "Export PNG", action = function() self:OnPNGExport() end, enabled = true, toolTip = "Generate a 'tilemap.png' file."}, -- Reset all the values
        {name = "Save", action = function() self:OnSave() end, enabled = false, key = Keys.S, toolTip = "Save changes made to the tilemap.json file."}, -- Reset all the values
        {divider = true},
        {name = "Undo", action = function() OnUndo() end, enabled = false, key = Keys.Z, toolTip = "Undo the last action."}, -- Reset all the values
        {name = "Redo", action = function() OnRedo() end, enabled = false, key = Keys.Y, toolTip = "Redo the last undo."}, -- Reset all the values
        {name = "Copy", action = function() OnCopyTile() end, enabled = false, key = Keys.C, toolTip = "Copy the currently selected tile."}, -- Reset all the values
        {name = "Paste", action = function() OnPasteTile() end, enabled = false, key = Keys.V, toolTip = "Paste the last copied tile."}, -- Reset all the values
        {divider = true},
        {name = "BG Color", action = function() self:ToggleBackgroundColor(not showBGColor) end, key = Keys.B, toolTip = "Toggle background color."},
        {name = "Toggle Layer", action = function() self:ChangeEditMode(self.mode == FlagMode and TileMode or FlagMode) end, key = Keys.L, toolTip = "Toggle flag mode for collision."},
        {divider = true},
        {name = "Flip H", action = OnFlipH, enabled = false, key = Keys.H, toolTip = "Flip the current tile horizontally."}, -- Reset all the values
        {name = "Flip V", action = OnFlipV, enabled = false, key = Keys.G, toolTip = "Flip the current tile vertically."}, -- Reset all the values
        {divider = true},
        {name = "Quit", key = Keys.Q, action = function() self:OnQuit() end, toolTip = "Quit the current game."}, -- Quit the current game
    }

    if(PathExists(NewWorkspacePath(self.rootDirectory).AppendFile("code.lua"))) then
        table.insert(menuOptions, #menuOptions, {name = "Run Game", action = function() self:OnRunGame() end, key = Keys.R, toolTip = "Run the code for this game."})
    end

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

end

function TilemapTool:OnPNGExport()


    local tmpFilePath = UniqueFilePath(NewWorkspacePath(self.rootDirectory .. "tilemap-export.png"))

    newFileModal:SetText("Export Tilemap As PNG ", string.split(tmpFilePath.EntityName, ".")[1], "Name file", true)

    pixelVisionOS:OpenModal(newFileModal,
            function()

                if(newFileModal.selectionValue == false) then
                    return
                end

                local filePath = tmpFilePath.ParentPath.AppendFile( newFileModal.inputField.text .. ".png")

                SaveImage(filePath, pixelVisionOS:GenerateImage(self.tilePickerData))

            end
    )

    --

end

function TilemapTool:OnSave()

    -- TODO need to save all of the colors back to the game

    -- This will save the system data, the colors and color-map
    gameEditor:Save(rootDirectory, {SaveFlags.System, SaveFlags.Colors, SaveFlags.Tilemap})-- SaveFlags.ColorMap, SaveFlags.FlagColors})

    -- Display a message that everything was saved
    pixelVisionOS:DisplayMessage("Your changes have been saved.", 5)

    -- Need to fix the extension if we switched from a png to a json file
    if(string.ends(self.toolTitle, "png")) then

        -- Rewrite the extension
        toolTitle = string.split(self.toolTitle, ".")[1] .. ".json"

    end

    -- Clear the validation
    self:ResetDataValidation()

end

function TilemapTool:OnUndo()

    -- local action = pixelVisionOS:Undo()

    -- if(action ~= nil and action.Action ~= nil) then
    --     action.Action()
    -- end

    -- UpdateHistoryButtons()
end

function TilemapTool:OnRedo()

    -- local action = pixelVisionOS:Redo()

    -- if(action ~= nil and action.Action ~= nil) then
    --     action.Action()
    -- end

    -- UpdateHistoryButtons()
end

function TilemapTool:UpdateHistoryButtons()

    -- pixelVisionOS:EnableMenuItem(UndoShortcut, pixelVisionOS:IsUndoable())
    -- pixelVisionOS:EnableMenuItem(RedoShortcut, pixelVisionOS:IsRedoable())

end

function TilemapTool:ClearHistory()

    -- Reset history
    -- pixelVisionOS:ResetUndoHistory()
    -- UpdateHistoryButtons()

end

function TilemapTool:OnCopyTile()

end

function TilemapTool:OnPasteTile()

end

function TilemapTool:ToggleBackgroundColor(value)

    self.showBGColor = value

    self.tilePickerData.showBGColor = value

    pixelVisionOS:InvalidateItemPickerDisplay(self.tilePickerData)

end

function TilemapTool:ChangeMode(value)

    -- If value is true select layer 2, if not select layer 1
    self:SelectLayer(value == true and 2 or 1)

    -- Set the flag mode to the value
    self.flagModeActive = value

    -- If value is true we are in the flag mode
    if(value == true) then
        self.lastBGState = self.tilePickerData.showBGColor

        self.tilePickerData.showBGColor = false

        -- Disable bg menu option
        pixelVisionOS:EnableMenuItem(BGColorShortcut, false)

        pixelVisionOS:InvalidateItemPickerDisplay(self.tilePickerData)

        self:DrawFlagPage()

    else
        -- Swicth back to tile modes

        -- Restore background color state
        self.tilePickerData.showBGColor = self.lastBGState

        -- editorUI:Ena ble(bgBtnData, true)
        pixelVisionOS:EnableMenuItem(BGColorShortcut, true)


        pixelVisionOS:RebuildPickerPages(self.paletteColorPickerData)
        pixelVisionOS:SelectColorPage(self.paletteColorPickerData, 1)
        pixelVisionOS:InvalidateItemPickerDisplay(self.paletteColorPickerData)


    end

    -- Fix the button state if triggered outside of the button
    if(self.flagBtnData.selected ~= value) then

        editorUI:ToggleButton(self.flagBtnData, value, false)

    end

    -- Clear history between layers
    self:ClearHistory()

end

function TilemapTool:OnRunGame()
    -- TODO should this ask to launch the game first?

    if(self.invalid == true) then

        pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have unsaved changes. You will lose those changes if you run the game now?", 160, true,
                function()
                    if(pixelVisionOS.messageModal.selectionValue == true) then
                        LoadGame(NewWorkspacePath(self.rootDirectory))
                    end

                end
        )

    else

        LoadGame(NewWorkspacePath(self.rootDirectory))

    end

end

function TilemapTool:OnSave()

    -- This will save the system data and the tilemap
    gameEditor:Save(rootDirectory, {SaveFlags.System, SaveFlags.Tilemap})

    -- Display a message that everything was saved
    pixelVisionOS:DisplayMessage("Your changes have been saved.", 5)

    -- Need to fix the extension if we switched from a png to a json file
    if(string.ends(self.toolTitle, "png")) then

        -- Rewrite the extension
        self.toolTitle = string.split(self.toolTitle, ".")[1] .. ".json"

    end

    -- Clear the validation
    self:ResetDataValidation()

end

function TilemapTool:OnQuit()

    -- TODO need to rewire this?
    --if(self.tilePickerData.renderingMap == true) then
    --    return
    --end

    if(self.invalid == true) then

        pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have unsaved changes. Do you want to save your work before you quit?", 160, true,
                function()
                    if(pixelVisionOS.messageModal.selectionValue == true) then
                        -- Save changes
                        self:OnSave()

                    end

                    -- Quit the tool
                    QuitCurrentTool()

                end
        )

    else
        -- Quit the tool
        QuitCurrentTool()
    end

end