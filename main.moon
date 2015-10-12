
require "AnAl"
actor = require "luactor"
require "actor"
require "world"
require 'camera'
vector = require 'vector'

export ^

game_over_font_h = 50

-- Load animation
anim = (path, x, y, speed, a, b) ->
    newAnimation love.graphics.newImage(path), x, y, speed, a, b

current_room = {}

newbbox = (o) ->
    o.body = love.physics.newBody(o.room.world, o.x, o.y, "dynamic")
    o.shape = love.physics.newCircleShape(o.bbox_radius)
    o.fixture = love.physics.newFixture(o.body, o.shape, 1)
    o.fixture\setUserData(o)
    o.fixture\setFriction(o.friction)
    o.body\setMass(5)


newbbox_quad = (o) ->
    o.body = love.physics.newBody(o.room.world, o.x, o.y, "dynamic")
    o.shape = love.physics.newRectangleShape(0, 0, o.bboxed_quad_w, o.bboxed_quad_h)
    o.fixture = love.physics.newFixture(o.body, o.shape, 1)
    o.fixture\setUserData(o)
    o.fixture\setFriction(o.friction)
    o.body\setMass(5)


newbbox_prismatic = (o) ->
    o.body2 = love.physics.newBody(o.room.world, o.x, o.y - 40, "dynamic")
    o.shape2 = love.physics.newRectangleShape(0, 0, 10, 64)
    o.fixture2 = love.physics.newFixture(o.body2, o.shape2, 1)
    o.fixture2\setUserData(o)
    o.body2\setFixedRotation(true)


steppers = {}
class Stepper
    new: =>
        @x_vel = 0
        @y_vel = 0
        table.insert steppers, @

    remove: (msg, sender) =>
        for key, obj in pairs steppers
            if obj == @
                table.remove steppers, key

    set_vel: (msg, sender) =>
        @x_vel = msg[1]
        @y_vel = msg[2]

    step: (dt, sender) =>
        @x += @x_vel * dt
        @y += @y_vel * dt


damageables = {}
class Damageable
    new: =>
        @hp = 50
        @hp_max = 100
        table.insert damageables, @

    remove: (msg, sender) =>
        for key, obj in pairs damageables
            if obj == @
                table.remove damageables, key

    dmg: (msg, sender) =>

        --print(string.format('msg from:%s msg:%s', sender, msg.pts))

        actor.send sender, "dmging", @id

        @hp -= msg.pts
        if @hp <= 0
            actor.send @id, "die", "you're dead"
            actor.send @id, "remove"
            --actor.send Heart().id, 'set_pos', {@x, @y - 60}

            o = Skull()
            actor.send o.id, 'set_pos', {@x, @y - 60}
            actor.send o.id, 'set_vel', {math.sin(math.random()) * 3000, -math.sin(math.random()) * 3000}

            o = Ribcage()
            actor.send o.id, 'set_pos', {@x, @y - 60}
            actor.send o.id, 'set_vel', {math.sin(math.random()) * 3000, -math.sin(math.random()) * 3000}

            o = Limb()
            actor.send o.id, 'set_pos', {@x, @y - 60}
            actor.send o.id, 'set_vel', {math.sin(math.random()) * 3000, -math.sin(math.random()) * 3000}

            o = Limb()
            actor.send o.id, 'set_pos', {@x, @y - 60}
            actor.send o.id, 'set_vel', {math.sin(math.random()) * 3000, -math.sin(math.random()) * 3000}

            o = Limb()
            actor.send o.id, 'set_pos', {@x, @y - 60}
            actor.send o.id, 'set_vel', {math.sin(math.random()) * 3000, -math.sin(math.random()) * 3000}

            o = Limb()
            actor.send o.id, 'set_pos', {@x, @y - 60}
            actor.send o.id, 'set_vel', {math.sin(math.random()) * 3000, -math.sin(math.random()) * 3000}

    hp: (msg, sender) =>
        @hp += msg.pts
        @hp = @hp_max if @hp_max < @hp


class PainfulTouch
    @needs = {'Touchable'}

    touch: (msg, sender) =>
        actor.send msg, 'dmg', {pts: @dmg_pts}


