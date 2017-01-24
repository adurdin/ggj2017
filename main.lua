debugVars = {}

terrain = {
    WIDTH = 1024,
    HEIGHT = 160,
    GRASS_DEPTH = 5,
    MIN_DEPOSIT_WIDTH = 40,
    MIN_DEPOSIT_HEIGHT = 5,
    MIN_EDGE_HEIGHT = 10,
}

world = {
    WIDTH = 1440,
    HEIGHT = 500,
    TERRAIN_Y = 200,
    TERRAIN_SIZE = 160
}

screen = {
    -- NOTE: on andy's macbook, use 1680x1050 for fullscreen
  WIDTH = 800,
  HEIGHT = 600,
  DEFAULT_FULLSCREEN = false
}

-- minimum scale fills the height of the screen
SCREEN_CAMERA_SCALE = (screen.HEIGHT / world.HEIGHT)

camera = {
    positionX = 0.0, -- world space coordinate that is top left of camera
    positionY = 0.0,
    scale = 1.0 -- 1.0 is 1 to 1 pixels, 2.0 is double size pixels
}

level = {}
level.current = nil
level.next = nil

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- SOUND

sounds = {
    test    = {"assets/sounds/test1.wav",   nil, false},
    sonar   = {"assets/sounds/sonar.wav",   nil, false},
    splat   = {"assets/sounds/splat.wav",   nil, false},
    colapse = {"assets/sounds/colapse.wav", nil, false},
    deposit = {"assets/sounds/deposit.wav", nil, false},
    coin    = {"assets/sounds/coin.wav",    nil, false},
    drill_up   = {"assets/sounds/drill_up.wav",   nil, false},
    drill_down = {"assets/sounds/drill_down.wav", nil, false},
    pumping    = {"assets/sounds/pumping.wav", nil, false},
    suck    = {"assets/sounds/suck.wav", nil, true},
    tick    = {"assets/sounds/tick.wav", nil, false},
    music   = {"assets/music.ogg", nil, true}
}

function soundLoad()
    for key, value in pairs(sounds) do
        local path = value[1]
        local src = love.audio.newSource(path, "static")
        sounds[key][2] = src
        if not src then
            print("unable to load " .. path)
        else
            local loop = value[3]
            src:setLooping(loop)
        end
    end
    -- NOTE: this is a quick fix to stop playing music over the top of itself.
    love.audio.stop( )
    soundEmit("music", 0.5, 1.0)
end

function soundEmit(name, vol, pitch)
    if not vol then
        vol = 0.75
    end
    if not pitch then
        pitch = 1.0
    end
    local sound = sounds[name]
    if sound then
        local src = sound[2]
        if src then
            src:setVolume(vol)
            src:setPitch(pitch)
            if (sound[3]) then -- looping
                src:rewind()
            end
            src:play()
        end
    end
end

function soundStop(name)
    local sound = sounds[name]
    if sound then
        local src = sound[2]
        if src then
            src:stop()
        end
    end
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- UTILITY FUNCTIONS

