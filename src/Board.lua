--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.level = level
    self.matches = {}

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    self.baseColors = {}

    local onlyColor = (MIN_NUM_TILES_TYPES + self.level) <= 18 -- only different colors (when level <= 18)

    for i = 1, MIN_NUM_TILES_TYPES + self.level do
        local newColor = {
            color = math.random(18),
            variety = math.min(math.random(1, self.level), 6)
        }
        while self:contains(newColor, onlyColor) do
            newColor = {
                color = math.random(18),
                variety = math.min(math.random(1, self.level), 6)
            }
        end
        table.insert(self.baseColors, newColor);
    end

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            local baseColor = self.baseColors[math.random(#self.baseColors)]
            -- create a new tile at X,Y with a random color and variety
            table.insert(self.tiles[tileY], Tile(tileX, tileY, baseColor.color, baseColor.variety))
        end
    end

    local m = self:calculateMatches()
    if m then
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    elseif m == false then
        self:possibleMoves()
    end
end

function Board:contains(baseColor, onlyColor)
    for i=1, #self.baseColors do
       if (self.baseColors.color == baseColor.color and onlyColor) or (self.baseColors.color == baseColor.color and self.baseColors.variety == baseColor.variety) then 
          return true
       end
    end
    return false
 end

 function Board:possibleMoves()
    local tiles = {} -- take note of movable tiles for future highlights...
    for y = 1, 8 do
        for x = 1, 8 do
            -- try increment x
            if x < 8 then
                local newX = x + 1;
                self:swapTiles(self.tiles[y][x], self.tiles[y][newX])
                if self:calculateMatches() then
                    table.insert(tiles, self.tiles[y][newX])
                end
                self:swapTiles(self.tiles[y][x], self.tiles[y][newX])
            end
            -- try increment y
            if y < 8 then
                local newY = y + 1;
                self:swapTiles(self.tiles[y][x], self.tiles[newY][x])
                if self:calculateMatches() then
                    table.insert(tiles, self.tiles[newY][x])
                end
                self:swapTiles(self.tiles[y][x], self.tiles[newY][x])
            end
        end
    end
    print("Possible Moves:" .. #tiles);
    if(#tiles > 0) then
        print("X:" .. (tiles[1].x/32+1) .. " Y:" .. (tiles[1].y/32+1))
    end
    return #tiles > 0 and tiles or false
 end

 function Board:shuffleH()
    local tweens = {}
    local swapped = {}
    -- shuffle by row
    for y = 1, 8 do
        local x = math.random(4)
        local j = math.random(5, 8)

        self:swapTiles(self.tiles[y][x], self.tiles[y][j])
        
        tweens[self.tiles[y][x]] = {x = self.tiles[y][j].x, y = self.tiles[y][j].y}
        tweens[self.tiles[y][j]] = {x = self.tiles[y][x].x, y = self.tiles[y][x].y}
    end
    return tweens
 end

 function Board:shuffleV()
    local tweens = {}
    local swapped = {}
    -- shuffle by row
    for x = 1, 8 do
        local y = math.random(4)
        local j = math.random(5, 8)

        self:swapTiles(self.tiles[y][x], self.tiles[j][x])
        
        tweens[self.tiles[y][x]] = {x = self.tiles[j][x].x, y = self.tiles[j][x].y}
        tweens[self.tiles[j][x]] = {x = self.tiles[y][x].x, y = self.tiles[y][x].y}
    end
    return tweens
 end
--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}
                    local lineExplosion = false
                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        
                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])

                        -- verify if any tile of the match is explosive
                        if self.tiles[y][x2].explosive then
                            lineExplosion = true
                        end

                    end

                    if lineExplosion then
                        -- add all line
                        match = {}
                        for x2 = 8, 1, -1 do
                            table.insert(match, self.tiles[y][x2])
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            local lineExplosion = false

            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])

                -- verify if any tile of the match is explosive
                if self.tiles[y][x].explosive then
                    lineExplosion = true
                end
            end

            if lineExplosion then
                -- add all line
                match = {}
                for x = 8, 1, -1 do
                    table.insert(match, self.tiles[y][x])
                end
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}
                    local columnExplosion = false
                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])
                        -- verify if any tile of the match is explosive
                        if self.tiles[y2][x].explosive then
                            columnExplosion = true
                        end
                    end

                    if columnExplosion then
                        -- add all column
                        match = {}
                        for y2 = 8, 1, -1 do
                            table.insert(match, self.tiles[y2][x])
                        end
                    end
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            local columnExplosion = false
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
                -- verify if any tile of the match is explosive
                if self.tiles[y][x].explosive then
                    columnExplosion = true
                end
            end

            if columnExplosion then
                -- add all column
                match = {}
                for y = 8, 1, -1 do
                    table.insert(match, self.tiles[y][x])
                end
            end
            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

function Board:swapTiles(tile1, tile2)

    -- swap grid positions of tiles
    local tempX = tile1.gridX
    local tempY = tile1.gridY

    tile1.gridX = tile2.gridX
    tile1.gridY = tile2.gridY
    tile2.gridX = tempX
    tile2.gridY = tempY

    -- swap tiles in the tiles table
    self.tiles[tile1.gridY][tile1.gridX] = tile1
    self.tiles[tile2.gridY][tile2.gridX] = tile2

end
--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        local toExclude = 0
        if #match == 5 or #match == 4 then
            toExclude = 3
        end
        for k, tile in pairs(match) do
            if k == toExclude then
                tile:startShine()
            else
                if tile.explosive then
                    tile:stopShine()
                end
                self.tiles[tile.gridY][tile.gridX] = nil
            end
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                local baseColor = self.baseColors[math.random(#self.baseColors)]
                
                -- new tile with random color and variety
                local tile = Tile(x, y, baseColor.color, baseColor.variety)
                if math.random(RANDOM_SHINE_TILE) == RANDOM_SHINE_TILE then
                    tile:startShine()
                end
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end