class DamageOnContact
    step: (dt, sender) =>
        contacts = @body\getContactList()
        for _, o in pairs contacts
            if o\isTouching()
                fixtureA, fixtureB = o\getFixtures()
                a = fixtureA\getUserData()
                b = fixtureB\getUserData()
                if a != nil and a.id != nil and b != nil and b.id != nil
                    if a.id == @id
                        actor.send b.id, 'dmg', {pts: @dmg_pts}
                    else 
                        actor.send a.id, 'dmg', {pts: @dmg_pts}


-- Removes itself when it damages something
class RemovedOnDamage
    dmging: (msg, sender) =>
        actor.send @id, "remove"


class NoDamageIfStill
    new: =>
        @no_dmg_in = true

    step: (dt, sender) =>
        if math.abs(@x_vel) < 200 and math.abs(@y_vel) < 200
            actor.send @id, "mixout", "Touchable"
            @no_dmg_in = false
        else if not @no_dmg_in
            actor.send @id, "mixin", "Touchable"
            @no_dmg_in = true


class RoomOccupier
    new: =>
        @x = 0
        @y = 100
        @room = current_room
        @last_room_change_time = 0

    set_pos: (msg, sender) =>
        @x = msg[1]
        @y = msg[2]

    set_room: (msg, sender) =>
        @room = msg

    enter_room: (msg, sender) =>
        if @last_room_change_time < love.timer.getTime()
            @last_room_change_time = 1 + love.timer.getTime()

            tdoor = msg.door.world_obj.target_door
            current_room = tdoor.room
            actor.send @id, 'set_pos', {tdoor.x, tdoor.y}
            actor.send @id, 'set_room', tdoor.room

            --x = tdoor.x
            --camera:setX(x - x % windowWidth)


class Bleeds
    dmg: (msg, sender) =>
        b = Blood()
        actor.send b.id, 'set_pos', {@x, @y}


class Walker
    @needs = {'Animated'}

    step: (dt, sender) =>
        if 80 < math.abs(@x_vel)
            actor.send @id, 'enqueue_anim', {anim:@anims['walking']}
            -- change animation speed according to ground speed
            --@curr_anim\setSpeed(math.min(math.abs(@x_vel) / 60, 1.4))
        else
            actor.send @id, 'enqueue_anim', {anim:@anims['standing']}


class WalkerJumper extends Walker
    @needs = {'Animated'}

    step: (dt, sender) =>
        if not @touching_ground
            actor.send @id, 'enqueue_anim', {anim:@anims['jumping']}
        else
            super dt, sender


class Croucher
    @needs = {'Animated'}

    new: =>
        @crouching = false

    cmd_down: (dt, sender) =>
        @crouching = true
        -- TODO: need to set to false somehow
        --actor.send @id, 'enqueue_anim', {anim:@anims['crouching']}
        actor.send @id, 'set_anim', 'crouching'


class Falls
    @needs = {'Stepper'}
    step: (dt, sender) =>
        @yvel += 100 * dt


class Shooter
    die: (msg, sender) =>
        print 'dead!!!'

    cmd_shoot: (msg, sender) =>
        print 'cmd shoot!!!'


class MouseTeleporter
    click: (msg, sender) =>
        actor.send @id, 'set_pos', msg
        actor.send @id, 'set_vel', {0, 0}


class MouseFollower
    @needs = {'Stepper'}
    step: (dt, sender) =>
        x, y = love.mouse.getPosition()
        x += camera._x
        y += camera._y
        if @x < x
            actor.send @id, 'cmd_right'
        elseif @x > x
            actor.send @id, 'cmd_left'


class PlayerFollower
    @needs = {'Stepper'}
    step: (dt, sender) =>
        @target = d
        if @x < d.x
            actor.send @id, 'cmd_right'
        elseif @x > d.x
            actor.send @id, 'cmd_left'


class FacesDirectionByVelocity
    @needs = {'Stepper'}
    new: =>
        @facing_direction = 1

    step: (dt, sender) =>
        if 0 < @x_vel
            @facing_direction = 1
        if @x_vel < 0
            @facing_direction = -1


class FacesDirection
    new: =>
        @facing_direction = 1

    cmd_right: (msg, sender) =>
        @facing_direction = 1

    cmd_left: (msg, sender) =>
        @facing_direction = -1


class Burning
    draw_start: (msg, sender) =>
        love.graphics.setColor 255, 0, 0


class Poisoned
    draw_start: (msg, sender) =>
        love.graphics.setColor 0, 255, 0


