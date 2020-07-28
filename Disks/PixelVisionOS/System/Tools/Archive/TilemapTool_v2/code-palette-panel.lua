--[[
	Pixel Vision 8 - Tilemap Tool
	Copyright (C) 2017, Pixel Vision 8 (http://pixelvision8.com)
	Created by Jesse Freeman (@jessefreeman)

	Please do not copy and distribute verbatim copies
	of this license document, but modifications without
	distributing is allowed.
]]--

local palettePanelID = "PalettePanelUI"

function TilemapTool:CreatePalettePanel()

    self.paletteLabelArgs = {gamecolortext.spriteIDs, 4, 21, gamecolortext.width, false, false, DrawMode.Tile}

    -- Create the palette color picker
    self.paletteColorPickerData = pixelVisionOS:CreateColorPicker(
        {x = 184, y = 24, w = 64, h = 16},
        {x = 8, y = 8},
        pixelVisionOS.totalPaletteColors,
        16, -- Total per page
        8, -- Max pages
        pixelVisionOS.colorOffset + 128,
        "spritepicker",
        "palette color",
        false,
        true,
        false
    )

    pixelVisionOS:ColorPickerVisiblePerPage(self.paletteColorPickerData, pixelVisionOS.colorsPerSprite)

    self.paletteColorPickerData.picker.borderOffset = 8

    -- TODO this shouldn't have to be called?
    pixelVisionOS:RebuildColorPickerCache(self.paletteColorPickerData)

    -- Force the palette picker to only display the total colors per sprite
    self.paletteColorPickerData.visiblePerPage = pixelVisionOS.paletteColorsPerPage

    pixelVisionOS:OnColorPickerPage(self.paletteColorPickerData, 1)

    -- Wire up the picker to change the color offset of the sprite picker
    self.paletteColorPickerData.onPageAction = function(value)

       -- Calculate page offset value
        local pageOffset = ((value - 1) * 16)

        -- Calculate the new color offset
        local newColorOffset = pixelVisionOS.colorOffset + pixelVisionOS.totalPaletteColors + pageOffset

        -- Change the spite picker color offset
        pixelVisionOS:ChangeItemPickerColorOffset(self.spritePickerData, newColorOffset)

        pixelVisionOS:InvalidateItemPickerDisplay(self.spritePickerData)

    end

    self.paletteColorPickerData.onDrawColor = function(data, id, x, y)

        if(id < data.total and (id % data.totalPerPage) < data.visiblePerPage) then
            local colorID = id + data.altColorOffset
            
            if(Color(colorID) == pixelVisionOS.maskColor) then
                data.canvas.DrawSprites(emptymaskcolor.spriteIDs, x, y, emptymaskcolor.width, false, false)
            else
                data.canvas.Clear(colorID, x, y, data.itemSize.x, data.itemSize.y)
            end
            
        else
            data.canvas.DrawSprites(emptycolor.spriteIDs, x, y, emptycolor.width, false, false)
        end

    end

    pixelVisionOS:RegisterUI({name = palettePanelID}, "UpdatePalettePanel", self)
    
end

function TilemapTool:UpdatePalettePanel()

    pixelVisionOS:UpdateColorPicker(self.paletteColorPickerData)

end
