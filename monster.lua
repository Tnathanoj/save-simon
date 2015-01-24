
local attack_time = 0.3
local attack_cooldown_time = 1
local walk_speed = 2
local max_walk_speed = 150



Monster = {}

function Monster:attack()

    if love.timer.getTime() < self.last_attack + attack_cooldown_time then
        return
    end

    self.last_attack = love.timer.getTime()

    self.current_animation = anims.reverant.attacking
    self.current_animation:reset()
    for k, obj in pairs(current_room.map.layers.Objects.objects) do
        if obj.o and obj.o.takedamage then
            x,y = self.body:getWorldCenter()
--            d = distance(x + self.facing_direction * self.weapon_reach, y, obj.o.x + obj.width/2, obj.o.y + obj.height/2)
--            if d < 50 then
--                obj.o:takedamage(50)
--                if obj.o.hp < 0 then
--                    obj.o:kill()
--                    current_room.map.layers.Objects.objects[k] = nil
--                end
--            end
        end
    end
end



function Monster:new_bbox()
    self.body = love.physics.newBody(current_room.world, self.x, self.y, "dynamic")
    self.shape = love.physics.newCircleShape(10)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setUserData(self)
    self.body:setFixedRotation(true)

    local x = self.x
    local y = self.y
    self.body2 = {}
    self.body2.body = love.physics.newBody(current_room.world, x, y - 50, "dynamic")
    self.body2.shape = love.physics.newRectangleShape(0, 0, 20, 55)
    self.body2.fixture = love.physics.newFixture(self.body2.body, self.body2.shape, 1)
    self.body2.fixture:setUserData(self)
    love.physics.newPrismaticJoint(self.body, self.body2.body, x, y - 50, 0, -1, false)
    self.body2.body:setFixedRotation(true)
end

function apply_monster_cage(self)
    if self.x < self.cage.x then
        self.body:setX(self.cage.x + 5)
        --self.body:applyLinearImpulse(self.speed * 10, 0)
        self.body:setLinearVelocity(5, 0)
        self.wonder_time = 1 + love.timer.getTime()
        self.facing_direction =  self.facing_direction * -1
    elseif self.cage.x + self.cage.width < self.x then
        self.body:setX(self.cage.x + self.cage.width - 5)
        --self.body:applyLinearImpulse(-self.speed * 10, 0)
        self.body:setLinearVelocity(-5, 0)
        self.wonder_time = 1 + love.timer.getTime()
        self.facing_direction =  self.facing_direction * -1
    end
end

function Monster:update(dt)

    -- change animation speed according to ground speed
    local x, y = self.body:getLinearVelocity()

    clamp_velocity(x, y, self.body, max_walk_speed)

    self.current_animation:update(dt)

    if self.cage then
        apply_monster_cage(self)
    end

    self.x = self.body:getX()
    self.y = self.body:getY()

    -- Find the monster
    if not self.target then
        for id, obj in pairs(current_room.map.layers.Objects.objects) do
            if obj.type == "player" then
                self.target = obj
            end
        end
    else

        -- Handle attacking animation    
        if love.timer.getTime() < self.last_attack + attack_time then
            self.current_animation:setSpeed(1)

        elseif self.wonder_time < love.timer.getTime() then
            if self.x < self.target.o.x then
                --self.body:applyForce(self.speed, 0)
                self.body:applyLinearImpulse(walk_speed, 0)
                self.current_animation = anims.reverant.walking
                self.facing_direction = 1
            else
                --self.body:applyForce(-self.speed, 0)
                self.body:applyLinearImpulse(-walk_speed, 0)
                self.current_animation = anims.reverant.walking
                self.facing_direction = -1
            end
        else
            self.body:applyLinearImpulse(walk_speed * self.facing_direction, 0)
            self.current_animation:setSpeed(math.min(math.abs(x) / 60, 1.4))
        end
    end

   for k, obj in pairs(current_room.map.layers.Objects.objects) do
        if obj.o then --and obj.o.takedamage then
            if obj.type == "player" then
                d = distance(obj.o.x, obj.o.y, self.x, self.y)
                if d < 80 then
                    self:attack()
                end
            end
        end
    end

end

function Monster:draw()
--    love.graphics.draw(self.img, self.x, self.y)
    self.current_animation:draw(self.x-self.facing_direction*40, self.y-83, 0, self.facing_direction, 1)
end

function Monster:takedamage(dmg)
    self.hp = self.hp - dmg
end

function Monster:kill()
    self.body:destroy()
    self.body2.body:destroy()
end

function place_in_monster_cage(self)
    for id, obj in pairs(current_room.map.layers.Objects.objects) do
        if obj.type == "invisiblemonstercage" then
            if obj.x < self.x and self.x < obj.x + obj.width then
                self.cage = obj
            end
        end
    end
end

function Monster:new(x, y)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.hp = 50
    o.img = love.graphics.newImage("assets/gfx/monster.png")
    o.x = x
    o.y = y
    o.current_animation = anims.reverant.standing
    o.touching_ground = false
    o.target = nil
    o.facing_direction = 1
    o.cage = nil
    o:new_bbox()
    o.wonder_time = 0
    o.last_attack = 0

    place_in_monster_cage(o)

    return o
end

