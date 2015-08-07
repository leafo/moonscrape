
import queue, run from require "moonscrape"
import is_relative_url from require "moonscrape.util"

import query_all from require "web_sanitize.query"

handle_result = (url, page) ->
  print "working on #{url.url} #{page} (#{page.status})"
  return if page.status != 200

  for link in *query_all page.body, "a"
    href = link.attr and link.attr.href
    if href and is_relative_url href
      tags = {}

      table.insert tags, "posts" if href\match "/posts/"
      table.insert tags, "guides" if href\match "/guides/"

      url\queue { :tags, url: href }, handle_result

queue "http://leafo.net", handle_result

run!
