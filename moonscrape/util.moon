
is_relative_url = (url) ->
  return false if url\match "^%w+:" -- mailto:
  return false if url\match "^%w+://" -- http://
  return false if url\match "^//" -- //hello.world

  true

normalize_url = (url) ->
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

{ :is_relative_url, :normalize_url, :decode_html_entities }
