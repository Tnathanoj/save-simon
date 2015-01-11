require "postshader"
require "AnAl"
require 'camera'
require 'world'
local vector = require 'vector'
local sti = require 'sti'
local LightWorld = require "light"

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

function love.load()
    normal = love.graphics.newImage("assets/gfx/normal.png")

    -- load animation
    anims["walking"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessman.png"), 80, 103, .175, 1, 0)
    anims["standing"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessmanstanding.png"), 80, 103, .15, 1, 1)
    anims["attacking"] = newAnimation(love.graphics.newImage("assets/gfx/manattacking.png"), 80, 103, .175, 1, 0)

    love.physics.setMeter(64)

    levels = load_levels()

    current_room = levels["1"].rooms["start"]

    new_player()

    love.graphics.setBackgroundColor(0, 0, 0)
    --love.window.setMode(windowWidth, windowHeight, {fullscreen=true})
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

    if love.keyboard.isDown("z") then
        player.current_animation = anims.attacking
        for k, obj in pairs(current_room.map.layers.Objects.objects) do
            if obj.type == "monster" then
                x,y = objects.player.body:getWorldCenter()
                d = distance(x, y, obj.x + obj.width/2, obj.y + obj.height/2)
                if d < 40 then
                    obj.hp = obj.hp - 1000
                    if obj.hp < 0 then
                        current_room.map.layers.Objects.objects[k] = nil
                    end
                end
            end
        end
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

function update_camera(dt)
    cam_org = vector.new(camera._x, camera._y)
    ent_org = vector.new(objects.player.x - windowWidth / 2, objects.player.y - windowHeight / 1.5)
    sub = ent_org - cam_org
    sub:normalize_inplace()
    dist = ent_org:dist(cam_org)
    camera:move(sub.x * dist * dt * 2, sub.y * dist * dt * 2)
    --camera:setPosition(love.mouse.getX() - 100, love.mouse.getY() - 100)
    --camera:setPosition(0, 0)
end

function love.update(dt)
    objects.player.touching_ground = false
    current_room.world:update(dt)
    current_room.map:update(dt)

    --lightMouse:setPosition(love.mouse.getX(), love.mouse.getY())
    --lightMouse.setPosition(player.x, player.y)

    update_player(objects.player, dt)
    update_camera(dt)
    current_room.lightWorld:update(dt)

    player.x = objects.player.body:getX()
    player.y = objects.player.body:getY()
end

function love.draw()
    current_room.lightWorld:setTranslation(-camera._x, -camera._y, 1)
    love.graphics.push()
    love.graphics.translate(-camera._x, -camera._y)
    current_room.lightWorld:draw(function(l, t, w, h, s)
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth() * 2, love.graphics.getHeight())
        --current_room.map:drawWorldCollision(current_room.collision)
        current_room.map.layers['Tile Layer 1']:draw()
        current_room.map.layers['Objects']:draw()
        --current_room.map:draw()
    end)
    player.current_animation:draw(player.x-player.z*40, player.y-83, 0, player.z, player.p)
    love.graphics.pop()
end
