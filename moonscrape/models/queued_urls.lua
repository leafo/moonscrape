local db = require("lapis.db")
local Model, enum
do
  local _obj_0 = require("lapis.db.model")
  Model, enum = _obj_0.Model, _obj_0.enum
end
local is_relative_url, normalize_url
do
  local _obj_0 = require("moonscrape.util")
  is_relative_url, normalize_url = _obj_0.is_relative_url, _obj_0.normalize_url
end
local QueuedUrls
do
  local _parent_0 = Model
  local _base_0 = {
    queue = function(self, url_opts, ...)
      assert(self.scraper, "missing scraper for QueuedUrls\\queue")
      if type(url_opts) == "string" then
        url_opts = {
          url = url_opts
        }
      end
      url_opts.parent_queued_url_id = self.id
      url_opts.depth = self.depth + 1
      assert(url_opts.url, "missing URL for fetch")
      url_opts.url = self:join(url_opts.url)
      return self.scraper:queue(url_opts, ...)
    end,
    fetch = function(self)
      assert(self.status == self.__class.statuses.running, "invalid status for fetch")
      local http = require("socket.http")
      local ltn12 = require("ltn12")
      local Pages
      Pages = require("moonscrape.models").Pages
      local colors = require("ansicolors")
      io.stdout:write(colors("%{bright}%{cyan}Fetching:%{reset} " .. tostring(self.url)))
      local redirects = { }
      local redirects_set = { }
      local status, body, headers
      local current_url = self.url
      local max_redirects = 10
      local finish_log
      finish_log = function()
        local status_color
        local _exp_0 = math.floor(status / 100)
        if 2 == _exp_0 then
          status_color = "green"
        elseif 3 == _exp_0 then
          status_color = "yellow"
        else
          status_color = "red"
        end
        return print(colors(" [%{" .. tostring(status_color) .. "}" .. tostring(status) .. "%{reset}]"))
      end
      while true do
        max_redirects = max_redirects - 1
        if max_redirects == 0 then
          self:mark_failed()
          finish_log()
          return nil, "too many redirects"
        end
        local buffer = { }
        local _
        _, status, headers = http.request({
          url = current_url,
          sink = ltn12.sink.table(buffer),
          redirect = false
        })
        body = table.concat(buffer)
        if math.floor(status / 100) == 3 then
          local new_url = headers.location
          if not (new_url) then
            self:mark_failed()
            finish_log()
            return nil, "missing location"
          end
          new_url = normalize_url(new_url)
          if redirects_set[new_url] then
            self:mark_failed()
            finish_log()
            return nil, "redirect loop"
          end
          table.insert(redirects, new_url)
          redirects_set[new_url] = true
          current_url = new_url
        else
          break
        end
      end
      if next(redirects) then
        io.stdout:write(" (redirects: " .. tostring(#redirects) .. ")")
      end
      finish_log()
      local page = Pages:create({
        body = body,
        status = status,
        content_type = headers["content-type"],
        queued_url_id = self.id
      })
      local url_status
      if (tostring(status)):match("^5") then
        url_status = "failed"
      else
        url_status = "complete"
      end
      self:update({
        status = QueuedUrls.statuses:for_db(url_status),
        redirects = redirects[1] and db.array(redirects)
      })
      return page
    end,
    mark_failed = function(self)
      return self:update({
        status = QueuedUrls.statuses.failed
      })
    end,
    join = function(self, path)
      local base_url = self.redirects and self.redirects[#self.redirects] or self.url
      if not (is_relative_url(path)) then
        return path
      end
      if path == "" then
        return base_url
      end
      local scheme, host, rest = base_url:match("(%w+)://([^/]+)(.*)$")
      if not (scheme) then
        error("couldn't parse url: " .. tostring(base_url))
      end
      rest = rest:gsub("[?#].*$", "")
      local in_directory = rest == "" or rest:match("/$")
      local url_parts
      do
        local _accum_0 = { }
        local _len_0 = 1
        for p in rest:gmatch("[^/]+") do
          _accum_0[_len_0] = p
          _len_0 = _len_0 + 1
        end
        url_parts = _accum_0
      end
      local path_head, path_tail = path:match("(.-)(/?[?#].*)$")
      if path_head then
        path = path_head
      end
      if path:match("^/") then
        url_parts = {
          (path:gsub("^/", ""))
        }
      else
        for path_part in path:gmatch("[^/]+") do
          local _exp_0 = path_part
          if "." == _exp_0 then
            local _ = nil
          elseif ".." == _exp_0 then
            table.remove(url_parts)
          else
            if not (in_directory) then
              table.remove(url_parts)
              in_directory = true
            end
            table.insert(url_parts, path_part)
          end
        end
      end
      local url_out = tostring(scheme) .. "://" .. tostring(host)
      local out_path = url_parts[1] and table.concat(url_parts, "/")
      if out_path then
        url_out = url_out .. "/" .. tostring(out_path)
      end
      if path_tail then
        url_out = url_out .. path_tail
      end
      return url_out
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "QueuedUrls",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.timestamp = true
  self.statuses = enum({
    queued = 1,
    running = 2,
    complete = 3,
    failed = 4
  })
  self.get_relation_model = function(self, name)
    return require("moonscrape.models")[name]
  end
  self.relations = {
    {
      "page",
      has_one = "Pages"
    }
  }
  self.has_url = function(self, scraper, url)
    local url_match = db.encode_clause({
      url = url
    })
    local redirect_match = db.interpolate_query("(redirects is not null and ? <@ redirects)", db.array({
      url
    }))
    return not not QueuedUrls:find({
      project = scraper.project or db.NULL,
      [db.TRUE] = db.raw("(" .. tostring(url_match) .. " OR " .. tostring(redirect_match) .. ")")
    })
  end
  self.create = function(self, opts)
    assert(opts.url, "missing URL")
    if is_relative_url(opts.url) then
      error("Must get full URL for queued URL, got relative: " .. tostring(opts.url))
    end
    opts.status = self.statuses:for_db(opts.status or "queued")
    if opts.tags and next(opts.tags) then
      opts.tags = db.array(opts.tags)
    else
      opts.tags = nil
    end
    local scraper = opts.scraper
    opts.project = scraper and scraper.project or db.NULL
    opts.scraper = nil
    do
      local _with_0 = Model.create(self, opts)
      _with_0.scraper = scraper
      return _with_0
    end
  end
  self.get_next = function(self, scraper)
    local clause = db.encode_clause({
      project = scraper.project or db.NULL,
      status = self.statuses.queued
    })
    local res = db.update(self:table_name(), {
      status = self.statuses.running
    }, "\n      id in (\n        select id from " .. tostring(db.escape_identifier(self:table_name())) .. "\n        where " .. tostring(clause) .. "\n        order by depth asc limit 1 for update\n      ) returning *\n    ")
    res = unpack(res)
    if res then
      do
        local _with_0 = self:load(res)
        _with_0.scraper = scraper
        return _with_0
      end
    else
      return nil, "queue empty"
    end
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  QueuedUrls = _class_0
  return _class_0
end
