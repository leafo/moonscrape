
import queue, run from require "moonscrape"
import query_all from require "web_sanitize.query"

queue "http://leafo.net", (url, page) ->
  for link in *query_all page.body, ".inner .row_list a"
    href = link.attr and link.attr.href
    if href and href\match "^http://leafo.net"
      require("moon").p link

run!
