attack_time = 0.3
attack_cooldown_time = 1
walk_speed = 2
max_walk_speed = 150

export *

class Monster
    new: (x, y, room) =>
        @hp = 50
        @img = love.graphics.newImage("assets/gfx/monster.png")
        @x = x
        @y = y
        @room = room
        @current_animation = anims.reverant.standing
        @touching_ground = false
        @target = nil
        @facing_direction = 1
        @cage = nil
        @\new_bbox()
        @wonder_time = 0
        @last_attack = 0

    kill: =>
        @body\destroy()
        @body2.body\destroy()

    new_bbox: =>
        @body = love.physics.newBody(@room.world, @x, @y, "dynamic")
        @shape = love.physics.newCircleShape(10)
        @fixture = love.physics.newFixture(@body, @shape, 1)
        @fixture\setUserData(self)
        @body\setFixedRotation(true)

        @body2 = {}
        @body2.body = love.physics.newBody(@room.world, @x, @y - 50, "dynamic")
        @body2.shape = love.physics.newRectangleShape(0, 0, 20, 55)
        @body2.fixture = love.physics.newFixture(@body2.body, @body2.shape, 1)
        @body2.fixture\setUserData(self)
        love.physics.newPrismaticJoint(@body, @body2.body, @x, @y - 50, 0, -1, false)
        @body2.body\setFixedRotation(true)

    attack: =>
        return if love.timer.getTime() < @last_attack + attack_cooldown_time

        @last_attack = love.timer.getTime()
        @current_animation = anims.reverant.attacking
        @current_animation\reset()

    apply_monster_cage: =>
        if @x < @cage.x then
            @body\setX(@cage.x + 5)
            --@body\applyLinearImpulse(@speed * 10, 0)
            @body\setLinearVelocity(5, 0)
            @wonder_time = 1 + love.timer.getTime()
            @facing_direction =  @facing_direction * -1
        elseif @cage.x + @cage.width < @x then
            @body\setX(@cage.x + @cage.width - 5)
            --@body\applyLinearImpulse(-@speed * 10, 0)
            @body\setLinearVelocity(-5, 0)
            @wonder_time = 1 + love.timer.getTime()
            @facing_direction =  @facing_direction * -1

    update: (dt) =>

        -- change animation speed according to ground speed
        x, y = @body\getLinearVelocity()

        clamp_velocity(x, y, @body, max_walk_speed)

        @current_animation\update(dt)

        if @cage
            @\apply_monster_cage()

        @x = @body\getX()
        @y = @body\getY()

        -- Find the monster
        if not @target then
            for id, obj in pairs @room.map.layers.Objects.objects
                if obj.type == "player"
                    @target = obj
        else
            -- Handle attacking animation    
            if love.timer.getTime() < @last_attack + attack_time
                @current_animation\setSpeed(1)

            elseif @wonder_time < love.timer.getTime()
                if @x < @target.o.x
                    --@body\applyForce(@speed, 0)
                    @body\applyLinearImpulse(walk_speed, 0)
                    @current_animation = anims.reverant.walking
                    @facing_direction = 1
                else
                    --@body\applyForce(-@speed, 0)
                    @body\applyLinearImpulse(-walk_speed, 0)
                    @current_animation = anims.reverant.walking
                    @facing_direction = -1
            else
                @body\applyLinearImpulse(walk_speed * @facing_direction, 0)
                @current_animation\setSpeed(math.min(math.abs(x) / 60, 1.4))

       --for k, obj = pairs current_room.map.layers.Objects.objects
       --     if obj.o
       --         if obj.type == "player" then
       --             d = distance(obj.o.x, obj.o.y, @x, @y)
       --             if d < 80 then
       --                 @\attack()

    draw: =>
        @current_animation\draw(@x - @facing_direction*40, @y - 83, 0, @facing_direction, 1)

    takedamage: (dmg) =>
        @hp = @hp - dmg
