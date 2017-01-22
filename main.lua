sonarVars = {}
debugVars = {}

terrain = {
    WIDTH = 1024,
    HEIGHT = 160
}

world = {
    WIDTH = 1440,
    HEIGHT = 500,
    TERRAIN_Y = 200,
    TERRAIN_SIZE = 200
}

screen = {
  WIDTH = 800,
  HEIGHT = 600
}

-- minimum scale fills the height of the screen
MINIMUM_CAMERA_SCALE = (screen.HEIGHT / world.HEIGHT)

camera = {
    positionX = 0.0, -- world space coordinate that is top left of camera
    positionY = 0.0,
    scale = MINIMUM_CAMERA_SCALE -- 1.0 is 1 to 1 pixels, 2.0 is double size pixels
}

frameCounter = 0

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

function clamp(min, val, max)
    return math.max(min, math.min(val, max))
end

function lerp(v1, v2, t)
    return v1 + (v2 - v1) * t
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
    return
        (x * (terrain.WIDTH / world.WIDTH)),
        ((y - world.TERRAIN_Y) * (terrain.HEIGHT / world.HEIGHT))
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
-- LOVE CALLBACKS

function love.load()
    -- enable debugging if required
--    if arg[#arg] == "-debug" then require("mobdebug").start() end

    -- set up the window
    love.window.setMode(screen.WIDTH, screen.HEIGHT)

    -- When the game starts:
    -- load an image
    educational_image = love.graphics.newImage("assets/education.jpg")
    singelPixelImage = love.graphics.newImage("assets/singlePixelImage.jpg")

    protestorSheet = love.graphics.newImage("assets/protestors.png")
    
    houseSheet = love.graphics.newImage("assets/houses.png")
    houseSheet:setFilter("nearest", "nearest")
    houseSheet:setWrap("clampzero", "clamp")

    sonarShader = love.graphics.newShader("assets/sonarShader.fs")
    drawShader = love.graphics.newShader("assets/drawShader.fs")

    intermediateCanvas = love.graphics.newCanvas(world.WIDTH, world.HEIGHT)
    intermediateCanvas:setWrap("repeat", "clamp")
    intermediateCanvas:setFilter("nearest", "nearest")

    -- load some fonts
    debugFont = love.graphics.newFont(16)

    -- set background colour
    love.graphics.setBackgroundColor(255,255,255)

    sonarVars.sourcePosition = {0.0, 0.0}
    sonarVars.radius = 0.5
    sonarVars.maxTime = sonarVars.radius * 10.0
    sonarVars.currentTime = 0.0

    debugVars.debugModeEnabled = false

    -- set some default values
    showFPSCounter = true

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
end

function love.update(dt)

    sonar:update(dt)

    -- Every frame:
    hotReload()

    if love.keyboard.isDown("o") then
        -- wake the central column on space.
        terrain:wakeColumn(math.floor(terrain.width / 2))
    end

    -- update terrain
    terrain:update(dt)

    -- update player
    player:update(dt)

    -- update people
    for x=0,(people.COUNT-1) do
        people[x]:update(dt)
    end
    
    if houses then
        for key, value in pairs(houses) do
            value:update()
        end
    end
end

function love.keypressed(key, unicode)
    -- Quit on escape
    if key == "escape" then
        love.event.quit()
    end

    if love.keyboard.isDown("p") then
        if debugVars.debugModeEnabled == false then
            debugVars.debugModeEnabled = true
        else
            debugVars.debugModeEnabled = false
        end
    end

    if love.keyboard.isDown("space") and not player.isDrilling then
        screenWidth = love.graphics.getWidth()
        screenHeight = love.graphics.getHeight()
        sonarVars.sourcePosition = {(player.x / world.WIDTH), (player.y / world.HEIGHT)}
        sonarVars.currentTime = sonarVars.maxTime;
    end

    -- toggle FPS counter on ctrl+f
    if key == "f" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        showFPSCounter = not showFPSCounter
    end
end

function love.draw()

    -- render terrain to a canvas
    -- love.graphics.setCanvas(terrainDataConavs)
    -- terrain:draw(0, 0, true)
    -- love.graphics.setCanvas()

    sonarShader:send("sourcePosition", sonarVars.sourcePosition)
    sonarShader:send("radius", sonarVars.radius)
    sonarShader:send("maxTime", sonarVars.maxTime)
    sonarShader:send("currentTime", sonarVars.currentTime)
    sonarShader:send("densityMap", terrain.image)
    sonarShader:send("WORLD_WIDTH", world.WIDTH)
    sonarShader:send("WORLD_HEIGHT", world.HEIGHT)
    sonarShader:send("WORLD_TERRAIN_Y", world.TERRAIN_Y)
    sonarShader:send("WORLD_TERRAIN_SIZE", world.TERRAIN_SIZE)
    sonarShader:send("debugModeEnabled", debugVars.debugModeEnabled)

    love.graphics.setShader(sonarShader)
    love.graphics.setCanvas(intermediateCanvas)
    -- Every frame:
    -- show an educational image
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(singelPixelImage, 0, 0, 0, world.WIDTH, world.HEIGHT)

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
    
    -- final draw
    
    -- draw people folk
    for x=0,(people.COUNT-1) do
        people[x]:draw()
    end
    
    local fullScreenCorrection = (screen.HEIGHT / world.HEIGHT)
    
    drawShader:send("cameraPosition", {camera.positionX / world.WIDTH, camera.positionY / world.HEIGHT})
    drawShader:send("cameraScale", camera.scale / fullScreenCorrection)
    love.graphics.setShader(drawShader)
    love.graphics.draw(intermediateCanvas, 0, 0, 0, fullScreenCorrection, fullScreenCorrection)
    love.graphics.setShader()
    
    -- show the fps counter
    if showFPSCounter then
        love.graphics.setFont(debugFont)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle("fill", 0, 0, 70, 20)
        love.graphics.setColor(255, 255, 0, 255)
        love.graphics.print("FPS: "..tostring(love.timer.getFPS()), 0, 0)
    end

    love.graphics.setColor(0,0,0,255)
    love.graphics.print("FRACK THE PLANET!", 300, 10)
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
    local noise = love.math.noise(x / terrain.width * 16, y / terrain.height * 16, 0.1) * 2
    local isDirt = (noise > 0.75)
    -- rgb channels can be used for color data
    -- alpha channel is terrain data and should not be rendered
    if y < 5 then
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

    -- create a terrain and copy it into the second data buffer
    self.data:mapPixel(generateTerrainPixel)
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
    for x=0,(self.width-1) do
        if oldAwakeColumns[x] then
            -- collapse this column
            local stayAwake = self:collapseColumn(x, dt)
            self.awakeColumns[x] = stayAwake

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
                        -- print("collided at: "..dump(newY).." newY: "..dump(newY).." newVelocity: "..dump(newVelocity))
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
            else
                -- FIXME: later we want to keep track of the size of the void below each pixel maybe,
                -- so we can look it up without scanning the data again
                -- but for now do nothing
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

    sonarVars.currentTime = sonarVars.currentTime - dt
    if sonarVars.currentTime < 0.0 then
        sonarVars.currentTime = 0.0
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
    DRILL_MAX_DEPTH = 256,
    DRILL_EXTEND_SPEED = 64, -- frackulons/second
    DRILL_RETRACT_SPEED = 128, -- frackulons/second
}

