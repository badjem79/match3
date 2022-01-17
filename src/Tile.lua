--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety, explosive)
    
    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety

    self.colorTimer = null

    self.rotation = 0

    if explosive then
        self:startShine()
    end

    self.shinyColors = {
        [1] = {174/255, 187/255, 1, 1},
        [2] = {146/255, 178/255, 1, 1},
        [3] = {138/255, 211/255, 1, 1},
        [4] = {182/255, 1, 253/255, 1},
        [5] = {113/255, 1, 241/255, 1}
    }

end
function Tile:startShine()
    if self.colorTimer == null then
        self.explosive = true
        self.colorTimer = Timer.every(0.075, function()
            
            self.shinyColors[0] = self.shinyColors[5]

            for i = 5, 1, -1 do
                self.shinyColors[i] = self.shinyColors[i - 1]
            end
        end)
    end
end
function Tile:stopShine()
    if self.colorTimer then
        self.colorTimer:remove()
        self.colorTimer = null
    end
end
function Tile:render(x, y)
    
    -- draw shadow
    love.graphics.setColor(34/255, 32/255, 52/255, 1)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(1, 1, 1, 1)
    if self.explosive then
        love.graphics.setColor(self.shinyColors[1])
    end
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 16, self.y + y + 16, math.rad(self.rotation), 1 , 1, 16, 16)
    love.graphics.setColor(1, 1, 1, 1)

end