local is_relative_url
is_relative_url = function(url)
  if url:match("^%w+:") then
    return false
  end
  if url:match("^%w+://") then
    return false
  end
  if url:match("^//") then
    return false
  end
  return true
end
local clean_url
clean_url = function(url)
  url = url:gsub("#.*$", ""):gsub("(//[^/]+)/$", "%1")
  return url
end
local decode_html_entities
do
  local utf8
  utf8 = require("unicode").utf8
  local entities = {
    amp = '&',
    gt = '>',
    lt = '<',
    quot = '"',
    apos = "'"
  }
  decode_html_entities = function(str)
    return (str:gsub('&(.-);', function(tag)
      if entities[tag] then
        return entities[tag]
      else
        do
          local chr = tag:match("#(%d+)")
          if chr then
            return utf8.char(tonumber(chr))
          else
            do
              chr = tag:match("#[xX]([%da-fA-F]+)")
              if chr then
                return utf8.char(tonumber(chr, 16))
              else
                return '&' .. tag .. ';'
              end
            end
          end
        end
      end
    end))
  end
end
local normalize_url
normalize_url = function(url)
  local parse_query_string
  parse_query_string = require("lapis.util").parse_query_string
  local query = url:match(".-%?(.*)")
  if query then
    local flat_query = { }
    for _, _des_0 in ipairs(parse_query_string(query)) do
      local k, v
      k, v = _des_0[1], _des_0[2]
      table.insert(flat_query, tostring(k) .. "=" .. tostring(v))
    end
    table.sort(flat_query)
    flat_query = table.concat(flat_query, "&")
    query = "?" .. tostring(flat_query)
  else
    query = ""
  end
  local host, path = url:match("//([^/#?]*)(/?[^#?]*)")
  if not (host) then
    return nil, "invalid url"
  end
  local portless_host, port = host:match("^(.-):(%d+)$")
  host = portless_host or host
  port = port or "80"
  if port == "80" then
    port = ""
  else
    port = ":" .. tostring(port)
  end
  if path == "/" then
    path = ""
  end
  return tostring(host) .. tostring(port) .. tostring(path) .. tostring(query)
end
local _random = math.random
local random_normal
random_normal = function(std)
  if std == nil then
    std = 1
  end
  local rand = (_random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random() + _random()) / 12
  rand = (rand - 0.5) * 2
  return rand * std
end
return {
  is_relative_url = is_relative_url,
  clean_url = clean_url,
  normalize_url = normalize_url,
  decode_html_entities = decode_html_entities,
  random_normal = random_normal
}
