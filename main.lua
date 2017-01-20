function love.load()
    -- When the game starts:
    -- load an image
    educational_image = love.graphics.newImage("assets/education.jpg")

    -- set background colour
    love.graphics.setBackgroundColor(255,255,255)
end

function love.update(dt)
    -- Every frame:
    if love.keyboard.isDown("space") then
        -- Print to console
        print("Your are pressing space")
    end
end

function love.draw()
    -- Every frame:
    -- show an educational image
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(educational_image, 0, 0)
    love.graphics.setColor(0,0,0,255)
    love.graphics.print("FRACK THE PLANET", 300, 10)
end
