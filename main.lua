
require("AnAl")

local angle = 0
local anims = {}
local player = {}
local objects = {} -- table to hold all our physical objects

function love.load()
	
	love.graphics.setBackgroundColor( 255, 255, 255 )

	-- load animation
	anims["walking"] = newAnimation(love.graphics.newImage("manwalking1.png"), 80, 103, .175, 1, 0)
	anims["standing"] = newAnimation(love.graphics.newImage("manstanding.png"), 80, 103, .15, 1, 1)
	
	love.physics.setMeter(64) --the height of a meter our worlds will be 64px
	world = love.physics.newWorld(0, 9.81 * 64, true) --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
	world:setCallbacks(beginContact, endContact, preSolve, postSolve)

	--let's create the ground
	objects.ground = {}
	objects.ground.body = love.physics.newBody(world, 650/2, 650-50/2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
	objects.ground.shape = love.physics.newRectangleShape(650, 50) --make a rectangle with a width of 650 and a height of 50
	objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape); --attach shape to body
	objects.ground.show_bbox = true

	--let's create a ball
	objects.player = {}
	player = objects.player
	player.body = love.physics.newBody(world, 650/2, 650/2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
	player.shape = love.physics.newRectangleShape(0, 00, 30, 30) -- ball is a rectangle
	player.fixture = love.physics.newFixture(player.body, player.shape, 1) -- Attach fixture to body and give it a density of 1.
	player.fixture:setRestitution(0.091) --let the ball bounce
	player.fixture:setUserData(player)
	player.x = 50
	player.y = 50
	player.z = 1
	player.p = 1
	player.speed = 300
	player.current_animation = anims.standing
	player.show_bbox = true
	player.touching_ground = false
	player.last_jump_time = 0

	--let's create a couple blocks to play around with
	objects.block1 = {}
	objects.block1.show_bbox = true
	objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
	objects.block1.shape = love.physics.newRectangleShape(0, 0, 60, 100)
	objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 1) -- A higher density gives it more mass.

	objects.block2 = {}
	objects.block2.show_bbox = true
	objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
	objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
	objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 1)

	--initial graphics setup
	love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue
	love.window.setMode(650, 650) --set the window dimensions to 650 by 650
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
	anim = player.current_animation
	anim:update(dt)
	world:update(dt) --this puts the world into motion

	--here we are going to create some keyboard events
	if love.keyboard.isDown("right") then
		objects.player.body:applyForce(300, 0)
		player.p = 1
		player.z = 1
		player.current_animation = anims.walking
	elseif love.keyboard.isDown("left") then
		objects.player.body:applyForce(-300, 0)
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

end

function love.draw()
	player.x = objects.player.body:getX()
	player.y = objects.player.body:getY()

	anim = player.current_animation
	anim:draw(player.x-player.z*40,player.y-83,angle,player.z,player.p)

	for id, obj in pairs(objects) do
		if obj.show_bbox then
			love.graphics.polygon("fill", obj.body:getWorldPoints(obj.shape:getPoints()))
		end
	end
 	
end
