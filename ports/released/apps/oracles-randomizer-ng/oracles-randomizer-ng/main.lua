-------------------------------------------------------------------------------------------
-- INITIALIZATION -------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local fadeParams = {
    fadeAlpha = 1,
    fadeDurationFrames = 20,
    fadeTimer = 0,
    fadeType = "in", -- can be "in" or "out"
    fadeFinished = false
}

-- Menu globals
local bg
local menus = { mainMenu = {} }
local selectedMenu = "mainMenu"
local menuPositionYPercentage = 0.6   -- 60% vertical
local menuPositionXPercentage = 1.15   -- 98% horizontal
local maxVisibleItems = 5  -- Number of items to display at once
local startIndex = 0       -- Index of the first item in the visible range
local selectedOption = 1

-- Font globals
local referenceWidth = 1050
local referenceHeight = 900
local normalColor = {0.5, 0.5, 0.5, 1}  -- Grey for non-selected
local selectedColor = {1, 1, 1, 1}      -- White for selected
local menuFont

-- Load radio selection from file
function readFromFile(filename)
    local fileHandle = io.open(filename, "r")
    if fileHandle then
        local content = fileHandle:read("*all"):match("^%s*(.-)%s*$")
        fileHandle:close()
        return content
    else
        print("Error opening " .. filename .. " for reading")
        return nil
    end
end

-- Radio button globals
local radioButtonBaseSize = 25           -- Base size of the radio button
local radioButtonBaseSpacing = 175       -- Base spacing between the radio buttons
local radioButtonBaseLabelOffset = 20    -- Base space between radio button and label text
local radioButtonYPercentage = 0.90      -- Radio button Y position (range 0.00 - 1.00)
local radioButtonXPercentage = 0.60      -- Radio button X position (range 0.00 - 1.00)
local fontSizeScaleFactor = 1.0          -- Scale factor for font size relative to button size
local radioFile = "launcher/radio.txt"
local radioContent = readFromFile(radioFile)
local selectedRadioOption = (radioContent == "1" and 1) or (radioContent == "2" and 2) or 1

-- Options state
local toggleOptions = {
    hard = false,
    dungeons = false,
    keysanity = false,
    crossitems = false,
    portals = false
}

-- Music has three modes: 1=off, 2=on, 3=all
local musicOptions = { "off", "on", "all" }
local selectedMusicIndex = 1

-- Menu Options
local menuOptions = {
    { label = "Hard",       value = toggleOptions.hard },
    { label = "Dungeons",   value = toggleOptions.dungeons },
    { label = "Keysanity",  value = toggleOptions.keysanity },
    { label = "CrossItems", value = toggleOptions.crossitems },
    { label = "Portals",    value = toggleOptions.portals },
    { label = "Music",      value = musicOptions[selectedMusicIndex] },
    { label = "Generate",   value = false },
    { label = "Exit",       value = false }
}

-- Input globals
local inputCooldown = 0.2
local timeSinceLastInput = 0
local isAPressed = false

-- Initialize display
function setupWindow()
    love.window.setTitle("Minilauncher")
    love.window.setFullscreen(true, "desktop")
    love.window.setMode(0, 0)
end

-- Draw order
function love.draw()
    drawBackground()
    drawMenu()
    drawRadioButtons()
    fadeScreen(fadeParams.fadeType)
end

-- Load background music
function loadMusic()
    -- Stop the background music if it's playing
    if backgroundMusic and backgroundMusic:isPlaying() then
        love.audio.stop(backgroundMusic)
    end

    -- Load a specific music file
    backgroundMusic = love.audio.newSource("launcher/assets/audio/music/menu.ogg", "stream")

    -- Set the music to loop and play it if it is not nil
    if backgroundMusic then
        backgroundMusic:setLooping(true)
        love.audio.play(backgroundMusic)
    end
end

