local db = require("lapis.db")
local Model, enum
do
  local _obj_0 = require("lapis.db.model")
  Model, enum = _obj_0.Model, _obj_0.enum
end
local Runs
do
  local _parent_0 = Model
  local _base_0 = {
    check_message = function(self)
      self:refresh("message")
      do
        local m = self.message
        if m then
          self:update({
            message = db.NULL
          })
          return m
        end
      end
    end,
    finish = function(self, status)
      if status == nil then
        status = "finished"
      end
      return self:update({
        status = self.__class.statuses:for_db(status),
        finished_at = db.raw("NOW()")
      })
    end,
    increment = function(self)
      return self:update({
        processed_count = db.raw("processed_count + 1")
      })
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Runs",
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
    running = 1,
    finished = 2,
    canceled = 3
  })
  self.create = function(self, opts)
    if opts == nil then
      opts = { }
    end
    opts.started_at = opts.started_at or db.raw("NOW()")
    opts.status = opts.status or self.statuses:for_db(opts.status or "running")
    return Model.create(self, opts)
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Runs = _class_0
  return _class_0
end
