
http = require "socket.http"

import QueuedUrls, Pages from require "models"

callbacks = {}

run = ->
  while true
    next_url = QueuedUrls\get_next!
    return unless next_url

    page = next_url\fetch!
    if cb = callbacks[next_url.id]
      cb next_url, page

queue = (url_opts, callback) ->
  if type(url_opts) == "string"
    url_opts = { url: url_opts }

  url = QueuedUrls\create url_opts
  callbacks[url.id] = callback

{:run, :queue}
