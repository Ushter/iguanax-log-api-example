-- Retrieve component error logs and metadata through the Iguana X API.
local function post(baseUrl, path, parameters, cookie)
   local body, status, headers = net.http.post{
      url = baseUrl .. path,
      parameters = parameters,
      headers = cookie and {Cookie = cookie} or {},
      live = true
   }
   assert(status and status >= 200 and status < 300, 'Iguana X API request failed')
   return body, headers
end

function main(Data)
   local fields = component.fields()
   local input = json.parse{data = Data}
   assert(type(input.component) == 'string' and input.component ~= '',
      'Input must specify a component')
   assert(fields.username and fields.username ~= '' and
      fields.password and fields.password ~= '', 'Configure component credentials')

   local baseUrl = (fields.base_url or 'http://127.0.0.1:7654'):gsub('/+$', '')
   assert(baseUrl:match('^https?://'), 'Base URL must use HTTP or HTTPS')
   local _, headers = post(baseUrl, '/session/login', {
      username = fields.username,
      password = fields.password
   })
   local rawCookie = headers and (headers['Set-Cookie'] or headers['set-cookie'])
   local cookie = rawCookie and rawCookie:match('^[^;]+')
   assert(cookie, 'Login did not return a session cookie')

   local ok, payload = pcall(function()
      local logBody = post(baseUrl, '/logs/retrieve', {
         component = input.component,
         exact = '',
         formatted = true,
         include_non_matches = false,
         limit = 5,
         search = '',
         tags = '#error'
      }, cookie)
      local detailBody = post(baseUrl, '/component/detail', {
         component = input.component
      }, cookie)
      local logs = json.parse{data = logBody}
      local details = json.parse{data = detailBody}
      -- Preserve API ordering instead of assuming which record is newest.
      return {logs = logs.data or {}, component = details}
   end)

   local loggedOut = pcall(post, baseUrl, '/session/logout', {}, cookie)
   assert(ok, 'Unable to retrieve component logs and details')
   assert(loggedOut, 'Unable to close the API session')
   queue.push{data = json.serialize{data = payload}}
end
