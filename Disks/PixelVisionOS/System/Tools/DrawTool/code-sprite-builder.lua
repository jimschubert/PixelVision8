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


    -- self.sbTemplate  = "%s={width=%d,spriteIDs={%s}}\n" -- name, width, spriteList (string)
    -- self.metaTemplate = "NewMetaSprite(%s, {%s}, %d, 0)\n" -- name, spriteList (string), width
    
    

    -- Configure the title and message
    local title = "Sprite Builder"
    local message = "It's important to note that performing this optimization may break any places where you have hardcoded references to sprite IDs. You will have the option to apply the optimization after the sprites are processed. \n\nDo you want to perform the following?\n\n"

    local templatePath = NewWorkspacePath(ReadMetadata("RootPath", "/")).AppendDirectory(ReadMetadata("GameName", "untitled")).AppendDirectory("Templates")

    if(PathExists(templatePath)) then

        local files = GetEntities(templatePath)

        self.spriteBuilderTemplates = {}
        for i = 1, #files do
            if(files[i].GetExtension() ~= ".txt") then

                table.insert(self.spriteBuilderTemplates, files[i])

            end
        end

        for i = 1, #self.spriteBuilderTemplates do
            message = message .. "*  Create " .. self.spriteBuilderTemplates[i].EntityName .. " file\n"
        end

    else

        pixelVisionOS:ShowMessageModal("Error", "There are no templates for the Sprite Builder, please add the them to the '" .. templatePath.Path .. "' folder.", 162)
    
        return
    end

    -- TODO need to tie these to template files
    -- message = message .. "*  Create sb-sprites.lua file\n"
    -- message = message .. "*  Create meta-sprites.lua file\n"
    -- message = message .. "*  Create meta-sprites.json file\n"

    message = message .. "\n#  Import missing sprites\n"

    -- Create the new warning model
    local warningModal = FixSpriteModal:Init(title, message .. "\n", 216, true)

    -- Open the modal
    pixelVisionOS:OpenModal( warningModal,
    
        function()
        
            -- Check to see if ok was pressed on the model
            if(warningModal.selectionValue == true) then

                local filePath = self.spriteBuilderTemplates[warningModal.selectionGroupData.currentSelection]
                local templatePath = filePath.ParentPath.AppendFile(filePath.EntityNameWithoutExtension .. "-" .. string.sub(filePath.GetExtension(), 2) .. "-template.txt") 

                if(PathExists(templatePath) == false) then

                    pixelVisionOS:ShowMessageModal("Error", "Could not find the template file that goes with '" .. filePath.Path .. "'. Please makes sure one exists at " .. templatePath.Path)
                    return
                end

                print("Templates", filePath.Path, templatePath.Path)

                -- local templatePath = NewWorkspacePath(self.spriteBuilderTemplates.EntityNameWithoutExtension .. " - " )
                -- if()

                self.spriteFile = ReadTextFile(filePath)
                self.spriteFilePath = NewWorkspacePath(self.rootDirectory .. filePath.EntityName)
                self.spriteFileTemplate = ReadTextFile(templatePath)
                self.spriteFileContents = ""

                print("Templates", self.spriteFile, self.spriteFileTemplate)

                -- Kick off the process sprites logic
                self:StartSpriteBuilder()

                -- -- TODO need to add some kind of version to this file, maybe a global variable?

                
                
                -- if(warningModal.selectionGroupData.currentSelection == 1) then
                --     self.spriteFile ="-- spritelib-start\n%s\n-- spritelib-end"
                                        
                --     self.spriteFilePath = NewWorkspacePath(self.rootDirectory .. "sb-sprites.lua")
                --     self.spriteFileTemplate = "%s={spriteIDs={%s}, width=%d}\n" -- name, width, spriteList (string)
                
                -- elseif(warningModal.selectionGroupData.currentSelection == 2) then

                --     -- TODO need to load the template file
                --     self.spriteFile = "{\n    \"MetaSprites\": {\n        \"version\": \"v1\",\n        \"total\": 96,\n        \"collections\": [\n%s\n        ]\n    }\n}"
                    
                --     self.spriteFilePath = NewWorkspacePath(self.rootDirectory .. "meta-sprites.json")
                    
                --     self.spriteFileTemplate = "            {\n                \"name\": \"%s\",\n                \"spriteIDs\": [%s],\n                \"width\": %d\n            },\n"
                
                -- elseif(warningModal.selectionGroupData.currentSelection == 3) then

                --     self.spriteFile = "{\n    \"MetaSprites\": {\n        \"version\": \"v1\",\n        \"total\": 96,\n        \"collections\": [\n%s\n        ]\n    }\n}"
                    
                --     self.spriteFilePath = NewWorkspacePath(self.rootDirectory .. "meta-sprites.json")
                    
                --     self.spriteFileTemplate = "            {\n                \"name\": \"%s\",\n                \"spriteIDs\": [%s],\n                \"width\": %d\n            },\n"
                    
                -- end

                

            end
        
        end
    )

    -- Select the default file template
    editorUI:SelectToggleButton(warningModal.selectionGroupData, 1, false)
    warningModal.optionGroupData.buttons[1].selected = true
