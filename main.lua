require "postshader"
require "light"
require "AnAl"
require 'camera'
local vector = require 'vector'
local sti = require 'sti'

local anims = {}
local objects = {} -- table to hold all our physical objects

local windowWidth = 640
local windowHeight = 480

-- A level is made up of many rooms
local levels = {}

local current_room = {}

function new_player_bbox(player)

    --let's create a ball
    player.body = love.physics.newBody(current_room.world, player.x, player.y, "dynamic")
    player.shape = love.physics.newCircleShape(10)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setUserData(player)
    player.body:setFixedRotation(true)
    player.shadow_rect = current_room.lightWorld.newImage(love.graphics.newImage("assets/gfx/manstanding.png"), player.x, player.y, 90, 180)
    player.shadow_rect.setShadowType('image')

    x = player.x
    y = player.y
    objects.player_body = {}
    player_body = objects.player_body
    player_body.body = love.physics.newBody(current_room.world, x, y - 50, "dynamic")
    player_body.shape = love.physics.newRectangleShape(0, 0, 20, 55)
    player_body.fixture = love.physics.newFixture(player_body.body, player_body.shape, 1)
    player_body.fixture:setUserData(player_body)
    --player_body.show_bbox = true
    love.physics.newPrismaticJoint(player.body, player_body.body, x, y - 50, 0, -1, false)
    player_body.body:setFixedRotation(true)
    --love.physics.newWheelJoint(player.body, player_body.body, x, y - 20, 0, -1, false)
    --love.physics.newDistanceJoint(player.body, player_body.body, x, y, x, y-40, false)
end

function new_player()
    objects.player = {}
    player = objects.player
    player.x = 650/2
    player.y = 650/2
    player.z = 1
    player.p = 1
    player.speed = 100
    player.current_animation = anims.standing
    --player.show_bbox = true
    player.touching_ground = false
    player.last_jump_time = 0
    player.last_room_change_time = 0

    new_player_bbox(player)
end

function player_change_room(player)
    player.body:destroy()
    objects.player_body.body:destroy()
    new_player_bbox(player)
    objects.player.last_room_change_time = 1 + love.timer.getTime()
end

function blocks()
    --let's create a couple blocks to play around with
    objects.block1 = {}
    objects.block1.show_bbox = true
    objects.block1.body = love.physics.newBody(world, 400, 300, "dynamic")
    objects.block1.shape = love.physics.newRectangleShape(0, 0, 70, 20)
    objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, .5) -- A higher density gives it more mass.

    objects.block2 = {}
    objects.block2.show_bbox = true
    objects.block2.body = love.physics.newBody(world, 400, 400, "dynamic")
    objects.block2.shape = love.physics.newRectangleShape(0, 0, 60, 60)
    objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, .5)

    objects.block3 = {}
    objects.block3.show_bbox = true
    objects.block3.body = love.physics.newBody(world, 400, 200, "dynamic")
    objects.block3.shape = love.physics.newRectangleShape(0, 0, 50, 5)
    objects.block3.fixture = love.physics.newFixture(objects.block3.body, objects.block3.shape, .5)
end


local function getPolygonVertices(object, tile, precalc)
    local ox, oy = 0, 0

--    if not precalc then
        ox = object.x
        oy = object.y
--    end

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

    print(o.shape)

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

        print(unpack(o.polygon))

        local vertices = getPolygonVertices(o, t, true)
        coroutine.yield(vertices)
    elseif o.shape == "polygon" then
        local vertices	= getPolygonVertices(o, t, true)
        coroutine.yield(vertices)
    end
    end)
end

function _allPolygons(object, tile, f)
end

-- @return item from list that has a key with the same value
function item_with_key_value(tbl, key, val)
    for _, i in pairs(tbl) do
        for k, v in pairs(i) do
            if k == key and v == val then
                return i
            end
        end
    end
    return nil
end


