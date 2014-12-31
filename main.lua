
require("AnAl")

local angle = 0
local anims = {}
local player = {}


function love.load()
	
	love.graphics.setBackgroundColor( 255, 255, 255 )

	picture = "manstanding.png"
	
	man = love.graphics.newImage("manwalking1.png")

	player.x = 50
	player.y = 50
	player.z = 1
	player.p = 1
	player.speed = 300

	-- load animation
	anims["walking"] = newAnimation(man, 80, 103, .175, 1, 0)
	anims["standing"] = newAnimation(love.graphics.newImage("manstanding.png"), 80, 103, .15, 1, 1)
	player.current_animation = anims.standing
end

function love.update(dt)
	anim = player.current_animation
	anim:update(dt)

	if love.keyboard.isDown("right") then
		player.x = player.x + (player.speed * dt)
		player.p = 1
		player.z = 1
		player.current_animation = anims.walking
	elseif love.keyboard.isDown("left") then
		player.x = player.x - (player.speed * dt)
		player.p = 1
		player.z = -1
		player.current_animation = anims.walking
	else
		player.current_animation = anims.standing
	end

	if love.keyboard.isDown("down") then
		player.y = player.y + (player.speed * dt)	
	end

	if love.keyboard.isDown("up") then
		player.y = player.y - (player.speed * dt)	
	end
	if player.y > 200 then
		player.y = 200
	end

	if player.y <200 then
		player.y = player.y +(0.89 * player .speed *dt)
	end

end

function love.draw()
	anim = player.current_animation
	anim:draw(player.x-player.z*40,player.y,angle,player.z,player.p)

end
