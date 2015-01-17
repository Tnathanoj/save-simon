

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
    self.body2.fixture:setUserData(self.body2)
    love.physics.newPrismaticJoint(self.body, self.body2.body, x, y - 50, 0, -1, false)
    self.body2.body:setFixedRotation(true)
end

function Monster:update(dt)
    -- change animation speed according to ground speed
--    local x, y = self.body:getLinearVelocity()
--    self.current_animation:setSpeed(math.min(math.abs(x) / 60, 1.4))
--    self.current_animation:update(dt)

    self.x = self.body:getX()
    self.y = self.body:getY()

    if not self.target then
        for id, obj in pairs(current_room.map.layers.Objects.objects) do
            if obj.type == "player" then
                self.target = obj
            end
        end
    else
        if self.x < self.target.o.x then
            self.body:applyForce(self.speed, 0)
        else
            self.body:applyForce(-self.speed, 0)
        end
    end

end

function Monster:draw()
--    love.graphics.draw(self.img, self.x, self.y)
    love.graphics.draw(self.img, self.x - self.z*40, self.y - 60, 0, self.z, self.p)
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

    o.hp = 100
    o.img = love.graphics.newImage("assets/gfx/monster.png")
    o.x = x
    o.y = y
    o.z = 1
    o.p = 1
    o.speed = 100
    --o.current_animation = anims.standing
    o.touching_ground = false
    o.target = nil

    o:new_bbox()

    return o
end

