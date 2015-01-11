local LightWorld = require "light"
local sti = require 'sti'

local windowWidth = 640
local windowHeight = 480

-- @return item from list that has a key with the same value
function item_with_key_value(tbl, key, val)
    for idx, i in pairs(tbl) do
        for k, v in pairs(i) do
            if k == key and v == val then
                return i, idx
            end
        end
    end
    return nil
end

function new_room(map_file)
    local room = {}
    room.path = map_file
    room.map = sti.new(map_file)
    room.world = love.physics.newWorld(0, 9.81 * 64, true)
    room.world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    room.collision = room.map:initWorldCollision(room.world)

    -- create light world
    room.lightWorld = LightWorld()
    room.lightWorld:setAmbientColor(0, 0, 0)
    room.lightWorld:setRefractionStrength(16.0)
    room.lightWorld:setReflectionVisibility(0.75)

    if room.map.layers['NormalMap'] then
        --lightMouse = room.lightWorld:newLight(windowWidth / 2, windowHeight / 2, 255, 255, 255)--, 300)

        local layer = room.map.layers['NormalMap']
	local w			= love.graphics.getWidth()
	local h			= love.graphics.getHeight()
	local tw		= 32
	local th		= 32
	local bw		= math.ceil(w / tw)
	local bh		= math.ceil(h / th)

	if bw < 20 then bw = 20 end
	if bh < 20 then bh = 20 end

        for y = 1, layer.height do
            local by = math.ceil(y / bh)

            for x = 1, layer.width do
                local tile	= layer.data[y][x]
                local bx	= math.ceil(x / bw)
                local id

                if tile then
                    local ts = room.map.tilesets[tile.tileset]
                    local image = room.map.tilesets[tile.tileset].image
                    local image2 = room.map.tilesets[1].image

                    local tx, ty
                    tx = x * tw
                    ty = y * th

                    tile.x = tx
                    tile.y = ty

                    -- Compensation for scale/rotation shift
                    if tile.sx	< 0 then tx = tx + tw end
                    if tile.sy	< 0 then ty = ty + th end
                    if tile.r	> 0 then tx = tx + tw end
                    if tile.r	< 0 then ty = ty + th end

                    local ts_tile, _ = item_with_key_value(ts.tiles, 'id', tile.id)
                    if ts_tile and ts_tile.objectGroup then
                        for _, obj in pairs(ts_tile.objectGroup.objects) do
                            for poly in allPolygons(obj, {x=tx-32, y=ty-32}) do
                                --local r = room.lightWorld:newImage(image2, x * 32 - 16, y * 32 - 16, 32, 32)
                                --local r = room.lightWorld:newRectangle(x * 32 - 16, y * 32 - 16, 32, 32)
                                local r = room.lightWorld:newPolygon(unpack(poly))
                                -- 10 is the number of tiles that make up a tileset row
                                local x1 = tile.id % 10
                                local y1 = (tile.id - tile.id % 10) / 10
                                r:setNormalMap2(image, x1, y1, 32, 32)
                                --normal = love.graphics.newImage("assets/gfx/normal.png")
                                --r:setNormalMap(normal, 32, 32)
                                --r:setShadowType("polygon", unpack(poly))
                                --r.setAlpha(0.5)
                            end
                        end
                    end
                end
            end
	end
    end

    local spriteLayer = room.map.layers["Objects"]

    for k, obj in ipairs(room.map.layers.Objects.objects) do
        if obj.type == 'monster' then
            obj.hp = 100
            obj.img = love.graphics.newImage("assets/gfx/monster.png")
        elseif obj.type == 'door' then
            obj.img = love.graphics.newImage("assets/gfx/door.png")
        elseif obj.type == 'light' then
            obj.light = room.lightWorld:newLight(obj.x, obj.y, 255, 255, 255)--, 300)
        end
    end

    function spriteLayer:update(dt)
        for _, obj in pairs(self.objects) do

        end
    end

    function spriteLayer:draw()
        for _, obj in pairs(self.objects) do
            if obj.type == 'monster' then
                love.graphics.draw(obj.img, obj.x, obj.y)
            elseif obj.type == 'door' then
                love.graphics.draw(obj.img, obj.x, obj.y)
            end
        end
    end

    return room
end

function room_unused_doors(room)
    return coroutine.wrap(function()
    for _, obj in pairs(room.map.layers.Objects.objects) do
        if obj.type == "door" and not obj.used then
            obj.room = room
            obj.used = true
            coroutine.yield(obj)
        end
    end
    end)
end

function connect_doors(levels)
    for _, level in pairs(levels) do
        local doors = {}

        -- get the doors from start first
        for door in room_unused_doors(level.rooms["start"]) do
            table.insert(doors, door)
        end

        -- get the rest of the doors
        for _, room in pairs(level.rooms) do
            for door in room_unused_doors(room) do
                table.insert(doors, door)
            end
        end

        -- TODO: this algorithm sucks, needs some love
        local door = table.remove(doors, 1)
        while 1 < #doors do
            for i, door2 in ipairs(doors) do
                if door2.room == door.room then

                else
                    --print("connected " .. door.room.path .. " to " .. door2.room.path)
                    table.remove(doors, i)
                    door2.target_door = door
                    door.target_door = door2
                    break
                end
            end
            door = table.remove(doors, 1)
        end
    end
end

function load_levels()
    local levels = {}
    local files = love.filesystem.getDirectoryItems("assets")
    for k, file in ipairs(files) do
        local room_level, room_name = string.match(file, "level(%d+)_(%a+).lua")
        if room_level then
            if levels[room_level] == nil then
                levels[room_level] = {rooms={}}
            end
            levels[room_level].rooms[room_name] = new_room("assets/level" .. room_level .. "_" .. room_name)
            --print("loaded " .. room_level .. "_" .. room_name)
        end
    end

    connect_doors(levels)

    return levels
end

local function getPolygonVertices(object, tile, precalc)
    local ox, oy = 0, 0

    ox = object.x
    oy = object.y

    local vertices = {}
    for _, vertex in ipairs(object.polygon) do
        table.insert(vertices, tile.x + ox + vertex.x)
        table.insert(vertices, tile.y + oy + vertex.y)
    end

    return vertices
end

function allPolygons(object, tile)
    return coroutine.wrap(function()
    local o = {
        shape	= object.shape,
        x		= object.x,
        y		= object.y,
        w		= object.width,
        h		= object.height,
        polygon	= object.polygon or object.polyline or object.ellipse or object.rectangle
    }
    local t		= tile or { x=0, y=0 }

    if o.shape == "rectangle" then
        o.r = object.rotation or 0
        local cos = math.cos(math.rad(o.r))
        local sin = math.sin(math.rad(o.r))

        o.polygon = {
            { x=o.x,		y=o.y },
            { x=o.x + o.w,	y=o.y },
            { x=o.x + o.w,	y=o.y + o.h },
            { x=o.x,		y=o.y + o.h },
        }

        local vertices = getPolygonVertices(o, t, true)
        coroutine.yield(vertices)
    elseif o.shape == "polygon" then
        local vertices	= getPolygonVertices(o, t, true)
        coroutine.yield(vertices)
    end
    end)
end

