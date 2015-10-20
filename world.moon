LightWorld = require 'light'
sti = require 'sti'

export ^
export load_levels

windowWidth = 640
windowHeight = 480


first_from_iter = (iter) ->
    for item in iter
        return item


getPolygonVertices = (object, tile, precalc) ->
    ox, oy = 0, 0

    ox = object.x
    oy = object.y

    vertices = {}
    for _, vertex in ipairs(object.polygon)
        table.insert(vertices, tile.x + ox + vertex.x)
        table.insert(vertices, tile.y + oy + vertex.y)
    return vertices


-- http://coronalabs.com/blog/2014/09/30/tutorial-how-to-shuffle-table-items/
shuffle_table = (t) ->
    rand = math.random 
    iterations = #t
    j
    for i = iterations, 2, -1
        j = rand(i)
        t[i], t[j] = t[j], t[i]


-- @return item from list that has a key with the same value
item_with_key_value = (tbl, key, val) ->
    for idx, i in pairs(tbl)
        for k, v in pairs(i)
            if k == key and v == val then
                return i, idx
    return nil


allPolygons = (object, tile) ->
    _allPolygons = ->
        o =
            shape: object.shape,
            x: object.x,
            y: object.y,
            w: object.width,
            h: object.height,
            polygon: object.polygon or object.polyline or object.ellipse or object.rectangle

        t = { x:0, y:0 }
        if tile
            t = tile

        if o.shape == "rectangle"
            o.r = object.rotation or 0
            cos = math.cos(math.rad(o.r))
            sin = math.sin(math.rad(o.r))

            o.polygon = {
                { x:o.x,		y:o.y },
                { x:o.x + o.w,	y:o.y },
                { x:o.x + o.w,	y:o.y + o.h },
                { x:o.x,		y:o.y + o.h },
            }

            vertices = getPolygonVertices(o, t, true)
            coroutine.yield(vertices)
        elseif o.shape == "polygon"
            vertices= getPolygonVertices(o, t, true)
            coroutine.yield(vertices)
    return coroutine.wrap(_allPolygons)


load_normal_map = (room) ->
    --lightMouse = room.lightWorld\newLight(windowWidth / 2, windowHeight / 2, 255, 255, 255)--, 300)

    layer = room.map.layers['NormalMap']
    w = love.graphics.getWidth()
    h = love.graphics.getHeight()
    tw = 32
    th = 32
    bw = math.ceil(w / tw)
    bh = math.ceil(h / th)

    if bw < 20
        bw = 20 

    if bh < 20
        bh = 20 

    for y = 1, layer.height, 1
        by = math.ceil(y / bh)

        for x = 1, layer.width
            tile = layer.data[y][x]

            --tile = layer.data[y][x]
            bx = math.ceil(x / bw)

            if not tile
                continue

            ts = room.map.tilesets[tile.tileset]
            image = room.map.tilesets[tile.tileset].image
            image2 = room.map.tilesets[1].image

            tx = x * tw
            ty = y * th

            tile.x = tx
            tile.y = ty

            -- Compensation for scale/rotation shift
            if tile.sx	< 0
                tx = tx + tw
            if tile.sy	< 0
                ty = ty + th
            if tile.r	> 0
                tx = tx + tw
            if tile.r	< 0
                ty = ty + th

            ts_tile, _ = item_with_key_value(ts.tiles, 'id', tile.id)

            if ts_tile == nil or ts_tile.objectGroup == nil
                continue

            for _, obj in pairs(ts_tile.objectGroup.objects)
                for poly in allPolygons(obj, {x:tx-32, y:ty-32})
                    r = room.lightWorld\newPolygon(unpack(poly))
                    -- 10 is the number of tiles that make up a tileset row
                    x1 = tile.id % 10
                    y1 = (tile.id - tile.id % 10) / 10
                    r\setNormalMap2(image, x1, y1, 32, 32)


