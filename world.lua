local LightWorld = require('light')
local sti = require('sti')
local windowWidth = 640
local windowHeight = 480
local getPolygonVertices
getPolygonVertices = function(object, tile, precalc)
  local ox, oy = 0, 0
  ox = object.x
  oy = object.y
  local vertices = { }
  for _, vertex in ipairs(object.polygon) do
    table.insert(vertices, tile.x + ox + vertex.x)
    table.insert(vertices, tile.y + oy + vertex.y)
  end
  return vertices
end
local shuffleTable
shuffleTable = function(t)
  local rand = math.random
  local iterations = #t
  local _ = j
  for i = iterations, 2, -1 do
    local j = rand(i)
    t[i], t[j] = t[j], t[i]
  end
end
local item_with_key_value
item_with_key_value = function(tbl, key, val)
  for idx, i in pairs(tbl) do
    for k, v in pairs(i) do
      if k == key and v == val then
        return i, idx
      end
    end
  end
  return nil
end
local allPolygons
allPolygons = function(object, tile)
  local _allPolygons
  _allPolygons = function()
    local o = {
      shape = object.shape,
      x = object.x,
      y = object.y,
      w = object.width,
      h = object.height,
      polygon = object.polygon or object.polyline or object.ellipse or object.rectangle
    }
    local t = {
      x = 0,
      y = 0
    }
    if tile then
      t = tile
    end
    if o.shape == "rectangle" then
      o.r = object.rotation or 0
      local cos = math.cos(math.rad(o.r))
      local sin = math.sin(math.rad(o.r))
      o.polygon = {
        {
          x = o.x,
          y = o.y
        },
        {
          x = o.x + o.w,
          y = o.y
        },
        {
          x = o.x + o.w,
          y = o.y + o.h
        },
        {
          x = o.x,
          y = o.y + o.h
        }
      }
      local vertices = getPolygonVertices(o, t, true)
      return coroutine.yield(vertices)
    elseif o.shape == "polygon" then
      local vertices = getPolygonVertices(o, t, true)
      return coroutine.yield(vertices)
    end
  end
  return coroutine.wrap(_allPolygons)
end
local load_normal_map
load_normal_map = function(room)
  local layer = room.map.layers['NormalMap']
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  local tw = 32
  local th = 32
  local bw = math.ceil(w / tw)
  local bh = math.ceil(h / th)
  if bw < 20 then
    bw = 20
  end
  if bh < 20 then
    bh = 20
  end
  for y = 1, layer.height, 1 do
    local by = math.ceil(y / bh)
    for x = 1, layer.width do
      local _continue_0 = false
      repeat
        local tile = layer.data[y][x]
        local bx = math.ceil(x / bw)
        if not tile then
          _continue_0 = true
          break
        end
        local ts = room.map.tilesets[tile.tileset]
        local image = room.map.tilesets[tile.tileset].image
        local image2 = room.map.tilesets[1].image
        local tx = x * tw
        local ty = y * th
        tile.x = tx
        tile.y = ty
        if tile.sx < 0 then
          tx = tx + tw
        end
        if tile.sy < 0 then
          ty = ty + th
        end
        if tile.r > 0 then
          tx = tx + tw
        end
        if tile.r < 0 then
          ty = ty + th
        end
        local ts_tile, _ = item_with_key_value(ts.tiles, 'id', tile.id)
        if ts_tile == nil or ts_tile.objectGroup == nil then
          _continue_0 = true
          break
        end
        for _, obj in pairs(ts_tile.objectGroup.objects) do
          for poly in allPolygons(obj, {
            x = tx - 32,
            y = ty - 32
          }) do
            local r = room.lightWorld:newPolygon(unpack(poly))
            local x1 = tile.id % 10
            local y1 = (tile.id - tile.id % 10) / 10
            r:setNormalMap2(image, x1, y1, 32, 32)
          end
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  end
end
local new_room
new_room = function(map_file, object_create)
  local room = { }
  room.path = map_file
  room.map = sti.new(map_file)
  room.world = love.physics.newWorld(0, 9.81 * 64, true)
  room.world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  room.collision = room.map:initWorldCollision(room.world)
  room.lightWorld = LightWorld()
  room.lightWorld:setAmbientColor(0, 0, 0)
  room.lightWorld:setRefractionStrength(16.0)
  room.lightWorld:setReflectionVisibility(0.75)
  if room.map.layers['NormalMap'] then
    load_normal_map(room)
  end
  local spriteLayer = room.map.layers["Objects"]
  shuffleTable(room.map.layers.Objects.objects)
  spriteLayer.draw = function(self, dt) end
  return room
end
local room_unused_doors
room_unused_doors = function(room)
  local _room_unused_doors
  _room_unused_doors = function()
    for _, obj in pairs(room.map.layers.Objects.objects) do
      if obj.type == "door" and not obj.used then
        obj.room = room
        obj.used = true
        coroutine.yield(obj)
      end
    end
  end
  return coroutine.wrap(_room_unused_doors)
end
local connect_level_doors
connect_level_doors = function(level)
  local start_doors = { }
  for door in room_unused_doors(level.rooms["start"]) do
    table.insert(start_doors, door)
  end
  local doors = { }
  for _, room in pairs(level.rooms) do
    for door in room_unused_doors(room) do
      table.insert(doors, door)
    end
  end
  shuffleTable(doors)
  for _, door in pairs(start_doors) do
    table.insert(doors, 1, door)
  end
  local door = table.remove(doors, 1)
  while 0 < #doors do
    for i, door2 in ipairs(doors) do
      if door2.room ~= door.room then
        print("connected " .. door.room.path .. " to " .. door2.room.path)
        table.remove(doors, i)
        door2.target_door = door
        door.target_door = door2
        break
      end
    end
    door = table.remove(doors, 1)
  end
  return door
end
local connect_doors
connect_doors = function(levels)
  local last_stair = nil
  for _, level in pairs(levels) do
    if last_stair then
      for door in room_unused_doors(level.rooms["start"]) do
        door.type = 'upstairs'
        door.target_door = last_stair
        door.img = love.graphics.newImage("assets/gfx/upstairs.png")
        last_stair.type = 'downstairs'
        last_stair.target_door = door
        last_stair.img = love.graphics.newImage("assets/gfx/downstairs.png")
        break
      end
    end
    last_stair = connect_level_doors(level)
  end
end
load_levels = function(object_create)
  local levels = { }
  local files = love.filesystem.getDirectoryItems("assets")
  for k, file in ipairs(files) do
    local room_level, room_name = string.match(file, "level(%d+)_(%a+).lua")
    room_level = tonumber(room_level)
    if room_level then
      if levels[room_level] == nil then
        levels[room_level] = {
          rooms = { }
        }
      end
      print("loading " .. room_level .. "_" .. room_name)
      local map_file_name = "assets/level" .. room_level .. "_" .. room_name
      levels[room_level].rooms[room_name] = new_room(map_file_name, object_create)
    end
  end
  for k, level in pairs(levels) do
    for j, room in pairs(level.rooms) do
      for k, obj in ipairs(room.map.layers.Objects.objects) do
        object_create(obj, room)
      end
    end
  end
  connect_doors(levels)
  return levels
end
