-- start of sprite list

local metaSprites = {
    {name="test", spriteIDs = {0,1,24,25}, width = 2}
}

-- end of sprite list

-- Call this when you are ready to load the sprites
function CreateMetaSprites()

    -- Change the total meta sprites
    local total = TotalMetaSprites(#metaSprites)

    -- Get the current sprite size
    local spriteSize = SpriteSize()
    
    -- Loop through all of the meta sprites
    for i = 1, total do

        -- Get a meta sprite
        local metaSpriteData = metaSprites[i]

        -- 
        local metaSprite = MetaSprite()
        metaSprite.Clear()
        metaSprite.Name = metaSpriteData.name

        for j = 1, metaSpriteData.spriteIDs do

            local pos = CalculatePosition(j, metaSpriteData.width)
            metaSprite.Add(SpriteData(metaSpriteData.spriteIDs[j], pos.X * spriteSize.X, pos.Y * spriteSize.Y))

        end

        -- Create a global meta sprite name mapped to the meta sprite id
        _G[metaSprite.Name] = i
        
    end

end
