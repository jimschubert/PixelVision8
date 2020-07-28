--[[
	Pixel Vision 8 - Tilemap Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

local tilemapPanelID = "TilemapPanelUI"

function TilemapTool:CreateTilemapPanel()

    self.lastTileSelection = -1
    self.flagModeActive = false

    self.flagBtnData = editorUI:CreateToggleButton({x = 232, y = 56}, "flag", "Toggle between tilemap and flag layers (CTRL+L).")
    self.flagBtnData.onAction = function(value) self:ChangeEditMode(value and FlagMode or TileMode) end
    table.insert(self.enabledUI, flagBtnData)
    
    -- TODO need to account for tilemaps that are smaller than the default viewport

    self.tilePickerData = pixelVisionOS:CreateTilemapPicker(
            {x = self.viewport.x, y = self.viewport.y, w = self.viewport.w, h = self.viewport.h},
            {x = 8, y = 8},
            self.mapSize.x * 8,
            self.mapSize.y * 8,
            pixelVisionOS.colorOffset,
            "spritepicker",
            "tile",
            true,
            "tilemap"
    )

    self.tilePickerData.onRelease = function(value) self:OnTileSelection(value) end
    self.tilePickerData.onDropTarget = function() self:OnTilePickerDrop(src, dest) end


    -- Add custom tool tip logic
    self.tilePickerData.UpdateToolTip = function(tmpData)

        if(tmpData.dragging) then

            if(tmpData.overPos.index ~= nil and tmpData.overPos.index ~= -1 and tmpData.overPos.index < tmpData.picker.total) then

                local tmpPosA = CalculatePosition( tmpData.overPos.index, tmpData.columns)

                local tmpColA = string.lpad(tostring(tmpPosA.x), #tostring(tmpData.columns), "0")
                local tmpRowA = string.lpad(tostring(tmpPosA.y), #tostring(tmpData.rows), "0")

                local tmpPosB = CalculatePosition( tmpData.pressSelection.index, tmpData.columns)

                local tmpColB = string.lpad(tostring(tmpPosB.x), #tostring(tmpData.columns), "0")
                local tmpRowB = string.lpad(tostring(tmpPosB.y), #tostring(tmpData.rows), "0")

                tmpData.picker.toolTip = "Swap "..tmpData.toolTipLabel.." " .. tmpColB .. "," .. tmpRowB .." (ID " .. string.lpad(tostring(tmpData.pressSelection.index), tmpData.totalItemStringPadding, "0")..")" .. " with "..tmpColA .. "," .. tmpRowA .." (ID " .. string.lpad(tostring(tmpData.overPos.index), tmpData.totalItemStringPadding, "0")..")"
            else

                local tmpPos = CalculatePosition( tmpData.pressSelection.index, tmpData.columns)

                local tmpCol = string.lpad(tostring(tmpPos.x), #tostring(tmpData.columns), "0")
                local tmpRow = string.lpad(tostring(tmpPos.y), #tostring(tmpData.rows), "0")

                tmpData.picker.toolTip = "Dragging "..tmpData.toolTipLabel.." " .. tmpCol .. "," .. tmpRow .." (ID " .. string.lpad(tostring(tmpData.pressSelection.index), tmpData.totalItemStringPadding, "0")..")"

            end

        elseif(tmpData.overPos.index ~= nil and tmpData.overPos.index ~= -1) then

            local tmpPos = CalculatePosition( tmpData.overPos.index, tmpData.columns)

            local tmpCol = string.lpad(tostring(tmpPos.x), #tostring(tmpData.columns), "0")
            local tmpRow = string.lpad(tostring(tmpPos.y), #tostring(tmpData.rows), "0")

            --print("Tool Mode", toolMode)

            local action = "Select"

            if(self.toolMode == 2) then
                action = "Draw"
            elseif(self.toolMode == 3) then
                action = "Erase"
            elseif(self.toolMode == 4) then
                action = "Fill"
            end

            -- Update the tooltip with the index and position
            tmpData.picker.toolTip = action .. " "..tmpData.toolTipLabel.." " .. tmpCol .. "," .. tmpRow .." (ID " .. string.lpad(tostring(tmpData.overPos.index), tmpData.totalItemStringPadding, "0")..")"

        else
            tmpData.picker.toolTip = ""
        end

    end

    -- Need to convert sprites per page to editor's sprites per page value
    -- local spritePages = math.floor(gameEditor:TotalSprites() / 192)

    -- TODO need to wire this up to the sprite size
    pixelVisionOS:ChangeItemPickerScale(tilePickerData, size)
    
    pixelVisionOS:RegisterUI({name = tilemapPanelID}, "UpdateTilemapPanel", self)

    pixelVisionOS:PreRenderTilemap(self.tilePickerData)
    
end

function TilemapTool:UpdateTilemapPanel()

    pixelVisionOS:UpdateTilemapPicker(self.tilePickerData)
    editorUI:UpdateButton(self.flagBtnData)


    if(self.tilePickerData.mapInvalid and invalid == false) then
        self:InvalidateData()
    end

    if(self.tilePickerData.renderingMap == true) then
        
        print("Rendering")
        pixelVisionOS:NextRenderStep(self.tilePickerData)

        local percent = pixelVisionOS:ReadRenderPercent(self.tilePickerData)

        pixelVisionOS:DisplayMessage("Rendering Layer " .. tostring(percent).. "% complete.", 2)

        if(self.tilePickerData.vSlider.inFocus or self.tilePickerData.hSlider.inFocus) then
            editorUI.mouseCursor:SetCursor(2, false)
        elseif(editorUI.mouseCursor.cursorID ~= 5) then
            editorUI.mouseCursor:SetCursor(5, true)
        end

    elseif(self.uiLock == true or editorUI.mouseCursor.cursorID == 5) then
        --pixelVisionOS:EnableMenuItem(QuitShortcut, true)
        editorUI.mouseCursor:SetCursor(1, false)
        for i = 1, #self.enabledUI do
            editorUI:Enable(self.enabledUI[i], true)
        end

        pixelVisionOS:EnableItemPicker(self.spritePickerData, not self.flagModeActive)

        self.uiLock = false

    end
    
end

function TilemapTool:OnTileSelection(value)

    -- When in palette mode, change the palette page
    if(pixelVisionOS.paletteMode == true) then

        local pos = CalculatePosition(value, tilePickerData.tiles.w)

        local tileData = gameEditor:Tile(pos.x, pos.y)

        local colorPage = (tileData.colorOffset - 128) / 16

        -- print("Color Page", value, colorPage, tileData.colorOffset)

    end


end


function TilemapTool:OnTilePickerDrop(src, dest)

    if(dest.inDragArea == false) then
        return
    end

    -- If the src and the dest are the same, we want to swap colors
    if(src.name == dest.name) then

        local srcPos = src.pressSelection

        -- Get the source color ID
        local srcTile = gameEditor:Tile(srcPos.x, srcPos.y)

        local srcIndex = srcTile.index
        local srcSpriteID = srcTile.spriteID

        local destPos = pixelVisionOS:CalculateItemPickerPosition(src)

        -- Get the destination color ID
        local destTile = gameEditor:Tile(destPos.x, destPos.y)

        local destIndex = destTile.index
        local destSpriteID = destTile.spriteID

        -- ReplaceTile(destIndex, srcSpriteID)
        --
        -- ReplaceTile(srcIndex, destSpriteID)

        pixelVisionOS:SwapTiles(tilePickerData, srcTile, destTile)

    end
end

function TilemapTool:SelectLayer(value)

    self.layerMode = value

    -- Clear the color and sprite pickers
    pixelVisionOS:ClearItemPickerSelection(self.spritePickerData)
    pixelVisionOS:ClearItemPickerSelection(self.paletteColorPickerData)

    -- Check to see if we are in tilemap mode
    if(self.layerMode == FlagMode) then
    --
    --    -- Disable selecting the color picker
    --    pixelVisionOS:EnableColorPicker(self.paletteColorPickerData, false, true)
    --    pixelVisionOS:EnableItemPicker(self.spritePickerData, true, true)
    --
    --    pixelVisionOS:ClearItemPickerSelection(self.spritePickerData)
    --
    --    pixelVisionOS:ChangeItemPickerColorOffset(self.tilePickerData, pixelVisionOS.colorOffset)
    --
    --    if(self.spritePickerData.currentSelection == -1) then
    --        self:ChangeSpriteID(self.tilePickerData.paintTileIndex)
    --    end
    --
    --    -- Test to see if we are in flag mode
    elseif(self.layerMode == SpriteMode) then
    --
    --    -- Disable selecting the color picker
    --    pixelVisionOS:EnableColorPicker(self.paletteColorPickerData, true, true)
    --    pixelVisionOS:EnableItemPicker(self.spritePickerData, false, true)
    --    pixelVisionOS:ChangeItemPickerColorOffset(self.tilePickerData, 0)
    --
    --    -- If the flag has been cleared, make sure we select one
    --    -- if(tilePickerData.paintFlagIndex == -1) then
    --
    --    editorUI:SelectPicker(self.flagPicker, self.tilePickerData.paintFlagIndex)
    --
    --    -- end
    --
    end
    --
    ---- Clear background
    ---- DrawRect(viewport.x, viewport.y, viewport.w, viewport.h, pixelVisionOS.emptyColorID, DrawMode.TilemapCache)
    --
    --
    --
    --gameEditor:RenderMapLayer(self.layerMode - 1)
    --
    --uiLock = true
    --
    
    --
    --editorUI.mouseCursor:SetCursor(5, true)
    --
    --for i = 1, #self.enabledUI do
    --    editorUI:Enable(self.enabledUI[i], false)
    --end

    --pixelVisionOS:EnableMenuItem(QuitShortcut, false)

    -- editorUI:Enable(pixelVisionOS.titleBar.iconButton, false)


end

function TilemapTool:ChangeEditMode(mode)
     print("Mode", mode)

    if(mode == self.mode) then
        return
    end

    self.mode = mode

    if(self.mode == TileMode) then
    --
        
    --
    --    self.flagModeActive = false
    --
    --    self.tilePickerData.showBGColor = self.lastBGState
    --
    --    -- editorUI:Ena ble(bgBtnData, true)
    --    pixelVisionOS:EnableMenuItem(BGColorShortcut, true)
    --
    --
    --    pixelVisionOS:RebuildPickerPages(self.paletteColorPickerData)
    --    pixelVisionOS:SelectColorPage(self.paletteColorPickerData, 1)
    --    pixelVisionOS:InvalidateItemPickerDisplay(self.paletteColorPickerData)
    --
    elseif(self.mode == FlagMode) then
    --
    --    self:SelectLayer(2)
    --
    --    self.flagModeActive = true
    --
    --    self.lastBGState = self.tilePickerData.showBGColor
    --
    --    self.tilePickerData.showBGColor = false
    --
    --    -- Disable bg menu option
    --    pixelVisionOS:EnableMenuItem(BGColorShortcut, false)
    --
    --    pixelVisionOS:InvalidateItemPickerDisplay(tilePickerData)
    --
    --    DrawFlagPage()
    --
    end

    self:SelectLayer(self.mode)

    local value = self.mode == FlagMode

    if(self.flagBtnData.selected ~= value) then

        editorUI:ToggleButton(self.flagBtnData, value, false)

    end

end

function TilemapTool:ReplaceTile(index, value, oldValue)

    local pos = CalculatePosition(index, self.mapSize.x)

    local tile = gameEditor:Tile(pos.x, pos.y)

    oldValue = oldValue or tile.spriteID

    if(tile.spriteID == oldValue) then

        pixelVisionOS:ChangeTile(self.tilePickerData, pos.x, pos.y, value, self.spritePickerData.colorOffset - 256)

    end

end