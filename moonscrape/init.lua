local socket = require("socket")
local http = require("socket.http")
math.randomseed(os.time())
local clean_url, normalize_url, random_normal
do
  local _obj_0 = require("moonscrape.util")
  clean_url, normalize_url, random_normal = _obj_0.clean_url, _obj_0.normalize_url, _obj_0.random_normal
end
local QueuedUrls, Pages, Runs
do
  local _obj_0 = require("moonscrape.models")
  QueuedUrls, Pages, Runs = _obj_0.QueuedUrls, _obj_0.Pages, _obj_0.Runs
end
local Scraper
do
  local _base_0 = {
    project = nil,
    sleep = nil,
    user_agent = "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405",
    reset = function(self)
      return QueuedUrls:reset(self.project)
    end,
    normalize_url = function(self, url)
      return normalize_url(url)
    end,
    has_url = function(self, url)
      return QueuedUrls:has_url(self, url)
    end,
    url_priority = function(self, url)
      return 0
    end,
    filter_page = function(self, queued_url, status, body, headers)
      if not (status == 200) then
        return false, "non 200"
      end
      if not ((headers["content-type"] or ""):match("text")) then
        return false, "non-text content type"
      end
      return true
    end,
    filter_url = function(self, url)
      return true
    end,
    _url_clause = function(self)
      local db = require("lapis.db")
      return db.encode_clause({
        project = self.project or db.NULL
      })
    end,
    all_queued = function(self)
      return QueuedUrls:select("\n      where " .. tostring(self:_url_clause()) .. " and status = ?\n    ", QueuedUrls.statuses.queued)
    end,
    reprioritize_queued = function(self)
      local count = 0
      local _list_0 = self:all_queued()
      for _index_0 = 1, #_list_0 do
        local url = _list_0[_index_0]
        local priority = self:url_priority(url.url)
        if priority ~= url.priority then
          url:update({
            priority = priority
          })
          count = count + 1
        end
      end
      return count
    end,
    refilter_queued = function(self)
      local count = 0
      local _list_0 = self:all_queued()
      for _index_0 = 1, #_list_0 do
        local url = _list_0[_index_0]
        if not (self:filter_url(url.url)) then
          url:delete()
          count = count + 1
        end
      end
      return count
    end,
    requeue_failed = function(self)
      local db = require("lapis.db")
      db.query("\n      delete from pages where queued_url_id in (\n        select id from queued_urls where " .. tostring(self:_url_clause()) .. " and status = ?\n      )\n    ", QueuedUrls.statuses.failed)
      local res = db.update(QueuedUrls:table_name(), {
        status = QueuedUrls.statuses.queued
      }, tostring(self:_url_clause()) .. " and status = ?", QueuedUrls.statuses.failed)
      return res.affected_rows
    end,
    rescan_complete = function(self)
      local count
      count = function()
        return QueuedUrls:count(tostring(self:_url_clause()) .. " and status = ?", QueuedUrls.statuses.queued)
      end
      local before_count = count()
      local pager = QueuedUrls:paginated("\n      where " .. tostring(self:_url_clause()) .. " and status = ?\n      and url like '%/stats'\n\n    ", QueuedUrls.statuses.complete, {
        per_page = 200,
        prepare_results = function(urls)
          Pages:include_in(urls, "queued_url_id", {
            flip = true
          })
          return urls
        end
      })
      for group in pager:each_page() do
        for _index_0 = 1, #group do
          local _continue_0 = false
          repeat
            local url = group[_index_0]
            if not (url.page) then
              _continue_0 = true
              break
            end
            url.scraper = self
            self:default_handler(url, url.page)
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
      end
      return count() - before_count
    end,
    run = function(self)
      local run = Runs:create({
        project = self.project
      })
      local start_time = socket.gettime()
      local count = 0
      local finish_status
      while true do
        local _continue_0 = false
        repeat
          do
            local msg = run:check_message()
            if msg then
              finish_status = "canceled"
              break
            end
          end
          local next_url = QueuedUrls:get_next(self)
          if not (next_url) then
            break
          end
          count = count + 1
          run:increment()
          local page, err = next_url:fetch()
          if not (page) then
            local colors = require("ansicolors")
            if not (self.silent) then
              print(colors("%{bright}%{yellow}Skipped:%{reset} " .. tostring(err)))
            end
            _continue_0 = true
            break
          end
          do
            local cb = self.callbacks[next_url.id] or self.default_handler
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
      local elapsed = socket.gettime() - start_time
      run:finish(finish_status)
      if not (self.silent) then
        return print("Processed " .. tostring(count) .. " urls in " .. tostring(("%.2f"):format(elapsed)) .. " seconds")
      end
    end,
    queue = function(self, url_opts, callback)
      if type(url_opts) == "string" then
        url_opts = {
          url = url_opts
        }
      end
      url_opts.url = clean_url(url_opts.url)
      url_opts.normalized_url = self:normalize_url(url_opts.url)
      local save, reason = self:filter_url(url_opts.url)
      if not (save) then
        return nil, reason or "skipping from filter_url"
      end
      if not url_opts.force and self:has_url(url_opts.url) then
        return nil, "skipping URL already fetched"
      end
      url_opts.scraper = self
      url_opts.priority = url_opts.priority or self:url_priority(url_opts.url)
      local url = QueuedUrls:create(url_opts)
      self.callbacks[url.id] = callback
      return true
    end,
    request = function(self, url)
      if url:match("^https:") then
        http = require("ssl.https")
      else
        http = require("socket.http")
      end
      local ltn12 = require("ltn12")
      do
        local seconds = self.sleep
        if seconds then
          if type(seconds) == "table" then
            local target, spread
            target, spread = seconds[1], seconds[2]
            seconds = target + math.abs(random_normal(spread))
          end
          socket.sleep(seconds)
        end
      end
      local buffer = { }
      local success, status, headers = http.request({
        url = url,
        sink = ltn12.sink.table(buffer),
        redirect = false,
        headers = {
          ["User-Agent"] = self.user_agent
        }
      })
      assert(success, status)
      return table.concat(buffer), status, headers
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
        "sleep",
        "filter_page",
        "filter_url",
        "normalize_url",
        "default_handler",
        "silent",
        "url_priority"
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
