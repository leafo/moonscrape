
is_relative_url = (url) ->
  return false if url\match "^%w+:" -- mailto:
  return false if url\match "^%w+://" -- http://
  return false if url\match "^//" -- //hello.world

  true

clean_url = (url) ->
  url = url\gsub("#.*$", "")\gsub "(//[^/]+)/$", "%1"
  url

decode_html_entities = do
  import utf8 from require "unicode"
  entities = { amp: '&', gt: '>', lt: '<', quot: '"', apos: "'" }

  (str) ->
    (str\gsub '&(.-);', (tag) ->
      if entities[tag]
        entities[tag]
      elseif chr = tag\match "#(%d+)"
        utf8.char tonumber chr
      elseif chr = tag\match "#[xX]([%da-fA-F]+)"
        utf8.char tonumber chr, 16
      else
        '&'..tag..';')

-- turn url into a canonical string
normalize_url = (url) ->
  import parse_query_string from require "lapis.util"
  query = url\match ".-%?(.*)"

  query = if query
    flat_query = {}
    for _,{k,v} in ipairs parse_query_string(query) or {}
      table.insert flat_query, "#{k}=#{v}"

    table.sort flat_query
    flat_query = table.concat(flat_query, "&")
    "?#{flat_query}"
  else
    ""

  host, path = url\match "//([^/#?]*)(/?[^#?]*)"
  unless host
    return nil, "invalid url"

  portless_host, port = host\match "^(.-):(%d+)$"
  host = portless_host or host

  port or= "80"
  port = if port == "80"
    ""
  else
    ":#{port}"

  if path == "/"
    path = ""

  "#{host}#{port}#{path}#{query}"


_random = math.random
random_normal = (std=1)->
  rand = (_random! + _random! + _random! + _random! + _random! + _random! + _random! + _random! + _random! + _random! + _random! + _random!) / 12
  rand = (rand - 0.5) * 2
  rand * std

{ :is_relative_url, :clean_url, :normalize_url, :decode_html_entities, :random_normal }
