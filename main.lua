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

    -- update terrain
    terrain:update()
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
    sonarShader:send("densityMap", terrain.readImage)
    love.graphics.setShader(sonarShader)
    -- Every frame:
    -- show an educational image
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(level_image, 0, 0)

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
TERRAIN_SKY_ALPHA = 129

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
    terrain.readData = love.image.newImageData(terrain.width, terrain.height)
    terrain.writeData = love.image.newImageData(terrain.width, terrain.height)

    -- create a terrain and copy it into the second data buffer
    terrain.readData:mapPixel(generateTerrainPixel)
    terrain.writeData:paste(terrain.readData, 0, 0, 0, 0, terrain.width, terrain.height)
    terrain.readImage = love.graphics.newImage(terrain.readData)
    terrain.writeImage = love.graphics.newImage(terrain.writeData)

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
        terrain.awakeColumns[x] = true
    end
    return terrain
end

function terrain:update()
    -- FIXME(andy): simulate the terrain here!

    -- refresh the terrain image from its data
    terrain.writeImage:refresh()

    -- swap the read and write buffers
    local t = terrain.readData; terrain.readData = terrain.writeData; terrain.writeData = t;
    local t = terrain.readImage; terrain.readImage = terrain.writeImage; terrain.writeImage = t;
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
    love.graphics.draw(terrain.readImage, 0, 0)

    -- restore state
    love.graphics.setBlendMode(unpack(prevBlendMode))
    love.graphics.setColor(unpack(prevColor))
    love.graphics.setColorMask(unpack(prevColorMask))
end
