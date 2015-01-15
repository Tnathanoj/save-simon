require "postshader"
require "AnAl"
require 'camera'
require 'world'
require 'player'
local vector = require 'vector'
local sti = require 'sti'
local LightWorld = require "light"

anims = {}
objects = {} -- table to hold all our physical objects

windowWidth = 640
windowHeight = 480

-- A level is made up of many rooms
local levels = {}

current_room = {}

function love.load()
    math.randomseed( os.time() )
    normal = love.graphics.newImage("assets/gfx/normal.png")

    -- load animation
    anims["walking"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessman.png"), 80, 103, .175, 1, 0)
    anims["standing"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessmanstanding.png"), 80, 103, .15, 1, 1)
    anims["attacking"] = newAnimation(love.graphics.newImage("assets/gfx/manattacking.png"), 80, 103, .175, 1, 0)

    love.physics.setMeter(64)

    levels = load_levels()

    current_room = levels[1].rooms["start"]
    
    objects.player = Player:new()

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

    objects.player:update(dt)
    update_camera(dt)
    current_room.lightWorld:update(dt)

    objects.player.x = objects.player.body:getX()
    objects.player.y = objects.player.body:getY()
end

function love.draw()
    current_room.lightWorld:setTranslation(-camera._x, -camera._y, 1)
    love.graphics.push()
    love.graphics.translate(-camera._x, -camera._y)
    current_room.lightWorld:draw(function(l, t, w, h, s)
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("fill", 0, -500, love.graphics.getWidth() * 4, love.graphics.getHeight() * 2)
        --current_room.map:drawWorldCollision(current_room.collision)
        current_room.map.layers['Tile Layer 1']:draw()
        current_room.map.layers['Objects']:draw()
        --current_room.map:draw()
    end)
    objects.player.current_animation:draw(objects.player.x-objects.player.z*40, objects.player.y-83, 0, objects.player.z, objects.player.p)
    love.graphics.pop()
end