function fadeOutBackgroundMusic()
    local fadeDuration = 0.5  -- Fade duration in seconds

    if backgroundMusic and backgroundMusic:isPlaying() then
        local initialVolume = backgroundMusic:getVolume()

        -- Perform gradual volume reduction
        local startTime = love.timer.getTime()
        local elapsedTime = 0

        while elapsedTime < fadeDuration do
            elapsedTime = love.timer.getTime() - startTime
            local progress = elapsedTime / fadeDuration
            local currentVolume = initialVolume * (1 - progress)

            backgroundMusic:setVolume(currentVolume)
            love.timer.sleep(0.01)  -- Adjust sleep time for smoother effect
        end

        love.audio.stop(backgroundMusic)
    end
end
	
-- Play UI sounds
function playUISound(actionType)
    local soundMapping = {
        toggle = "launcher/assets/audio/fx/toggle.ogg",
        enter = "launcher/assets/audio/fx/enter.ogg"
    }

    local soundPath = soundMapping[actionType]

    if soundPath then
        love.audio.play(love.audio.newSource(soundPath, "static"))
    end
end

-- Handle fade effect
function fadeScreen(fadeDirection)
    -- Handle fade effect
    fadeParams.fadeTimer = fadeParams.fadeTimer + 1
    local progress = fadeParams.fadeTimer / fadeParams.fadeDurationFrames

    if fadeDirection == "in" then
        fadeParams.fadeAlpha = 1 - progress
    elseif fadeDirection == "out" then
        fadeParams.fadeAlpha = progress
    end

    if fadeParams.fadeTimer >= fadeParams.fadeDurationFrames then
        fadeParams.fadeAlpha = fadeDirection == "in" and 0 or 1
        fadeParams.fadeFinished = true
    end

    love.graphics.setColor(0, 0, 0, fadeParams.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Check for quit combinations
    if love.keyboard.isDown("z") and love.keyboard.isDown("x") then
        love.event.quit()
    end

    local gamepad = love.joystick.getJoysticks()[1]
    if gamepad and gamepad:isGamepadDown("rightshoulder") and gamepad:isGamepadDown("leftshoulder") then
        love.event.quit()
    end

    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to white
end

-- Draw background
function loadBackground()
    -- Release previously loaded images (if any)
    if bg then
        bg:release()
    end

    -- Load the background image
    bg = love.graphics.newImage("launcher/assets/oraclesbg.png")
end

function drawBackground()
    if not bg then
        return
    end

    local windowWidth, windowHeight = love.graphics.getDimensions()

    -- Stretch the background to fit the entire screen
    love.graphics.draw(bg, 0, 0, 0, windowWidth / bg:getWidth(), windowHeight / bg:getHeight())
end

-- Init -- splash screen
function love.load()
    setupWindow()
    local scaleFactor = math.min(love.graphics.getWidth() / referenceWidth, love.graphics.getHeight() / referenceHeight)
    local fontSize = 44 * scaleFactor
    menuFont = love.graphics.newFont("launcher/assets/font/Proxima Nova Regular Italic.otf", fontSize)
    menuFont:setFilter("linear", "linear")
    love.graphics.setFont(menuFont)
    loadBackground()
    menus.mainMenu = menuOptions
    loadMusic()
    fadeParams.fadeAlpha = 1
    fadeParams.fadeDurationFrames = 20
    fadeParams.fadeTimer = 0
    fadeParams.fadeType = "in"
    fadeParams.fadeFinished = false
end

-------------------------------------------------------------------------------------------
-- INPUT HANDLING -------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Main input handler (default menu)
function handleInput()
    local gamepad = love.joystick.getJoysticks()[1]
    handleDefaultMenuInput(gamepad)
end

-- Default menu input handler
function handleDefaultMenuInput(gamepad)
    if timeSinceLastInput >= inputCooldown then
        if love.keyboard.isDown("up") or (gamepad and gamepad:isGamepadDown("dpup")) then
            selectPreviousOption()
            playUISound("toggle")
            timeSinceLastInput = 0
        elseif love.keyboard.isDown("down") or (gamepad and gamepad:isGamepadDown("dpdown")) then
            selectNextOption()
            playUISound("toggle")
            timeSinceLastInput = 0
        elseif love.keyboard.isDown("left") or (gamepad and gamepad:isGamepadDown("dpleft")) then
            selectLeftColumnOption()
            playUISound("toggle")
            timeSinceLastInput = 0
        elseif love.keyboard.isDown("right") or (gamepad and gamepad:isGamepadDown("dpright")) then
            selectRightColumnOption()
            playUISound("toggle")
            timeSinceLastInput = 0
        elseif (gamepad and gamepad:isGamepadDown("leftshoulder")) then
            selectedRadioOption = 1  -- "Ages" selected
            selectRadioOption()
            playUISound("toggle")
            timeSinceLastInput = 0
        elseif (gamepad and gamepad:isGamepadDown("rightshoulder")) then
            selectedRadioOption = 2  -- "Seasons" selected
            selectRadioOption()
            playUISound("toggle")
            timeSinceLastInput = 0
        elseif (love.keyboard.isDown("return") or (gamepad and gamepad:isGamepadDown("a"))) then
            if not isAPressed then  -- Trigger only on first press
                local selectedItem = menus.mainMenu[selectedOption]
                handleSelection()
                playUISound("enter")
                isAPressed = true
                timeSinceLastInput = 0
            end
        else
            isAPressed = false  -- Reset when A/Enter is not pressed
        end
    end
end

function selectLeftColumnOption()
    local totalItems = #menus[selectedMenu]
    local generateIndex = totalItems - 1
    local exitIndex = totalItems

    -- If currently on bottom row (Generate/Exit)
    if selectedOption == exitIndex then
        selectedOption = generateIndex
    elseif selectedOption == generateIndex then
        -- already leftmost, do nothing
    else
        -- existing left column logic
        local itemsPerColumn = math.ceil((totalItems - 2) / 2)
        local leftColumnCount = itemsPerColumn
        local rightColumnCount = (totalItems - 2) - leftColumnCount
        local currentIndex = selectedOption
        local isRightColumn = currentIndex > leftColumnCount and currentIndex <= totalItems - 2
        if isRightColumn then
            local row = currentIndex - leftColumnCount - 1
            local newIndex = row + 1
            if newIndex <= leftColumnCount then
                selectedOption = newIndex
            end
        end
    end
    timeSinceLastInput = 0
end

function selectRightColumnOption()
    local totalItems = #menus[selectedMenu]
    local generateIndex = totalItems - 1
    local exitIndex = totalItems

    -- If currently on bottom row (Generate/Exit)
    if selectedOption == generateIndex then
        selectedOption = exitIndex
    elseif selectedOption == exitIndex then
        -- already rightmost, do nothing
    else
        -- existing right column logic
        local itemsPerColumn = math.ceil((totalItems - 2) / 2)
        local leftColumnCount = itemsPerColumn
        local rightColumnCount = (totalItems - 2) - leftColumnCount
        local currentIndex = selectedOption
        local isLeftColumn = currentIndex <= leftColumnCount
        if isLeftColumn then
            local row = currentIndex - 1
            local newIndex = leftColumnCount + row + 1
            if newIndex <= totalItems - 2 then
                selectedOption = newIndex
            end
        end
    end
    timeSinceLastInput = 0
end

-- Select previous option (upward movement)
function selectPreviousOption()
    selectedOption = selectedOption - 1
    if selectedOption < 1 then
        selectedOption = #menus[selectedMenu]
    end
    timeSinceLastInput = 0
end

-- Select next option (downward movement)
function selectNextOption()
    selectedOption = selectedOption + 1
    if selectedOption > #menus[selectedMenu] then
        selectedOption = 1
    end
    timeSinceLastInput = 0
end

-- Select radio option
function selectRadioOption()
    timeSinceLastInput = 0
end

--------------------------------------------------------------------------------------
-- DRAW MENU -------------------------------------------------------------------------
--------------------------------------------------------------------------------------
function drawMenu()
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to white
    local windowHeight = love.graphics.getHeight()
    local windowWidth = love.graphics.getWidth()
    
    -- Calculate scale factor based on reference resolution
    local scaleFactor = math.min(windowWidth / referenceWidth, windowHeight / referenceHeight)
    
    -- Calculate positioning
    local optionYStart = windowHeight * menuPositionYPercentage
    local optionSpacing = menuFont:getHeight() * 1.2 * scaleFactor  -- Keep reduced spacing
    local radioButtonSize = 20 * scaleFactor  -- Scaled radio button size
    local radioButtonSpacing = 10 * scaleFactor  -- Space between circle and text
    
    -- Calculate items per column (exclude Generate and Exit)
    local itemsPerColumn = math.ceil((#menus[selectedMenu] - 2) / 2)
    local leftColumnCount = itemsPerColumn
    local rightColumnCount = (#menus[selectedMenu] - 2) - leftColumnCount
    
    -- Calculate total menu height for centering (based on taller column)
    local totalMenuHeight = math.max(leftColumnCount, rightColumnCount) * optionSpacing
    local optionY = optionYStart - (totalMenuHeight / 2)
    
    -- Calculate column positions
    local columnWidth = math.max(
        math.max(menuFont:getWidth("Crossitems"), menuFont:getWidth("Keysanity")),
        menuFont:getWidth("Music: All")  -- Account for longest possible Music label
    ) + radioButtonSize + radioButtonSpacing
    local leftColumnX = (windowWidth * menuPositionXPercentage - columnWidth) / 2
    local rightColumnX = leftColumnX + columnWidth + (20 * scaleFactor)
    
    -- Define yellow color for toggled options
    local toggledColor = {1, 1, 0, 1}  -- Yellow for toggled-on options
    
    -- Draw menu options in two columns (exclude Generate and Exit)
    for i = 0, itemsPerColumn - 1 do
        -- Left column
        if i + startIndex + 1 <= leftColumnCount then
            local index = startIndex + i + 1
            local option = menus[selectedMenu][index]

            -- Dynamic display label
            local displayLabel
            if type(option) == "table" then
                if option.label == "Portals" and selectedRadioOption == 1 then
                    displayLabel = "AutoMermaid"
                elseif option.label == "Music" then
                    displayLabel = "Music: " .. option.value:gsub("^%l", string.upper)
                else
                    displayLabel = option.label
                end
            else
                displayLabel = option
            end

            local y = optionY + i * optionSpacing
            local textH = menuFont:getHeight()
            
            -- Set color: yellow if toggled, white if selected, grey otherwise
            local isSelected = (index == selectedOption)
            local isToggled = type(option) == "table" and ((option.label == "Music" and option.value ~= "off") or (option.label ~= "Music" and option.value == true))
            love.graphics.setColor(isSelected and selectedColor or (isToggled and toggledColor or normalColor))
            
            -- Draw radio circle
            local circleX = leftColumnX + radioButtonSize / 2
            local circleY = y + textH / 2
            local radius = radioButtonSize / 2
            love.graphics.setLineWidth(2 * scaleFactor)
            love.graphics.circle("line", circleX, circleY, radius)
            if isToggled then
                love.graphics.circle("fill", circleX, circleY, radius * 0.6)
            end
            
            -- Draw label
            love.graphics.print(displayLabel, leftColumnX + radioButtonSize + radioButtonSpacing, y)
        end
        
        -- Right column
        local rightIndex = startIndex + i + 1 + leftColumnCount
        if rightIndex <= #menus[selectedMenu] - 2 then
            local option = menus[selectedMenu][rightIndex]

            -- Dynamic display label
            local displayLabel
            if type(option) == "table" then
                if option.label == "Portals" and selectedRadioOption == 1 then
                    displayLabel = "AutoMermaid"
                elseif option.label == "Music" then
                    displayLabel = "Music: " .. option.value:gsub("^%l", string.upper)
                else
                    displayLabel = option.label
                end
            else
                displayLabel = option
            end

            local y = optionY + i * optionSpacing
            local textH = menuFont:getHeight()
            
            -- Set color: yellow if toggled, white if selected, grey otherwise
            local isSelected = (rightIndex == selectedOption)
            local isToggled = type(option) == "table" and ((option.label == "Music" and option.value ~= "off") or (option.label ~= "Music" and option.value == true))
            love.graphics.setColor(isSelected and selectedColor or (isToggled and toggledColor or normalColor))
            
            -- Draw radio circle
            local circleX = rightColumnX + radioButtonSize / 2
            local circleY = y + textH / 2
            local radius = radioButtonSize / 2
            love.graphics.setLineWidth(2 * scaleFactor)
            love.graphics.circle("line", circleX, circleY, radius)
            if isToggled then
                love.graphics.circle("fill", circleX, circleY, radius * 0.6)
            end
            
            -- Draw label
            love.graphics.print(displayLabel, rightColumnX + radioButtonSize + radioButtonSpacing, y)
        end
    end
    
    -- Draw Generate and Exit buttons below columns
    local generateIndex = #menus[selectedMenu] - 1
    local exitIndex = #menus[selectedMenu]
    local buttonSpacing = 20 * scaleFactor
    local y = optionY + totalMenuHeight + optionSpacing

    -- Generate button
    local generateOption = menus[selectedMenu][generateIndex]
    if generateOption then
        local isSelected = (generateIndex == selectedOption)
        love.graphics.setColor(isSelected and selectedColor or normalColor)
        love.graphics.print(generateOption.label, windowWidth / 1.75, y)
    end

    -- Exit button
    local exitOption = menus[selectedMenu][exitIndex]
    if exitOption then
        local isSelected = (exitIndex == selectedOption)
        love.graphics.setColor(isSelected and selectedColor or normalColor)
        love.graphics.print(exitOption.label, windowWidth / 1.25, y)
    end

    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Draw the radio buttons
function drawRadioButtons()
    love.graphics.setColor(1, 1, 1, 1)
    local windowWidth, windowHeight = love.graphics.getDimensions()

    -- Calculate scale factor based on current window size
    local scaleFactor = math.min(windowWidth / referenceWidth, windowHeight / referenceHeight)

    -- Adjust button sizes and spacing using scale factor
    local radioButtonSize = radioButtonBaseSize * scaleFactor
    local radioButtonSpacing = radioButtonBaseSpacing * scaleFactor
    local radioButtonLabelOffset = radioButtonBaseLabelOffset * scaleFactor

    -- Set font size dynamically
    local fontSize = radioButtonSize * 0.8  -- Font size relative to button size
    local radioFont = love.graphics.newFont(fontSize)
    love.graphics.setFont(radioFont)

    -- Calculate the base X position for the first radio button
    local radioX = windowWidth * radioButtonXPercentage
    local radioY = windowHeight * radioButtonYPercentage

    -- Draw each radio button and its label
    for i, label in ipairs({"Ages", "Seasons"}) do
        local buttonX = radioX + (i - 1) * (radioButtonSize + radioButtonSpacing)

        -- Draw outer circle
        love.graphics.circle("line", buttonX, radioY, radioButtonSize / 2)

        -- Draw filled inner circle if selected
        if selectedRadioOption == i then
            love.graphics.circle("fill", buttonX, radioY, radioButtonSize / 4)
        end

        -- Draw the label next to the radio button
        love.graphics.print(label, buttonX + radioButtonLabelOffset, radioY - fontSize / 2)
    end

    -- Draw the instruction text below the buttons
    local helpText = "Use L/R to select a game to randomize"
    local helpTextWidth = radioFont:getWidth(helpText)
    local buttonsWidth = #({"Ages", "Seasons"}) * (radioButtonSize + radioButtonSpacing) - radioButtonSpacing
    local buttonsCenterX = radioX + buttonsWidth / 2
    local helpTextX = buttonsCenterX - helpTextWidth / 2 + (windowWidth * 0.03)
    love.graphics.print(helpText, helpTextX, radioY + fontSize)
    love.graphics.setFont(menuFont)
end

-----------------------------------------------------------------------------------
-- HANDLE SELECTION ---------------------------------------------------------------
-----------------------------------------------------------------------------------
function handleSelection()
    local selectedItem = menus[selectedMenu][selectedOption]
    local label = type(selectedItem) == "table" and selectedItem.label or selectedItem

    -- Toggle boolean options
    if label == "Hard" or label == "Dungeons" or label == "Keysanity" or label == "Crossitems" or label == "Portals" then
        selectedItem.value = not selectedItem.value
        playUISound("toggle")

    -- Cycle Music options
    elseif label == "Music" then
        selectedMusicIndex = (selectedMusicIndex % #musicOptions) + 1
        selectedItem.value = musicOptions[selectedMusicIndex]
        playUISound("toggle")

    -- Generate options.ini and fade out
    elseif label == "Generate" then
        generateOptions()

    -- Exit without saving
    elseif label == "Exit" then
        fadeOutBackgroundMusic()
        fadeParams.fadeTimer = 0
        fadeParams.fadeType = "out"
        fadeParams.fadeFinished = false
        playUISound("enter")
    end
end

-----------------------------------------------------------------------------------
-- HANDLE SELECTION ---------------------------------------------------------------
-----------------------------------------------------------------------------------
function handleSelection()
    local selectedItem = menus[selectedMenu][selectedOption]
    local label = type(selectedItem) == "table" and selectedItem.label or selectedItem

    -- Toggle boolean options
    if label == "Hard" or label == "Dungeons" or label == "Keysanity" or label == "Crossitems" or label == "Portals" then
        selectedItem.value = not selectedItem.value
        playUISound("toggle")

    -- Cycle Music options
    elseif label == "Music" then
        selectedMusicIndex = (selectedMusicIndex % #musicOptions) + 1
        selectedItem.value = musicOptions[selectedMusicIndex]
        playUISound("toggle")

    -- Generate options.ini and fade out
    elseif label == "Generate" then
        generateOptions()

    -- Exit without saving
    elseif label == "Exit" then
        fadeOutBackgroundMusic()
        fadeParams.fadeTimer = 0
        fadeParams.fadeType = "out"
        fadeParams.fadeFinished = false
        playUISound("enter")
    end
end

-----------------------------------------------------------------------------------
-- GENERATE OPTIONS ---------------------------------------------------------------
-----------------------------------------------------------------------------------
function generateOptions()
    local selectedGameFile = "options.ini"
    local radioFile = "launcher/radio.txt"
    local radioOptions = { "ages", "seasons" }

    local lines = {}

    -- [rom] section
    lines[#lines + 1] = "[rom]"
    lines[#lines + 1] = "1=" .. radioOptions[selectedRadioOption]

    -- [flags] section
    lines[#lines + 1] = "[flags]"
    for _, option in ipairs(menus[selectedMenu]) do
        if type(option) == "table" and option.label ~= "Music" then
            local keyName = string.lower(option.label)
            local value = option.value and "1" or "0"

            -- Special handling for Portals
            if option.label == "Portals" then
                if selectedRadioOption == 1 then  -- Ages selected
                    keyName = "automermaid"
                end
                -- If Seasons, keyName stays "portals" and value is 1/0 as normal
            end

            lines[#lines + 1] = keyName .. "=" .. value
        end
    end

    -- Music
    local musicOption = menus[selectedMenu][6]  -- Music index
    lines[#lines + 1] = 'music="' .. musicOption.value .. '"'

    -- Write options.ini with newline at the end
    local file = io.open(selectedGameFile, "w")
    if file then
        file:write(table.concat(lines, "\n") .. "\n")
        file:close()
    else
        print("Error: Cannot write to " .. selectedGameFile)
    end

    -- Write selected radio option to radio.txt
    local fileRadio = io.open(radioFile, "w")
    if fileRadio then
        fileRadio:write(tostring(selectedRadioOption))
        fileRadio:close()
    else
        print("Error: Cannot write to " .. radioFile)
    end

    -- Fade out background music and start fade
    fadeOutBackgroundMusic()
    fadeParams.fadeTimer = 0
    fadeParams.fadeType = "out"
    fadeParams.fadeFinished = false
    playUISound("enter")
end

-------------------------------------------------------------------------------------------
-- UPDATE LOGIC ---------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Main update function
function love.update(dt)
    timeSinceLastInput = timeSinceLastInput + dt
    if timeSinceLastInput >= inputCooldown then
        handleInput()
    end
    if fadeParams.fadeFinished and fadeParams.fadeType == "out" then
        love.event.quit()
    end
end