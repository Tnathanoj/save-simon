--- Box2D plugin for STI
-- @module box2d
-- @author Landon Manning
-- @copyright 2015
-- @license MIT/X11

return {
	box2d_LICENSE     = "MIT/X11",
	box2d_URL         = "https://github.com/karai17/Simple-Tiled-Implementation",
	box2d_VERSION     = "2.3.0.2",
	box2d_DESCRIPTION = "Box2D hooks for STI.",

	--- Initialize Box2D physics world.
	-- @param world The Box2D world to add objects to.
	-- @return nil
	box2d_init = function(map, world)
		assert(love.physics, "To use the Box2D plugin, please enable the love.physics module.")

		local body      = love.physics.newBody(world)
		local collision = {
			body = body,
		}

		local function rotateVertex(v, x, y, cos, sin, oy)
			oy = oy or 0

			local vertex = {
				x = v.x,
				y = v.y - oy,
			}

			vertex.x = vertex.x - x
			vertex.y = vertex.y - y

			local vx = cos * vertex.x - sin * vertex.y
			local vy = sin * vertex.x + cos * vertex.y

			return vx + x, vy + y + oy
		end

		local function addObjectToWorld(objshape, vertices, userdata, object)
			local shape

			if objshape == "polyline" then
				shape = love.physics.newChainShape(false, unpack(vertices))
			else
				shape = love.physics.newPolygonShape(unpack(vertices))
			end

			local fixture = love.physics.newFixture(body, shape)

			fixture:setUserData(userdata)

			if userdata.properties.sensor == "true" then
				fixture:setSensor(true)
			end

			local obj = {
				object  = object,
				shape   = shape,
				fixture = fixture,
			}

			table.insert(collision, obj)
		end

		local function getPolygonVertices(object, tile, precalc)
      local ox, oy = 0, 0

      if not precalc then
        ox = object.x
        oy = object.y
      end

			local vertices = {}
			for _, vertex in ipairs(object.polygon) do
				-- table.insert(vertices, vertex.x)
				-- table.insert(vertices, vertex.y)
        table.insert(vertices, tile.x + ox + vertex.x)
        table.insert(vertices, tile.y + oy + vertex.y)
			end

			return vertices
		end

		local function calculateObjectPosition(object, tile)
			local o = {
				shape   = object.shape,
				x       = object.x,
				y       = object.y,
				w       = object.width,
				h       = object.height,
				polygon = object.polygon or object.polyline or object.ellipse or object.rectangle
			}

			local userdata = {
				object     = o,
				properties = object.properties
			}

			if o.shape == "rectangle" then
				o.r       = object.rotation or 0
				local cos = math.cos(math.rad(o.r))
				local sin = math.sin(math.rad(o.r))
				local oy  = 0

				if object.gid then
					local tileset = map.tilesets[map.tiles[object.gid].tileset]
					local lid     = object.gid - tileset.firstgid
					local tile    = {}

					-- This fixes a height issue
					 o.y = o.y + map.tiles[object.gid].offset.y
					 oy  = tileset.tileheight

					for _, t in ipairs(tileset.tiles) do
						if t.id == lid then
							tile = t
							break
						end
					end

					if tile.objectGroup then
						for _, obj in ipairs(tile.objectGroup.objects) do
							-- Every object in the tile
							calculateObjectPosition(obj, object)
						end

						return
					else
						o.w = map.tiles[object.gid].width
						o.h = map.tiles[object.gid].height
					end
				end

				o.polygon = {
					{ x=o.x,       y=o.y       },
					{ x=o.x + o.w, y=o.y       },
					{ x=o.x + o.w, y=o.y + o.h },
					{ x=o.x,       y=o.y + o.h },
				}

				for _, vertex in ipairs(o.polygon) do
					vertex.x, vertex.y = rotateVertex(vertex, o.x, o.y, cos, sin, oy)
				end

				local vertices = getPolygonVertices(o, tile, true)
				addObjectToWorld(o.shape, vertices, userdata, tile or object)
			elseif o.shape == "polygon" then
        local precalc = false
        if not tile.gid then precalc = true end
				local vertices  = getPolygonVertices(o, tile, precalc)
				local triangles = love.math.triangulate(vertices)

				for _, triangle in ipairs(triangles) do
					addObjectToWorld(o.shape, triangle, userdata, object)
				end
			elseif o.shape == "polyline" then
        local precalc = false
        if not tile.gid then precalc = true end

				local vertices	= getPolygonVertices(o, tile, precalc)
				addObjectToWorld(o.shape, vertices, userdata, object)
			end
		end

    -- FIXME: should instead be specifying the layer that causes collision higher up
		for _, layer in ipairs(map.layers) do
      if layer.type == "tilelayer" and layer.properties.collidable ~= "false" then
        for _, tileset in ipairs(map.tilesets) do
          for _, tile in ipairs(tileset.tiles) do
            local gid = tileset.firstgid + tile.id

            if tile.objectGroup and map.tileInstances[gid] then
              for _, instance in ipairs(map.tileInstances[gid]) do

                if instance.layer == layer then
                  for _, object in ipairs(tile.objectGroup.objects) do
                      -- Every object in every instance of a tile
                      calculateObjectPosition(object, instance)
                  end
                end
              end
            end
          end
        end
      end
    end

		map.box2d_collision = collision
	end,

	--- Remove Box2D fixtures and shapes from world.
	-- @param index The index or name of the layer being removed
	-- @return nil
	box2d_removeLayer = function(map, index)
		local layer = assert(map.layers[index], "Layer not found: " .. index)
		local collision = map.box2d_collision

		-- Remove collision objects
		for i=#collision, 1, -1 do
			local obj = collision[i]

			if obj.object.layer == layer
			and (
				layer.properties.collidable == "true"
				or obj.object.properties.collidable == "true"
			) then
				obj.fixture:destroy()
				table.remove(collision, i)
			end
		end
	end,

	--- Draw Box2D physics world.
	-- @return nil
	box2d_draw = function(map)
		local collision = map.box2d_collision

		for _, obj in ipairs(collision) do
			local points = {collision.body:getWorldPoints(obj.shape:getPoints())}

			if #points == 4 then
				love.graphics.line(points)
			else
				love.graphics.polygon("line", points)
			end
		end
	end,
}

--- Custom Properties in Tiled are used to tell this plugin what to do.
-- @table Properties
-- @field collidable set to "true", can be used on any Layer, Tile, or Object
-- @field sensor set to "true", can be used on any Tile or Object that is also collidable