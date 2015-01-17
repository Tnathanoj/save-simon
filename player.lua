
Player = {}

function Player:new_bbox()

    --let's create a ball
    self.body = love.physics.newBody(current_room.world, self.x, self.y, "dynamic")
    self.shape = love.physics.newCircleShape(10)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setUserData(self)
    self.body:setFixedRotation(true)

    x = self.x
    y = self.y
    self.body2 = {}
    self.body2.body = love.physics.newBody(current_room.world, x, y - 50, "dynamic")
    self.body2.shape = love.physics.newRectangleShape(0, 0, 20, 55)
    self.body2.fixture = love.physics.newFixture(self.body2.body, self.body2.shape, 1)
    self.body2.fixture:setUserData(self.body2)
    love.physics.newPrismaticJoint(self.body, self.body2.body, x, y - 50, 0, -1, false)
    self.body2.body:setFixedRotation(true)
    --love.physics.newWheelJoint(player.body, player_body.body, x, y - 20, 0, -1, false)
    --love.physics.newDistanceJoint(player.body, player_body.body, x, y, x, y-40, false)

end

function Player:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.x = 650/2
    o.y = 650/2
    o.z = 1
    o.p = 1
    o.speed = 100
    o.current_animation = anims.standing
    --o.show_bbox = true
    o.touching_ground = false
    o.last_jump_time = 0
    o.last_room_change_time = 0
    o.last_attack = 0
    o.facing_direction = 1
    o.weapon_reach = 50

    o:new_bbox()

    return o
end

function Player:change_room(door)
    self.body:destroy()
    self.body2.body:destroy()

    me = current_room.map.layers.Objects.objects[self]
    current_room.map.layers.Objects.objects[self] = nil

    current_room = door.room
    current_room.map.layers.Objects.objects[self] = me

    self.x = door.x
    self.y = door.y

    self:new_bbox()
    self.last_room_change_time = 1 + love.timer.getTime()
    camera:setX(self.x - windowWidth / 2)--, self.y - windowHeight / 1.5)
end

function Player:update(dt)
    self.x = self.body:getX()
    self.y = self.body:getY()

    -- change animation speed according to ground speed
    local x, y = self.body:getLinearVelocity()
    self.current_animation:setSpeed(math.min(math.abs(x) / 60, 1.4))

    self.current_animation:update(dt)

    if love.keyboard.isDown("right") then
        self.body:applyForce(self.speed, 0)
        self.p = 1
        self.z = 1
        self.current_animation = anims.walking
        self.facing_direction = 1
    elseif love.keyboard.isDown("left") then
        self.body:applyForce(-self.speed, 0)
        self.p = 1
        self.z = -1
        self.current_animation = anims.walking
        self.facing_direction = -1
    else
        self.current_animation = anims.standing
    end

    if love.keyboard.isDown("z") then
        self:attack()
    end

    for id, obj in pairs(current_room.map.layers.Objects.objects) do
        if obj.type == "door" or obj.type == "downstairs" or obj.type == "upstairs" then
            if love.keyboard.isDown("up") then
                x,y = self.body:getWorldCenter()
                d = distance(x, y, obj.x + obj.width/2, obj.y + obj.height/2)
                if d < 20 and self.last_room_change_time < love.timer.getTime() then
                    self:change_room(obj.target_door)
                    return
                end
            end
        elseif obj.type == "goldbar" then
            x,y = self.body:getWorldCenter()
            d = distance(x, y, obj.x + obj.width/2, obj.y + obj.height/2)
            if d < 20 then
                obj = current_room.map.layers.Objects.objects[id]
                current_room.lightWorld:remove(obj.light)
                current_room.map.layers.Objects.objects[id] = nil
            end
        end
    end

    if love.keyboard.isDown("up") then
        if self.touching_ground and self.last_jump_time < love.timer.getTime() then
            local jump_power = 40
            self.last_jump_time = 1.0 + love.timer.getTime()
            self.touching_ground = false
            self.body:applyLinearImpulse(0, -jump_power)
            self.body2.body:applyLinearImpulse(0, -jump_power)
        end
    end

    if love.keyboard.isDown("down") then
        self.current_animation = anims.crouching
    end
end

function Player:attack()
    if love.timer.getTime() < self.last_attack then
        return
    end

    self.last_attack = 0.5 + love.timer.getTime()

    self.current_animation = anims.attacking
    for k, obj in pairs(current_room.map.layers.Objects.objects) do
        if obj.o and obj.o.takedamage then
            x,y = self.body:getWorldCenter()
            d = distance(x + self.facing_direction * self.weapon_reach, y, obj.o.x + obj.width/2, obj.o.y + obj.height/2)
            if d < 50 then
                obj.o:takedamage(50)
                if obj.o.hp < 0 then
                    obj.o:kill()
                    current_room.map.layers.Objects.objects[k] = nil
                end
            end
        end
    end
end
