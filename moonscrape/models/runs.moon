
db = require "lapis.db"
import Model, enum from require "lapis.db.model"

class Runs extends Model
  @timestamp: true

  @statuses: enum {
    running: 1
    finished: 2
    canceled: 3
  }

  @create: (opts={}) =>
    opts.started_at or= db.raw "NOW()"
    opts.status or= @statuses\for_db opts.status or "running"
    Model.create @, opts

  check: =>
    @refresh "message"
    if m = @message
      @update message: db.NULL
      return m

  finish: =>
    @update finished_at: db.raw "NOW()"

  increment: =>
    @update {
      processed_count: db.raw "processed_count + 1"
    }


