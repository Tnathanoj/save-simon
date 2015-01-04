
local sti = require "sti"
require("AnAl")

local anims = {}
local objects = {} -- table to hold all our physical objects

local windowWidth = 640
local windowHeight = 480

-- A level is made up of many rooms
local levels = {}

local current_room = {}

function new_player_bbox()
    --let's create a ball
    player.body = love.physics.newBody(current_room.world, 650/2, 650/2, "dynamic")
    player.shape = love.physics.newCircleShape(10)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setUserData(player)
    player.body:setFixedRotation(true)

    x = 650/2
    y = 650/2
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
    player.x = 50
    player.y = 50
    player.z = 1
    player.p = 1
    player.speed = 300
    player.current_animation = anims.standing
    --player.show_bbox = true
    player.touching_ground = false
    player.last_jump_time = 0
    player.last_room_change_time = 0

    new_player_bbox()
end

function player_change_room()
    new_player_bbox()
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

function new_room(map_file)
    room = {}
    room.world = love.physics.newWorld(0, 9.81 * 64, true)
    room.world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    room.map = sti.new(map_file)
    room.map:addCustomLayer("Sprite Layer", 3)
    room.collision = room.map:initWorldCollision(room.world)
    return room
end

function love.load()
    love.graphics.setBackgroundColor( 255, 255, 255 )

    -- load animation
    anims["walking"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessman.png"), 80, 103, .175, 1, 0)
    anims["standing"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessmanstanding.png"), 80, 103, .15, 1, 1)


    love.physics.setMeter(64)

    current_room = new_room("assets/level1_treasure_room")
    --levels.add({})
    --levels[1].add(new_room("assets/level1"))

    new_player()

    --initial graphics setup
    love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue
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
        objects.player.body:applyForce(100, 0)
        player.p = 1
        player.z = 1
        player.current_animation = anims.walking
    elseif love.keyboard.isDown("left") then
        objects.player.body:applyForce(-100, 0)
        player.p = 1
        player.z = -1
        player.current_animation = anims.walking
    else
        player.current_animation = anims.standing
    end

    if love.keyboard.isDown("up") then
        for _, obj in pairs(current_room.map.layers.Objects.objects) do
            if obj.type == "door" then
                d = distance(objects.player.x, objects.player.y, obj.x, obj.y)
                if d < 20 then
                    current_room = new_room("assets/level1")
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

    update_player(objects.player, dt)
end

function love.draw()
    player.x = objects.player.body:getX()
    player.y = objects.player.body:getY()
	
    -- Translation would normally be based on a player's x/y
    local translateX = 0
    local translateY = 0

    -- Draw Range culls unnecessary tiles
    current_room.map:setDrawRange(translateX, translateY, windowWidth, windowHeight)

    -- Draw the map and all objects within
    current_room.map:draw()

    -- Draw Collision Map (useful for debugging)
    --current_room.map:drawWorldCollision(current_room.collision)

    for id, obj in pairs(objects) do
        if obj.show_bbox then
            love.graphics.polygon("fill", obj.body:getWorldPoints(obj.shape:getPoints()))
        end
    end

    player.current_animation:draw(player.x-player.z*40, player.y-83, 0, player.z, player.p)

end
