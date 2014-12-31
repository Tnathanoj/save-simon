
require("AnAl")

local angle = 0
local anims = {}
local player = {}


function love.load()
	love.graphics.setBackgroundColor( 255, 255, 255 )

	picture = "man3.png"
	
	man = love.graphics.newImage("manwalk.png")

	x = 50
	y = 50
	z = 1
	p = 1
	speed = 300

	-- load animation
	anims["walking"] = newAnimation(man, 80, 103, .15, 1, 0)
	anims["standing"] = newAnimation(man, 80, 103, .15, 1, 1)
	player.current_animation = anims.standing
end

function love.update(dt)
	anim = player.current_animation
	anim:update(dt)

	if love.keyboard.isDown("right") then
		x = x + (speed * dt)
		p = 1
		z = 1
		player.current_animation = anims.walking
	elseif love.keyboard.isDown("left") then
		x = x - (speed * dt)
		p = 1
		z = -1
		player.current_animation = anims.walking
	else
		player.current_animation = anims.standing
	end

	if love.keyboard.isDown("down") then
		y = y + (speed * dt)	
	end

	if love.keyboard.isDown("up") then
		y = y - (speed * dt)	
	end

end

function love.draw()
	anim = player.current_animation
	anim:draw(x-z*40,y,angle,z,p)

end
