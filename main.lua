require("AnAl")
local actor = require("luactor")
require("actor")
require("world")
require('camera')
local vector = require('vector')
local game_over_font_h = 50
local anim
anim = function(path, x, y, speed, a, b)
  return newAnimation(love.graphics.newImage(path), x, y, speed, a, b)
end
local current_room = { }
local newbbox
newbbox = function(o)
  o.body = love.physics.newBody(o.room.world, o.x, o.y, "dynamic")
  o.shape = love.physics.newCircleShape(o.bbox_radius)
  o.fixture = love.physics.newFixture(o.body, o.shape, 1)
  o.fixture:setUserData(o)
  o.fixture:setFriction(o.friction)
  return o.body:setMass(5)
end
local newbbox_quad
newbbox_quad = function(o)
  o.body = love.physics.newBody(o.room.world, o.x, o.y, "dynamic")
  o.shape = love.physics.newRectangleShape(0, 0, 9, 28)
  o.fixture = love.physics.newFixture(o.body, o.shape, 1)
  o.fixture:setUserData(o)
  o.fixture:setFriction(o.friction)
  return o.body:setMass(5)
end
local newbbox_prismatic
newbbox_prismatic = function(o)
  o.body2 = love.physics.newBody(o.room.world, o.x, o.y - 40, "dynamic")
  o.shape2 = love.physics.newRectangleShape(0, 0, 10, 64)
  o.fixture2 = love.physics.newFixture(o.body2, o.shape2, 1)
  return o.body2:setFixedRotation(true)