drawables = {}
class Drawable
    new: =>
        table.insert drawables, @

    remove: (msg, sender) =>
        for key, obj in pairs drawables
            if obj == @
                table.remove drawables, key


class Sprite
    @needs = {'Drawable'}

    draw: (msg, sender) =>
        love.graphics.draw @sprite, @x, @y

    draw_done: (msg, sender) =>
        love.graphics.setColor 255, 255, 255


class QuadSprite
    @needs = {'Drawable', 'BBoxedQuad'}

    new: =>
        @bboxed_quad_w = @sprite\getWidth()
        @bboxed_quad_h = @sprite\getHeight()

    init: (msg, sender) =>
        --@bboxed_quad_w = @sprite.width
        --@bboxed_quad_h = @sprite.height
        a = { 0, 0, 0, 0, 255, 255, 255 }
        b = { 0, 0, 1, 0, 255, 255, 255 }
        c = { 0, 0, 1, 1, 255, 255, 255 }
        d = { 0, 0, 0, 1, 255, 255, 255 }
        @mesh = love.graphics.newMesh({a,b,c,d}, @sprite)
        @body\setAngle(90)

    draw: (msg, sender) =>
        x1, y1, x2, y2, x3, y3, x4, y4 = @body\getWorldPoints(@shape\getPoints())
        a = { x1, y1, 0, 0, 255, 255, 255 }
        b = { x2, y2, 1, 0, 255, 255, 255 }
        c = { x3, y3, 1, 1, 255, 255, 255 }
        d = { x4, y4, 0, 1, 255, 255, 255 }
        @mesh\setVertices({a,b,c,d})
        love.graphics.draw @mesh, 0, 0

    draw_done: (msg, sender) =>
        love.graphics.setColor 255, 255, 255


class Animated
    @needs = {'FacesDirection', 'Drawable', 'Stepper'}
    new: =>
        @anims = {}
        @queue = {}

    set_anim: (anim, sender) =>
        @curr_anim = @anims[anim]
        @curr_anim\reset()
        --@curr_anim\seek(1)
        @curr_anim\setSpeed(1)
        @curr_anim\play()

    enqueue_anim: (msg, sender) =>
        if @curr_anim.playing
            if msg.anim != @curr_anim
                table.insert @queue, msg
--        else
--            @\set_anim msg.anim

    step: (dt, sender) =>
        @curr_anim\update dt
        if not @curr_anim.playing
            anim = table.remove @queue
            if anim
                @curr_anim = anim.anim
                @curr_anim\reset()
                @curr_anim\setSpeed(1)
                @curr_anim\play()

    draw: (msg, sender) =>
        --love.graphics.circle "fill", @x, @y, 50, 5
        --@curr_anim\draw(@x - @facing_direction*40, @y, 0, @facing_direction, 1)
        @curr_anim\draw(@x - @facing_direction*40, @y - 83, 0, @facing_direction, 1)

    draw_done: (msg, sender) =>
        love.graphics.setColor 255, 255, 255


-- Objects that touch things
-- touch messages are sent to Touchables
touchers = {}
class Toucher
    new: =>
        table.insert touchers, @

    remove: (msg, sender) =>
        for key, obj in pairs touchers
            if obj == @
                table.remove touchers, key


-- Objects that can be activated
activatables = {}
class Activatable
    new: =>
        table.insert activatables, @

    remove: (msg, sender) =>
        for key, obj in pairs activatables
            if obj == @
                table.remove activatables, key

    activate: (msg, sender) =>


distance = (x1, y1, x2, y2) ->
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)

easeOutQuad = (t, b, c, d) ->
    t = t / d
    return -c * t * (t - 2) + b


-- Receives touch messages from Touchers
class Touchable
    @needs = {'Stepper'}
    step: (msg, sender) =>
        for key, o in pairs touchers
            continue if o.room != @room
            continue if 32 < distance(@x, @y, o.x, o.y)
            continue if o\id == @id
            actor.send @id, 'touch', o.id


-- Gives HP
class Hpbonus
    touch: (msg, sender) =>
        actor.send msg, 'hp', {pts: 10}


-- Removes Poisoned
class Cure
    touch: (msg, sender) =>
        actor.send msg, "mixout", "Poisoned"


-- Makes entities Poisoned
class Poison
    touch: (msg, sender) =>
        actor.send msg, "mixin", "Poisoned"


