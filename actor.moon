actor = require "luactor"

export ^
export objects

mixin = (cls, ...) =>
    for key, val in pairs cls.__base
        --print cls.__name, key, val
        new_method_name = cls.__name .. key
        if not key\match"^__"
            self[new_method_name] = val 
            self\add_handler key, val
    cls.__init self, ...

    -- Add in the other mixins that this one relies on
    self.mixed_in[cls] = cls
    if cls.needs != nil then
        for _, val in pairs cls.needs
            -- Get class from globals table
            val_cls = _G[val]
            if val_cls == nil
                error "Does not exist: " .. val
            if not self.mixed_in[val_cls]
                mixin self, val_cls

mixout = (cls, ...) =>
    for key, val in pairs cls.__base
        new_method_name = cls.__name .. key
        if not key\match"^__"
            self[new_method_name] = nil 
            self\remove_handler key, val


object_count = 0

objects = {}
class Object
    new: =>
        @mixed_in = {}
        @handlers = {}
        @id = tostring(object_count)
        object_count += 1
        @actor = actor.create(@id, @_think)
        @\mixins!
        table.insert objects, @

        -- We have to manually add builtin handlers
        @\add_handler "mixin", Object.mixin
        @\add_handler "mixout", Object.mixout
        @\add_handler "remove", Object.remove

    add_handler: (name, method) =>
        --print 'add_handler', name, method
        if not @handlers[name]
            @handlers[name] = {} 
        table.insert @handlers[name], method

    remove_handler: (name, method) =>
        if @handlers[name]
            for key, method_name in pairs @handlers[name]
                if method_name == method
                    --print 'removingx', name, method
                    table.remove @handlers[name], key

    _start: =>
        actor.start(@actor, @)

    _think: =>
        while true
            actor.wait(@, @handlers)

    _mixin: (cls) =>
        mixin self, cls

    -- Receive mixin message
    -- This adds a mixin to the class
    mixin: (class_name, sender) =>
        self\_mixin _G[class_name]

    -- Receive mixout message
    -- This removes a mixin from the class
    mixout: (class_name, sender) =>
        mixout self, _G[class_name]

    remove: (msg, sender) =>
        for key, obj in pairs objects
            if obj == @
                table.remove objects, key
