function love.load()
    -- When the game starts:
    -- load an image
    educational_image = love.graphics.newImage("assets/education.jpg")

    -- set background colour
    love.graphics.setBackgroundColor(255,255,255)
end

function love.update(dt)
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
    -- Every frame:
    -- show an educational image
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(educational_image, 0, 0)
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