-- Object is able to be picked up
class Pickupable
    touch: (msg, sender) =>
        actor.send @id, "remove"


class Attacker
    @needs = {'Animated', 'FacesDirection'}
    new: =>
        @last_attack = 0
        @attack_cooldown_time = 0.3
        @dmg_pts = 25
        @attack_range = 80

    cmd_attack: (msg, sender) =>
        if love.timer.getTime() < @last_attack + @attack_cooldown_time
            return
        @last_attack = love.timer.getTime()
        for key, o in pairs damageables
            continue if o.room != @room
            continue if o.id == @id
            continue if o.faction == @faction
            continue if @attack_range < distance(@x, @y, o.x, o.y)
            actor.send o.id, 'dmg', {pts: @dmg_pts}
        actor.send @id, 'set_anim', 'attacking'


class Thrower
    @needs = {'Animated', 'FacesDirection'}
    new: =>
        @last_throw = 0
        @throw_cooldown_time = 0.3

    cmd_secondary: (msg, sender) =>
        if love.timer.getTime() < @last_throw + @throw_cooldown_time
            return
        @last_throw = love.timer.getTime()

        b = ThrowingKunai()
        actor.send b.id, 'set_pos', {@x + 40 * @facing_direction, @y - 60}
        actor.send b.id, 'set_vel', {3000 * @facing_direction, 0}


-- Sends activate messages to Activatables
class Activator
    new: =>
        @last_activate = 0

    cmd_up: (msg, sender) =>
        if love.timer.getTime() < @last_activate + 1
            return
        for key, a in pairs activatables
            continue if a.room != @room
            continue if distance(@x, @y, a.x, a.y) > 40 
            continue if a\id == @id
            actor.send a.id, 'activate'


class Controlled
    @needs = {'Animated', 'Stepper', 'TouchingGroundChecker'}

    new: =>
        @hspeed = 200
        @walk_speed = 100

    cmd_right: (msg, sender) =>
        if @touching_ground
            actor.send @id, 'move_right', @walk_speed
        else
            -- Air control
            actor.send @id, 'move_right', @walk_speed * 0.2

    cmd_left: (msg, sender) =>
        if @touching_ground
            actor.send @id, 'move_left', @walk_speed
        else
            -- Air control
            actor.send @id, 'move_left', @walk_speed * 0.2


class Doorable
    @needs = {'Activatable', 'RoomOccupier'}
    activate: (msg, sender) =>
        actor.send sender, 'enter_room', {'door': @}


sign = (x) ->
    if x < 0
        return -1
    else
        return 1


clamp_velocity = (x_vel, y_vel, body, max_speed) ->
    if max_speed < math.abs(x_vel)
        body\setLinearVelocity(sign(x_vel) * max_speed, y_vel)


clamp_camera = (self) ->
    left_hand_side = 0
    right_hand_side = current_room.map.width * current_room.map.tilewidth - windowWidth

    if self._x < left_hand_side
        self._x = left_hand_side
    elseif right_hand_side < self._x
        self._x = right_hand_side


class PlayerBBoxed
    @needs = {'BBoxed'}

    new: =>
        @prismatic_connected = false

    init: (msg, sender) =>
        newbbox_prismatic(@)

    step: (dt, sender) =>
        if not @prismatic_connected
            @prismatic_connected = true
            love.physics.newPrismaticJoint(@body, @body2, @x, @y - 50, 0, -1, false)

    set_vel: (msg, sender) =>
        @body2\applyLinearImpulse(msg[1], msg[2])

    move_right: (speed, sender) =>
        @body2\applyLinearImpulse(speed, 0)

    move_left: (speed, sender) =>
        @body2\applyLinearImpulse(-speed, 0)

    set_pos: (msg, sender) =>
        @body2\setX msg[1]
        @body2\setY msg[2]

    set_room: (msg, sender) =>
        @body2\destroy!
        newbbox_prismatic(@)
        @prismatic_connected = false

    remove: (msg, sender) =>
        @body2\destroy!

--    draw: (dt, sender) =>
--        love.graphics.polygon("fill", @body2\getWorldPoints(@shape2\getPoints()))


