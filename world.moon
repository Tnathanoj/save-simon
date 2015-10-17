LightWorld = require 'light'
sti = require 'sti'

export ^
export load_levels

windowWidth = 640
windowHeight = 480


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
shuffleTable = (t) ->
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
        object_create(obj, room)

    shuffleTable(room.map.layers.Objects.objects)

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


connect_level_doors = (level) ->
    -- get the doors from start first
    start_doors = {}
    for door in room_unused_doors(level.rooms["start"])
        table.insert(start_doors, door)

    -- get the rest of the doors
    doors = {}
    for _, room in pairs(level.rooms)
        for door in room_unused_doors(room)
            table.insert(doors, door)

    -- here's your procedural generation
    shuffleTable(doors)

    -- insert start doors at front
    for _, door in pairs(start_doors)
        table.insert(doors, 1, door)

    -- TODO: this algorithm sucks, needs some love
    door = table.remove(doors, 1)
    while 0 < #doors
        for i, door2 in ipairs(doors)
            if door2.room != door.room
                print("connected " .. door.room.path .. " to " .. door2.room.path)
                table.remove(doors, i)
                door2.target_door = door
                door.target_door = door2
                break
        door = table.remove(doors, 1)

    return door


connect_doors = (levels) ->
    last_stair = nil
    for _, level in pairs(levels)
    --for i=1, 9, 1 do
        --local level = levels[i]
        --print(i)
        --print(level)
        -- Hook up stair case from previous level 
        if last_stair
           for door in room_unused_doors(level.rooms["start"])
               door.type = 'upstairs'
               door.target_door = last_stair
               door.img = love.graphics.newImage("assets/gfx/upstairs.png")

               last_stair.type = 'downstairs'
               last_stair.target_door = door
               last_stair.img = love.graphics.newImage("assets/gfx/downstairs.png")
               break

        last_stair = connect_level_doors(level)


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

    return levels