function player:create()
    self.x, self.y = terrain_to_world(0, 0)
    self.vel = 0
    self.direction = 1 -- facing right
    self.rot = 0
    self.trailerRot = 0

    -- drilling
    self.isDrilling = false
    self.drillDepth = 0
    self.drillDirection = 1

    -- sprites
    self.image = love.graphics.newImage("assets/fractor.png")
    self.image:setFilter("nearest", "nearest")
    self.image:setWrap("clampzero", "clampzero")
    local imageWidth, imageHeight = self.image:getDimensions()
    self.playerQuad = love.graphics.newQuad(
        41, 1, -- subimage x, y
        54, 47, -- subimage width, height
        imageWidth, imageHeight) -- image width, height
    __, __, self.playerQuadWidth, self.playerQuadHeight = self.playerQuad:getViewport()

    self.trailerQuad = love.graphics.newQuad(2, 1, 35, 47, imageWidth, imageHeight)
    __, __, self.trailerQuadWidth, self.trailerQuadHeight = self.trailerQuad:getViewport()

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
    frameCounter = frameCounter + 1

    -- control inputs
    local retractDrill = (love.keyboard.isDown("up") or love.keyboard.isDown("w"))
    local extendDrill = (love.keyboard.isDown("down") or love.keyboard.isDown("s"))
    local moveLeft = (love.keyboard.isDown("left") or love.keyboard.isDown("a"))
    local moveRight = (love.keyboard.isDown("right") or love.keyboard.isDown("d"))

    -- start drilling when the player presses down
    if extendDrill and self.vel == 0 and not self.isDrilling then
        self.isDrilling = true
        self.vel = 0
    end

    if self.isDrilling then
        -- can only move the drill up and down while drilling
        if extendDrill and not retractDrill then
            self:extendDrill(dt)
        elseif not extend and retractDrill then
            self:retractDrill(dt)
        end
    else
        -- can move and ping when not drilling
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
        self.vel = self.vel + x * dt * 1000
        self.x = (self.x + self.vel * dt) % world.WIDTH
        self.vel = self.vel * (1 - 10 * dt)
        if (math.abs(self.vel) < 0.05) then
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
    self.trailerX = (self.x - self.direction * (1 + math.floor(self.playerQuadWidth / 2))) % world.WIDTH
    self.trailerY, nx, ny = terrain:worldSurface(self.trailerX, 5)
    self.trailerRot = lerp(self.trailerRot, -math.atan2(nx, ny), 0.1)

    -- put the drill in the trailer
    self.drillX = (self.trailerX - self.direction * math.floor(self.trailerQuadWidth / 2)) % world.WIDTH
    self.drillY = terrain:worldSurface(self.drillX)
