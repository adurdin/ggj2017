sonarVars = {}

function love.load()
    -- When the game starts:
    -- load an image
    educational_image = love.graphics.newImage("assets/education.jpg")
    level_image = love.graphics.newImage("assets/level.jpg")
    densityMap = love.graphics.newImage("assets/density.jpg")

    sonarShader = love.graphics.newShader("assets/sonarShader.fs")

    -- set background colour
    love.graphics.setBackgroundColor(255,255,255)
    
    sonarVars.sourcePosition = {0.0, 0.0}
    sonarVars.radius = 0.5
    sonarVars.maxTime = sonarVars.radius * 10.0
    sonarVars.currentTime = 0.0
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
end

function love.keypressed(key, unicode)
    -- Quit on escape
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
  
    sonarShader:send("sourcePosition", sonarVars.sourcePosition)
    sonarShader:send("radius", sonarVars.radius)
    sonarShader:send("maxTime", sonarVars.maxTime)
    sonarShader:send("currentTime", sonarVars.currentTime)
    sonarShader:send("densityMap", densityMap)
    love.graphics.setShader(sonarShader)
    -- Every frame:
    -- show an educational image
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(level_image, 0, 0)
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
                print("Load error: "..err)
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