class BBoxed
    new: =>
        @friction = 6
        @bbox_radius = 10
        @speed_max = 300

    init: (msg, sender) =>
        newbbox(@)

    step: (dt, sender) =>
        @x = @body\getX!
        @y = @body\getY!

        @x_vel, @y_vel = @body\getLinearVelocity()
        clamp_velocity(@x_vel, @y_vel, @body, @speed_max)

    set_vel: (msg, sender) =>
        @body\applyLinearImpulse(msg[1], msg[2])

    move_right: (speed, sender) =>
        @body\applyLinearImpulse(speed, 0)

    move_left: (speed, sender) =>
        @body\applyLinearImpulse(-speed, 0)

    set_pos: (msg, sender) =>
        @body\setX msg[1]
        @body\setY msg[2]

    set_room: (msg, sender) =>
        @body\destroy!
        newbbox(@)

    remove: (msg, sender) =>
        @body\destroy!

--    draw: (dt, sender) =>
--        love.graphics.circle("fill", @x, @y, @bbox_radius)


class BBoxedQuad extends BBoxed
    init: (msg, sender) =>
        newbbox_quad(@)

    step: (dt, sender) =>
        super dt, sender

    set_vel: (msg, sender) =>
        super msg, sender

    move_right: (speed, sender) =>
        super speed, sender

    move_left: (speed, sender) =>
        super speed, sender

    set_pos: (msg, sender) =>
        super msg, sender

    set_room: (msg, sender) =>
        @body\destroy!
        newbbox_quad(@)

    remove: (msg, sender) =>
        super msg, sender

--    draw: (dt, sender) =>
--        love.graphics.polygon("fill", @body\getWorldPoints(@shape\getPoints()))


-- Checks if we are touching the ground or not
class TouchingGroundChecker
    @needs = {'BBoxed'}

    new: =>
        @touching_ground = false

    step: (dt, sender) =>
        contacts = @body\getContactList()
        for _, o in pairs contacts
            if o\isTouching()
                if not @touching_ground
                    actor.send @id, 'touch_ground'
                @touching_ground = true
                return

        @touching_ground = false


-- Jumps if up is pushed
class Jumper
    @needs = {'TouchingGroundChecker'}
    
    new: =>
        @last_jump_time = 0
        @jump_impulse = 2000
        @jump_cooldown = 0.3

    cmd_up: (msg, sender) =>
        --if self.touching_ground and self.last_jump_time + 1 < love.timer.getTime() then
        if @touching_ground and @last_jump_time + @jump_cooldown < love.timer.getTime()
            @last_jump_time = love.timer.getTime()
            @body\applyLinearImpulse 0, -@jump_impulse


-- concrete
class Player extends Object
    mixins: =>
        @\_mixin Damageable
        @\_mixin RoomOccupier
        @\_mixin MouseTeleporter
        @\_mixin Animated
        @\_mixin WalkerJumper
        @\_mixin Croucher
        @\_mixin Attacker
        --@\_mixin FacesDirectionByVelocity
        @\_mixin Toucher
        @\_mixin PlayerBBoxed
        --@\_mixin BBoxed
        @\_mixin TouchingGroundChecker
        @\_mixin Jumper
        @\_mixin Activator
        @\_mixin Bleeds
        @\_mixin RunSmokey
        @\_mixin Controlled
        @\_mixin Thrower
        --@\_mixin MouseFollower
        --@\_mixin FacesDirection
        --@\_mixin Falls
        @anims['walking'] = anim "assets/gfx/manwalking.png", 80, 103, .175, 1, 0
        @anims["walking"]\setMode('once')
        @anims["standing"] = anim "assets/gfx/manstanding.png", 80, 103, .15, 1, 1
        @anims["standing"]\setMode('once')
        @anims["attacking"] = anim "assets/gfx/manattacking2.png", 96, 103, .055, 1, 0
        @anims["attacking"]\setMode('once')
        @anims["crouching"] = anim "assets/gfx/mancrouching.png", 80, 103, 0.5, 1, 0
        @anims["crouching"]\setMode('once')
        @anims['jumping'] = anim "assets/gfx/manjumping.png", 80, 103, .175, 1, 0
        @anims["jumping"]\setMode('once')
        --actor.send @id, 'enqueue_anim', 'walking'
        actor.send @id, 'set_anim', 'walking'
        @room = current_room
        @faction = 'good'
        @hp = 100


