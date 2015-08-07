
is_relative_url = (url) ->
  return false if url\match "^%w+:" -- mailto:
  return false if url\match "^%w+://" -- http://
  return false if url\match "^//" -- //hello.world

  true

normalize_url = (url) ->
  (url\gsub("#.*$", ""))

{ :is_relative_url, :normalize_url }