end

function player:draw()
    love.graphics.setColor(255, 255, 255, 255)

    -- draw the fractor (three copies because of world wrapping)
    local xs = {self.x, self.x - world.WIDTH, self.x + world.WIDTH}
    for i=1,3 do
        love.graphics.draw(self.image, self.playerQuad, xs[i], self.y,
            self.rot, -- rotation
            self.direction, 1, -- scale
            (self.playerQuadWidth / 2), self.playerQuadHeight)
    end

    -- draw the trailer (three copies because of world wrapping)
    local xs = {self.trailerX, self.trailerX - world.WIDTH, self.trailerX + world.WIDTH}
    for i=1,3 do
        love.graphics.draw(self.image, self.trailerQuad, xs[i], self.trailerY,
            self.trailerRot, -- rotation
            self.direction, 1, -- scale
            self.trailerQuadWidth, self.trailerQuadHeight) -- fixme: offset is wrong
    end

    -- draw the drill

    if self.drillDepth > 0 then
        if frameCounter % 5 == 0 then
            if self.drillDirection == 1 then
                self.drillDirection = -1
            else
                self.drillDirection = 1
            end
        end
        love.graphics.draw(self.drillImage, self.drillShaftQuad, self.drillX, self.drillY,
            self.trailerRot, -- rotation
            self.drillDirection, self.drillDepth / self.drillShaftQuadHeight, -- scale
            (self.drillShaftQuadWidth / 2), 0)
        love.graphics.draw(self.drillImage, self.drillBitQuad, self.drillX, self.drillY + self.drillDepth,
            0, -- rotation
            self.drillDirection, 1, -- scale
            (self.drillBitQuadWidth / 2), 0)
    end
end

function player:extendDrill(dt)
    player.isDrilling = true
    player.drillDepth = math.min(player.drillDepth + (player.DRILL_EXTEND_SPEED * dt), player.DRILL_MAX_DEPTH)
end

function player:retractDrill(dt)
    player.drillDepth = math.max(0, player.drillDepth - (player.DRILL_RETRACT_SPEED * dt))
    if player.drillDepth == 0 then
        player.isDrilling = false
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
-- HOUSE

houses = {}

houseData = {
    REQUIRED = 64,
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
        local pick = math.floor(love.math.random(houseData.COUNT-1) * 4)
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

people = {
    COUNT = 20
}

function createPerson()
    local person = {}
    person.x = love.math.random(0, world.WIDTH)
    person.target = person.x
    person.anger = love.math.random(0, 1)
    person.accumulator = 0
    person.quad = love.graphics.newQuad(love.math.random(0, 3) * 16,
                                        love.math.random(0, 3) * 16,
                                        16, 16, 64, 64)

    function person:update(dt)
        -- run away
        local diff = player.x - self.x
        if math.abs(diff) < 30 then
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
        love.graphics.draw(protestorSheet, self.quad, self.x, y, -angle, dir, 1, 8, 12)
        love.graphics.setCanvas()
    end
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