end
local steppers = { }
do
  local _base_0 = {
    remove = function(self, msg, sender)
      for key, obj in pairs(steppers) do
        if obj == self then
          table.remove(steppers, key)
        end
      end
    end,
    set_vel = function(self, msg, sender)
      self.x_vel = msg[1]
      self.y_vel = msg[2]
    end,
    step = function(self, dt, sender)
      self.x = self.x + (self.x_vel * dt)
      self.y = self.y + (self.y_vel * dt)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.x_vel = 0
      self.y_vel = 0
      return table.insert(steppers, self)
    end,
    __base = _base_0,
    __name = "Stepper"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Stepper = _class_0
end
local damageables = { }
do
  local _base_0 = {
    remove = function(self, msg, sender)
      for key, obj in pairs(damageables) do
        if obj == self then
          table.remove(damageables, key)
        end
      end
    end,
    dmg = function(self, msg, sender)
      self.hp = self.hp - msg.pts
      if self.hp <= 0 then
        actor.send(self.id, "die", "you're dead")
        return actor.send(self.id, "remove")
      end
    end,
    hp = function(self, msg, sender)
      self.hp = self.hp + msg.pts
      if self.hp_max < self.hp then
        self.hp = self.hp_max
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.hp = 50
      self.hp_max = 100
      return table.insert(damageables, self)
    end,
    __base = _base_0,
    __name = "Damageable"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Damageable = _class_0
end
do
  local _base_0 = {
    touch = function(self, msg, sender)
      return actor.send(sender.id, 'dmg', {
        pts = self.dmg_pts
      })
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "PainfulTouch"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Touchable'
  }
  PainfulTouch = _class_0
end
do
  local _base_0 = {
    set_pos = function(self, msg, sender)
      self.x = msg[1]
      self.y = msg[2]
    end,
    set_room = function(self, msg, sender)
      self.room = msg
    end,
    enter_room = function(self, msg, sender)
      if self.last_room_change_time < love.timer.getTime() then
        self.last_room_change_time = 1 + love.timer.getTime()
        local tdoor = msg.door.world_obj.target_door
        current_room = tdoor.room
        actor.send(self.id, 'set_pos', {
          tdoor.x,
          tdoor.y
        })
        return actor.send(self.id, 'set_room', tdoor.room)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.x = 0
      self.y = 100
      self.room = current_room
      self.last_room_change_time = 0
    end,
    __base = _base_0,
    __name = "RoomOccupier"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  RoomOccupier = _class_0
end
do
  local _base_0 = {
    dmg = function(self, msg, sender)
      local b = Blood()
      return actor.send(b.id, 'set_pos', {
        self.x,
        self.y
      })
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Bleeds"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Bleeds = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      if 80 < math.abs(self.x_vel) then
        return actor.send(self.id, 'enqueue_anim', {
          anim = self.anims['walking']
        })
      else
        return actor.send(self.id, 'enqueue_anim', {
          anim = self.anims['standing']
        })
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Walker"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Animated'
  }
  Walker = _class_0
end
do
  local _parent_0 = Walker
  local _base_0 = {
    step = function(self, dt, sender)
      if not self.touching_ground then
        return actor.send(self.id, 'enqueue_anim', {
          anim = self.anims['jumping']
        })
      else
        return _parent_0.step(self, dt, sender)
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "WalkerJumper",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Animated'
  }
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  WalkerJumper = _class_0
end
do
  local _base_0 = {
    cmd_down = function(self, dt, sender)
      self.crouching = true
      return actor.send(self.id, 'set_anim', 'crouching')
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.crouching = false
    end,
    __base = _base_0,
    __name = "Croucher"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Animated'
  }
  Croucher = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      self.yvel = self.yvel + (100 * dt)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Falls"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Stepper'
  }
  Falls = _class_0
end
do
  local _base_0 = {
    die = function(self, msg, sender)
      return print('dead!!!')
    end,
    cmd_shoot = function(self, msg, sender)
      return print('cmd shoot!!!')
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Shooter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Shooter = _class_0
end
do
  local _base_0 = {
    click = function(self, msg, sender)
      actor.send(self.id, 'set_pos', msg)
      return actor.send(self.id, 'set_vel', {
        0,
        0
      })
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "MouseTeleporter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  MouseTeleporter = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      local x, y = love.mouse.getPosition()
      x = x + camera._x
      y = y + camera._y
      if self.x < x then
        return actor.send(self.id, 'cmd_right')
      elseif self.x > x then
        return actor.send(self.id, 'cmd_left')
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "MouseFollower"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Stepper'
  }
  MouseFollower = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      self.target = d
      if self.x < d.x then
        return actor.send(self.id, 'cmd_right')
      elseif self.x > d.x then
        return actor.send(self.id, 'cmd_left')
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "PlayerFollower"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Stepper'
  }
  PlayerFollower = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      if 0 < self.x_vel then
        self.facing_direction = 1
      end
      if self.x_vel < 0 then
        self.facing_direction = -1
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.facing_direction = 1
    end,
    __base = _base_0,
    __name = "FacesDirectionByVelocity"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Stepper'
  }
  FacesDirectionByVelocity = _class_0
end
do
  local _base_0 = {
    cmd_right = function(self, msg, sender)
      self.facing_direction = 1
    end,
    cmd_left = function(self, msg, sender)
      self.facing_direction = -1
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.facing_direction = 1
    end,
    __base = _base_0,
    __name = "FacesDirection"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  FacesDirection = _class_0
end
do
  local _base_0 = {
    draw_start = function(self, msg, sender)
      return love.graphics.setColor(255, 0, 0)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Burning"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Burning = _class_0
end
do
  local _base_0 = {
    draw_start = function(self, msg, sender)
      return love.graphics.setColor(0, 255, 0)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Poisoned"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Poisoned = _class_0
end
local drawables = { }
do
  local _base_0 = {
    remove = function(self, msg, sender)
      for key, obj in pairs(drawables) do
        if obj == self then
          table.remove(drawables, key)
        end
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      return table.insert(drawables, self)
    end,
    __base = _base_0,
    __name = "Drawable"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Drawable = _class_0
end
do
  local _base_0 = {
    draw = function(self, msg, sender)
      return love.graphics.draw(self.sprite, self.x, self.y)
    end,
    draw_done = function(self, msg, sender)
      return love.graphics.setColor(255, 255, 255)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Sprite"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Drawable'
  }
  Sprite = _class_0
end
do
  local _base_0 = {
    init = function(self, msg, sender)
      local a = {
        0,
        0,
        0,
        0,
        255,
        255,
        255
      }
      local b = {
        0,
        0,
        1,
        0,
        255,
        255,
        255
      }
      local c = {
        0,
        0,
        1,
        1,
        255,
        255,
        255
      }
      local d = {
        0,
        0,
        0,
        1,
        255,
        255,
        255
      }
      self.mesh = love.graphics.newMesh({
        a,
        b,
        c,
        d
      }, self.sprite)
      return self.body:setAngle(90)
    end,
    draw = function(self, msg, sender)
      local x1, y1, x2, y2, x3, y3, x4, y4 = self.body:getWorldPoints(self.shape:getPoints())
      local a = {
        x1,
        y1,
        0,
        0,
        255,
        255,
        255
      }
      local b = {
        x2,
        y2,
        1,
        0,
        255,
        255,
        255
      }
      local c = {
        x3,
        y3,
        1,
        1,
        255,
        255,
        255
      }
      local d = {
        x4,
        y4,
        0,
        1,
        255,
        255,
        255
      }
      self.mesh:setVertices({
        a,
        b,
        c,
        d
      })
      return love.graphics.draw(self.mesh, 0, 0)
    end,
    draw_done = function(self, msg, sender)
      return love.graphics.setColor(255, 255, 255)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "QuadSprite"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Drawable',
    'BBoxedQuad'
  }
  QuadSprite = _class_0
end
do
  local _base_0 = {
    set_anim = function(self, anim, sender)
      self.curr_anim = self.anims[anim]
      self.curr_anim:reset()
      self.curr_anim:setSpeed(1)
      return self.curr_anim:play()
    end,
    enqueue_anim = function(self, msg, sender)
      if self.curr_anim.playing then
        if msg.anim ~= self.curr_anim then
          return table.insert(self.queue, msg)
        end
      end
    end,
    step = function(self, dt, sender)
      self.curr_anim:update(dt)
      if not self.curr_anim.playing then
        anim = table.remove(self.queue)
        if anim then
          self.curr_anim = anim.anim
          self.curr_anim:reset()
          self.curr_anim:setSpeed(1)
          return self.curr_anim:play()
        end
      end
    end,
    draw = function(self, msg, sender)
      return self.curr_anim:draw(self.x - self.facing_direction * 40, self.y - 83, 0, self.facing_direction, 1)
    end,
    draw_done = function(self, msg, sender)
      return love.graphics.setColor(255, 255, 255)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.anims = { }
      self.queue = { }
    end,
    __base = _base_0,
    __name = "Animated"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'FacesDirection',
    'Drawable',
    'Stepper'
  }
  Animated = _class_0
end
local touchers = { }
do
  local _base_0 = {
    remove = function(self, msg, sender)
      for key, obj in pairs(touchers) do
        if obj == self then
          table.remove(touchers, key)
        end
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      return table.insert(touchers, self)
    end,
    __base = _base_0,
    __name = "Toucher"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Toucher = _class_0
end
local activatables = { }
do
  local _base_0 = {
    remove = function(self, msg, sender)
      for key, obj in pairs(activatables) do
        if obj == self then
          table.remove(activatables, key)
        end
      end
    end,
    activate = function(self, msg, sender) end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      return table.insert(activatables, self)
    end,
    __base = _base_0,
    __name = "Activatable"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Activatable = _class_0
end
local distance
distance = function(x1, y1, x2, y2)
  return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end
local easeOutQuad
easeOutQuad = function(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end
do
  local _base_0 = {
    step = function(self, msg, sender)
      for key, o in pairs(touchers) do
        local _continue_0 = false
        repeat
          if o.room ~= self.room then
            _continue_0 = true
            break
          end
          if 32 < distance(self.x, self.y, o.x, o.y) then
            _continue_0 = true
            break
          end
          if (function()
            local _base_1 = o
            local _fn_0 = _base_1.id
            return function(...)
              return _fn_0(_base_1, ...)
            end
          end)() == self.id then
            _continue_0 = true
            break
          end
          actor.send(self.id, 'touch', o.id)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Touchable"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Stepper'
  }
  Touchable = _class_0
end
do
  local _base_0 = {
    touch = function(self, msg, sender)
      return actor.send(msg, 'hp', {
        pts = 10
      })
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Hpbonus"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Hpbonus = _class_0
end
do
  local _base_0 = {
    touch = function(self, msg, sender)
      return actor.send(msg, "mixout", "Poisoned")
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Cure"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Cure = _class_0
end
do
  local _base_0 = {
    touch = function(self, msg, sender)
      return actor.send(msg, "mixin", "Poisoned")
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Poison"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Poison = _class_0
end
do
  local _base_0 = {
    touch = function(self, msg, sender)
      return actor.send(self.id, "remove")
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Pickupable"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Pickupable = _class_0
end
do
  local _base_0 = {
    cmd_attack = function(self, msg, sender)
      if love.timer.getTime() < self.last_attack + self.attack_cooldown_time then
        return 
      end
      self.last_attack = love.timer.getTime()
      for key, o in pairs(damageables) do
        local _continue_0 = false
        repeat
          if o.room ~= self.room then
            _continue_0 = true
            break
          end
          if o.id == self.id then
            _continue_0 = true
            break
          end
          if o.faction == self.faction then
            _continue_0 = true
            break
          end
          if self.attack_range < distance(self.x, self.y, o.x, o.y) then
            _continue_0 = true
            break
          end
          actor.send(o.id, 'dmg', {
            pts = self.dmg_pts
          })
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      return actor.send(self.id, 'set_anim', 'attacking')
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.last_attack = 0
      self.attack_cooldown_time = 0.3
      self.dmg_pts = 25
      self.attack_range = 80
    end,
    __base = _base_0,
    __name = "Attacker"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Animated',
    'FacesDirection'
  }
  Attacker = _class_0
end
do
  local _base_0 = {
    cmd_secondary = function(self, msg, sender)
      if love.timer.getTime() < self.last_throw + self.throw_cooldown_time then
        return 
      end
      self.last_throw = love.timer.getTime()
      local b = ThrowingKunai()
      actor.send(b.id, 'set_pos', {
        self.x + 40 * self.facing_direction,
        self.y - 60
      })
      return actor.send(b.id, 'set_vel', {
        3000 * self.facing_direction,
        0
      })
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.last_throw = 0
      self.throw_cooldown_time = 0.3
    end,
    __base = _base_0,
    __name = "Thrower"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Animated',
    'FacesDirection'
  }
  Thrower = _class_0
end
do
  local _base_0 = {
    cmd_up = function(self, msg, sender)
      if love.timer.getTime() < self.last_activate + 1 then
        return 
      end
      for key, a in pairs(activatables) do
        local _continue_0 = false
        repeat
          if a.room ~= self.room then
            _continue_0 = true
            break
          end
          if distance(self.x, self.y, a.x, a.y) > 40 then
            _continue_0 = true
            break
          end
          if (function()
            local _base_1 = a
            local _fn_0 = _base_1.id
            return function(...)
              return _fn_0(_base_1, ...)
            end
          end)() == self.id then
            _continue_0 = true
            break
          end
          actor.send(a.id, 'activate')
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.last_activate = 0
    end,
    __base = _base_0,
    __name = "Activator"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Activator = _class_0
end
do
  local _base_0 = {
    cmd_right = function(self, msg, sender)
      if self.touching_ground then
        return actor.send(self.id, 'move_right', self.walk_speed)
      else
        return actor.send(self.id, 'move_right', self.walk_speed * 0.2)
      end
    end,
    cmd_left = function(self, msg, sender)
      if self.touching_ground then
        return actor.send(self.id, 'move_left', self.walk_speed)
      else
        return actor.send(self.id, 'move_left', self.walk_speed * 0.2)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.hspeed = 200
      self.walk_speed = 100
    end,
    __base = _base_0,
    __name = "Controlled"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Animated',
    'Stepper',
    'TouchingGroundChecker'
  }
  Controlled = _class_0
end
local sign
sign = function(x)
  if x < 0 then
    return -1
  else
    return 1
  end
end
local clamp_velocity
clamp_velocity = function(x_vel, y_vel, body, max_speed)
  if max_speed < math.abs(x_vel) then
    return body:setLinearVelocity(sign(x_vel) * max_speed, y_vel)
  end
end
local clamp_camera
clamp_camera = function(self)
  local left_hand_side = 0
  local right_hand_side = current_room.map.width * current_room.map.tilewidth - windowWidth
  if self._x < left_hand_side then
    self._x = left_hand_side
  elseif right_hand_side < self._x then
    self._x = right_hand_side
  end
end
do
  local _base_0 = {
    init = function(self, msg, sender)
      return newbbox_prismatic(self)
    end,
    step = function(self, dt, sender)
      if not self.prismatic_connected then
        self.prismatic_connected = true
        return love.physics.newPrismaticJoint(self.body, self.body2, self.x, self.y - 50, 0, -1, false)
      end
    end,
    set_vel = function(self, msg, sender)
      return self.body2:applyLinearImpulse(msg[1], msg[2])
    end,
    move_right = function(self, speed, sender)
      return self.body2:applyLinearImpulse(speed, 0)
    end,
    move_left = function(self, speed, sender)
      return self.body2:applyLinearImpulse(-speed, 0)
    end,
    set_pos = function(self, msg, sender)
      self.body2:setX(msg[1])
      return self.body2:setY(msg[2])
    end,
    set_room = function(self, msg, sender)
      self.body2:destroy()
      newbbox_prismatic(self)
      self.prismatic_connected = false
    end,
    remove = function(self, msg, sender)
      return self.body2:destroy()
    end,
    draw = function(self, dt, sender)
      return love.graphics.polygon("fill", self.body2:getWorldPoints(self.shape2:getPoints()))
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.prismatic_connected = false
    end,
    __base = _base_0,
    __name = "PlayerBBoxed"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'BBoxed'
  }
  PlayerBBoxed = _class_0
end
do
  local _base_0 = {
    init = function(self, msg, sender)
      return newbbox_quad(self)
    end,
    step = function(self, dt, sender)
      self.x = self.body:getX()
      self.y = self.body:getY()
      self.x_vel, self.y_vel = self.body:getLinearVelocity()
      return clamp_velocity(self.x_vel, self.y_vel, self.body, self.speed_max)
    end,
    set_vel = function(self, msg, sender)
      return self.body:applyLinearImpulse(msg[1], msg[2])
    end,
    move_right = function(self, speed, sender)
      return self.body:applyLinearImpulse(speed, 0)
    end,
    move_left = function(self, speed, sender)
      return self.body:applyLinearImpulse(-speed, 0)
    end,
    set_pos = function(self, msg, sender)
      self.body:setX(msg[1])
      return self.body:setY(msg[2])
    end,
    set_room = function(self, msg, sender)
      self.body:destroy()
      return newbbox_quad(self)
    end,
    remove = function(self, msg, sender)
      return self.body:destroy()
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.friction = 6
      self.bbox_radius = 10
      self.speed_max = 300
    end,
    __base = _base_0,
    __name = "BBoxedQuad"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BBoxedQuad = _class_0
end
do
  local _base_0 = {
    init = function(self, msg, sender)
      return newbbox(self)
    end,
    step = function(self, dt, sender)
      self.x = self.body:getX()
      self.y = self.body:getY()
      self.x_vel, self.y_vel = self.body:getLinearVelocity()
      return clamp_velocity(self.x_vel, self.y_vel, self.body, self.speed_max)
    end,
    set_vel = function(self, msg, sender)
      return self.body:applyLinearImpulse(msg[1], msg[2])
    end,
    move_right = function(self, speed, sender)
      return self.body:applyLinearImpulse(speed, 0)
    end,
    move_left = function(self, speed, sender)
      return self.body:applyLinearImpulse(-speed, 0)
    end,
    set_pos = function(self, msg, sender)
      self.body:setX(msg[1])
      return self.body:setY(msg[2])
    end,
    set_room = function(self, msg, sender)
      self.body:destroy()
      return newbbox(self)
    end,
    remove = function(self, msg, sender)
      return self.body:destroy()
    end,
    draw = function(self, dt, sender)
      return love.graphics.circle("fill", self.x, self.y, self.bbox_radius)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.friction = 6
      self.bbox_radius = 10
      self.speed_max = 300
    end,
    __base = _base_0,
    __name = "BBoxed"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BBoxed = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      local contacts = self.body:getContactList()
      for _, o in pairs(contacts) do
        if o:isTouching() then
          if not self.touching_ground then
            actor.send(self.id, 'touch_ground')
          end
          self.touching_ground = true
          return 
        end
      end
      self.touching_ground = false
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.touching_ground = false
    end,
    __base = _base_0,
    __name = "TouchingGroundChecker"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'BBoxed'
  }
  TouchingGroundChecker = _class_0
end
do
  local _base_0 = {
    cmd_up = function(self, msg, sender)
      if self.touching_ground and self.last_jump_time + self.jump_cooldown < love.timer.getTime() then
        self.last_jump_time = love.timer.getTime()
        return self.body:applyLinearImpulse(0, -self.jump_impulse)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.last_jump_time = 0
      self.jump_impulse = 2000
      self.jump_cooldown = 0.3
    end,
    __base = _base_0,
    __name = "Jumper"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'TouchingGroundChecker'
  }
  Jumper = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(Damageable)
      self:_mixin(RoomOccupier)
      self:_mixin(MouseTeleporter)
      self:_mixin(Animated)
      self:_mixin(WalkerJumper)
      self:_mixin(Croucher)
      self:_mixin(Attacker)
      self:_mixin(Toucher)
      self:_mixin(PlayerBBoxed)
      self:_mixin(TouchingGroundChecker)
      self:_mixin(Jumper)
      self:_mixin(Activator)
      self:_mixin(Bleeds)
      self:_mixin(RunSmokey)
      self:_mixin(Controlled)
      self:_mixin(Thrower)
      self.anims['walking'] = anim("assets/gfx/manwalking.png", 80, 103, .175, 1, 0)
      self.anims["walking"]:setMode('once')
      self.anims["standing"] = anim("assets/gfx/manstanding.png", 80, 103, .15, 1, 1)
      self.anims["standing"]:setMode('once')
      self.anims["attacking"] = anim("assets/gfx/manattacking2.png", 96, 103, .055, 1, 0)
      self.anims["attacking"]:setMode('once')
      self.anims["crouching"] = anim("assets/gfx/mancrouching.png", 80, 103, 0.5, 1, 0)
      self.anims["crouching"]:setMode('once')
      self.anims['jumping'] = anim("assets/gfx/manjumping.png", 80, 103, .175, 1, 0)
      self.anims["jumping"]:setMode('once')
      actor.send(self.id, 'set_anim', 'walking')
      self.room = current_room
      self.faction = 'good'
      self.hp = 100
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Player",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Player = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      if self.short_lived_start_time + self.var_short_lived_life_time < love.timer.getTime() then
        return actor.send(self.id, "remove")
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.var_short_lived_life_time = 0.3
      self.short_lived_start_time = love.timer.getTime()
    end,
    __base = _base_0,
    __name = "ShortLived"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  ShortLived = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      return self.blood:update(dt)
    end,
    draw = function(self, msg, sender)
      return love.graphics.draw(self.blood, self.x, self.y - 30)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      local bloodimg = love.graphics.newImage("assets/gfx/blood_puffy.png")
      self.blood = love.graphics.newParticleSystem(bloodimg, 100)
      self.blood:setParticleLifetime(0.5, 1)
      self.blood:setEmissionRate(5)
      self.blood:setSizeVariation(1)
      self.blood:setLinearAcceleration(-100, 60, 100, 60)
      self.blood:setRotation(-4, 4)
      return self.blood:setColors(255, 255, 255, 255, 255, 255, 255, 0)
    end,
    __base = _base_0,
    __name = "Bloody"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Drawable'
  }
  Bloody = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      self.ps:update(dt)
      return self.ps:setPosition(self.x, self.y + 10)
    end,
    draw = function(self, msg, sender)
      return love.graphics.draw(self.ps)
    end,
    touch_ground = function(self, msg, sender)
      return self.ps:emit(1)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      local img = love.graphics.newImage("assets/gfx/smoke_breathable.png")
      self.ps = love.graphics.newParticleSystem(img, 100)
      self.ps:setParticleLifetime(1, 1)
      self.ps:setSizes(0.5, 0.25, 0.12, 0.06)
      self.ps:setLinearAcceleration(-20, -20, 20, 20)
      self.ps:setRotation(-20, 20)
      return self.ps:setColors(255, 255, 255, 255, 255, 255, 255, 0)
    end,
    __base = _base_0,
    __name = "RunSmokey"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Drawable'
  }
  RunSmokey = _class_0
end
do
  local _base_0 = {
    step = function(self, dt, sender)
      self.ps:update(dt)
      return self.ps:setPosition(self.x, self.y + 10)
    end,
    draw = function(self, msg, sender)
      return love.graphics.draw(self.ps)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      local img = love.graphics.newImage("assets/gfx/smoke_breathable.png")
      self.ps = love.graphics.newParticleSystem(img, 100)
      self.ps:setParticleLifetime(1, 1)
      self.ps:setEmissionRate(5)
      self.ps:setSizes(0.5, 0.25, 0.12, 0.06)
      self.ps:setLinearAcceleration(-20, -20, 20, 20)
      self.ps:setRotation(-20, 20)
      return self.ps:setColors(255, 255, 255, 255, 255, 255, 255, 0)
    end,
    __base = _base_0,
    __name = "Smokey"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.needs = {
    'Drawable'
  }
  Smokey = _class_0
end
do
  local _base_0 = {
    touch = function(self, msg, sender)
      return self.body:applyLinearImpulse(0, -5)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Ladderable"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Ladderable = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Touchable)
      return self:_mixin(Ladderable)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Ladder",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Ladder = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Bloody)
      self:_mixin(Stepper)
      return self:_mixin(ShortLived)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Blood",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Blood = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Stepper)
      self:_mixin(BBoxedQuad)
      self:_mixin(ShortLived)
      self:_mixin(QuadSprite)
      self.speed_max = 3000
      self.bbox_radius = 5
      self.sprite = love.graphics.newImage("assets/gfx/kunai.png")
      self.var_short_lived_life_time = 2
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ThrowingKunai",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ThrowingKunai = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Animated)
      self:_mixin(Damageable)
      self:_mixin(PlayerFollower)
      self:_mixin(FacesDirectionByVelocity)
      self:_mixin(Toucher)
      self:_mixin(Attacker)
      self:_mixin(Walker)
      self:_mixin(PlayerBBoxed)
      self:_mixin(Bleeds)
      self.anims['walking'] = anim("assets/gfx/reverant_walking.png", 80, 103, .175, 1, 0)
      self.anims["walking"]:setMode('once')
      self.anims["standing"] = anim("assets/gfx/reverant_standing.png", 80, 103, .15, 1, 1)
      self.anims["standing"]:setMode('once')
      self.anims["attacking"] = anim("assets/gfx/reverant_attacking.png", 80, 103, .15, 1, 1)
      self.anims["attacking"]:setMode('once')
      self.walk_speed_max = 200
      actor.send(self.id, 'set_anim', 'walking')
      self:add_handler("step", Monster.step)
      self.attack_cooldown_time = 1.5
      self.faction = 'bad'
    end,
    step = function(self, dt, sender)
      return actor.send(self.id, 'cmd_attack')
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Monster",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Monster = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Animated)
      self:_mixin(MouseFollower)
      self:_mixin(Damageable)
      self:_mixin(FacesDirectionByVelocity)
      self:_mixin(Attacker)
      self:_mixin(Walker)
      self:_mixin(BBoxed)
      self.anims['walking'] = anim("assets/gfx/imp.png", 64, 64, .175, 1, 0)
      self.anims["standing"] = anim("assets/gfx/imp.png", 64, 64, .15, 1, 0)
      self.walk_speed_max = 100
      actor.send(self.id, 'set_anim', 'walking')
      self.faction = 'bad'
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Imp",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Imp = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self:_mixin(Touchable)
      self:_mixin(Cure)
      self:_mixin(Pickupable)
      self.sprite = love.graphics.newImage("assets/gfx/cure.png")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Antidoteflask",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Antidoteflask = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self:_mixin(Touchable)
      self:_mixin(Poison)
      self:_mixin(Pickupable)
      self.sprite = love.graphics.newImage("assets/gfx/poison.png")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Poisonflask",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Poisonflask = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self:_mixin(Touchable)
      self:_mixin(Pickupable)
      self.sprite = love.graphics.newImage("assets/gfx/goldbar.png")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Goldbar",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Goldbar = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self:_mixin(Touchable)
      self:_mixin(Pickupable)
      self:_mixin(Hpbonus)
      self.sprite = love.graphics.newImage("assets/gfx/turkey.png")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Turkey",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Turkey = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self.sprite = love.graphics.newImage("assets/gfx/jihanki.png")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Vendingmachine",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Vendingmachine = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self:_mixin(Activatable)
      self.sprite = love.graphics.newImage("assets/gfx/door.png")
      return self:add_handler("activate", Door.activate)
    end,
    activate = function(self, msg, sender)
      return actor.send(sender, 'enter_room', {
        ['door'] = self
      })
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Door",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Door = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self.sprite = love.graphics.newImage("assets/gfx/upstairs.png")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Upstairs",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Upstairs = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self.sprite = love.graphics.newImage("assets/gfx/downstairs.png")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Downstairs",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Downstairs = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self)
      self.x = 0
      self.y = 100
    end,
    __base = _base_0,
    __name = "World",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  World = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self)
      self.x = 0
      self.y = 100
    end,
    __base = _base_0,
    __name = "Camera",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Camera = _class_0
end
do
  local _parent_0 = Object
  local _base_0 = {
    mixins = function(self)
      self:_mixin(PainfulTouch)
      self:_mixin(RoomOccupier)
      self:_mixin(Sprite)
      self.sprite = love.graphics.newImage("assets/gfx/spike.png")
      self.dmg_pts = 10000
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Spike",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Spike = _class_0
end
love.mousereleased = function(x, y, button)
  if button == "l" then
    d:_start()
    return actor.send(d.id, 'click', {
      x,
      y
    })
  end
end
local levels = { }
d = { }
windowWidth = 640
windowHeight = 480
local screen_pan_time = 1
local on_level_object_creation
on_level_object_creation = function(o, room)
  current_room = room
  local name = o.type
  name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
  if _G[name] then
    local n = _G[name]()
    n.world_obj = o
    n.name = name
    return actor.send(n.id, 'set_pos', {
      o.x,
      o.y
    })
  end
end
local game_over_font = { }
love.load = function()
  math.randomseed(os.time())
  actor.init()
  game_over_font = love.graphics.newFont("assets/font/joystix.ttf", game_over_font_h)
  local font = game_over_font
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setFont(font)
  love.graphics.setBackgroundColor(0, 0, 0)
  love.window.setMode(windowWidth, windowHeight)
  love.physics.setMeter(32)
  levels = load_levels(on_level_object_creation)
  current_room = levels[1].rooms["start"]
  d = Player()
  local g = Poisonflask()
  local c = Antidoteflask()
  local t = Turkey()
  actor.send(d.id, 'set_pos', {
    400,
    100
  })
  actor.send(d.id, 'cmd_right')
  actor.send(g.id, 'set_pos', {
    200,
    300
  })
  actor.send(c.id, 'set_pos', {
    500,
    300
  })
  return actor.send(t.id, 'set_pos', {
    800,
    300
  })
end
camera_change_time = 0
local update_camera
update_camera = function(dt)
  local cam_org = vector.new(camera._x, camera._y)
  local ent_org = vector.new(d.x - windowWidth / 2, d.y - windowHeight / 1.5)
  local sub = ent_org - cam_org
  sub:normalize_inplace()
  local dist = ent_org:dist(cam_org)
  camera:move(sub.x * dist * dt * 2, 0)
  return clamp_camera(camera)
end
love.update = function(dt)
  if love.keyboard.isDown("right") or love.keyboard.isDown("f") then
    actor.send(d.id, 'cmd_right')
  end
  if love.keyboard.isDown("left") or love.keyboard.isDown("e") then
    actor.send(d.id, 'cmd_left')
  end
  if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
    actor.send(d.id, 'cmd_up')
  end
  if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
    actor.send(d.id, 'cmd_down')
  end
  if love.keyboard.isDown("z") or love.keyboard.isDown("j") then
    actor.send(d.id, 'cmd_attack')
  end
  if love.keyboard.isDown("x") or love.keyboard.isDown("l") then
    actor.send(d.id, 'cmd_secondary')
  end
  for _, o in pairs(steppers) do
    if o.room == current_room then
      actor.send(o.id, 'step', dt)
    end
  end
  actor.run()
  current_room.map:update(dt)
  current_room.world:update(dt)
  update_camera(dt)
  return current_room.lightWorld:update(dt)
end
local draw_hp_bar
draw_hp_bar = function(x, y, edge, w, h, ratio)
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(255, 0, 0)
  return love.graphics.rectangle("fill", x + edge, y + edge, (w - edge * 2) * ratio, h - edge * 2)
end
love.draw = function()
  current_room.lightWorld:setTranslation(-camera._x, -camera._y, 1)
  love.graphics.push()
  love.graphics.translate(-camera._x, -camera._y)
  current_room.lightWorld:draw(function(l, t, w, h, s)
    love.graphics.setColor(255, 255, 255)
    w, h = love.graphics.getWidth() * 4, love.graphics.getHeight() * 2
    love.graphics.rectangle("fill", 0, -500, w, h)
    current_room.map.layers['Tile Layer 1']:draw()
    return current_room.map:drawWorldCollision(current_room.collision)
  end)
  current_room.map.layers['Objects']:draw()
  for _, d in pairs(drawables) do
    if d.room == current_room then
      actor.send(d.id, 'draw_start', dt)
      actor.send(d.id, 'draw', dt)
      actor.send(d.id, 'draw_done', dt)
    end
  end
  actor.run()
  love.graphics.pop()
  draw_hp_bar(10, 10, 2, 100, 10, d.hp / 100)
  if d.hp <= 0 then
    return love.graphics.print("GAME\nOVER", windowWidth / 2 - 4 * game_over_font_h / 2, windowHeight / 3)
  end
end
