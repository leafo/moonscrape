
import Scraper from require "moonscrape"
import is_relative_url, decode_html_entities from require "moonscrape.util"
import query_all from require "web_sanitize.query"


leafonet = ->
  scraper = Scraper {
    project: "leafo.net"
  }

  handle_result = (url, page) =>
    return if page.status != 200

    -- skip the directory listings
    if page.body\match "Proudly Served by LiteSpeed Web Server"
      return

    for link in *query_all page.body, "a"
      href = link.attr and link.attr.href
      href = href and decode_html_entities href

      if href and is_relative_url href
        tags = {}

        table.insert tags, "posts" if href\match "/posts/"
        table.insert tags, "guides" if href\match "/guides/"

        url\queue { :tags, url: href }, handle_result


  -- scraper\queue "http://leafo.net", handle_result
  scraper\queue "http://localhost/blog2/www/", handle_result
  scraper\run!


moonrocks = ->
  scraper = Scraper {
    project: "moonrocks"
    filter_url: (url) =>
      return false if url\match "/register"
      return false if url\match "/login"
      return false if url\match "rockspec$"
      return false if url\match "rock$"
      true
  }

  handle_result = (url, page) =>
    for link in *query_all page.body, "a"
      href = link.attr and link.attr.href
      href = href and decode_html_entities href

      if href and is_relative_url href
        url\queue href, handle_result

  scraper\queue "http://localhost:8080", handle_result
  scraper\run!

-- leafonet!
moonrocks!
