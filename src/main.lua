-- Retrieve component error logs and metadata through the Iguana X API.
-- Send one form-parameter POST request, optionally authenticated by a session cookie.
-- Return the response body and headers. Raise a generic error for non-2xx status
-- so API response bodies and authentication details do not appear in error messages.
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

-- Iguana X entry point. Data is JSON containing the target component identifier.
-- Authenticate, retrieve logs and metadata, attempt logout, then queue the combined result.
function main(Data)
   -- Read deployment configuration separately from the input component identifier.
   local fields = component.fields()
   local input = json.parse{data = Data}
   assert(type(input.component) == 'string' and input.component ~= '',
      'Input must specify a component')
   assert(fields.username and fields.username ~= '' and
      fields.password and fields.password ~= '', 'Configure component credentials')

   local baseUrl = (fields.base_url or 'http://127.0.0.1:7654'):gsub('/+$', '')
   assert(baseUrl:match('^https?://'), 'Base URL must use HTTP or HTTPS')
   -- Start a session using protected component fields. Keep its cookie only in memory.
   local _, headers = post(baseUrl, '/session/login', {
      username = fields.username,
      password = fields.password
   })
   -- Accept either common header capitalization and retain only the first cookie pair.
   -- This example assumes the session cookie is the first Set-Cookie value.
   local rawCookie = headers and (headers['Set-Cookie'] or headers['set-cookie'])
   local cookie = rawCookie and rawCookie:match('^[^;]+')
   assert(cookie, 'Login did not return a session cookie')

   -- Protect both retrievals and JSON parsing so a failure still reaches the logout attempt.
   local ok, payload = pcall(function()
      -- Request at most five error-tagged entries. No chronological ordering is assumed.
      local logBody = post(baseUrl, '/logs/retrieve', {
         component = input.component,
         exact = '',
         formatted = true,
         include_non_matches = false,
         limit = 5,
         search = '',
         tags = '#error'
      }, cookie)
      -- Retrieve metadata for the same component so downstream consumers have context.
      local detailBody = post(baseUrl, '/component/detail', {
         component = input.component
      }, cookie)
      local logs = json.parse{data = logBody}
      local details = json.parse{data = detailBody}
      -- Preserve API ordering instead of assuming which record is newest.
      return {logs = logs.data or {}, component = details}
   end)

   -- Attempt session cleanup on either retrieval outcome. Cleanup failure also prevents
   -- queue publication; the downstream channel receives results only after both checks pass.
   local loggedOut = pcall(post, baseUrl, '/session/logout', {}, cookie)
   assert(ok, 'Unable to retrieve component logs and details')
   assert(loggedOut, 'Unable to close the API session')
   -- Serialize a named object with logs and component fields. Log contents may contain
   -- operational data even though no original log samples are embedded in this repository.
   queue.push{data = json.serialize{data = payload}}
end
