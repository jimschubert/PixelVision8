function DrawTool:EnableSpriteBuilder()

    if(self.spriteBuilderPath == nil) then
        self.spriteBuilderPath = NewWorkspacePath(self.rootDirectory).AppendDirectory("SpriteBuilder")
    end

    return PathExists(self.spriteBuilderPath)

end


function DrawTool:OnSpriteBuilder()

    -- Make sure we can we can still do the sprite builder
    if(self:EnableSpriteBuilder() == false) then
        return
    end

    -- TODO reset all of the sprite process flags

    self:ResetProcessSprites()
    
end