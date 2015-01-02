
local sti = require "sti"
require("AnAl")

local anims = {}
local objects = {} -- table to hold all our physical objects

local windowWidth = 640
local windowHeight = 480


function new_player()
    --let's create a ball
    objects.player = {}
    player = objects.player
    player.body = love.physics.newBody(world, 650/2, 650/2, "dynamic")
    --player.shape = love.physics.newRectangleShape(0, 00, 30, 30) -- ball is a rectangle
    player.shape = love.physics.newCircleShape(10)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    --player.fixture:setRestitution(0.091) --let the ball bounce
    player.fixture:setUserData(player)
    player.x = 50
    player.y = 50
    player.z = 1
    player.p = 1
    player.speed = 300
    player.current_animation = anims.standing
    --player.show_bbox = true
    player.touching_ground = false
    player.last_jump_time = 0
    player.body:setFixedRotation(true)

    x = 650/2
    y = 650/2
    objects.player_body = {}
    player_body = objects.player_body
    player_body.body = love.physics.newBody(world, x, y - 50, "dynamic")
    player_body.shape = love.physics.newRectangleShape(0, 0, 20, 55)
    player_body.fixture = love.physics.newFixture(player_body.body, player_body.shape, 1)
    player_body.fixture:setUserData(player_body)
    player_body.show_bbox = true
    love.physics.newPrismaticJoint(player.body, player_body.body, x, y - 50, 0, -1, false)
    player_body.body:setFixedRotation(true)
    --love.physics.newWheelJoint(player.body, player_body.body, x, y - 20, 0, -1, false)
    --love.physics.newDistanceJoint(player.body, player_body.body, x, y, x, y-40, false)
end

function new_room()
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

function love.load()
    love.graphics.setBackgroundColor( 255, 255, 255 )

    -- load animation
    anims["walking"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessman.png"), 80, 103, .175, 1, 0)
    anims["standing"] = newAnimation(love.graphics.newImage("assets/gfx/weaponlessmanstanding.png"), 80, 103, .15, 1, 1)

    map = sti.new("assets/level1")

    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 9.81 * 64, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    collision = map:initWorldCollision(world)
    map:addCustomLayer("Sprite Layer", 3)

    new_player()
    new_room()

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

function love.update(dt)
	objects.player.touching_ground = false
	player = objects.player
	player.current_animation:update(dt)
	world:update(dt) --this puts the world into motion

	--here we are going to create some keyboard events
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
	if love.keyboard.isDown("up") and objects.player.touching_ground then
		if objects.player.last_jump_time < love.timer.getTime() then
			objects.player.body:applyForce(0,-5000)
			objects.player.last_jump_time = 1 + love.timer.getTime()
		end
		--objects.ball.body:setPosition(650/2, 650/2)
		--objects.ball.body:setLinearVelocity(0, 0)
	end

	--objects.player_body.body:setLinearVelocity(0, -10)

end

function love.draw()
    player.x = objects.player.body:getX()
    player.y = objects.player.body:getY()
	
    -- Translation would normally be based on a player's x/y
    local translateX = 0
    local translateY = 0

    -- Draw Range culls unnecessary tiles
    map:setDrawRange(translateX, translateY, windowWidth, windowHeight)

    -- Draw the map and all objects within
    map:draw()

    -- Draw Collision Map (useful for debugging)
    --love.graphics.setColor(255, 0, 0, 255)
    --map:drawWorldCollision(collision)

    -- Reset color
    --love.graphics.setColor(255, 255, 255, 255)

    for id, obj in pairs(objects) do
        if obj.show_bbox then
            love.graphics.polygon("fill", obj.body:getWorldPoints(obj.shape:getPoints()))
        end
    end

    player.current_animation:draw(player.x-player.z*40,player.y-83,0,player.z,player.p)
end
