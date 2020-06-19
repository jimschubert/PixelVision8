function DrawTool:ValidateFirstPalette()


end


function DrawTool:ConvertSpritesToPalette()

    local colorMap = {}

    local spritePixelTotal = gameEditor:SpriteSize().X * gameEditor:SpriteSize().Y

    local totalSprites = gameEditor:TotalSprites()

    local tmpPixelData = {};
    local pixel,tmpIndex, i, j;
    local cps = gameEditor:ColorsPerSprite()

    -- Loop through each sprite
    for i = 1, totalSprites do
     
        -- Read the sprite data
        tmpPixelData = gameEditor:Sprite(i)

        -- Index the pixel data
        for j = 0, spritePixelTotal do
        
            pixel = tmpPixelData[j]

            if (pixel > -1) then 
            
                tmpIndex = colorMap.IndexOf(pixel)
                if (tmpIndex == -1) then
                
                    colorMap.Add(pixel)
                    tmpIndex = colorMap.Count - 1
                end

                tmpPixelData[j] = tmpIndex
            end
        
        end
        gameEditor:Sprite(i, tmpPixelData)

    end

    -- Update the CPS to reflect the indexed colors
    cps = gameEditor:ColorsPerSprite(colorMap.Count == 0 and cps or colorMap.Count)

    -- Copy the colors to the first palette
    for i = 0, cps do
        Color(256 + 128 + i, Color(colorMap.Count == 0 and i or colorMap[i]));
    end
end