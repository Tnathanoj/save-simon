require "AnAl"
require 'camera'
require 'world'
require 'player'
require 'monster'

local vector = require 'vector'
local sti = require 'sti'
local LightWorld = require "light"

anims = {}
objects = {} -- table to hold all our physical objects

windowWidth = 640
windowHeight = 480

screen_pan_time = 1

-- A level is made up of many rooms
levels = {}

current_room = {}

function love.load()
    math.randomseed( os.time() )
    normal = love.graphics.newImage("assets/gfx/normal.png")

    font = love.graphics.newFont("assets/font/joystix.ttf", 15)

    love.graphics.setDefaultFilter("nearest","nearest")
    love.graphics.setFont(font)

    -- load animation
    anims["walking"] = newAnimation(love.graphics.newImage("assets/gfx/manwalking.png"), 80, 103, .175, 1, 0)
    anims["standing"] = newAnimation(love.graphics.newImage("assets/gfx/manstanding.png"), 80, 103, .15, 1, 1)
    --anims["attacking"] = newAnimation(love.graphics.newImage("assets/gfx/manattacking2.png"), 96, 103, .055, 1, 0)
    anims["attacking"] = newAnimation(love.graphics.newImage("assets/gfx/manattacking2.png"), 96, 103, .055, 1, 0)
    anims["crouching"] = newAnimation(love.graphics.newImage("assets/gfx/mancrouching.png"), 80, 103, .175, 1, 0)

    anims.reverant = {
        walking = newAnimation(love.graphics.newImage("assets/gfx/reverant_walking.png"), 80, 103, .175, 1, 0),
        standing = newAnimation(love.graphics.newImage("assets/gfx/reverant_standing.png"), 80, 103, .15, 1, 1),
        attacking = newAnimation(love.graphics.newImage("assets/gfx/reverant_attacking.png"), 96, 103, .085, 1, 0),
    }


    love.physics.setMeter(64)

    levels = load_levels()

    current_room = levels[1].rooms["start"]
    
    objects.player = Player:new()
    current_room.map.layers.Objects.objects[objects.player] = {x=objects.player.x, y=objects.player.y, o=objects.player, type="player"}

    love.graphics.setBackgroundColor(0, 0, 0)
    --love.window.setMode(windowWidth, windowHeight, {fullscreen=true, highdpi=true})
    --love.window.setMode(windowWidth, windowHeight, {vsync=false})
    love.window.setMode(windowWidth, windowHeight)
end

function beginContact(a, b, coll)
end

function endContact(a, b, coll)
end

function preSolve(a, b, coll)
    if a:getUserData() == objects.player or b:getUserData() == objects.player then
        local obj = objects.player
        obj.last_touching_ground = 0.1 + love.timer.getTime()
        obj.touching_ground= true
    end
end

function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
end

function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

function easeOutQuad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end

camera_change_time = 0

-- Clamp camera
-- Make sure camera is on focus
function clamp_camera(self)
    local left_hand_side = 0
    local right_hand_side = current_room.map.width * current_room.map.tilewidth - windowWidth

    if self._x < left_hand_side then
        self._x = left_hand_side
    elseif right_hand_side < self._x then
        self._x = right_hand_side
    end
end

function update_camera(dt)

    clamp_camera(camera)

    cam_org = vector.new(camera._x, camera._y)
    ent_org = vector.new(objects.player.x - windowWidth / 2, objects.player.y - windowHeight / 1.5)

    local left_hand_side = 0
    local right_hand_side = current_room.map.width * current_room.map.tilewidth - windowWidth

    -- Do camera panning
    local dist_from_left = math.abs(left_hand_side - ent_org.x)
    local dist_from_right = math.abs(right_hand_side - ent_org.x)

    if love.timer.getTime() < camera_change_time + screen_pan_time then
        if dist_from_left < dist_from_right then
            camera._x = windowWidth - easeOutQuad(love.timer.getTime() - camera_change_time, 0, windowWidth, screen_pan_time)
        else
            camera._x = easeOutQuad(love.timer.getTime() - camera_change_time, 0, windowWidth, screen_pan_time)
        end

    elseif camera._x + windowWidth / 2 < ent_org.x then
        camera_change_time = love.timer.getTime()
    elseif ent_org.x + windowWidth / 2 < camera._x then
        camera_change_time = love.timer.getTime()
    end

    -- Do camera follow mouse
    --camera:setPosition(love.mouse.getX() - 100, love.mouse.getY() - 100)
end

function love.update(dt)
    current_room.map:update(dt)
    current_room.world:update(dt)

    --lightMouse:setPosition(love.mouse.getX(), love.mouse.getY())
    --lightMouse.setPosition(player.x, player.y)

    update_camera(dt)
    current_room.lightWorld:update(dt)
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
        --current_room.map:draw()
    end)
    current_room.map.layers['Objects']:draw()
    objects.player.current_animation:draw(objects.player.x-objects.player.facing_direction*40, objects.player.y-83, 0, objects.player.facing_direction, 1)
    love.graphics.pop()

    love.graphics.print(objects.player.gold, 16, 16)
end
