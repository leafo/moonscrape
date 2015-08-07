
is_relative_url = (url) ->
  return false if url\match "^%w+:" -- mailto:
  return false if url\match "^%w+://" -- http://
  return false if url\match "^//" -- //hello.world

  true

normalize_url = (url) ->
  url = url\gsub("#.*$", "")\gsub "(//[^/]+)/$", "%1"
  url

{ :is_relative_url, :normalize_url }
