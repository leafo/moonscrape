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
local normalize_url
normalize_url = function(url)
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
return {
  is_relative_url = is_relative_url,
  normalize_url = normalize_url,
  decode_html_entities = decode_html_entities
}
