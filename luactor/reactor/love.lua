--
-- Reactor Interface
--
-- This is an fake model of a reactor or dispatcher, based on reactor
-- pattern. There are many event-driven based libraries,
-- eg. libevent(luaevent), libev(lua-ev), uloop(OpenWrt) and so on.
--
-- This interface provide an template of the reactor/dispatcher,
-- so it is easy to port to any other system.
--
-- A dispather can hold multiple transports.
--
-- Any reactor MUST follow this interface.
--

local your_reactor = {}

local __events = {}

--
-- method to register a fd event
--
-- return the event object which is used to unregister
--
your_reactor.register_fd_event = function (fd_event_cb, fd, ev_type)
    print("register")
    local event = {valid=true, cb=fd_event_cb}
    --love.event.push(event, fd_event_cb)
    table.insert(__events, event)
    return event
end

--
-- method to register a timeout event
--
-- return the event object which is used to unregister
--
your_reactor.register_timeout_cb = function (timeout_cb, timeout_interval)
    print("timeout")
    local event = {valid=true, cb=timeout_cb}
    --love.event.push(event, timeout_cb)
    table.insert(__events, event)
    return event
end

--
-- method to unregister a timeout or fd event
--
your_reactor.unregister_event = function (ev_obj)
    print("unregister")
    --error('Method not implemented.')
end

--
-- run the reactor to start listen all events
--
your_reactor.run = function ()
    local event = table.remove(__events)
    if event then
        print("polling")
        event.cb()
    end
--    for e, a, b, c, d in __events do
--        print('loop')
--        print(e .. a)
--        a()
--    end
end

--
-- cancel the reactor
--
your_reactor.cancel = function ()
    print("cancel")
    --error('Method not implemented.')
end

return your_reactor