-- Removes itself pretty soon
class ShortLived
    new: =>
        @var_short_lived_life_time = 0.3
        @short_lived_start_time = love.timer.getTime()

    step: (dt, sender) =>
        if @short_lived_start_time + @var_short_lived_life_time < love.timer.getTime()
            actor.send @id, "remove"


-- Emits blood
class Bloody 
    @needs = {'Drawable'}

    step: (dt, sender) =>
        @blood\update dt

    draw: (msg, sender) =>
        love.graphics.draw(@blood, @x, @y - 30)

    new: =>
        bloodimg = love.graphics.newImage "assets/gfx/blood_puffy.png"
        @blood = love.graphics.newParticleSystem(bloodimg, 100)
        @blood\setParticleLifetime(0.5, 1) -- Particles live at least 2s and at most 5s.
        @blood\setEmissionRate(5)
        @blood\setSizeVariation(1)
        @blood\setLinearAcceleration(-100, 60, 100, 60)
        @blood\setRotation(-4, 4)
        @blood\setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.


class RunSmokey 
    @needs = {'Drawable'}

    step: (dt, sender) =>
        @ps\update dt
        @ps\setPosition @x, @y + 10

    draw: (msg, sender) =>
        love.graphics.draw(@ps)

    touch_ground: (msg, sender) =>
        @ps\emit 1

    new: =>
        img = love.graphics.newImage "assets/gfx/smoke_breathable.png"
        @ps = love.graphics.newParticleSystem(img, 100)
        @ps\setParticleLifetime(1, 1)
        --@ps\setSizeVariation(0.9)
        @ps\setSizes(0.5, 0.25, 0.12, 0.06)
        @ps\setLinearAcceleration(-20, -20, 20, 20)
        @ps\setRotation(-20, 20)
        @ps\setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.


class Smokey 
    @needs = {'Drawable'}

    step: (dt, sender) =>
        @ps\update dt
        @ps\setPosition @x, @y + 10

    draw: (msg, sender) =>
        love.graphics.draw(@ps)

    new: =>
        img = love.graphics.newImage "assets/gfx/smoke_breathable.png"
        @ps = love.graphics.newParticleSystem(img, 100)
        @ps\setParticleLifetime(1, 1)
        @ps\setEmissionRate(5)
        --@ps\setSizeVariation(0.9)
        @ps\setSizes(0.5, 0.25, 0.12, 0.06)
        @ps\setLinearAcceleration(-20, -20, 20, 20)
        @ps\setRotation(-20, 20)
        @ps\setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.


class Ladderable
    touch: (msg, sender) =>
        --actor.send msg, "mixout", "Poisoned"
        @body\applyLinearImpulse 0, -5


class Ladder extends Object
    mixins: =>
        @\_mixin RoomOccupier
--        @\_mixin BBoxed
        @\_mixin Touchable
        @\_mixin Ladderable

--    new: =>
--        @last_jump_time = 0

--    cmd_up: (msg, sender) =>
--        --if self.touching_ground and self.last_jump_time + 1 < love.timer.getTime() then
--        if @last_jump_time + 1 < love.timer.getTime()
--            @last_jump_time = love.timer.getTime()
--            @touching_ground = false
--            @body\applyLinearImpulse 0, -20


-- concrete
class Blood extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Bloody
        @\_mixin Stepper
        @\_mixin ShortLived


class ThrowingKunai extends Object
    mixins: =>
        @sprite = love.graphics.newImage "assets/gfx/kunai.png"

        @\_mixin RoomOccupier
        @\_mixin Stepper
        @\_mixin BBoxedQuad
        @\_mixin QuadSprite
        @\_mixin DamageOnContact
        @\_mixin RemovedOnDamage
        --@\_mixin NoDamageIfStill

        @dmg_pts = 10

        @speed_max = 3000

        --@bboxed_quad_w = 9
        --@bboxed_quad_h = 28

        --@\_mixin ShortLived
        --@var_short_lived_life_time = 2

class Gib extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Stepper
        @\_mixin BBoxedQuad
        @\_mixin QuadSprite


class Skull extends Gib
    mixins: =>
        @sprite = love.graphics.newImage "assets/gfx/skull.png"
        super!


class Heart extends Gib
    mixins: =>
        @sprite = love.graphics.newImage "assets/gfx/heart.png"
        super!


class Ribcage extends Gib
    mixins: =>
        @sprite = love.graphics.newImage "assets/gfx/ribcage.png"
        super!


