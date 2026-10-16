local calls, queued, fail, empty = {}, nil, false, false
component = {fields = function() return {username = 'synthetic-user', password = 'synthetic-placeholder'} end}
json = {
   parse = function(options)
      if options.data == 'input' then return {component = 'synthetic-component'} end
      if options.data == 'logs' then return {data = empty and {} or {{message = 'Synthetic error'}}} end
      return {name = 'Synthetic component'}
   end,
   serialize = function(options) return options.data end
}
queue = {push = function(options) queued = options.data end}
net = {http = {post = function(options)
   calls[#calls + 1] = options.url
   if options.url:find('/session/login', 1, true) then
      return '', 200, {['Set-Cookie'] = 'session=synthetic; Path=/'}
   end
   if options.url:find('/logs/retrieve', 1, true) then
      if fail then error('Synthetic request failure') end
      return 'logs', 200, {}
   end
   return 'detail', 200, {}
end}}
dofile('src/main.lua')
main('input')
assert(#queued.logs == 1)
assert(calls[#calls]:find('/session/logout', 1, true))
empty = true
main('input')
assert(#queued.logs == 0)
fail = true
queued = nil
assert(not pcall(main, 'input'))
assert(queued == nil)
assert(calls[#calls]:find('/session/logout', 1, true))
