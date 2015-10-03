local actor = require("luactor")
local mixin
mixin = function(self, cls, ...)
  for key, val in pairs(cls.__base) do
    local new_method_name = cls.__name .. key
    if not key:match("^__") then
      self[new_method_name] = val
      self:add_handler(key, val)
    end
  end
  cls.__init(self, ...)
  self.mixed_in[cls] = cls
  if cls.needs ~= nil then
    for _, val in pairs(cls.needs) do
      local val_cls = _G[val]
      if val_cls == nil then
        error("Does not exist: " .. val)
      end
      if not self.mixed_in[val_cls] then
        mixin(self, val_cls)
      end
    end
  end
end
local mixout
mixout = function(self, cls, ...)
  for key, val in pairs(cls.__base) do
    local new_method_name = cls.__name .. key
    if not key:match("^__") then
      self[new_method_name] = nil
      self:remove_handler(key, val)
    end
  end
end
local object_count = 0
objects = { }
do
  local _base_0 = {
    add_handler = function(self, name, method)
      if not self.handlers[name] then
        self.handlers[name] = { }
      end
      return table.insert(self.handlers[name], method)
    end,
    remove_handler = function(self, name, method)
      if self.handlers[name] then
        for key, method_name in pairs(self.handlers[name]) do
          if method_name == method then
            table.remove(self.handlers[name], key)
          end
        end
      end
    end,
    _start = function(self)
      return actor.start(self.actor, self)
    end,
    _think = function(self)
      while true do
        actor.wait(self, self.handlers)
      end
    end,
    _mixin = function(self, cls)
      return mixin(self, cls)
    end,
    mixin = function(self, class_name, sender)
      return self:_mixin(_G[class_name])
    end,
    mixout = function(self, class_name, sender)
      return mixout(self, _G[class_name])
    end,
    remove = function(self, msg, sender)
      for key, obj in pairs(objects) do
        if obj == self then
          table.remove(objects, key)
        end
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self)
      self.mixed_in = { }
      self.handlers = { }
      self.id = tostring(object_count)
      object_count = object_count + 1
      self.actor = actor.create(self.id, self._think)
      self:mixins()
      table.insert(objects, self)
      self:add_handler("mixin", Object.mixin)
      self:add_handler("mixout", Object.mixout)
      self:add_handler("remove", Object.remove)
      return self:_start()
    end,
    __base = _base_0,
    __name = "Object"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Object = _class_0
  return _class_0
end