class Limb extends Gib
    mixins: =>
        @sprite = love.graphics.newImage "assets/gfx/Limb.png"
        super!


class Monster extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Animated
        @\_mixin Damageable
        --@\_mixin MouseFollower
        @\_mixin PlayerFollower
        @\_mixin FacesDirectionByVelocity
        @\_mixin Toucher
        @\_mixin Attacker
        @\_mixin Walker
        @\_mixin PlayerBBoxed
        @\_mixin Bleeds
        @anims['walking'] = anim "assets/gfx/reverant_walking.png", 80, 103, .175, 1, 0
        @anims["walking"]\setMode('once')
        @anims["standing"] = anim "assets/gfx/reverant_standing.png", 80, 103, .15, 1, 1
        @anims["standing"]\setMode('once')
        @anims["attacking"] = anim "assets/gfx/reverant_attacking.png", 80, 103, .15, 1, 1
        @anims["attacking"]\setMode('once')
        @walk_speed_max = 200
        actor.send @id, 'set_anim', 'walking'
        @\add_handler "step", Monster.step
        @attack_cooldown_time = 1.5
        @faction = 'bad'

    step: (dt, sender) =>
        actor.send @id, 'cmd_attack'


class Imp extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Animated
        @\_mixin MouseFollower
        @\_mixin Damageable
        @\_mixin FacesDirectionByVelocity
        @\_mixin Attacker
        @\_mixin Walker
        @\_mixin BBoxed
        @anims['walking'] = anim "assets/gfx/imp.png", 64, 64, .175, 1, 0
        @anims["standing"] = anim "assets/gfx/imp.png", 64, 64, .15, 1, 0
        @walk_speed_max = 100
        actor.send @id, 'set_anim', 'walking'
        @faction = 'bad'


class Antidoteflask extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Sprite
        @\_mixin Touchable
        @\_mixin Cure
        @\_mixin Pickupable
        @sprite = love.graphics.newImage "assets/gfx/cure.png"


class Poisonflask extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Sprite
        @\_mixin Touchable
        @\_mixin Poison
        @\_mixin Pickupable
        @sprite = love.graphics.newImage "assets/gfx/poison.png"


class Goldbar extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Sprite
        @\_mixin Touchable
        @\_mixin Pickupable
        --@\_mixin Falls
        --@\_mixin BBoxed
        @sprite = love.graphics.newImage "assets/gfx/goldbar.png"


class Turkey extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Sprite
        @\_mixin Touchable
        @\_mixin Pickupable
        @\_mixin Hpbonus
        @sprite = love.graphics.newImage "assets/gfx/turkey.png"


class Vendingmachine extends Object
    mixins: =>
        @\_mixin RoomOccupier
        @\_mixin Sprite
        @sprite = love.graphics.newImage "assets/gfx/jihanki.png"


class Door extends Object
    mixins: =>
        @\_mixin Sprite
        @\_mixin Doorable
        @sprite = love.graphics.newImage "assets/gfx/door.png"
        --@\add_handler "activate", Door.activate


class Upstairs extends Object
    mixins: =>
        @\_mixin Sprite
        @\_mixin Doorable
        @sprite = love.graphics.newImage "assets/gfx/upstairs.png"


class Downstairs extends Object
    mixins: =>
        @\_mixin Sprite
        @\_mixin Doorable
        @sprite = love.graphics.newImage "assets/gfx/downstairs.png"


class World extends Object
    new: =>
        @x = 0
        @y = 100


class Camera extends Object
    new: =>
        @x = 0
        @y = 100


class Spike extends Object
    mixins: =>
        @\_mixin PainfulTouch
        @\_mixin RoomOccupier
        @\_mixin Sprite
        @sprite = love.graphics.newImage "assets/gfx/spike.png"
        @dmg_pts = 10000


love.mousereleased = (x, y, button) ->
    if button == "l"
        d\_start!
        actor.send d.id, 'click', {x, y}


-- A level is made up of many rooms
levels = {}

export d = {}
export windowWidth = 640
export windowHeight = 480
screen_pan_time = 1

on_level_object_creation = (o, room) ->
    current_room = room
    name = o.type
    name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    if _G[name]
        n = _G[name]()
        n.world_obj = o
        n.name = name
        actor.send n.id, 'set_pos', {o.x, o.y}

