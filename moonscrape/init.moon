
http = require "socket.http"

import QueuedUrls, Pages from require "models"

import normalize_url from require "moonscrape.util"

callbacks = {}

has_url = (url) ->
  QueuedUrls\find url: url

run = ->
  while true
    next_url = QueuedUrls\get_next!
    return unless next_url

    page, err = next_url\fetch!

    unless page
      colors = require "ansicolors"
      print\write colors "%{bright}%{red}Warning:%{reset} #{err}"
      continue

    if cb = callbacks[next_url.id]
      cb next_url, page

queue = (url_opts, callback) ->
  if type(url_opts) == "string"
    url_opts = { url: url_opts }

  url_opts.url = normalize_url url_opts.url

  if not url_opts.force and has_url url_opts.url
    return nil, "skipping URL already fetched"

  url = QueuedUrls\create url_opts
  callbacks[url.id] = callback


{:run, :queue, :has_url}
