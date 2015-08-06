
db = require "lapis.db"
import Model, enum from require "lapis.db.model"

class QueuedUrls extends Model
  @timestamp: true

  @statuses: enum {
    queued: 1
    running: 2
    complete: 3
  }

  @relations: {
    {"page", has_one: "Pages"}
  }

  @create: (opts) =>
    assert opts.url, "missing URL"
    opts.status = @statuses\for_db opts.status or "queued"
    opts.tags = db.array opts.tags if opts.tags
    Model.create @, opts

  @get_next: =>
    res = db.update @table_name!, {
      status: @statuses.running
    }, "
      id in (
        select id from #{db.escape_identifier @table_name!}
        where status = ? order by depth asc limit 1 for update
      ) returning *
    ", @statuses.queued

    res = unpack res
    if res
      @load res
    else
      nil, "queue empty"

