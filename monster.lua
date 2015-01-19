

Monster = {}

function Monster:new_bbox()
    self.body = love.physics.newBody(current_room.world, self.x, self.y, "dynamic")
    self.shape = love.physics.newCircleShape(20)
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

function Monster:update(dt)

    -- change animation speed according to ground speed
    local x, y = self.body:getLinearVelocity()
    self.current_animation:setSpeed(math.min(math.abs(x) / 60, 1.4))
    self.current_animation:update(dt)

    -- Apply monster cage restriction
    if self.cage then
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
        if self.wonder_time < love.timer.getTime() then
            if self.x < self.target.o.x then
                --self.body:applyForce(self.speed, 0)
                self.body:applyLinearImpulse(self.speed, 0)
                self.current_animation = anims.reverant.walking
                self.facing_direction = 1
            else
                --self.body:applyForce(-self.speed, 0)
                self.body:applyLinearImpulse(-self.speed, 0)
                self.current_animation = anims.reverant.walking
                self.facing_direction = -1
            end
        else
            self.body:applyLinearImpulse(self.speed * self.facing_direction, 0)
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

function Monster:new(x, y)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.hp = 50
    o.img = love.graphics.newImage("assets/gfx/monster.png")
    o.x = x
    o.y = y
    o.speed = 3
    o.current_animation = anims.reverant.standing
    o.touching_ground = false
    o.target = nil
    o.facing_direction = 1
    o.cage = nil
    o:new_bbox()
    o.wonder_time = 0

    for id, obj in pairs(current_room.map.layers.Objects.objects) do
        if obj.type == "invisiblemonstercage" then
            o.cage = obj
        end
    end


    return o
end