new_room = (map_file, object_create) ->
    room = {}
    room.path = map_file
    room.map = sti.new(map_file)
    room.world = love.physics.newWorld(0, 9.81 * 64, true)
    room.world\setCallbacks(beginContact, endContact, preSolve, postSolve)
    room.collision = room.map\initWorldCollision(room.world)

    -- create light world
    room.lightWorld = LightWorld()
    room.lightWorld\setAmbientColor(0, 0, 0)
    room.lightWorld\setRefractionStrength(16.0)
    room.lightWorld\setReflectionVisibility(0.75)

    if room.map.layers['NormalMap']
        load_normal_map(room)

    spriteLayer = room.map.layers["Objects"]

    for k, obj in ipairs(room.map.layers.Objects.objects)
        if obj.type == "door"
            continue
        object_create(obj, room)

    shuffle_table(room.map.layers.Objects.objects)

--    spriteLayer.update = (self, dt) ->
--        for _, obj in pairs(self.objects) do
--            if obj.o and obj.o.update then
--                obj.o\update(dt)

    spriteLayer.draw = (self, dt) ->

    return room


room_unused_doors = (room) ->
    _room_unused_doors = ->
        for _, obj in pairs(room.map.layers.Objects.objects)
            if obj.type == "door" and not obj.used
                obj.room = room
                obj.used = true
                coroutine.yield(obj)
    return coroutine.wrap(_room_unused_doors)


connect_2_rooms = (room1, room2) ->
    d1 = first_from_iter(room_unused_doors(room1))
    if d1 == nil
        print "Does not have doors left", room1.path

    d2 = first_from_iter(room_unused_doors(room2))
    if d2 == nil
        print "Does not have doors left", room2.path

    d1.target_door = d2
    d2.target_door = d1


connect_level_doors = (level) ->

    -- Get everything except for start and end
    rooms = {}
    for name, room in pairs(level.rooms)
        if name == 'start' or name == 'end'
            continue 
        table.insert(rooms, room)

    start = level.rooms["start"]
    endd = level.rooms["end"]

    -- Connect start to all other rooms
    cur = start
    for _, room in pairs(rooms)
        connect_2_rooms(cur, room)
        cur = room

    -- Link up with end
    connect_2_rooms(cur, endd)

    last_door = first_from_iter(room_unused_doors(endd))

    -- Connect the rest of the doors

    doors = {}
    for name, room in pairs(level.rooms)
        for door in room_unused_doors(room)
            table.insert(doors, door)

    if 1 < #doors
        d1 = table.remove(doors, 1)
        d2 = table.remove(doors, 1)
        if d2.room != d1.room
            --print("connected " .. d1.room.path .. " to " .. d2.room.path)
            d1.target_door = d2
            d2.target_door = d1
        else
            table.insert(doors, d2)

    return last_door


connect_doors = (levels) ->
    i = 1
    last_stair = nil
    for _, level in pairs(levels)
        -- Hook up stair case from previous level 
        if last_stair
           door = first_from_iter(room_unused_doors(level.rooms["start"]))
           door.type = 'upstairs'
           door.target_door = last_stair

           last_stair.type = 'downstairs'
           last_stair.target_door = door

        -- Special case: first_from_iter level is special
        if 1 == i
            last_stair = first_from_iter(room_unused_doors(level.rooms["start"]))
        else
            last_stair = connect_level_doors(level)
        i += 1


load_levels = (object_create) ->
    levels = {}
    files = love.filesystem.getDirectoryItems("assets")
    for k, file in ipairs(files)
        room_level, room_name = string.match(file, "level(%d+)_(%a+).lua")
        room_level = tonumber(room_level)
        if room_level
            if levels[room_level] == nil
                levels[room_level] = {rooms: {}}
            print("loading " .. room_level .. "_" .. room_name)
            map_file_name = "assets/level" .. room_level .. "_" .. room_name
            levels[room_level].rooms[room_name] = new_room(map_file_name, object_create)

    connect_doors(levels)

    -- Inject doors into game
    for _, level in pairs(levels)
        for _, room in pairs(level.rooms)
            for _, obj in ipairs(room.map.layers.Objects.objects)
                if (obj.type == "door" or obj.type == "upstairs" or obj.type == "downstairs") and obj.target_door != nil
                    object_create(obj, room)

    return levels
