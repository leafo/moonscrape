
db = require "lapis.db"
import Model, enum from require "lapis.db.model"

class QueuedUrls extends Model
  @timestamp: true

  @statuses: enum {
    queued: 1
    running: 2
    complete: 3
    failed: 4
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

  queue: (url_opts, ...) =>
    import queue from require "moonscrape"

    if type(url_opts) == "string"
      url_opts = { url: url_opts }

    url_opts.parent_queued_url_id = @id
    url_opts.depth = @depth + 1

    queue url_opts, ...

  fetch: =>
    assert @status == @@statuses.running, "invalid status for fetch"
    http = require "socket.http"
    import Pages from require "models"

    colors = require "ansicolors"
    print colors "%{bright}%{cyan}Fetching:%{reset} #{@url}"

    body, status, headers = http.request @url

    page = Pages\create {
      :body
      :status
      queued_url_id: @id
    }

    url_status = if "#{status}"\match "^5"
      "failed"
    else
      "complete"

    @update status: QueuedUrls.statuses\for_db url_status
    page

