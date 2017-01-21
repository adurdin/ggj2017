sonarVars = {}

function love.load()
    -- When the game starts:
    -- load an image
    educational_image = love.graphics.newImage("assets/education.jpg")
    level_image = love.graphics.newImage("assets/level.jpg")
    densityMap = love.graphics.newImage("assets/density.jpg")
    
    sonarShader = love.graphics.newShader("assets/sonarShader.fs")

    -- load some fonts
    debugFont = love.graphics.newFont(16)

    -- set background colour
    love.graphics.setBackgroundColor(255,255,255)
    
    sonarVars.sourcePosition = {0.0, 0.0}
    sonarVars.radius = 0.5
    sonarVars.maxTime = sonarVars.radius * 10.0
    sonarVars.currentTime = 0.0

    -- set some default values
    showFPSCounter = true

    -- create a raster terrain
    createTerrain(terrain)

    -- create player
    player:create()
end

function love.update(dt)
    if love.mouse.isDown(1) then
        screenWidth = love.graphics.getWidth()
        screenHeight = love.graphics.getHeight()
        sonarVars.sourcePosition = {(love.mouse.getX() / screenWidth), (love.mouse.getY() / screenHeight)}
        sonarVars.currentTime = sonarVars.maxTime;
    end
    
    sonarVars.currentTime = sonarVars.currentTime - dt
    if sonarVars.currentTime < 0.0 then
        sonarVars.currentTime = 0.0
    end
  
    -- Every frame:
    hotReload()

    if love.keyboard.isDown("space") then
        -- Print to console
        print("Your are pressing space")
    end

    local x = 0
    if love.keyboard.isDown("a") then x = -1 end
    if love.keyboard.isDown("d") then x =  1 end
    player.vel = player.vel + x * dt * 5000
    player.x = player.x + player.vel * dt
    player.vel = player.vel * (1 - 0.01 * dt * 1000)

    -- update terrain
    terrain:update(dt)
end

function love.keypressed(key, unicode)
    -- Quit on escape
    if key == "escape" then
        love.event.quit()
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
    love.graphics.setShader(sonarShader)
    -- Every frame:
    -- show an educational image
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(level_image, 0, 0)

    love.graphics.setShader()

    -- render terrain
    terrain:draw(0, 0)

    -- render player
    player:draw()

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

-- Hot reload

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

-- Raster terrain

TERRAIN_WIDTH = 1024
TERRAIN_HEIGHT = 160

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

terrain = {}

function generateTerrainPixel(x, y, r, g, b, a, debug)
    local noise = love.math.noise(x / terrain.width * 16, y / terrain.height * 16, 0.1) * 2
    local isDirt = (noise > 0.75)
    -- rgb channels can be used for color data
    -- alpha channel is terrain data and should not be rendered
    if y < 5 then
      return 5, 162, 9, TERRAIN_DIRT_ALPHA_MIN
    elseif isDirt then
        return 123, 69, 23, TERRAIN_DIRT_ALPHA_MIN
    else
        if debug then
            return 0, 0, 0, TERRAIN_GAS_ALPHA
        else
            return 123, 69, 23, TERRAIN_GAS_ALPHA
        end
    end
end

function shockwaveForce(centerX, centerY, intensity, halfIntensityDistance, x, y)
    -- exponential falloff: return the value of the force at (`x`, `y`), given the
    -- force is `intensity` at its center, and half as strong at `halfIntensityDistance`.
    local distance = math.sqrt(math.pow((x - centerX), 2) + math.pow((y - centerY), 2))
    local exponent = distance * 0.6931471805599453 / halfIntensityDistance
    return intensity * math.exp(-exponent)
end

-- function renderShockwave(x, y, r, g, b, a)
--     local intensity = 1000
--     local force = shockwaveForce(300, 100, intensity, 50, x, y)
--     return r, g, b, math.min(255, force / intensity * 255)
-- end