function new_room(map_file)
    local room = {}
    room.map = sti.new(map_file)
    room.world = love.physics.newWorld(0, 9.81 * 64, true)
    room.world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    --room.map:addCustomLayer("Sprite Layer", 3)
    room.collision = room.map:initWorldCollision(room.world)

    -- create light world
    room.lightWorld = love.light.newWorld()
    --room.lightWorld.setAmbientColor(15, 15, 31) -- optional
    room.lightWorld.setAmbientColor(0, 0, 0) -- optional
    room.lightWorld.setRefractionStrength(16.0)
    room.lightWorld.setReflectionVisibility(0.75)

    -- create light (x, y, red, green, blue, range)
    --for _, obj in ipairs(room.collision) do
    --    room.lightWorld.newPolygon(room.collision.body:getWorldPoints(obj.shape:getPoints()))
    --end

    if room.map.layers['NormalMap'] then

        --lightMouse = room.lightWorld.newLight(windowWidth / 2, windowHeight / 2, 255, 127, 63, 300)
        lightMouse = room.lightWorld.newLight(windowWidth / 2, windowHeight / 2, 255, 255, 255)--, 300)
        --lightMouse.setGlowStrength(0.7) -- optional
        --lightMouse.setGlowSize(100) -- optional
        lightMouse.setSmooth(1)
        lightMouse.setRange(300)

--        for _, tiles in ipairs(room.map.layers.NormalMap.data) do
--            for _, tile in pairs(tiles) do
--                if tile then
--                    local image = room.map.tilesets[tile.tileset].image
--                    room.lightWorld.newImage(image)
--                end
--            end
--        end

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

                local ts_tile = item_with_key_value(ts.tiles, 'id', tile.id)
                if ts_tile and ts_tile.objectGroup then
                    for _, obj in pairs(ts_tile.objectGroup.objects) do
                        for poly in allPolygons(obj, {x=tx-32, y=ty-32}) do
                            --local r = room.lightWorld.newPolygon(room.collision.body:getWorldPoints(unpack(poly)))
                            --local r = room.lightWorld.newPolygon(unpack(poly))
                            --local r = room.lightWorld.newPolygon(poly)
                            --local r = room.lightWorld.newImage(image2, x * 32 - 16, y * 32 - 16, 16, 16)
                            local r = room.lightWorld.newImage(image2, x * 32 - 16, y * 32 - 16, 32, 32)
                            --local r = room.lightWorld.newRectangle(x * 32 - 16, y * 32 - 16, 16, 16)

                            local x1 = tile.id % 10
                            local y1 = (tile.id - tile.id % 10) / 10
                            r.setNormalMap2(image, x1, y1, 32, 32)
                            r.setShadowType("polygon", unpack(poly))
                            --r.setShadowType("rectangle", 32)
                            --r.setColor(255, 0, 0)
                            --r.setAlpha(0.5)

                            --r.setNormalMap(image, 32, 32, (1*32) / image:getWidth(), (1*32) / image:getHeight())
                            --r.setNormalTileOffset(32, 32)
                            --r.setShadowType("rectangle", 32)
                            --r.setShadowType("image")--, 0, 0, 0.0)
                            --r.setShadow(false)
                            --phyLight[phyCnt].setShadowType("circle", 16)
                            --id = batch:add(tile.quad, tx, ty, tile.r, tile.sx, tile.sy)
                            --self.tileInstances[tile.gid] = self.tileInstances[tile.gid] or {}
                            --table.insert(self.tileInstances[tile.gid], { batch=batch, id=id, gid=tile.gid, x=tx, y=ty })
                        end
                    end
                end
            end
        end
	end

    end

    return room
end

function room_get_unused_door(room)
    for _, obj in pairs(room.map.layers.Objects.objects) do
        if obj.type == "door" and not obj.used then
            obj.room = room
            obj.used = true
            return obj
        end
    end
end

function connect_doors()
    for _, level in pairs(levels) do
        local doors = {}
        for _, room in pairs(level.rooms) do
            local door = room_get_unused_door(room)
            if door and 0 < #doors then
                local door2 = table.remove(doors, 1)
                door2.target_door = door
                door.target_door = door2
            else
                table.insert(doors, door)
            end
        end
    end
end

function load_levels()
    local files = love.filesystem.getDirectoryItems("assets")
    for k, file in ipairs(files) do
        local room_level, room_name = string.match(file, "level(%d+)_(%a+).lua")
        if room_level then
            if levels[room_level] == nil then
                levels[room_level] = {rooms={}}
            end
            levels[room_level].rooms[room_name] = new_room("assets/level" .. room_level .. "_" .. room_name)
        end
    end
