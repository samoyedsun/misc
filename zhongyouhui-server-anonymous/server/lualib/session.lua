local session = {}

function session:new(data)
    local o = {
        fd      = nil, 
        ws      = nil,
        gate    = nil,
        agent   = nil,
        addr    = nil,
        ip      = nil,
        auth    = nil,
        uid     = nil,
        handle  = nil,
    }
    table.merge(o, data)
    setmetatable(o, {__index = self})
    return o
end

function session:totable()
    local ws = nil
    if self.ws then
        ws = true
    end
    local t = {fd = self.fd, 
                gate = self.gate, 
                agent = self.agent, 
                addr = self.addr, 
                ws = ws,
                ip = self.ip,
                auth = self.auth,
                uid = self.uid,
                handle = self.handle}
    return t
end

function session:tostring()
    return tostring(self:totable())
end

return session