function toCurrency(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

function clamp(min, val, max)
    return math.max(min, math.min(val, max))
end

function lerp(v1, v2, t)
    return v1 + (v2 - v1) * t
end

function randomScaledPointInRectWithOffset(centerX, centerY, rectWidth, rectHeight, scale, offsetX, offsetY)
    local leftHalfWidth = (rectWidth / 2) - (centerX - offsetX)
    local rightHalfWidth = rectWidth - leftHalfWidth
    local topHalfHeight = (rectHeight / 2) - (centerY - offsetY)
    local bottomHalfHeight = rectHeight - topHalfHeight
    local x, y
    local nx = 2 * scale * (love.math.random() - 0.5)
    local ny = 2 * scale * (love.math.random() - 0.5)
    if nx < 0 then
        x = offsetX + leftHalfWidth * nx
    else
        x = offsetX + rightHalfWidth * nx
    end
    if ny < 0 then
        y = offsetY + topHalfHeight * ny
    else
        y = offsetY + bottomHalfHeight * ny
    end
    return x, y
end

function isCtrlPressed()
    return (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"))
end

function isCmdPressed()
    return (love.keyboard.isDown("lcmd") or love.keyboard.isDown("rcmd"))
end

function isAltPressed()
    return (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))
end

function setWindow(width, height, fullscreen)
    local previousX, previousY, display = love.window.getPosition()
    local previousWidth, previousHeight, previousFlags = love.window.getMode()
    local desktopWidth, desktopHeight = love.window.getDesktopDimensions(display)

    if width == nil then width = previousWidth end
    if height == nil then height = previousHeight end
    if fullscreen == nil then fullscreen = previousFlags.fullscreen end

    -- ignore args, and just hardcode sizes here, until we can calculate screen sizes
    if fullscreen then
        width = desktopWidth
        height = desktopHeight
    else
        width = 800
        height = 600
    end

    -- make sure the window can fit on the screen
    width = math.min(width, desktopWidth)
    height = math.min(height, desktopHeight)

    -- set up the window
    love.window.setMode(width, height, {
        centered = true,
        fullscreen = fullscreen,
        love.window.setTitle( "Frack The Planet - GGJ2017" ),
        vsync = true,
        resizable = false,
        centered = true,
        borderless = fullscreen,
        display = display,
        minwidth = 640,
        minheight = 480,
        highdpi = false,
    })
end

function printCenteredShadowedText(text, x, y, color, shadowColor)
    local offset = 2
    local halfWidth = screen.WIDTH / 2
    love.graphics.setColor(shadowColor[1], shadowColor[2], shadowColor[3], shadowColor[4])
    love.graphics.printf(text, x - halfWidth + offset, y + offset, halfWidth * 2, "center")
    love.graphics.setColor(color[1], color[2], color[3], color[4])
    love.graphics.printf(text, x - halfWidth, y, halfWidth * 2, "center")
end

function string:split(sSeparator, nMax, bRegexp)
    assert(sSeparator ~= '')
    assert(nMax == nil or nMax >= 1)

    local aRecord = {}

    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField, nStart = 1, 1
        local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax-1
        end
        aRecord[nField] = self:sub(nStart)
    end

    return aRecord
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- SPACE CONVERSIONS

function terrain_to_world(x, y)
    return
        (x * (world.WIDTH / terrain.WIDTH)),
        (y * (world.TERRAIN_SIZE / terrain.HEIGHT) + world.TERRAIN_Y)
end

function world_to_terrain(x, y)
    local offsetY = (y - world.TERRAIN_Y)
    local scaleX = (terrain.WIDTH / world.WIDTH)
    local scaleY = (terrain.HEIGHT / world.TERRAIN_SIZE)
    return
        math.floor((x * scaleX) + 0.5),
        math.floor((offsetY * scaleY) + 0.5)
end

function terrain_to_world_height(h)
    return (h * (world.TERRAIN_SIZE / terrain.HEIGHT))
end

function world_to_view(x, y)
    return
        (x * (screen.WIDTH / world.WIDTH)),
        (y * (screen.HEIGHT / world.HEIGHT))
end

function view_to_world(x, y)
    return
        (x * (world.WIDTH / screen.WIDTH)),
        (y * (world.HEIGHT / screen.HEIGHT))
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- MENU LEVEL

menuLevel = {}

function menuLevel:load()
    -- load credits sprites
    self.titleSize = 48
    self.nameSize = 28
    self.titleFont = love.graphics.newFont("assets/nullp.ttf", self.titleSize)
    self.nameFont = love.graphics.newFont("assets/nullp.ttf", self.nameSize)
    self.titleColor = {255, 64, 32, 255}
    self.nameColor = {255, 255, 255, 255}
    self.shadowColor = {64, 64, 64, 255}
    self.scrollY = screen.HEIGHT
end

function menuLevel:printTitle(text, y)
    love.graphics.setFont(self.titleFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.titleColor, self.shadowColor)
    return y + self.titleSize
end

function menuLevel:printName(text, y)
    love.graphics.setFont(self.nameFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.nameColor, self.shadowColor)
    return y + self.nameSize
end

function menuLevel:blankLine(y)
    return y + self.titleSize
end

function menuLevel:draw()
    love.graphics.setFont(debugVars.debugFont)
    love.graphics.setBackgroundColor(0, 0, 0, 255)
    love.graphics.clear()
    
    -- nonsense from aaron
    love.graphics.setColor(0,140,255)
    love.graphics.rectangle("fill", 0, 0, screen.WIDTH, screen.HEIGHT-100)
    love.graphics.setColor(5,162,9)
    love.graphics.rectangle("fill", 0, screen.HEIGHT-100, screen.WIDTH, screen.HEIGHT-50)
    love.graphics.setColor(123,69,23)
    love.graphics.rectangle("fill", 0, screen.HEIGHT-50, screen.WIDTH, screen.HEIGHT)
    love.graphics.setColor(255,255,255,255);
    menuImage = love.graphics.newImage("assets/menu.png")
    love.graphics.draw(menuImage, screen.WIDTH-500,screen.HEIGHT-500)

    local y = 50
    y = self:printTitle("F R A C K  t h e  P L A N E T", y)
    y = self:blankLine(y)
    y = self:printName("SPACE to start", y)
    y = self:blankLine(y)
    y = self:printName("H for help and controls", y)
    y = self:printName("C for credits", y)
    y = self:printName("ESC to quit", y)
end

function menuLevel:keypressed(key)
    if key == "space" or key == "enter" then
        level.next = gameLevel
    elseif key == "h" then
        level.next = helpLevel
    elseif key == "c" then
        level.next = creditsLevel
    elseif key == "q" or key == "escape" then
        love.event.quit()
    end
end

function menuLevel:update()
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- HELP LEVEL

helpLevel = {}
helpLevel = {}

function helpLevel:load()
    -- load credits sprites
    self.titleSize = 48
    self.nameSize = 28
    self.titleFont = love.graphics.newFont("assets/nullp.ttf", self.titleSize)
    self.nameFont = love.graphics.newFont("assets/nullp.ttf", self.nameSize)
    self.titleColor = {255, 64, 32, 255}
    self.nameColor = {255, 255, 255, 255}
    self.shadowColor = {64, 64, 64, 255}
    self.scrollY = screen.HEIGHT
end

function helpLevel:printTitle(text, y)
    love.graphics.setFont(self.titleFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.titleColor, self.shadowColor)
    return y + self.titleSize
end

function helpLevel:printName(text, y)
    love.graphics.setFont(self.nameFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.nameColor, self.shadowColor)
    return y + self.nameSize
end

function helpLevel:blankLine(y)
    return y + self.titleSize
end

function helpLevel:draw()
    love.graphics.setFont(debugVars.debugFont)
    love.graphics.setBackgroundColor(0, 0, 0, 255)
    love.graphics.clear()
    
    -- nonsense from aaron
    love.graphics.setColor(0,140,255)
    love.graphics.rectangle("fill", 0, 0, screen.WIDTH, screen.HEIGHT-100)
    love.graphics.setColor(5,162,9)
    love.graphics.rectangle("fill", 0, screen.HEIGHT-100, screen.WIDTH, screen.HEIGHT-50)
    love.graphics.setColor(123,69,23)
    love.graphics.rectangle("fill", 0, screen.HEIGHT-50, screen.WIDTH, screen.HEIGHT)
    love.graphics.setColor(255,255,255,255);
    menuImage = love.graphics.newImage("assets/menu.png")
    love.graphics.draw(menuImage, screen.WIDTH-500,screen.HEIGHT-500)

    local y = 50
    y = self:printTitle("Help:", y)
    y = self:printName("Left/Right ------------------------- Drive", y)
    y = self:printName("Space ---  Scan for gas deposits", y)
    y = self:printName("Up/Down --------------  Drill up/down", y)
    y = self:printName("Space (hold) --- Pump gas from deposit", y)
    y = self:blankLine(y)
    y = self:printName("Space to return to menu", y)
end

function helpLevel:keypressed(key)
    if key == "space" or key == "escape" or key == "return" then
        level.next = menuLevel
    end
end

function helpLevel:update()
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- MENU LEVEL

creditsLevel = {}

function creditsLevel:load()
    -- load credits sprites
    self.titleSize = 24
    self.nameSize = 32
    self.titleFont = love.graphics.newFont("assets/nullp.ttf", self.titleSize)
    self.nameFont = love.graphics.newFont("assets/nullp.ttf", self.nameSize)
    self.titleColor = {32, 192, 255, 255}
    self.nameColor = {255, 255, 255, 255}
    self.shadowColor = {64, 64, 64, 255}
    self.scrollY = screen.HEIGHT
end

function creditsLevel:printTitle(text, y)
    love.graphics.setFont(self.titleFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.titleColor, self.shadowColor)
    return y + self.titleSize
end

function creditsLevel:printName(text, y)
    love.graphics.setFont(self.nameFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.nameColor, self.shadowColor)
    return y + self.nameSize
end

function creditsLevel:blankLine(y)
    return y + self.titleSize
end

function creditsLevel:draw()
    y = self.scrollY
    love.graphics.setBackgroundColor(0, 0, 0, 255)
    love.graphics.clear()

    y = self:printTitle("Team Wrangling / First Casualty", y)
    y = self:printName("Aaron Dron", y)
    y = self:blankLine(y)

    y = self:printTitle("Civil & Industrial Engineering", y)
    y = self:printName("Aidan Dodds", y)
    y = self:blankLine(y)

    y = self:printTitle("Geological Subduction", y)
    y = self:printName("Andy Durdin", y)
    y = self:blankLine(y)

    y = self:printTitle("Crowd Control", y)
    y = self:printName("David Farrell", y)
    y = self:blankLine(y)

    y = self:printTitle("Seismic Imaging", y)
    y = self:printName("Gordon Brown", y)
    y = self:blankLine(y)

    y = self:printTitle("Infrastructure / Second Casualty", y)
    y = self:printName("Luke Drummond", y)
    y = self:blankLine(y)

    y = y + 200

    y = self:printTitle("Intrepid Polar Expedition", y)
    y = self:printName("Gordon Brown, David Farrell, Aidan Dodds", y)

    if y < 0 then
        level.next = menuLevel
    end
end

function creditsLevel:keypressed(key)
    if key == "space" or key == "escape" or key == "return" then
        level.next = menuLevel
    end
end

function creditsLevel:update(dt)
    self.scrollY = self.scrollY - 50 * dt
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- GAME LEVEL

gameLevel = {
    LEVEL_TIME = 90.0 -- seconds
}

function gameLevel:load()
    -- When the game starts:

    -- random seed
    gameLevel.seed = (love.math.random() - 0.5) * 10 * 2 * terrain.WIDTH
    print("seed: "..dump(gameLevel.seed))

    -- load the hud fonts
    gameLevel.scoreFont = love.graphics.newFont("assets/nullp.ttf", 32)
    gameLevel.timerFont = love.graphics.newFont("assets/nullp.ttf", 48)
    messages:load()

    -- load an image
    protestorSheet = love.graphics.newImage("assets/protestors.png")
    protestorSheet:setFilter("nearest", "nearest")
    protestorSheet:setWrap("clamp", "clamp")

    houseSheet = love.graphics.newImage("assets/houses.png")
    houseSheet:setFilter("nearest", "nearest")
    houseSheet:setWrap("clampzero", "clamp")

    sonarShader = love.graphics.newShader("assets/sonarShader.fs")
    drawShader = love.graphics.newShader("assets/drawShader.fs")

    intermediateCanvas = love.graphics.newCanvas(world.WIDTH, world.HEIGHT)
    intermediateCanvas:setWrap("repeat", "clamp")
    intermediateCanvas:setFilter("nearest", "nearest")

    bloodParticleImage = love.graphics.newImage("assets/blood.png")
    bloodParticleImage:setFilter("nearest", "nearest")
    bloodParticleImage:setWrap("clamp", "clamp")

    pumpParticleImage = love.graphics.newImage("assets/pumpParticle.png")
    pumpParticleImage:setFilter("nearest", "nearest")
    pumpParticleImage:setWrap("clamp", "clamp")

    rockParticleImage = love.graphics.newImage("assets/rockParticle.png")
    rockParticleImage:setFilter("nearest", "nearest")
    rockParticleImage:setWrap("clamp", "clamp")
 
    -- load all of the sounds we can
    soundLoad()

    -- set background colour
    love.graphics.setBackgroundColor(255,255,255)

    sonar.sourcePosition = {0.0, 0.0}
    sonar.radius = 0.3
    sonar.maxTime = sonar.radius * 10.0
    sonar.currentTime = 0.0

    -- create a raster terrain
    terrain:create()

    -- create player
    player:create()

    -- create people
    for x=0,(people.COUNT-1) do
        people[x] = createPerson()
    end
    
    -- create houses
    for x=0, houseData.REQUIRED do
        houses[x] = createHouse()
    end

    -- set up the timer (+ a bit so people don't feel cheated)
    gameLevel.timeRemaining = gameLevel.LEVEL_TIME + 0.9
end

function gameLevel:update(dt)
    -- count down until game over (except in debug mode)
    if not debugVars.debugModeEnabled then
        local previousSecondsLeft = math.ceil(gameLevel.timeRemaining)
        gameLevel.timeRemaining = gameLevel.timeRemaining - dt
        local secondsLeft = math.ceil(gameLevel.timeRemaining)
        if gameLevel.timeRemaining <= 0 then
            gameOverLevel.score = player.score
            level.next = gameOverLevel
            return
        else
            if secondsLeft < 11 and previousSecondsLeft ~= secondsLeft then
                soundEmit("tick", nil, 1.0 + 0.04 * (11 - secondsLeft))
            end
        end
    end

    sonar:update(dt)

    -- update terrain
    terrain:update(dt)

    -- check to see if player wants to pump
    if player.isDrilling then
        -- see if there's a deposit at the drill
        local canStartPumping = player:canStartPumping()
        if not previousCanStartPumping and canStartPumping then
            print("a deposit!")
            -- TODO: visual or audio feedback (a "splash"?) that the drill is passing through an oil deposit?
            soundEmit("deposit")
        elseif previousCanStartPumping and not canStartPumping then
            -- moved the drill out of this deposit, so reset pumping progress
            player.pumpProgress = 0
        end
        previousCanStartPumping = canStartPumping

        -- see if the player is trying to pump
        local spacePressed = love.keyboard.isDown("space")
        if spacePressed and not player.isPumping then
            if canStartPumping then
                player:startPumping()
            else
                -- TODO: audio feedback that there's nothing to pump here
                player:addRockParticles()
            end
        elseif not spacePressed and player.isPumping then
            player:cancelPumping()
        elseif spacePressed and player.isPumping then
            -- keep pumping while space is held
            -- increment pumping progress
            player.pumpProgress = math.min(player.pumpProgress +
                (player.PUMP_RATE / player.pumpSize  * dt), 1.0)
            -- show feedback
            player:addPumpParticles()
            -- check for completion
            if player.pumpProgress == 1.0 then
                player:finishPumping()
            end
        end
    end

    -- update player
    player:update(dt)

    -- update people
    for x=0,(people.COUNT-1) do
        if people[x].alive then
            people[x]:update(dt)
        elseif love.math.random() < 0.1 * dt then
            people[x]:respawn()
        end
    end
    
    if houses then
        for key, value in pairs(houses) do
            value:update()
        end
    end
    
    -- update messages
    messages:update(dt)

    -- update camera position
    
    if debugVars.cameraControlEnabled then
        if screen.WIDTH == 1680 and screen.HEIGHT == 1050 then
            camera.scale = 3.0
        else
            camera.scale = 2.0
        end
        camera.positionX = player.x - (screen.WIDTH / 2.0) / camera.scale
        camera.positionY = 100.0
    else
        if false then
            if love.keyboard.isDown("r") then
                camera.scale = camera.scale + 0.01
            elseif love.keyboard.isDown("f") then
                camera.scale = camera.scale - 0.01
            elseif love.keyboard.isDown("t") then
                camera.positionX = camera.positionX + 5
            elseif love.keyboard.isDown("g") then
                camera.positionX = camera.positionX - 5
            elseif love.keyboard.isDown("y") then
                camera.positionY = camera.positionY + 5
            elseif love.keyboard.isDown("h") then
                camera.positionY = camera.positionY - 5
            end
            print(" s: "..dump(camera.scale).." x: "..dump(camera.positionX).." y: "..dump(camera.positionY))
        else
            if screen.WIDTH == 1680 and screen.HEIGHT == 1050 then
                camera.scale = 1.92
                camera.positionX = 280
                camera.positionY = -300
            else
                camera.scale = 1.3
                camera.positionX = 420.0
                camera.positionY = -245.0
            end
        end
    end
end

function gameLevel:keypressed(key, unicode)
    -- Quit on escape
    if key == "escape" then
        -- quit to menu
        level.next = menuLevel
    end

    if false and love.keyboard.isDown("p") then
        if debugVars.debugModeEnabled == false then
            debugVars.debugModeEnabled = true
        else
            debugVars.debugModeEnabled = false
        end
    end
    
    if false and love.keyboard.isDown("r") then
        if debugVars.polarRenderingEnabled == false then
            debugVars.polarRenderingEnabled = true
        else
            debugVars.polarRenderingEnabled = false
        end
    end
    
    if false and love.keyboard.isDown("c") then
        if debugVars.cameraControlEnabled == false then
            debugVars.cameraControlEnabled = true
        else
            debugVars.cameraControlEnabled = false
            camera.scale = 1.0
            camera.positionX = 0.0
            camera.positionY = 0.0
        end
    end

    if not player.isDrilling and key == "space" then
        screenWidth = love.graphics.getWidth()
        screenHeight = love.graphics.getHeight()
        sonar.sourcePosition = {(player.x / world.WIDTH), (player.y / world.HEIGHT)}
        sonar.currentTime = sonar.maxTime;
        soundEmit("sonar")
    end

    -- toggle FPS counter on ctrl+f
    if key == "f" and isCtrlPressed() then
        debugVars.showFPSCounter = not debugVars.showFPSCounter
    end

    if key == "v" then
        soundEmit("test")
    end

    if key == "o" then
        messages:spawn("text", {255, 128, 0, 255})
    end
end

function gameLevel:draw()
    -- Every frame:

    -- draw the world
    sonarShader:send("sourcePosition", sonar.sourcePosition)
    sonarShader:send("radius", sonar.radius)
    sonarShader:send("maxTime", sonar.maxTime)
    sonarShader:send("currentTime", sonar.currentTime)
    sonarShader:send("densityMap", terrain.image)
    sonarShader:send("WORLD_WIDTH", world.WIDTH)
    sonarShader:send("WORLD_HEIGHT", world.HEIGHT)
    sonarShader:send("WORLD_TERRAIN_Y", world.TERRAIN_Y)
    sonarShader:send("WORLD_TERRAIN_SIZE", world.TERRAIN_SIZE)
    sonarShader:send("debugModeEnabled", debugVars.debugModeEnabled)

    local prevBlendMode = {love.graphics.getBlendMode()}
    love.graphics.setBlendMode("replace", "premultiplied")
    love.graphics.setShader(sonarShader)
    love.graphics.setCanvas(intermediateCanvas)
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(singlePixelImage, 0, 0, 0, world.WIDTH, world.HEIGHT)
    love.graphics.setBlendMode(unpack(prevBlendMode))

    love.graphics.setCanvas()
    love.graphics.setShader()

    -- draw houses
    if houses then
        for key, value in pairs(houses) do
            value:draw()
        end
    end

    -- render player
    love.graphics.setCanvas(intermediateCanvas)
    player:draw()
    love.graphics.setCanvas()

    -- diplay rectangles in corners of world space
    if debugVars.debugModeEnabled then
        love.graphics.setCanvas(intermediateCanvas)
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle("fill", 5, 5, 45, 45)
        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.rectangle("fill", 1390, 5, 45, 45)
        love.graphics.setColor(0, 0, 255, 255)
        love.graphics.rectangle("fill", 5, 450, 45, 45)
        love.graphics.setColor(255, 255, 0, 255)
        love.graphics.rectangle("fill", 1390, 450, 45, 45)
        love.graphics.setCanvas()
    end
    
    -- draw people folk
    for x=0,(people.COUNT-1) do
        if people[x].alive then people[x]:draw() end
    end
    
    -- hack starting rotation
    local startingRotation = 4.6 -- math.pi * 3 / 4
    local playerRotation = player.x / world.WIDTH * 2 * math.pi
    
    -- draw game world to screen
    local fullScreenCorrection = (screen.HEIGHT / world.HEIGHT)
    drawShader:send("cameraPosition", {camera.positionX / world.WIDTH, camera.positionY / world.HEIGHT})
    drawShader:send("cameraScale", camera.scale / fullScreenCorrection)
    drawShader:send("polarRendering",debugVars.polarRenderingEnabled)
    drawShader:send("polarRotation", (startingRotation + playerRotation) / (math.pi * 2))
    love.graphics.setShader(drawShader)
    love.graphics.draw(intermediateCanvas, 0, 0, 0, fullScreenCorrection, fullScreenCorrection)
    love.graphics.setShader()

    -- draw messages
    love.graphics.push()
    messages:draw()
    love.graphics.pop()

    -- show the player score
    love.graphics.push()
    love.graphics.setFont(gameLevel.scoreFont)
    local text = "$"..toCurrency(math.floor(player.drawScore))
    local textColor
    if player.drawScore < 0 then
        textColor = {200, 32, 16, 255}
    else
        textColor = {0, 0, 0, 255}
    end
    printCenteredShadowedText(text, screen.WIDTH / 2, 10, textColor, {255, 255, 255, 192})
    love.graphics.pop()

    -- draw game time remaining
    love.graphics.push()
    love.graphics.setFont(gameLevel.timerFont)
    local secondsLeft = math.ceil(gameLevel.timeRemaining)
    local text = tostring(secondsLeft)
    local shakeX, shakeY = 0, 0
    if secondsLeft < 11 then
        local shakeMagnitude = 1.5 * (11 - secondsLeft)
        shakeX = love.math.random(-shakeMagnitude, shakeMagnitude)
        shakeY = love.math.random(-shakeMagnitude, shakeMagnitude)
    end
    printCenteredShadowedText(text, screen.WIDTH / 2 + shakeX, 40 + shakeY, {0, 0, 0, 255}, {255, 255, 255, 192})
    love.graphics.pop()

    if debugVars.renderTerrainBuffer then
        terrain:draw(-512, 0, false)
    end
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- GAME OVER LEVEL

gameOverLevel = {}

function gameOverLevel:load()
    -- expect score to be set elsewhere
    self.score = self.score or 0

    -- load gameOver graphics
    self.titleSize = 48
    self.nameSize = 36
    self.titleFont = love.graphics.newFont("assets/nullp.ttf", self.titleSize)
    self.nameFont = love.graphics.newFont("assets/nullp.ttf", self.nameSize)
    self.titleColor = {255, 64, 32, 255}
    self.nameColor = {255, 255, 255, 255}
    self.shadowColor = {64, 64, 64, 255}
    self.scrollY = screen.HEIGHT
end

function gameOverLevel:printTitle(text, y)
    love.graphics.setFont(self.titleFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.titleColor, self.shadowColor)
    return y + self.titleSize
end

function gameOverLevel:printName(text, y)
    love.graphics.setFont(self.nameFont)
    printCenteredShadowedText(text, screen.WIDTH / 2, y, self.nameColor, self.shadowColor)
    return y + self.nameSize
end

function gameOverLevel:blankLine(y)
    return y + self.titleSize
end

function gameOverLevel:draw()
    love.graphics.setBackgroundColor(0, 0, 0, 255)
    love.graphics.clear()
    
        -- nonsense from aaron
    love.graphics.setColor(0,140,255)
    love.graphics.rectangle("fill", 0, 0, screen.WIDTH, screen.HEIGHT-100)
    love.graphics.setColor(5,162,9)
    love.graphics.rectangle("fill", 0, screen.HEIGHT-100, screen.WIDTH, screen.HEIGHT-50)
    love.graphics.setColor(123,69,23)
    love.graphics.rectangle("fill", 0, screen.HEIGHT-50, screen.WIDTH, screen.HEIGHT)
    love.graphics.setColor(255,255,255,255);
    menuImage = love.graphics.newImage("assets/fractormenu.png")
    local shakeAmount = 4.0 * (love.math.random(-0.1,  0.05))
    love.graphics.draw(menuImage, 0,screen.HEIGHT-390 + shakeAmount)

    local y = 50
    y = self:printTitle("- GAME OVER -", y)
    y = self:blankLine(y)
    y = self:printName("Your score: $"..toCurrency(math.floor(self.score)), y)
    y = self:blankLine(y)
    y = self:printName("ESC to restart", y)
end

function gameOverLevel:keypressed(key)
    if key == "escape" or key == "return" then
        level.next = menuLevel
    end
end

function gameOverLevel:update()
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- LOVE CALLBACKS

function love.load()
    -- set some default values
    debugVars.debugFont = love.graphics.newFont(16)
    debugVars.showFPSCounter = false
    debugVars.debugModeEnabled = false
    debugVars.polarRenderingEnabled = true
    debugVars.cameraControlEnabled = false
    debugVars.renderTerrainBuffer = false

    -- set up the window
    setWindow(screen.WIDTH, screen.HEIGHT, screen.DEFAULT_FULLSCREEN)
    singlePixelImage = love.graphics.newImage("assets/singlePixelImage.jpg")

    -- load the first level
    local l = menuLevel
    level.current = l
    level.next = nil
    -- load the new level
    if l.load then l:load() end
end

function love.update(dt)
    hotReload()

    if level.next then
        -- change levels
        local l1, l2 = level.current, level.next
        -- quit the old level
        if l1 then
            if l1.quit then l1:quit() end
        end
        -- swap levels
        level.current = l2
        level.next = nil
        -- load the new level
        if l2 then
            if l2.load then l2:load() end
        end
    else
        -- update the current level
        local l = level.current
        if l.update then l:update(dt) end
    end
end

function love.keypressed(key, unicode)
    -- toggle fullscreen on alt-enter
    if key == "return" and isAltPressed then
        local _, _, flags = love.window.getMode()
        setWindow(screen.WIDTH, screen.HEIGHT, not flags.fullscreen)
        return
    end

    -- quit on ctrl-q or cmd-q
    if key == "q" and (isCtrlPressed or isCmdPressed) then
        love.event.quit()
        return
    end

    -- pass other keys to the current level
    local l = level.current
    if l.keypressed then l:keypressed(key, unicode) end
end

function love.draw()
    -- roughly scale to fit the screen
    local windowWidth, windowHeight, _ = love.window.getMode()
    screen.WIDTH = windowWidth
    screen.HEIGHT = windowHeight

    -- draw the current level
    local l = level.current

    love.graphics.push()
    if l.draw then l:draw() end
    love.graphics.pop()

    -- show the fps counter
    if debugVars.showFPSCounter then
        love.graphics.push()
        love.graphics.setFont(debugVars.debugFont)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle("fill", 0, 0, 70, 20)
        love.graphics.setColor(255, 255, 0, 255)
        love.graphics.print("FPS: "..tostring(love.timer.getFPS()), 0, 0)
        love.graphics.pop()
    end
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- HOT RELOAD

hotReloadFrameCounter = 0
mainLastModified = love.filesystem.getLastModified("main.lua")

function hotReload()
    hotReloadFrameCounter = (hotReloadFrameCounter + 1) % 10
    if hotReloadFrameCounter == 0 then
        if mainLastModified ~= love.filesystem.getLastModified("main.lua") then
            mainLastModified = love.filesystem.getLastModified("main.lua")
            ok, mainCode = pcall(love.filesystem.load,"main.lua")  -- Load program
            if not ok then
                print("Load error: "..mainCode)
            else
                print("Reloaded")
                ok, err = pcall(mainCode) -- Execute program
                if not ok then
                    print("Execute error: "..err)
                end
                love.load()
            end
        end
    end
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- TERRAIN

-- dirt 0 is not falling; dirt 1-127 is falling with some velocity
TERRAIN_DIRT_ALPHA_MIN = 0
TERRAIN_DIRT_ALPHA_MAX = 127
TERRAIN_DIRT_COLOR = {123, 69, 23}
-- gas is paydirt. paydirt is not dirt.
TERRAIN_GAS_ALPHA = 128
-- void is where gas used to be, but we pumped it out.
TERRAIN_VOID_ALPHA = 129
-- sky is the endless emptiness above all the dirt.
TERRAIN_SKY_ALPHA = 130
-- convert dirt alpha to velocity (pixels/second) with this value and multiplification
TERRAIN_ALPHA_TO_VELOCITY = 60
-- super falling force (pixels/second^2)
TERRAIN_GRAVITY = 16
-- maximum super falling speed (pixels/second)
TERRAIN_TERMINAL_VELOCITY = 10

function generateTerrainPixel(x, y, r, g, b, a)
    local scale = 3.5
    local scaleX = 1 * scale
    local scaleY = 1.5 * scale
    local noise = love.math.noise(x / terrain.width * scaleX + gameLevel.seed, y / terrain.height * scaleY + gameLevel.seed)
    local isDirt = (noise > 0.24)
    -- rgb channels can be used for color data
    -- alpha channel is terrain data and should not be rendered
    if y < terrain.GRASS_DEPTH then
        -- grass
        return 5, 162, 9, TERRAIN_DIRT_ALPHA_MIN
    elseif isDirt then
        -- dirt
        return 123, 69, 23, TERRAIN_DIRT_ALPHA_MIN
    else
        -- gas deposit
        return 0, 0, 0, TERRAIN_GAS_ALPHA
    end
end

function shockwaveForce(centerX, centerY, intensity, halfIntensityDistance, x, y)
    -- exponential falloff: return the value of the force at (`x`, `y`), given the
    -- force is `intensity` at its center, and half as strong at `halfIntensityDistance`.
    local distance = math.sqrt(math.pow((x - centerX), 2) + math.pow((y - centerY), 2))
    local exponent = distance * 0.6931471805599453 / halfIntensityDistance
    return intensity * math.exp(-exponent)
end

function terrain:create()
    self.width = self.WIDTH
    self.height = self.HEIGHT
    self.data = love.image.newImageData(self.width, self.height)
    self.collapsing = false

    -- create a terrain
    self.data:mapPixel(generateTerrainPixel)
    self:removeUnusableDeposits()

    self.image = love.graphics.newImage(self.data)
    self.image:setFilter("nearest", "nearest")
    self.image:setWrap("repeat", "clamp")

    -- surface is the y coordinate of the topmost piece of dirt in the terrain
    self.surface = {}
    for x=0,(self.width-1) do
        self.surface[x] = 0
    end

    -- an awake column is one where pixels might fall on an update
    -- for now, start with all columns awake
    -- we'll later only wake them with a shockwave
    self.awakeColumns={}
    for x=0,(self.width-1) do
        self.awakeColumns[x] = false
    end
end

function terrain:update(dt)
    -- find out which columns are awake
    local oldAwakeColumns = {}
    for x=0,(self.width-1) do
        oldAwakeColumns[x] = self.awakeColumns[x]
    end

    -- collapse each awake column
    local anyAwake = false
    local anyStayAwake = false
    for x=0,(self.width-1) do
        if oldAwakeColumns[x] then
            anyAwake = true
            -- collapse this column
            local stayAwake = self:collapseColumn(x, dt)
            self.awakeColumns[x] = stayAwake
            if stayAwake then
                anyStayAwake = true
            end

            -- wake up the columns beside it if it changed
            if stayAwake then
                if x > 0 and not oldAwakeColumns[x - 1] then
                    self:wakeColumn(x - 1)
                end
                if x < (self.width - 1) and not oldAwakeColumns[x + 1] then
                    self:wakeColumn(x + 1)
                end
            end
        end
    end
    if anyAwake and not anyStayAwake then
        self.collapsing = false
        print("collapse finished")
    end

    -- refresh the terrain image from its data
    terrain.image:refresh()
end

function terrain:draw(x, y, toCanvas)
    -- save state
    local prevBlendMode = {love.graphics.getBlendMode()}
    local prevColor = {love.graphics.getColor()}
    local prevColorMask = {love.graphics.getColorMask()}

    -- don't use alpha when drawing terrain, it's a data channel
    love.graphics.setBlendMode("replace", "premultiplied")
    love.graphics.setColor(255,255,255,255)
    love.graphics.setColorMask(true, true, true, toCanvas)
    love.graphics.draw(terrain.image, x, y)

    -- restore state
    love.graphics.setBlendMode(unpack(prevBlendMode))
    love.graphics.setColor(unpack(prevColor))
    love.graphics.setColorMask(unpack(prevColorMask))
end

-- collapse a single column of terrain
function terrain:collapseColumn(x, dt)
    local maxVelocity = 0 -- at the bottom of the terrain, all motion must stop
    local maxY = self.height - 1 -- and pixels can't fall past the bottom of the terrain

    local readY = self.height - 1
    local writeY = self.height - 1

    local stayAwake = false

    while readY >= 0 or writeY >= 0 do
        local r, g, b, a
        if readY >= 0 then
            r, g, b, a = self.data:getPixel(x, readY)

            if a >= TERRAIN_DIRT_ALPHA_MIN and a <= TERRAIN_DIRT_ALPHA_MAX then
                local velocity = a * TERRAIN_ALPHA_TO_VELOCITY
                if velocity == 0 then
                    -- this pixel isn't going to fall
                    -- but pixels above will stop if they hit this one
                    maxVelocity = 0
                    writeY = readY - 1
                else
                    -- something is falling
                    local newY = math.floor(readY + velocity * dt)
                    local newVelocity = math.floor(velocity + TERRAIN_GRAVITY * dt)

                    -- check for collisions and limit distance and velocity
                    if newY >= writeY then
                        newY = writeY
                        newVelocity = math.min(newVelocity, maxVelocity)
                    end

                    -- pixels above can't fall faster than this one if they hit it
                    maxVelocity = newVelocity

                    -- fill with void up to where it's fallen to
                    for y=writeY,newY+1,-1 do
                        self.data:setPixel(x, y, 0, 0, 0, TERRAIN_VOID_ALPHA)
                    end

                    -- and move the pixel
                    local newA = math.floor(newVelocity / TERRAIN_ALPHA_TO_VELOCITY)
                    self.data:setPixel(x, newY, r, g, b, newA)

                    -- keep the column awake if the pixel moved
                    if newVelocity > 0 then
                        stayAwake = true
                    end

                    writeY = newY - 1
                end
            elseif a == TERRAIN_SKY_ALPHA then
                -- Only sky from here up. Save the surface level and fall back to skyfilling
                self.surface[x] = readY
                readY = -1
            elseif a == TERRAIN_VOID_ALPHA then
                -- FIXME: later we want to keep track of the size of the void below each pixel maybe,
                -- so we can look it up without scanning the data again
                -- but for now do nothing
            elseif a == TERRAIN_GAS_ALPHA then
                -- this pixel isn't going to fall
                -- but pixels above will stop if they hit this one
                writeY = readY - 1
            else
                error("unknown terrain alpha: "..tostring(a))
            end
            readY = readY - 1
        else
            -- it's sky all the way up
            self.data:setPixel(x, writeY, 0, 140, 255, TERRAIN_SKY_ALPHA)
            writeY = writeY - 1
        end
    end

    return stayAwake
end

function terrain:startCollapse(x, minX, maxX, minY, maxY)
    if self.collapsing then
        print("error already collapsing. ignore it")
        return
    end
    self.collapsing = true
    self:wakeColumn(x)
    -- BUG: this sound is pretty quiet, so we tried to bump the volume up. I don't think it worked.
    soundEmit("colapse", 1.0, 4.0)
end

function terrain:wakeColumn(x)
    for y=0,(self.height-1) do
        local r, g, b, a = self.data:getPixel(x, y)
        if a == TERRAIN_DIRT_ALPHA_MIN then
            self.data:setPixel(x, y, r, g, b, (TERRAIN_DIRT_ALPHA_MIN + 1))
        end
    end
    self.awakeColumns[x] = true
end

function wrapToRange(min, value, max)
    local dif = max - min
    local v = math.fmod(value, dif)
    if (v < 0.0) then
      v = v + dif
    end
    return math.floor(min + v)
end

function terrain:worldSurface(worldX, vx)
    if vx == nil then
        vx = 1.0
    end
    -- warp worldx into terrain space
    local x, __ = world_to_terrain(worldX, 0)
    if x then
      -- sample terrain
      local y1 = self.surface[wrapToRange(0, x-vx, terrain.WIDTH)]
      local y2 = self.surface[wrapToRange(0, x-0.0, terrain.WIDTH)]
      local y3 = self.surface[wrapToRange(0, x+vx, terrain.WIDTH)]
      -- calculate normal
      local dx = vx * 2
      local dy = y3 - y1
      local sz = math.sqrt(dx*dx + dy*dy)
      -- transform y into world space
      local __, worldY = terrain_to_world(0, y2)
      return worldY,-dy/sz, dx/sz
    else
      return nil, nil, nil
    end
end

function terrain:sample(tx, ty)
    return self.data:getPixel(tx, ty)
end

function terrain:worldSample(worldX, worldY)
    local tx, ty = world_to_terrain(worldX, worldY)
    if (tx >= 0 and tx < self.WIDTH and ty >= 0 and ty < self.HEIGHT) then
        return self.data:getPixel(tx, ty)
    else
        return nil, nil, nil, nil
    end
end

function terrain:removeUnusableDeposits()
    local deposits = {}
    local filledPixels = {}

    -- find all deposits
    function handleDepositPixel(x, y, r, g, b, a)
        if a == TERRAIN_GAS_ALPHA and not PixelSet.contains(filledPixels, x, y) then
            -- do a floodfill to get the extents
            local fill = terrain:floodfill(x, y, TERRAIN_GAS_ALPHA)
            table.insert(deposits, fill)
            PixelSet.addPixelSet(filledPixels, fill.filled)
        end
        return r, g, b, a
    end
    self.data:mapPixel(handleDepositPixel)

    -- fill in unwanted deposits
    for i, d in pairs(deposits) do
        local atLeftEdge = (d.minX == 0)
        local atRightEdge = (d.maxX == terrain.WIDTH - 1)
        local atTopAndShallow = (d.minY <= terrain.GRASS_DEPTH and d.maxY < terrain.MIN_EDGE_HEIGHT)
        local atBottomAndShallow = (d.maxY >= (terrain.HEIGHT - 1) and (d.maxY - d.minY) < terrain.MIN_EDGE_HEIGHT)
        local notWideEnough = (d.maxX - d.minX < terrain.MIN_DEPOSIT_WIDTH)
        local notDeepEnough = (d.maxY - d.minY < terrain.MIN_DEPOSIT_HEIGHT)
        if (atLeftEdge or atRightEdge or atTopAndShallow or notWideEnough or notDeepEnough) then
            -- fill it with dirt
            local x, y = PixelSet.any(d.filled)
            terrain:floodfill(x, y, TERRAIN_DIRT_ALPHA_MIN, TERRAIN_DIRT_COLOR)
        end
    end
end

PixelSet = {}

function PixelSet.add(s, x, y)
    local key=x..':'..y
    s[key]=true
end

function PixelSet.contains(s, x, y)
    local key=x..':'..y
    return (s[key] ~= nil)
end

function PixelSet.any(s)
    local key
    for k in pairs(s) do
        key = k
        break
    end
    local r = key:split(":")
    return tonumber(r[1]), tonumber(r[2])
end

function PixelSet.addPixelSet(dest, source)
    for k,v in pairs(source) do
        dest[k] = v
    end
end

function terrain:floodfill(x, y, a, pixel)
    -- floodfill algorithm stolen from the forums
    local Queue={}
    Queue.__index=Queue
    function Queue:new()
        return setmetatable({Q={}}, Queue)
    end
    function Queue:put(x, y)
        local key=x..':'..y
        table.insert(self.Q, {x,y})
        self.Q[key]=true
    end
    function Queue:get()
        local x, y=unpack(table.remove(self.Q, 1))
        local key=x..':'..y
        self.Q[key]=nil
        return x, y
    end
    function Queue:has(x, y)
        local key=x..':'..y
        return self.Q[key]
    end
    function Queue:size()
        return #self.Q
    end

    local minX, maxX = x, x
    local minY, maxY = y, y
    local pixelCount = 0

    local seenPixels={}

    Q=Queue:new()
    function canFill(x, y, targetAlpha)
        if x < 0 or x >= self.width or y < 0 or y >= self.height then
            return false
        elseif PixelSet.contains(seenPixels, x, y) then
            return false
        else
            local pixel = {self.data:getPixel(x, y)}
            return (pixel[4] == targetAlpha)
        end
    end

    local fill
    function fill(x, y, targetAlpha, a)
        if not canFill(x, y, targetAlpha) then
            if Q:size()>0 then
                x, y=Q:get()
                return fill(x, y, targetAlpha, a)
            else
                return
            end
        end
        local r, g, b, _ = self.data:getPixel(x, y)
        if pixel ~= nil then
            r, g, b = pixel[1], pixel[2], pixel[3]
        end
        self.data:setPixel(x, y, r, g, b, a)
        PixelSet.add(seenPixels, x, y)
        pixelCount = pixelCount + 1
        if x < minX then minX = x end
        if x > maxX then maxX = x end
        if y < minY then minY = y end
        if y > maxY then maxY = y end
        if canFill(x+1, y, targetAlpha) and not Q:has(x+1, y) then
            Q:put(x+1, y)
        end
        if canFill(x, y+1, targetAlpha) and not Q:has(x, y+1) then
            Q:put(x, y+1)
        end
        if canFill(x-1, y, targetAlpha) and not Q:has(x-1, y) then
            Q:put(x-1, y)
        end
        return fill(x, y-1, targetAlpha, a)
    end

    -- start a floodfill
    local pixel = {self.data:getPixel(x, y)}
    fill(x, y, pixel[4], a)

    return {
        minX=minX, minY=minY, maxX=maxX, maxY=maxY,
        size=pixelCount, filled=seenPixels
    }
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- SONAR

sonar = {}

function sonar:update(dt)

    sonar.currentTime = sonar.currentTime - dt
    if sonar.currentTime < 0.0 then
        sonar.currentTime = 0.0
    end

end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- PLAYER

player = {
    DRILL_MAX_DEPTH = terrain_to_world_height(terrain.HEIGHT) - 1, -- frackulons
    DRILL_EXTEND_SPEED_DIRT = 64, -- frackulons/second
    DRILL_EXTEND_SPEED_GAS = 32, -- frackulons/second
    DRILL_RETRACT_SPEED_DIRT = 128, -- frackulons/second
    DRILL_RETRACT_SPEED_GAS = 64, -- frackulons/second
    PUMP_RATE = 1000/2, -- terrain units / second; an 1000 unit deposit will take four seconds
    GAS_PRICE = 987654/1, -- dollars / terrain units
    LAWYER_PRICE = 17 * 1754362 -- dollars / protester
}

function player:create()
    self.x, self.y = terrain_to_world(0, 0)
    self.trailerX, self.trailerY = 0, 0
    self.derrickX, self.derrickY = 0, 0
    self.vel = 0
    self.direction = 1 -- facing right
    self.rot = 0
    self.trailerRot = 0
    self.frameCounter = 0
    self.score = 0
    self.drawScore = self.score
    self.drawScoreAccum = 0

    -- drilling
    self.isDrilling = false
    self.drillDepth = 0
    self.drillDirection = 1

    -- pumping
    self.isPumping = false
    self.pumpX = 0
    self.pumpY = 0
    self.pumpSize = 0
    self.pumpScore = 0
    self.pumpProgress = 0
    self.pumpBounds = {minX=0, minY=0, maxX=0, maxY=0}
    self.pumpParticleSystems = {}
    self.pumpParticleSystemCount = 50
    self.rockParticleSystem = self:createRockParticleSystem()

    -- player image
    self.image = love.graphics.newImage("assets/fractor.png")
    self.image:setFilter("nearest", "nearest")
    self.image:setWrap("clampzero", "clampzero")
    local imageWidth, imageHeight = self.image:getDimensions()

    -- player sprite
    self.playerQuad = love.graphics.newQuad(
        41, 1, -- subimage x, y
        54, 47, -- subimage width, height
        imageWidth, imageHeight) -- image width, height
    __, __, self.playerQuadWidth, self.playerQuadHeight = self.playerQuad:getViewport()

    -- trailer sprite
    self.trailerQuad = love.graphics.newQuad(2, 41, 35, 7, imageWidth, imageHeight)
    __, __, self.trailerQuadWidth, self.trailerQuadHeight = self.trailerQuad:getViewport()

    -- derrick sprite
    self.derrickQuad = love.graphics.newQuad(2, 1, 35, 40, imageWidth, imageHeight)
    __, __, self.derrickQuadWidth, self.derrickQuadHeight = self.derrickQuad:getViewport()

    -- drill sprites
    self.drillImage = love.graphics.newImage("assets/drill.png")
    self.image:setFilter("nearest", "nearest")
    self.image:setWrap("clampzero", "clamp")
    local imageWidth, imageHeight = self.drillImage:getDimensions()
    self.drillShaftQuad = love.graphics.newQuad(6, 0, 3, 16, imageWidth, imageHeight)
    __, __, self.drillShaftQuadWidth, self.drillShaftQuadHeight = self.drillShaftQuad:getViewport()
    self.drillBitQuad = love.graphics.newQuad(20, 0, 7, 7, imageWidth, imageHeight)
    __, __, self.drillBitQuadWidth, self.drillBitQuadHeight = self.drillBitQuad:getViewport()
end

function player:update(dt)
    self.frameCounter = self.frameCounter + 1

    -- make 'ch'ching' noises
    if self.isPumping and love.math.random(25) == 1 then
        self:addScore(love.math.random() * 1000)
    end

    -- control inputs
    local retractDrill = (player.autoRetracting or love.keyboard.isDown("up") or love.keyboard.isDown("w"))
    local extendDrill = (love.keyboard.isDown("down") or love.keyboard.isDown("s"))
    local moveLeft = (love.keyboard.isDown("left") or love.keyboard.isDown("a"))
    local moveRight = (love.keyboard.isDown("right") or love.keyboard.isDown("d"))
    local spacePressed = love.keyboard.isDown("space")

    -- start drilling when the player presses down
    if extendDrill and math.abs(self.vel) < 30 and not self.isDrilling and not self.isPumping and not spacePressed then
        self.isDrilling = true
        self.vel = 0
    end

    if player.autoRetracting or (self.isDrilling and not self.isPumping and not spacePressed) then
        -- can only move the drill up and down while drilling, and not pumping
        if extendDrill and not retractDrill then
            self:extendDrill(dt)
        elseif not extend and retractDrill then
            self:retractDrill(dt)
        end
    elseif self.isDrilling and self.isPumping and not spacePressed then
        -- can't move or drill
        -- TODO: do pumping sounds or effects or whatever
    else
        -- can move and ping when not drilling or pumping
        local x = 0
        local newDirection = self.direction
        local directionChanged = false
        if moveLeft then
            x = -1
            newDirection = -1
        end
        if moveRight then
            x = 1
            newDirection = 1
        end
        if newDirection ~= self.direction then
            directionChanged = true
            self.direction = newDirection
        end

        -- move the player
        self.vel = self.vel + x * dt * 80
        self.x = (self.x + self.vel * dt) % world.WIDTH
        if moveLeft or moveRight then
            self.vel = self.vel * (1 - 0.2 * dt)
        else
            self.vel = self.vel * (1 - 5 * dt)
        end
        if (math.abs(self.vel) < 0.1) then
            self.vel = 0
        end

        -- offset a bit when changing direction so it looks less weird
        if directionChanged then
            self.x = (self.x + self.direction * self.playerQuadWidth * 0.5) % world.WIDTH
        end
    end

    -- set our height to the surface height
    local nx, ny
    self.y, nx, ny = terrain:worldSurface(self.x, 5)
    self.rot = lerp(self.rot, -math.atan2(nx, ny), 0.1)

    -- put the trailer behind us

    -- FIXME: lerping the trailer looks nicer, but right now has a bug when the trailer and player
    -- are on opposite sides of the wrapped edge of the world
    local lerpBugFixed = false
    if lerpBugFixed then
        -- lerp
        local newTrailerX = (self.x - self.direction * (1 + math.floor(self.playerQuadWidth / 2))) % world.WIDTH
        local limit = dt * 100
        self.trailerX = (self.trailerX + clamp(-limit, newTrailerX % world.WIDTH - self.trailerX, limit))
        self.trailerY = terrain:worldSurface(self.trailerX)
    else
        -- just flip, don't lerp
        self.trailerX = (self.x - self.direction * (1 + math.floor(self.playerQuadWidth / 2))) % world.WIDTH
    end
    self.trailerY, nx, ny = terrain:worldSurface(self.trailerX, 5)
    self.trailerRot = lerp(self.trailerRot, -math.atan2(nx, ny), 0.1)

    -- put the derrick on the trailer
    self.derrickX = (self.trailerX - self.direction * (self.trailerQuadWidth / 2) * math.cos(self.trailerRot)) % world.WIDTH
    self.derrickY = (self.trailerY - self.direction * (self.trailerQuadWidth / 2) * math.sin(self.trailerRot))

    -- put the drill in the trailer
    self.drillX = self.derrickX
    self.drillY = self.derrickY

    -- update player draw score
    self.drawScoreAccum = self.drawScoreAccum + dt
    local timestep = 1 / 35
    if self.drawScoreAccum > timestep then
        self.drawScoreAccum = self.drawScoreAccum - timestep
        local limit = 800000000
        self.drawScore = self.drawScore + clamp(-limit * dt, self.score - self.drawScore, limit * dt)
    end

    -- update particle systems
    self:updatePumpParticles(dt)
    self:updateRockParticles(dt)
end

function player:draw()
    love.graphics.setColor(255, 255, 255, 255)

    -- draw the fractor (three copies because of world wrapping)
    local xs = {self.x, self.x - world.WIDTH, self.x + world.WIDTH}
    for i=1,3 do
        love.graphics.draw(
            self.image,
            self.playerQuad,
            xs[i]      + love.math.random(-self.vel / 500, self.vel / 500),
            self.y + 4 + love.math.random(-0.1,  0.05),
            self.rot, -- rotation
            self.direction, 1, -- scale
            (self.playerQuadWidth / 2), self.playerQuadHeight)
    end

    -- draw the derrick (three copies because of world wrapping)
    local xs = {self.derrickX, self.derrickX - world.WIDTH, self.derrickX + world.WIDTH}
    local derrickY = self.derrickY
    if self.isDrilling then derrickY = derrickY + love.math.random(-0.3, 0.3) end
    for i=1,3 do
        love.graphics.draw(
            self.image,
            self.derrickQuad,
            xs[i] + love.math.random(-self.vel / 500, self.vel / 500),
            derrickY,
            0, -- rotation
            self.direction, 1, -- scale
            (self.derrickQuadWidth / 2), self.derrickQuadHeight)
    end

    -- draw the drill
    if self.isDrilling then
        -- make it look like the drill is rotating
        if self.frameCounter % 5 == 0 then
            if self.drillDirection == 1 then
                self.drillDirection = -1
            else
                self.drillDirection = 1
            end
        end
        love.graphics.draw(self.drillImage, self.drillShaftQuad, self.drillX, self.drillY,
            0, -- rotation
            self.drillDirection, self.drillDepth / self.drillShaftQuadHeight, -- scale
            (self.drillShaftQuadWidth / 2), 0)
        love.graphics.draw(self.drillImage, self.drillBitQuad, self.drillX, self.drillY + self.drillDepth,
            0, -- rotation
            self.drillDirection, 1, -- scale
            (self.drillBitQuadWidth / 2), (self.drillBitQuadHeight / 2))
    end

    -- draw the trailer (three copies because of world wrapping)
    local xs = {self.trailerX, self.trailerX - world.WIDTH, self.trailerX + world.WIDTH}
    for i=1,3 do
        love.graphics.draw(self.image, self.trailerQuad, xs[i], self.trailerY + 4,
            self.trailerRot, -- rotation
            self.direction, 1, -- scale
            self.trailerQuadWidth, self.trailerQuadHeight)
    end

    -- draw the particle systems
    self:drawPumpParticles()
    self:drawRockParticles()
end

function player:extendDrill(dt)
  
    soundStop("drill_up")
    soundEmit("drill_down")

    player.isDrilling = true

    local drillSpeed
    if player:canStartPumping() then
        drillSpeed = player.DRILL_EXTEND_SPEED_GAS
    else
        drillSpeed = player.DRILL_EXTEND_SPEED_DIRT
    end
    player.drillDepth = math.min(player.drillDepth + (drillSpeed * dt), player.DRILL_MAX_DEPTH)
end

function player:retractDrill(dt)
  
    
    soundStop("drill_down")
    soundEmit("drill_up")
  
    local drillSpeed
    if not autoRetracting and player:canStartPumping() then
        drillSpeed = player.DRILL_RETRACT_SPEED_GAS
    else
        drillSpeed = player.DRILL_RETRACT_SPEED_DIRT
    end
    player.drillDepth = math.max(0, player.drillDepth - (drillSpeed * dt))
    if player.drillDepth == 0 then
        player.isDrilling = false
        player.autoRetracting = false
    end
end

function player:canStartPumping()
    self.pumpX = self.drillX
    self.pumpY = self.drillY + self.drillDepth
    local _, _, _, a = terrain:worldSample(self.pumpX, self.pumpY)
    return (a == TERRAIN_GAS_ALPHA)
end

function player:startPumping()
  
    soundEmit("pumping")
    soundEmit("suck")

    -- resume pumping if we can
    if self.pumpProgress > 0 then
        local duration = self.pumpSize / self.PUMP_RATE * (1 - self.pumpProgress)
        print("resume pumping, size: "..dump(size).." duration: "..dump(duration))
    else
        -- floodfill to find the size of the deposit
        local tx, ty = world_to_terrain(self.pumpX, self.pumpY)
        local fill = terrain:floodfill(tx, ty, TERRAIN_GAS_ALPHA)
        local duration = fill.size / self.PUMP_RATE
        self.pumpSize = fill.size
        self.pumpScore = math.floor(self.GAS_PRICE * fill.size)
        self.pumpProgress = 0
        self.pumpBounds = {minX=fill.minX, minY=fill.minY, maxX=fill.maxX, maxY=fill.maxY}
        print("start pumping, size: "..dump(size).." duration: "..dump(duration))
    end
    self.isPumping = true
end

function player:cancelPumping()
    soundStop("suck")
    self.isPumping = false
    print("cancel pumping")
end

function player:addScore(value)
    self.score = self.score + value
    soundEmit("coin")
end

function player:addPumpParticles()
    -- find a free particle system (if any)
    local psys
    local maxParticleSystems = math.ceil(self.pumpProgress * self.pumpParticleSystemCount)
    for i=1,math.min(maxParticleSystems, #self.pumpParticleSystems) do
        local p = self.pumpParticleSystems[i]
        if p:getCount() == 0 then
            -- reuse it
            psys = p
            break
        end
    end
    if psys == nil then
        local count = #self.pumpParticleSystems
        if count <= maxParticleSystems then
            -- add a new particle system
            psys = self:createPumpParticleSystem()
            table.insert(self.pumpParticleSystems, psys)
        else
            -- too many particle systems; ignore
            return
        end
    end

    -- take a few tries to find a suitable point in the bounding rect that's gaseous
    -- I mean the point is gaseous, not the bounding rect
    -- that would just be ridiculous
    local centerTX = (self.pumpBounds.maxX + self.pumpBounds.minX) / 2
    local centerTY = (self.pumpBounds.maxY + self.pumpBounds.minY) / 2
    local rectTWidth = math.abs(self.pumpBounds.maxX - self.pumpBounds.minX)
    local rectTHeight = math.abs(self.pumpBounds.maxY - self.pumpBounds.minY)
    local pumpTX, pumpTY = world_to_terrain(self.pumpX, self.pumpY + 5)
    local x, y
    for i=1,5 do
        -- find a random point
        local tx, ty = randomScaledPointInRectWithOffset(centerTX, centerTY,
            rectTWidth, rectTHeight, self.pumpProgress, pumpTX, pumpTY)
        tx, ty = math.floor(tx), math.floor(ty)

        -- check if it's gas
        local _, _, _, a = terrain:sample(tx, ty)
        if a == TERRAIN_GAS_ALPHA then
            x, y = terrain_to_world(tx, ty)
            break
        end
    end
    if x ~= nil and y ~= nil then
        -- position the particle system
        psys:setPosition(x, y)
        -- set the speed
        local dx, dy = (self.pumpX - x), (self.pumpY - y)
        local length = math.sqrt(dx*dx + dy*dy)
        local ndx, ndy = dx / length, dy / length
        local speedMin, speedMax = 5, 10
        psys:setLinearAcceleration(dx * speedMin, dy * speedMin, dx * speedMax, dy * speedMax)
        -- emit some particles
        psys:emit(psys:getBufferSize())
    end
end

function player:createPumpParticleSystem()
    local particleCount = 10
    local psys = love.graphics.newParticleSystem(pumpParticleImage, particleCount)
    psys:setParticleLifetime(0.2, 0.5)
    psys:setColors(255, 255, 255, 255,  255, 255, 255, 128) -- Fade to transparency.
    return psys
end

function player:updatePumpParticles(dt)
    for i=1,#self.pumpParticleSystems do
        local p = self.pumpParticleSystems[i]
        p:update(dt)
    end
end

function player:drawPumpParticles()
    for i=1,#self.pumpParticleSystems do
        local p = self.pumpParticleSystems[i]
        love.graphics.draw(p, 0, 0)
    end
end

function player:addRockParticles()
    if self.rockParticleSystem:getCount() == 0 then
        self.rockParticleSystem:setPosition(self.pumpX, self.pumpY)
        self.rockParticleSystem:emit(self.rockParticleSystem:getBufferSize())
    end
end

function player:createRockParticleSystem()
    local particleCount = 10
    local psys = love.graphics.newParticleSystem(rockParticleImage, particleCount)
    psys:setParticleLifetime(0.5, 1.5)
    psys:setColors(255, 255, 255, 255,  255, 255, 255, 128) -- Fade to transparency.
    psys:setLinearAcceleration(-15, -15, 15, 15)
    return psys
end

function player:updateRockParticles(dt)
    self.rockParticleSystem:update(dt)
end

function player:drawRockParticles()
    love.graphics.draw(self.rockParticleSystem, 0, 0)
end

function player:finishPumping()
    soundStop("suck")
    local tx, ty = world_to_terrain(self.pumpX, self.pumpY)
    local fill = terrain:floodfill(tx, ty, TERRAIN_VOID_ALPHA)
    self:addScore(self.pumpScore)
    self.isPumping = false
    self.pumpProgress = 0
    self.autoRetracting = true

    terrain:startCollapse(tx, fill.minX, fill.maxX, fill.minY, fill.maxY)

    local msg = "Income"
    messages:spawn("", {255,255,255,0})
    messages:spawn("$"..toCurrency(math.floor(self.pumpScore))..": "..msg, {0, 255, 0, 255})

    print("finish pumping")
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- HOUSE

houses = {}

houseData = {
    REQUIRED = 20,
    COUNT = 8,
    prefab = {
        0, 0, 32, 48,
        32, 0, 32, 32,
        64, 0, 32, 32,
        96, 0, 32, 32,
        64, 32, 32, 16,
        96, 32, 32, 16,
        64, 64, 32, 32,
        0, 48, 16, 16
    }
}

function createHouse()
    local house = {}

    function house:spawn()
        house.x = love.math.random(0, world.WIDTH)
        local pick = math.floor(love.math.random(houseData.COUNT) - 1) * 4
        house.width = houseData.prefab[pick + 3]
        house.height = houseData.prefab[pick + 4]
        assert (houseSheet)
        house.quad = love.graphics.newQuad(
            houseData.prefab[pick + 1],
            houseData.prefab[pick + 2],
            houseData.prefab[pick + 3],
            houseData.prefab[pick + 4],
            128,
            64)
        assert (house.quad)
    end

    function house:update()
    end

    function house:draw()
        local y, nx, ny = terrain:worldSurface(self.x, 2)
        local angle =-math.atan2(nx, ny)
        assert (house.quad)
        assert (houseSheet)
        love.graphics.setCanvas(intermediateCanvas)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(
          houseSheet, 
          house.quad, 
          house.x,                -- xpos
          y + 3,   -- ypos
          angle,                  -- angle
          1, 1,                   -- scale
          house.width /2 , house.height
          
          )
        love.graphics.setCanvas()
    end

    house.spawn()
    return house
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- PEOPLE

deathMessages = {
    "Manslaughter",
    "Reckless driving",
    "Vehicular manslaughter",
    "Loss of life and/or limb",
    "Reckless endagerment",
    "Settled out of court",
    "Statutory fine",
    "Obstruction of justice",
}

people = {
    COUNT = 40,
    DEATH_TIME = 3, -- seconds
}

function createPerson()
    local person = {}

    function person:init()
        self.x = love.math.random(0, world.WIDTH)
        self.alive = true
        self.dying = false
        self.deadTime = 0
        self.deadX = 0
        self.target = self.x
        self.anger = love.math.random(0, 1)
        self.accumulator = 0
        self.quad = love.graphics.newQuad(love.math.random(0, 3) * 16,
                                            love.math.random(0, 3) * 16,
                                            16, 16, 64, 64)
        -- blood particles
        self.bloodParticleCount = 64
        self.bloodParticles = love.graphics.newParticleSystem(bloodParticleImage, self.bloodParticleCount)
        self.bloodParticles:setParticleLifetime(0.25, 1.0)
        self.bloodParticles:setColors(255, 255, 255, 255,  255, 255, 255, 128) -- Fade to transparency.
        self.bloodParticles:setPosition(0, -6)
    end

    function person:kill(velX)
        self.dying = true
        self.deadTime = love.timer.getTime() + people.DEATH_TIME
        self.deadX = self.x + 15 * velX
        person.bloodParticles:setLinearAcceleration(-(5 * velX), -10, (5 * velX), 50) -- Randomized movement towards the bottom of the screen.
        self.bloodParticles:emit(self.bloodParticleCount)
    end

    function person:respawn()
        self:init()
    end

    function person:update(dt)
        if self.dying then
            -- get y coord and normal, move towards deadX
            -- local y, nx, ny = terrain:worldSurface(self.x)
            -- local limit = dt * ny * ny
            -- self.x = (self.x + clamp(-limit, self.deadX - self.x, limit)) % world.WIDTH
            self.x = lerp(self.x, self.deadX, dt)

            if love.timer.getTime() > self.deadTime then
                self.alive = false
            end
            self.bloodParticles:update(dt)
        else
            -- run away
            local diff = player.x - self.x
            if math.abs(diff) < 22 and (math.abs(player.vel) - math.abs(diff)) > 0 then
                if self.alive then
                    soundEmit("splat", 0.5 + love.math.random(), 0.5 + love.math.random())
                    self:kill(-diff)
                    player.score = player.score - player.LAWYER_PRICE

                    local msg = deathMessages[math.random(#deathMessages)]
                    messages:spawn("", {255,255,255,0})
                    messages:spawn("$-"..toCurrency(player.LAWYER_PRICE)..": "..msg, {255, 0, 0, 255})
                end
            elseif math.abs(diff) < 30 then
                self.target = player.x - diff * 5
            end
            -- new target
            if love.math.random() < (0.5 * dt) then
                self.target = love.math.random(0, world.WIDTH)
                if math.abs(self.target - player.x) > 250 then
                    self.target = self.target + (player.x - self.target) * love.math.random(0, 0.35)
                elseif math.abs(self.target - player.x) > 150 then
                    self.target = self.target + (player.x - self.target) * love.math.random(0.25, 0.85)
                else
                    self.target = self.target + (player.x - self.target) * love.math.random(0.45, 0.95)
                end
            end

            -- get y coord and normal
            local y, nx, ny = terrain:worldSurface(self.x)

            -- scale speed by y component of normal
            local limit = dt * lerp(100, 150, self.anger) * ny * ny
            self.x = (self.x + clamp(-limit, self.target - self.x, limit)) % world.WIDTH

            if math.abs(self.target - self.x) < 2 then
                self.accumulator = 0
            else
                self.accumulator = (self.accumulator + dt) % lerp(0.2, 0.1, self.anger)
            end
        end
    end
    function person:draw()
        local dir = 1
        if person.target - person.x > 0 then dir = -1 end

        local y, nx, ny = terrain:worldSurface(self.x)
        if self.accumulator > lerp(0.125, 0.0625, self.anger) then
            y = y - lerp(4, 1.5, self.anger)
        end

        local angle = math.atan2(nx, ny) * 0.4

        love.graphics.setCanvas(intermediateCanvas)
        love.graphics.setColor(255, 255, 255, 255)

        if self.dying then
            if dir > 0 then
                angle = -math.pi / 2
            else
                angle = math.pi / 2
            end
            love.graphics.draw(protestorSheet, self.quad, self.x, y, angle, 1, 1, 8, 12)
            love.graphics.draw(self.bloodParticles, self.x, y)
        else
            love.graphics.draw(protestorSheet, self.quad, self.x, y, -angle, dir, 1, 8, 12)
        end

        love.graphics.setCanvas()
    end
    person:init()
    return person
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- HUD MESSAGE

MESSAGE_DURATION = 4.0
MESSAGE_DECELERATION = 5
MESSAGE_FLOAT_SPEED = 50
MESSAGE_FLOAT_VARIATION = 10
MESSAGE_DRIFT_SPEED = 10
messages = {}

function messages:load()
    self.fontSize = 24 
    self.font = love.graphics.newFont("assets/nullp.ttf", self.fontSize)
end

function messages:spawn(text, color)
    local message = {}
    message.duration = MESSAGE_DURATION;
    message.endTime = love.timer.getTime() + message.duration
    message.text = text
    message.x = screen.WIDTH / 2
    message.y = screen.HEIGHT + #messages * self.fontSize / 4
    message.dx = (love.math.random() - 0.5) * 2 * MESSAGE_DRIFT_SPEED
    message.dy = -MESSAGE_FLOAT_SPEED - (love.math.random() * MESSAGE_FLOAT_VARIATION)
    message.color = color
    message.shadowColor = {255, 255, 255, 192}

    function message:update(dt)
        local ax, ay = MESSAGE_DECELERATION, MESSAGE_DECELERATION
        if self.dx > 0 then ax = -ax end
        if self.dy > 0 then ay = -ay end
        self.x = self.x + self.dx * dt
        self.y = self.y + self.dy * dt
        self.dx = self.dx + ax * dt
        self.dy = self.dy + ay * dt

        local remaining = (self.endTime - love.timer.getTime())
        if remaining > 0 then
            local alpha = remaining / self.duration
            self.color[4] = 255 * alpha
            self.shadowColor[4] = 192 * alpha
        end
    end

    function message:draw()
        printCenteredShadowedText(self.text, self.x, self.y, self.color, self.shadowColor)
    end

    table.insert(messages, #messages, message)
end

function messages:update(dt)
    for i=#messages,1,-1 do
        -- if the message is finished, remove it
        local m = messages[i]
        if love.timer.getTime() > m.endTime then
            table.remove(messages, i)
        else
            m:update(dt)
        end
    end
end

function messages:draw()
    love.graphics.setFont(self.font)
    for i=1,#messages do
        local m = messages[i]
        m:draw()
    end
end

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
--
-- DEBUG

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
