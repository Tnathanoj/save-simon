
local jump_power = 40
local crouch_jump_power = jump_power * 1.5
local crouch_jump_time_delay = 0.2
local attack_time = 0.3
local attack_cooldown_time = 0.6
local max_walk_speed = 300

Player = {}

function Player:new_bbox()

    --let's create a ball
    self.body = love.physics.newBody(current_room.world, self.x, self.y, "dynamic")
    self.shape = love.physics.newCircleShape(10)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setUserData(self)
    self.fixture:setFriction(1)
    --self.body:setInertia(100)
    self.body:setFixedRotation(true)

    x = self.x
    y = self.y
    self.body2 = {}
    self.body2.body = love.physics.newBody(current_room.world, x, y - 50, "dynamic")
    self.body2.shape = love.physics.newRectangleShape(0, 0, 20, 45)
    self.body2.fixture = love.physics.newFixture(self.body2.body, self.body2.shape, 1)
    self.body2.fixture:setUserData(self)
    --self.body2.fixture:setFriction(2)
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
    o.speed = 4
    o.current_animation = anims.standing
    o.touching_ground = false
    o.last_touching_ground = 0
    o.last_jump_time = 0
    o.last_room_change_time = 0
    o.last_attack = 0
    o.last_crouch = 0
    o.facing_direction = 1
    o.weapon_reach = 50
    o.hp = 100
    o.shield_hp = 100
    o.gold = 0

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
    camera:setX(self.x - self.x % windowWidth)
end

function Player:jump()

    local power = jump_power

    -- Do crouch jump
    -- TODO: crouch jumping uses lots of FOOD!
    if love.timer.getTime() < self.last_crouch + crouch_jump_time_delay then
        power = crouch_jump_power
    end

    self.last_jump_time = love.timer.getTime()
    self.touching_ground = false
    self.body:applyLinearImpulse(0, -power)
    self.body2.body:applyLinearImpulse(0, -power)

end

function sign(x)
    if x < 0 then
        return -1
    else
        return 1
    end
end

function clamp_velocity(x_vel, y_vel, body, max_speed)
    if max_speed < math.abs(x_vel) then
        body:setLinearVelocity(sign(x_vel) * max_speed, y_vel)
    end
end

function Player:update(dt)
    self.x = self.body:getX()
    self.y = self.body:getY()

    local x, y = self.body:getLinearVelocity()

    clamp_velocity(x, y, self.body, max_walk_speed)

    if self.last_touching_ground < love.timer.getTime() then
        if math.floor(y) == 0 then

        else
            self.touching_ground = false
        end
    end

    self.current_animation:update(dt)

    -- Handle attacking animation    
    if love.timer.getTime() < self.last_attack + attack_time then
        self.current_animation:setSpeed(1)

    -- Handle walking animation    
    elseif 10 < math.abs(x) and self.touching_ground then
        self.current_animation = anims.walking

        -- change animation speed according to ground speed
        self.current_animation:setSpeed(math.min(math.abs(x) / 60, 1.4))

    -- Handle standing animation    
    else
        self.current_animation:setSpeed(1)
        self.current_animation = anims.standing
    end


    if love.timer.getTime() < self.last_attack + attack_time then

    elseif love.keyboard.isDown("right") or love.keyboard.isDown("f") then
        self.body:applyLinearImpulse(self.speed, 0)
        self.current_animation = anims.walking
        self.facing_direction = 1
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("e") then
        self.body:applyLinearImpulse(-self.speed, 0)
        self.current_animation = anims.walking
        self.facing_direction = -1
    end

    if love.keyboard.isDown("z") or love.keyboard.isDown("j")  then
        self:attack()
    end

    for id, obj in pairs(current_room.map.layers.Objects.objects) do
        if obj.type == "door" or obj.type == "downstairs" or obj.type == "upstairs" then
            if love.keyboard.isDown("up") or love.keyboard.isDown("c") then
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
                self.gold = self.gold + 10
                obj = current_room.map.layers.Objects.objects[id]
                current_room.lightWorld:remove(obj.light)
                current_room.map.layers.Objects.objects[id] = nil
            end
        end
    end

    if self.last_room_change_time < love.timer.getTime() and
        (love.keyboard.isDown("up") or love.keyboard.isDown("c")) then
        if self.touching_ground and self.last_jump_time + 1 < love.timer.getTime() then
            self:jump()
        end
    end

    if love.keyboard.isDown("down") or love.keyboard.isDown("d") then
        self.current_animation = anims.crouching
        self.last_crouch = love.timer.getTime()
    end

    if love.keyboard.isDown("1") then
        warp_to_level(self, 1)
    elseif love.keyboard.isDown("2") then
        warp_to_level(self, 2)
    elseif love.keyboard.isDown("3") then
        warp_to_level(self, 3)
    elseif love.keyboard.isDown("4") then
        warp_to_level(self, 4)
    elseif love.keyboard.isDown("5") then
        warp_to_level(self, 5)
    elseif love.keyboard.isDown("6") then
        warp_to_level(self, 6)
    elseif love.keyboard.isDown("7") then
        warp_to_level(self, 7)
    elseif love.keyboard.isDown("8") then
        warp_to_level(self, 8)
    elseif love.keyboard.isDown("9") then
        warp_to_level(self, 9)
    end
end

function warp_to_level(self, level)
    for door in room_doors(levels[level].rooms["start"]) do
        self:change_room(door)
        return 
    end
end

function room_doors(room)
    return coroutine.wrap(function()
    for _, obj in pairs(room.map.layers.Objects.objects) do
        if obj.type == "door" or obj.type == "downstairs" or obj.type == "upstairs" then
            coroutine.yield(obj)
        end
    end
    end)
end

function Player:attack()
    if love.timer.getTime() < self.last_attack + attack_cooldown_time then
        return
    end

    self.last_attack = love.timer.getTime()

    self.current_animation = anims.attacking
    self.current_animation:reset()
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

--function Player:takedamage(dmg)
--    self.hp = self.hp - dmg
--end

function Player:kill()
    self.body:destroy()
    self.body2.body:destroy()
end