game_over_font = {}

love.load = ->
    math.randomseed(os.time())
    --actor.send d.id, 'dmg', {pts: 100}
    actor.init()

    game_over_font = love.graphics.newFont("assets/font/joystix.ttf", game_over_font_h)
    font = game_over_font
    --font = love.graphics.newFont("assets/font/joystix.ttf", 15)
    love.graphics.setDefaultFilter("nearest","nearest")
    love.graphics.setFont(font)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.window.setMode(windowWidth, windowHeight)

    love.physics.setMeter(32)

    levels = load_levels(on_level_object_creation)

    current_room = levels[1].rooms["start"]
    --current_room.map.layers.Objects.objects[objects.player] =
    -- {x=objects.player.x, y=objects.player.y, o=objects.player, type="player"}
 
    d = Player()
    g = Poisonflask()
    c = Antidoteflask()
    --m = Monster()
    t = Turkey()
    --i = Imp()

    actor.send d.id, 'set_pos', {400, 100}
    actor.send d.id, 'cmd_right'
    actor.send g.id, 'set_pos', {200, 300}
    actor.send c.id, 'set_pos', {500, 300}
    --actor.send m.id, 'set_pos', {500, 200}
    actor.send t.id, 'set_pos', {800, 300}
    --actor.send i.id, 'set_pos', {500, 200}


export camera_change_time

camera_change_time = 0

update_camera = (dt) ->

    cam_org = vector.new(camera._x, camera._y)
    ent_org = vector.new(d.x - windowWidth / 2, d.y - windowHeight / 1.5)

    sub = ent_org - cam_org
    sub\normalize_inplace()
    dist = ent_org\dist(cam_org)

    camera\move(sub.x * dist * dt * 2, 0)--sub.y * dist * dt * 2)

    clamp_camera(camera)

    -- Do camera follow mouse
    --camera:setPosition(love.mouse.getX() - 100, love.mouse.getY() - 100)


love.update = (dt) ->
    if love.keyboard.isDown("right") or love.keyboard.isDown("f")
        actor.send d.id, 'cmd_right'
    if love.keyboard.isDown("left") or love.keyboard.isDown("e")
        actor.send d.id, 'cmd_left'
    if love.keyboard.isDown("up") or love.keyboard.isDown("w")
        actor.send d.id, 'cmd_up'
    if love.keyboard.isDown("down") or love.keyboard.isDown("s")
        actor.send d.id, 'cmd_down'
    if love.keyboard.isDown("z") or love.keyboard.isDown("j")
        actor.send d.id, 'cmd_attack'
    if love.keyboard.isDown("x") or love.keyboard.isDown("l")
        actor.send d.id, 'cmd_secondary'

    for _, o in pairs steppers
        if o.room == current_room
            actor.send o.id, 'step', dt
    actor.run()

    current_room.map\update(dt)
    current_room.world\update(dt)

    update_camera(dt)

    current_room.lightWorld\update(dt)


draw_hp_bar = (x, y, edge, w, h, ratio) ->
    love.graphics.setColor 255, 255, 255
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor 255, 0, 0
    love.graphics.rectangle("fill", x + edge, y + edge, (w - edge * 2) * ratio, h - edge * 2)


love.draw = ->
    current_room.lightWorld\setTranslation(-camera._x, -camera._y, 1)
    love.graphics.push()
    love.graphics.translate(-camera._x, -camera._y)
    current_room.lightWorld\draw (l, t, w, h, s) ->
        love.graphics.setColor 255, 255, 255
        w, h = love.graphics.getWidth() * 4, love.graphics.getHeight() * 2
        love.graphics.rectangle("fill", 0, -500, w, h)
        current_room.map.layers['Tile Layer 1']\draw()
        --current_room.map\drawWorldCollision(current_room.collision)

    current_room.map.layers['Objects']\draw()
    for _, d in pairs drawables
        if d.room == current_room
            actor.send d.id, 'draw_start', dt
            actor.send d.id, 'draw', dt
            actor.send d.id, 'draw_done', dt
    actor.run()

    love.graphics.pop()

    draw_hp_bar(10, 10, 2, 100, 10, d.hp / 100)

    if d.hp <= 0
        love.graphics.print("GAME\nOVER", windowWidth / 2 - 4 * game_over_font_h / 2, windowHeight / 3)
