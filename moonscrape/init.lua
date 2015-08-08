local http = require("socket.http")
local normalize_url
normalize_url = require("moonscrape.util").normalize_url
local QueuedUrls, Pages
do
  local _obj_0 = require("moonscrape.models")
  QueuedUrls, Pages = _obj_0.QueuedUrls, _obj_0.Pages
end
local Scraper
do
  local _base_0 = {
    project = nil,
    user_agent = "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405",
    has_url = function(self, url)
      return QueuedUrls:has_url(self, url)
    end,
    run = function(self)
      while true do
        local _continue_0 = false
        repeat
          local next_url = QueuedUrls:get_next(self)
          if not (next_url) then
            return 
          end
          local page, err = next_url:fetch()
          if not (page) then
            local colors = require("ansicolors")
            print:write(colors("%{bright}%{red}Warning:%{reset} " .. tostring(err)))
            _continue_0 = true
            break
          end
          do
            local cb = self.callbacks[next_url.id]
            if cb then
              cb(self, next_url, page)
            end
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end,
    queue = function(self, url_opts, callback)
      if type(url_opts) == "string" then
        url_opts = {
          url = url_opts
        }
      end
      url_opts.url = normalize_url(url_opts.url)
      if not url_opts.force and self:has_url(url_opts.url) then
        return nil, "skipping URL already fetched"
      end
      url_opts.scraper = self
      local url = QueuedUrls:create(url_opts)
      self.callbacks[url.id] = callback
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      local _list_0 = {
        "project",
        "user_agent",
        "sleep"
      }
      for _index_0 = 1, #_list_0 do
        local k = _list_0[_index_0]
        self[k] = opts[k]
      end
      self.callbacks = { }
    end,
    __base = _base_0,
    __name = "Scraper"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Scraper = _class_0
end
local default_scraper = Scraper()
return {
  run = (function()
    local _base_0 = default_scraper
    local _fn_0 = _base_0.run
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)(),
  queue = (function()
    local _base_0 = default_scraper
    local _fn_0 = _base_0.queue
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)(),
  has_url = (function()
    local _base_0 = default_scraper
    local _fn_0 = _base_0.has_url
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)(),
  default_scraper = default_scraper,
  Scraper = Scraper
}