function createTerrain(terrain)
    terrain.width = TERRAIN_WIDTH
    terrain.height = TERRAIN_HEIGHT
    terrain.data = love.image.newImageData(terrain.width, terrain.height)

    -- create a terrain and copy it into the second data buffer
    terrain.data:mapPixel(generateTerrainPixel)
    terrain.image = love.graphics.newImage(terrain.data)

    -- surface is the y coordinate of the topmost piece of dirt in the terrain
    -- FIXME: this should sample the initial data, but for the moment it's just flat
    terrain.surface = {}
    for x=0,(terrain.width-1) do
        terrain.surface[x] = 0
    end

    -- an awake column is one where pixels might fall on an update
    -- for now, start with all columns awake
    -- we'll later only wake them with a shockwave
    terrain.awakeColumns={}
    for x=0,(terrain.width-1) do
        terrain.awakeColumns[x] = false
    end
    -- start with one column awake
    terrain.awakeColumns[math.floor(terrain.width / 2)] = true

    return terrain
end

function terrain:update(dt)
    -- collapse a single column of terrain
    function collapseColumn(x, dt)
        -- start at the bottom of the column.
        -- move pixels down according to their velocity.
        -- update their velocity (if not 0) by dt.
        -- they collide if they would exceed maxY;
        -- if they collide, their velocity is capped to maxVelocity.
        -- after each pixel is moved, maxVelocity becomes its velocity,
        -- and maxY becomes its y - 1
        local maxVelocity = 0 -- at the bottom of the terrain, all motion must stop
        local maxY = self.height - 1 -- and pixels can't fall past the bottom of the terrain

        local readY = self.height - 1
        local writeY = self.height - 1

        local stayAwake = false

        while readY >= 0 or writeY >= 0 do
            local r, g, b, a
            if readY >= 0 then
                r, g, b, a = terrain.data:getPixel(x, readY)

                if a >= TERRAIN_DIRT_ALPHA_MIN and a <= TERRAIN_DIRT_ALPHA_MAX then
                    local velocity = a * TERRAIN_ALPHA_TO_VELOCITY
                    if velocity == 0 then
                        -- this pixel isn't going to fall
                        -- but pixels above will stop if they hit this one
                        maxVelocity = 0
                        writeY = writeY - 1
                    else
                        -- something is falling
                        stayAwake = true

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
                            terrain.data:setPixel(x, y, 0, 0, 0, TERRAIN_VOID_ALPHA)
                        end

                        -- and move the pixel
                        local newA = math.floor(newVelocity / TERRAIN_ALPHA_TO_VELOCITY)
                        terrain.data:setPixel(x, newY, r, g, b, newA)

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
                terrain.data:setPixel(x, writeY, 0, 140, 254, TERRAIN_SKY_ALPHA)
                writeY = writeY - 1
            end
        end

        return stayAwake
    end

    -- collapse each awake column
    local newAwakeColumns = {}
    for x=0,(self.width-1) do
        newAwakeColumns[x] = false
    end
    for x=0,(self.width-1) do
        if self.awakeColumns[x] then
            -- collapse this column
            newAwakeColumns[x] = collapseColumn(x, dt)
            -- wake up the columns beside it
            if x > 0 then
                newAwakeColumns[x - 1] = true
            end
            if x < self.width then
                newAwakeColumns[x + 1] = true
            end
        end
    end
    self.awakeColumns = newAwakeColumns

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

player = {}

function player:create()
    self.x = 0
    self.vel = 0
end

function player:draw()
    local y = terrain.surface[math.floor(self.x + 25) % TERRAIN_WIDTH] - 50 + 200
    love.graphics.setColor(255, 140, 0, 255)
    love.graphics.rectangle("fill", self.x % TERRAIN_WIDTH - TERRAIN_WIDTH, y, 50, 50, 0)
    love.graphics.rectangle("fill", self.x % TERRAIN_WIDTH, y, 50, 50, 0)
end

-- Debug

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
