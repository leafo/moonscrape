
db = require "laips.db"
import Model, enum from require "lapis.db.model"

class QueuedUrls extends Model
  @timestamp: true

  @statuses: enum {
    queued: 1
    fetching: 2
    complete: 3
  }

  @create: (opts) =>
    assert opts.url, "missing URL"
    opts.status = @statuses\for_db opts.status or "fetching"
    Model.create @

  @get_next: =>
    -- db.update @table_name!, {
    --   status: @statuses.fetching
    -- }, "where "

