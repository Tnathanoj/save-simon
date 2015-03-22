local attack_time = 0.3
local attack_cooldown_time = 1
local walk_speed = 2
local max_walk_speed = 150
do
  local _base_0 = {
    kill = function(self)
      self.body:destroy()
      return self.body2.body:destroy()
    end,
    new_bbox = function(self)
      self.body = love.physics.newBody(self.room.world, self.x, self.y, "dynamic")
      self.shape = love.physics.newCircleShape(10)
      self.fixture = love.physics.newFixture(self.body, self.shape, 1)
      self.fixture:setUserData(self)
      self.body:setFixedRotation(true)
      self.body2 = { }
      self.body2.body = love.physics.newBody(self.room.world, self.x, self.y - 50, "dynamic")
      self.body2.shape = love.physics.newRectangleShape(0, 0, 20, 55)
      self.body2.fixture = love.physics.newFixture(self.body2.body, self.body2.shape, 1)
      self.body2.fixture:setUserData(self)
      love.physics.newPrismaticJoint(self.body, self.body2.body, self.x, self.y - 50, 0, -1, false)
      return self.body2.body:setFixedRotation(true)
    end,
    attack = function(self)
      if love.timer.getTime() < self.last_attack + attack_cooldown_time then
        return 
      end
      self.last_attack = love.timer.getTime()
      self.current_animation = anims.reverant.attacking
      return self.current_animation:reset()
    end,
    apply_monster_cage = function(self)
      if self.x < self.cage.x then
        self.body:setX(self.cage.x + 5)
        self.body:setLinearVelocity(5, 0)
        self.wonder_time = 1 + love.timer.getTime()
        self.facing_direction = self.facing_direction * -1
      elseif self.cage.x + self.cage.width < self.x then
        self.body:setX(self.cage.x + self.cage.width - 5)
        self.body:setLinearVelocity(-5, 0)
        self.wonder_time = 1 + love.timer.getTime()
        self.facing_direction = self.facing_direction * -1
      end
    end,
    update = function(self, dt)
      local x, y = self.body:getLinearVelocity()
      clamp_velocity(x, y, self.body, max_walk_speed)
      self.current_animation:update(dt)
      if self.cage then
        self:apply_monster_cage()
      end
      self.x = self.body:getX()
      self.y = self.body:getY()
      if not self.target then
        for id, obj in pairs(self.room.map.layers.Objects.objects) do
          if obj.type == "player" then
            self.target = obj
          end
        end
      else
        if love.timer.getTime() < self.last_attack + attack_time then
          return self.current_animation:setSpeed(1)
        elseif self.wonder_time < love.timer.getTime() then
          if self.x < self.target.o.x then
            self.body:applyLinearImpulse(walk_speed, 0)
            self.current_animation = anims.reverant.walking
            self.facing_direction = 1
          else
            self.body:applyLinearImpulse(-walk_speed, 0)
            self.current_animation = anims.reverant.walking
            self.facing_direction = -1
          end
        else
          self.body:applyLinearImpulse(walk_speed * self.facing_direction, 0)
          return self.current_animation:setSpeed(math.min(math.abs(x) / 60, 1.4))
        end
      end
    end,
    draw = function(self)
      return self.current_animation:draw(self.x - self.facing_direction * 40, self.y - 83, 0, self.facing_direction, 1)
    end,
    takedamage = function(self, dmg)
      self.hp = self.hp - dmg
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, x, y, room)
      self.hp = 50
      self.img = love.graphics.newImage("assets/gfx/monster.png")
      self.x = x
      self.y = y
      self.room = room
      self.current_animation = anims.reverant.standing
      self.touching_ground = false
      self.target = nil
      self.facing_direction = 1
      self.cage = nil
      self:new_bbox()
      self.wonder_time = 0
      self.last_attack = 0
    end,
    __base = _base_0,
    __name = "Monster"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Monster = _class_0
  return _class_0
end