end

function love.load()
    normal = love.graphics.newImage("assets/gfx/normal.png")

    -- load animation
    anims["walking"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessman.png"), 80, 103, .175, 1, 0)
    anims["standing"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessmanstanding.png"), 80, 103, .15, 1, 1)

    love.physics.setMeter(64)

    load_levels()
    connect_doors()

    current_room = levels["1"].rooms["start"]

    new_player()

    love.graphics.setBackgroundColor(0, 0, 0)
    --love.graphics.setBackgroundColor(50, 50, 50)
    --love.graphics.setBackgroundColor(127, 127, 127)
    --love.graphics.setBackgroundColor(255, 255, 255)
    love.window.setMode(windowWidth, windowHeight)
end

function beginContact(a, b, coll)
end

function endContact(a, b, coll)
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
    if a:getUserData() == objects.player or b:getUserData() == objects.player then
        objects.player.touching_ground = true
    end
end

function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

function update_player(player, dt)
    player.current_animation:update(dt)

    if love.keyboard.isDown("right") then
        objects.player.body:applyForce(player.speed, 0)
        player.p = 1
        player.z = 1
        player.current_animation = anims.walking
    elseif love.keyboard.isDown("left") then
        objects.player.body:applyForce(-player.speed, 0)
        player.p = 1
        player.z = -1
        player.current_animation = anims.walking
    else
        player.current_animation = anims.standing
    end

    if love.keyboard.isDown("up") then
        for _, obj in pairs(current_room.map.layers.Objects.objects) do
            if obj.type == "door" then
                x,y = objects.player.body:getWorldCenter()
                d = distance(x, y, obj.x + obj.width/2, obj.y + obj.height/2)
                if d < 20 and objects.player.last_room_change_time < love.timer.getTime() then
                    current_room = obj.target_door.room
                    player.x = obj.target_door.x
                    player.y = obj.target_door.y
                    player_change_room(objects.player)
                    return
                end
            end
        end
        if objects.player.touching_ground and objects.player.last_jump_time < love.timer.getTime() then
            objects.player.body:applyForce(0, -5000)
            objects.player.last_jump_time = 1 + love.timer.getTime()
        end
    end
end

function love.update(dt)
    objects.player.touching_ground = false
    current_room.world:update(dt)

    lightMouse.setPosition(love.mouse.getX(), love.mouse.getY() - 120)
    --lightMouse.setPosition(player.x, player.y)

    update_player(objects.player, dt)

    cam_org = vector.new(camera._x, camera._y)
    ent_org = vector.new(objects.player.x - windowWidth / 2, objects.player.y - windowHeight / 1.5)
    sub = ent_org - cam_org
    sub:normalize_inplace()
    dist = ent_org:dist(cam_org)

    camera:move(sub.x * dist * dt * 2, sub.y * dist * dt * 2)
end

function love.draw()
    player.x = objects.player.body:getX()
    player.y = objects.player.body:getY()
    player.shadow_rect.setPosition(objects.player.body:getX(), player.y)

    -- update lightmap (doesn't need deltatime)
    current_room.lightWorld.update()

    love.postshader.setBuffer("render")

    --camera:set()

    love.graphics.setBlendMode("alpha")

    -- draw background
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())



    --current_room.map:drawWorldCollision(current_room.collision)

    -- draw lightmap shadows
    current_room.lightWorld.drawShadow()

    current_room.map.layers['Tile Layer 1']:draw()

    for id, obj in pairs(objects) do
        if obj.show_bbox then
            love.graphics.polygon("fill", obj.body:getWorldPoints(obj.shape:getPoints()))
        end
    end

    player.current_animation:draw(player.x-player.z*40, player.y-83, 0, player.z, player.p)

    current_room.lightWorld.drawShine()
    current_room.lightWorld.drawPixelShadow()
    current_room.lightWorld.drawMaterial()
    current_room.lightWorld.drawGlow()
    current_room.lightWorld.drawReflection()
    current_room.lightWorld.drawRefraction()

    love.postshader.draw()

    -- draw lightmap shine
    --camera:unset()
end