end

function DrawTool:StartSpriteBuilder()
    
    self:ResetProcessSprites()

    local files = GetEntities(self.spriteBuilderPath)

    self.spriteBuilderFiles = {}

    for i = 1, #files do
        if(files[i].GetExtension() == ".png") then
            table.insert(self.spriteBuilderFiles, files[i])
        end
    end

    -- Since this is referencing a array we need to start at 1
    self.currentParsedSpriteID = 1

    -- self.spriteList = {}
    self.spritesPerLoop = 8
    self.totalSpritesToProcess = #self.spriteBuilderFiles

    -- The action to preform on each step of the sprite progress loop
    self.onSpriteProcessAction = function()
        self:SpriteBuilderStep()
    end

    -- Open the progress model
    pixelVisionOS:OpenModal(self.progressModal,
        function() 
            
            pixelVisionOS:RemoveUI("ProgressUpdate")
            
            self:FinalizeSpriteBuilderFile()
            
        end
    )

    pixelVisionOS:RegisterUI({name = "ProgressUpdate"}, "UpdateSpriteProgress", self, true)

end

function DrawTool:SpriteBuilderStep()

    local path = self.spriteBuilderFiles[self.currentParsedSpriteID]
    
    -- TODO pass in system colors?
    local image = ReadImage(path, pixelVisionOS.maskColor, pixelVisionOS.systemColors)

    local spriteIDs = ""
    local index = -1
    local spriteData = nil
    local empty = true

    for i = 1, image.TotalSprites do
        
        spriteData = image.GetSpriteData(i-1, pixelVisionOS.colorsPerSprite)

        index = gameEditor:FindSprite(spriteData, true)

        if(empty == true and index > -1) then
            empty = false
        end

        if(index == -1 and self.addMissingSprites) then

            local missing = false

            -- Check that the sprite isn't empty
            for i = 1, #spriteData do
                if(spriteData[i] > -1) then
                    missing = true
                    break;
                end
            end

            if(missing == true) then
                print("Missing sprite", i, "in", path.EntityNameWithoutExtension)
                -- TODO need to loop backwards and find the last empty sprite
            end

        end
        
        spriteIDs = spriteIDs .. index

        if(i < image.TotalSprites) then
            spriteIDs = spriteIDs .. ","
        end

    end

    if(empty == false) then

        local name = string.match(string.lower(path.EntityNameWithoutExtension), '[_%-%w ]')
        self.spriteFileContents = self.spriteFileContents .. string.format(self.spriteFileTemplate, name, spriteIDs, image.Columns)
    end

    -- print("self.spriteFileTemplate", self.spriteFile)

end

function DrawTool:FinalizeSpriteBuilderFile()

    pixelVisionOS:RemoveUI("ProgressUpdate")

    -- Close the file
    self.spriteFile = string.format(self.spriteFile, self.spriteFileContents)

    if(PathExists(self.spriteFilePath) == true) then
        -- TODO display a warning
    end

    self:SaveSpriteFile(self.spriteFilePath, self.spriteFile)

end

function DrawTool:SaveSpriteFile(filePath, contents)

    SaveTextToFile(filePath, contents)

end