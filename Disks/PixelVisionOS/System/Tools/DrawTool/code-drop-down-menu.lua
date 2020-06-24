-- TODO these need to be merged
SaveShortcut, AddShortcut, EditShortcut, ClearShortcut, DeleteShortcut, BGShortcut, UndoShortcut, RedoShortcut, CopyShortcut, PasteShortcut = 5, 7, 8, 9, 10, 11, 13, 14, 15, 16
ClearShortcut, SaveShortcut, RevertShortcut, UndoShortcut, RedoShortcut, CopyShortcut, PasteShortcut = 4, 5, 6, 8, 9, 10, 11


function DrawTool:CreateDropDownMenu()

    -- Get a list of all the editors
    local editorMapping = pixelVisionOS:FindEditors()

    -- Find the json editor
    self.spriteEditorPath = editorMapping["sprites"]

    local menuOptions = 
    {
        -- About ID 1
        {name = "About", action = function() pixelVisionOS:ShowAboutModal(self.toolName) end, toolTip = "Learn about PV8."},
        {name = "Help", action = function() pixelVisionOS:ShowAboutModal(self.toolName) end, toolTip = "Learn about PV8."},
        {divider = true},
        -- Editor modes
        -- TODO toggle between "Palette Mode" and "Color Mode"
        {name = "Palette Mode", action = function() self:TogglePaletteMode(not self.usePalettes) end, enabled = canEdit, toolTip = "Toggle between palette and direct color mode."}, -- Reset all the values
        -- TODO toggle between "Edit Sprites" to "Edit Colors"
        {name = "Edit Sprites", enabled = self.spriteEditorPath ~= nil, action = function() self:OnEditSprites() end, toolTip = "Open the sprite editor."},
        -- TODO toggle between "Show BG Color" to "Hide BG Color"
        {name = "Show BG Color", action = function() self:ToggleBackgroundColor(not self.showBGColor) end, key = Keys.B, toolTip = "Toggle background color."},
        {divider = true},
        -- Reset all the values
        {name = "Save", action = function() self:OnSave() end, enabled = false, key = Keys.S, toolTip = "Save changes made to the colors.png file."}, -- Reset all the values
        {name = "Revert", action = OnRevert, enabled = false, toolTip = "Revert the sprite to its previous state."}, -- Reset all the values
        {divider = true},
        {name = "Add", action = function() self:OnAdd() end, enabled = false, key = Keys.A, toolTip = "Add a new color to the currently selected picker."},
        {name = "Edit", action = function() self:OnEditColor() end, enabled = false, key = Keys.E, toolTip = "Edit the currently selected color."},
        {name = "Clear", action = function() self:OnClear() end, enabled = false, key = Keys.B, toolTip = "Clear the currently selected color."},
        {name = "Delete", action = function() self:OnDelete() end, enabled = false, key = Keys.D, toolTip = "Remove the currently selected color."},
        {divider = true},
        {name = "Undo", action = function() self:OnUndo() end, enabled = false, key = Keys.Z, toolTip = "Undo the last action."}, -- Reset all the values
        {name = "Redo", action = function() self:OnRedo() end, enabled = false, key = Keys.Y, toolTip = "Redo the last undo."}, -- Reset all the values
        {name = "Copy", action = function() self:OnCopy() end, enabled = false, key = Keys.C, toolTip = "Copy the currently selected sound."}, -- Reset all the values
        {name = "Paste", action = function() self:OnPaste() end, enabled = false, key = Keys.V, toolTip = "Paste the last copied sound."}, -- Reset all the values
        {divider = true},
        {name = "Fill", action = OnFill, enabled = true, key = Keys.F, toolTip = "Paste the last copied sprite."}, -- Reset all the values
        {name = "Select All", action = OnSelectAll, enabled = true, key = Keys.A, toolTip = "Paste the last copied sprite."}, -- Reset all the values
        {name = "Set BG Color", action = function() self:OnSetBGColor() end, enabled = false, toolTip = "Set the current color as the background."}, -- Reset all the values
        {divider = true},
        {name = "Optimize", action = OnOptimize, toolTip = "Remove duplicate sprites."},
        {name = "Sprite Builder", action = OnSpriteBuilder, toolTip = "Generate a sprite table from a project's SpriteBuilder dir."}, -- Reset all the values
        {divider = true},
        {name = "Quit", key = Keys.Q, action = function () self:OnQuit() end, toolTip = "Quit the current game."}, -- Quit the current game
    }

    if(PathExists(NewWorkspacePath(self.rootDirectory).AppendFile("code.lua"))) then
        table.insert(menuOptions, #menuOptions, {name = "Run Game", action = OnRunGame, key = Keys.R, toolTip = "Run the code for this game."})
    end

    pixelVisionOS:CreateTitleBarMenu(menuOptions, "See menu options for this tool.")

end

function DrawTool:OnEditSprites()
    pixelVisionOS:ShowMessageModal("Edit Sprites", "Do you want to open the Sprite Editor? All unsaved changes will be lost.", 160, true,
        function()
            if(pixelVisionOS.messageModal.selectionValue == true) then

                -- Set up the meta data for the editor for the current directory
                local metaData = {
                    directory = self.rootDirectory,
                }

                -- Load the tool
                LoadGame(self.spriteEditorPath, metaData)

            end

        end
    )
end


function DrawTool:OnSave()

    -- Copy all of the colors over to the game
    pixelVisionOS:CopyToolColorsToGameMemory()

    -- These are the default flags we are going to save
    local flags = {SaveFlags.System, SaveFlags.Meta, SaveFlags.Colors, SaveFlags.Sprites}

    -- TODO need to tell if we are not in palette mode any more and recolor sprites and delete color-map.png file?

    gameEditor:WriteMetadata("paletteMode", usePalettes and "true" or "false")

    -- If the sprites have been re-indexed and we are using palettes we need to save the changes
    if(self.spritesInvalid == true) then

        -- print("Save Sprites", usePalettes)
        if(self.usePalettes == true) then

            -- Add the color map flag
            table.insert(flags, SaveFlags.ColorMap)

        else
            -- TODO look for a color-map.png file in the current directory and delete it
        end

        -- Add the sprite flag
        -- table.insert(flags, SaveFlags.Sprites)

        self.spritesInvalid = false

    end

    -- This will save the system data, the colors and color-map
    gameEditor:Save(self.rootDirectory, flags)

    -- Display a message that everything was saved
    pixelVisionOS:DisplayMessage("Your changes have been saved.", 5)

    -- Clear the validation
    self:ResetDataValidation()

end

-- Adds a transparent color to the end of the system color or palette color picker. This only works if there is enough space and the system color picker doesn't already have a transparent color.
function DrawTool:OnAdd()

    if(self.selectionMode == PaletteMode) then

        -- Make sure we are not at the end of the total per page value
        if(self.paletteColorPickerData.visiblePerPage < self.paletteColorPickerData.totalPerPage) then

            local index = self.paletteColorPickerData.picker.selected

            -- Rebuild all of the palettes

            local totalPerPalette = 16
            local totalPalettes = self.totalPaletteColors / 16

            for i = 1, totalPalettes do

                local palette = {}

                -- for j = 1, totalPerPalette do

                -- end

                table.insert(palette, index, 0)

            end

            pixelVisionOS:ColorPickerVisiblePerPage(self.paletteColorPickerData, self.paletteColorPickerData.visiblePerPage + 1)

            self:InvalidateData()

            -- Disable add option

            self:UpdateAddDeleteShortcuts()

            gameEditor:ColorsPerSprite(self.paletteColorPickerData.visiblePerPage)


        end

    else

        if(self.systemColorPickerData.total >= gameEditor:MaximumColors()) then
            pixelVisionOS:ShowMessageModal(self.toolName .." Error", "You can not add any more system colors. Please increase the maximum color limit in the data.json file.", 160, false)

            return
        end

        local currentSelection = self.systemColorPickerData.currentSelection

        if(self.editColorModal == nil) then
            self.editColorModal = EditColorModal:Init(editorUI, pixelVisionOS.maskColor)
        end

        self.editColorModal:SetColor()

        pixelVisionOS:OpenModal(self.editColorModal,
            function()

                if(self.editColorModal.selectionValue == true) then

                    local newColorHex = "#"..self.editColorModal.colorHexInputData.text

                    if(newColorHex == pixelVisionOS.maskColor) then

                        -- if(usePalettes == false) then
                        --   OnClear()
                        -- else

                        pixelVisionOS:ShowMessageModal(self.toolName .." Error", self.maskColorError, 160, false)

                        -- end

                        return false

                    else

                        -- Make sure the game as the current colors from the tool
                        pixelVisionOS:CopyToolColorsToGameMemory()

                        -- Get all the colors in the game
                        local colors = gameEditor:Colors()

                        -- Make sure this color doesn't already exist

                        local matchingColorIndex = table.indexOf(colors, newColorHex)
                        if(matchingColorIndex > - 1) then

                            pixelVisionOS:ShowMessageModal(toolName .." Error", "'".. newColorHex .."' the same as system color ".. (matchingColorIndex - 1) ..", enter a new color.", 160, false)

                        else

                            table.insert(colors, currentSelection + 2, newColorHex)

                            -- TODO need to clamp this to 256 or 128 depending on what mode
                            -- Increase the system colors by 1
                            pixelVisionOS.totalSystemColors = pixelVisionOS.totalSystemColors + 1

                            -- Copy the colors back to the editor
                            for i = 1, pixelVisionOS.totalSystemColors do

                                local index = (i - 1) + pixelVisionOS.colorOffset
                                pixelVisionOS:ColorPickerChangeColor(self.systemColorPickerData, index, colors[i])

                            end

                            pixelVisionOS:AddNewColorToPicker(self.systemColorPickerData)
                            --
                            -- pixelVisionOS:RefreshColorPickerColor(systemColorPickerData, currentSelection + 1)
                            -- pixelVisionOS:ChangeColorPickerTotal(systemColorPickerData, pixelVisionOS.totalSystemColors, true)

                            pixelVisionOS:SelectColorPickerIndex(self.systemColorPickerData, currentSelection + 1)

                            self:OnSelectSystemColor(currentSelection + 1)

                            self:InvalidateData()

                        end
                    end

                end
            end
        )

    end

end

-- This method handles the logic for clearing a color based on the currently selected palette and the current color mode.
function DrawTool:OnClear()

    self:ColorSnapshot()

    -- Find the currently selected picker
    local picker = self.selectionMode == SystemColorMode and self.systemColorPickerData or self.paletteColorPickerData

    -- Get the real color ID from the offset
    local realColorID = picker.currentSelection + picker.altColorOffset

    -- Set the color to the mask value
    pixelVisionOS:ColorPickerChangeColor(picker, realColorID, pixelVisionOS.maskColor)

    -- Invalidate the tool's data
    self:InvalidateData()

end

function DrawTool:OnDelete()
    if(self.selectionMode == SystemColorMode) then
        self:OnDeleteSystemColor(self.systemColorPickerData.currentSelection)
    end

end

function DrawTool:OnSetBGColor()

    local oldBGColor = gameEditor:BackgroundColor()

    local colorID = self.systemColorPickerData.currentSelection

    pixelVisionOS:ShowMessageModal("Set Background Color", "Do you want to change the current background color ID from " .. oldBGColor .. " to " .. colorID .. "?", 160, true,
        function()
            if(pixelVisionOS.messageModal.selectionValue == true) then
                
                -- TODO need a way to undo this
                
                self:SaveBGPosition()  

                gameEditor:BackgroundColor(colorID)

                self.showBGIcon = true

                self:RefreshBGColorIcon()

                self:InvalidateData()
            end
        end
    )

end

function DrawTool:OnCopy()

    local src = self.lastMode == 1 and self.systemColorPickerData or self.paletteColorPickerData

    local colorID = src.currentSelection + src.altColorOffset

    self.copyValue = Color(colorID)

    -- print("OnCopy", lastMode, src.name, colorID, copyValue)

    -- TODO This should only be enabled when you are in a palette since you can't copy system colors
    pixelVisionOS:EnableMenuItem(PasteShortcut, true)

    pixelVisionOS:DisplayMessage("Copied Color '"..self.copyValue .."'.")

end

function DrawTool:OnPaste()

    if(self.copyValue == nil or self.lastMode == 1) then
        return
    end

    local src = self.lastMode == 1 and self.systemColorPickerData or self.paletteColorPickerData

    local colorID = src.currentSelection + src.altColorOffset

    -- TODO need to wire up to the undo/redo logic
    self:ColorSnapshot()

    pixelVisionOS:ColorPickerChangeColor(self.paletteColorPickerData, colorID, self.copyValue)

    pixelVisionOS:EnableMenuItem(CopyShortcut, true)
    pixelVisionOS:EnableMenuItem(PasteShortcut, false)

    self.copyValue = nil

    self:InvalidateData()

end

function DrawTool:OnQuit()

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

function DrawTool:OnDeleteSystemColor(value)

    -- Calculate the total system colors from the picker
    local totalColors = self.systemColorPickerData.total - 1

    if(totalColors == 1) then

        -- Display a message to keep the user from deleting all of the system colors
        pixelVisionOS:ShowMessageModal(self.toolName .. " Error", "You must have at least 2 colors.", 160, false)

    else

        pixelVisionOS:ShowMessageModal("Delete Color", "Are you sure you want to delete this system color? Doing so will shift all the colors over and may change the colors in your sprites." .. (self.usePalettes and " This color will also be removed from any palettes that are referencing it." or ""), 160, true,
            function()
                if(pixelVisionOS.messageModal.selectionValue == true) then
                    -- If the selection if valid, remove the system color
                    self:DeleteSystemColor(value)
                end

            end
        )
    end
    -- end

end

function DrawTool:DeleteSystemColor(value)

    local currentSelection = self.systemColorPickerData.currentSelection

    -- Calculate the real color ID in the tool's memory
    local realColorID = value + self.systemColorPickerData.altColorOffset

    -- Set the current tool's color to the mask value
    pixelVisionOS:ColorPickerChangeColor(self.systemColorPickerData, realColorID, pixelVisionOS.maskColor)

    -- Copy all the colors to the game
    pixelVisionOS:CopyToolColorsToGameMemory()

    -- Reimport the game colors to rebuild the unique system color list
    pixelVisionOS:ImportColorsFromGame()

    -- TODO need to wire up to the undo/redo logic
    self:ColorSnapshot()

    -- Remove the last system color from the picker
    pixelVisionOS:RemoveColorFromPicker(self.systemColorPickerData)

    -- Need to rebuild the palette cache
    if(self.usePalettes == true) then
        -- TODO need to enable this

        -- TODO this is probably not needed since the update above should automatically remove any colors in the palette
        pixelVisionOS:RebuildColorPickerCache(self.paletteColorPickerData)
    end

    pixelVisionOS:SelectColorPickerIndex(self.systemColorPickerData, Clamp(currentSelection - 1, 0, 255))

    self:RefreshBGColorIcon()

    -- Invalidate the tool's data
    self:InvalidateData()

end

function DrawTool:OnUndo()
    
    pixelVisionOS:Undo(self)

    self:UpdateHistoryButtons()
end

function DrawTool:OnRedo()

    pixelVisionOS:Redo(self)

    self:UpdateHistoryButtons()

end

function DrawTool:BeginUndo()
    pixelVisionOS:BeginUndoable(self)
end

function DrawTool:EndUndo()
    pixelVisionOS:EndUndoable(self)
    self:UpdateHistoryButtons()
end

function DrawTool:UpdateHistoryButtons()

    pixelVisionOS:EnableMenuItem(UndoShortcut, pixelVisionOS:IsUndoable(self))
    pixelVisionOS:EnableMenuItem(RedoShortcut, pixelVisionOS:IsRedoable(self))

end

function DrawTool:GetState()

    local mode = 0

    local colorSnapshot = {}

    -- Mode 1 stores colors
    if(mode == 0 or mode == 1) then
        
        pixelVisionOS:CopyToolColorsToGameMemory()

        -- Copy over all the new system colors from the tool's memory
        for i = 1, pixelVisionOS.totalColors do

            -- Set the game's color to the tool's color
            table.insert(colorSnapshot, gameEditor:Color(i -1))

        end

    end

    -- Mode 2 stores bg position
    if(mode == 0 or mode == 2) then


    end

    if(mode == 0 or mode == 3) then
        -- TODO Capture state change for palette mode?
    end

    -- TODO capture position

    local state = {
        -- colors = colorSnapshot,
        -- sound = settingsString,
        Action = function()
            
            if(#colorSnapshot > 0) then

                -- Clear the game's colors
                gameEditor:ClearColors()

                -- Copy over all the new system colors from the tool's memory
                for i = 1, #colorSnapshot do

                    -- Calculate the index of the color
                    local index = i - 1

                    -- Set the game's color to the tool's color
                    gameEditor:Color(index, colorSnapshot[i])

                end

                -- TODO may need to redraw palette to remove transparent

                -- Reimport the game colors to rebuild the unique system color list
                pixelVisionOS:ImportColorsFromGame()

                self:InvalidateData()
            end
            
        end
    }

    return state

end

function DrawTool:SetState(state)

    if(state.Action == nil) then
        return
    end

    state:Action()

end

function DrawTool:SaveBGPosition()

    local value = gameEditor:BackgroundColor()

    local historyAction = {
        -- sound = settingsString,
        Action = function()

            gameEditor:BackgroundColor(value)
          
            self:RefreshBGColorIcon()

            self:UpdateHistoryButtons()

        end
    }

    pixelVisionOS:AddUndoHistory(historyAction)
    
    self:UpdateHistoryButtons()

end

-- function DrawTool:ColorSnapshot()

--     pixelVisionOS:CopyToolColorsToGameMemory()

--     local colorSnapshot = {}

--     -- Copy over all the new system colors from the tool's memory
--     for i = 1, pixelVisionOS.totalColors do

--         -- Set the game's color to the tool's color
--         table.insert(colorSnapshot, gameEditor:Color(i -1))

--     end

--     if(colorSnapshot.count == 0) then
--         return
--     end

--     local historyAction = {
--         -- colors = colorSnapshot,
--         -- sound = settingsString,
--         Action = function()
--             print("Redo action triggered")

--             -- print("Pre Restore", dump(colorSnapshot))
--             self:RestoreSnapshot(colorSnapshot)
            
--         end
--     }

--     pixelVisionOS:AddUndoHistory(historyAction)

--     print("Snapshot Saved", dump(historyAction))

--     self:UpdateHistoryButtons()

--     return colorSnapshot

-- end

-- function DrawTool:RestoreSnapshot(colorSnapshot)

--     -- Clear the game's colors
--     gameEditor:ClearColors()

--     -- Copy over all the new system colors from the tool's memory
--     for i = 1, #colorSnapshot do

--         -- Calculate the index of the color
--         local index = i - 1

--         -- Set the game's color to the tool's color
--         gameEditor:Color(index, colorSnapshot[i])

--     end

--     -- Reimport the game colors to rebuild the unique system color list
--     pixelVisionOS:ImportColorsFromGame()

--     self:InvalidateData()

--     print("Snapshot Restored", dump(colorSnapshot))

-- end

function DrawTool:ToggleBackgroundColor(value)

    self.showBGColor = value

    self.canvasData.showBGColor = value


    -- self.paletteColorPickerData.showBGColor = value

    -- pixelVisionOS:RebuildColorPickerCache(self.paletteColorPickerData)

    -- if(usePalettes == true) then

    pixelVisionOS:SelectColorPage(paletteColorPickerData, paletteColorPickerData.picker.selected)

    -- else
    --     canvasData.emptyColorID = pixelVisionOS.emptyColorID
    -- end

    pixelVisionOS:InvalidateCanvas(canvasData)

    -- spritePickerData.showBGColor = value

    -- TODO need a way to replace the mask color in palette mode here

    -- pixelVisionOS:InvalidateItemPickerDisplay(spritePickerData)

    -- DrawRect(viewport.x, viewport.y, viewport.w, viewport.h, pixelVisionOS.emptyColorID, DrawMode.TilemapCache)

end
