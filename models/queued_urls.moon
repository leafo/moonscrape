
db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import is_relative_url from require "moonscrape.util"

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

    if is_relative_url opts.url
      error "Must get full URL for queued URL, got relative: #{opts.url}"

    opts.status = @statuses\for_db opts.status or "queued"

    opts.tags = if opts.tags and next opts.tags
      db.array opts.tags
    else
      nil

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

    assert url_opts.url, "missing URL for fetch"
    url_opts.url = @join url_opts.url

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

  -- calculate absolute url from relative path
  join: (path) =>
    -- TODO: support scheme relative URLs
    return path unless is_relative_url path

    scheme, host, rest = @url\match "(%w+)://([^/]+)(.*)$"
    error "couldn't parse url: #{@url}" unless scheme
    url_parts = [p for p in rest\gmatch "[^/]+"]

    -- remove frament if it exists
    for i, p in ipairs url_parts
      if p\match "#"
        p = p\gsub "#.*", ""

        url_parts = if p == ""
          { unpack url_parts, 1, i - 1 }
        else
          url_parts[i] = p
          { unpack url_parts, 1, i }

        break

    for path_part in path\gmatch "[^/]+"
      switch path_part
        when "."
          nil
        when ".."
          table.remove url_parts
        else
          table.insert url_parts, path_part

    url_out = "#{scheme}://#{host}"

    -- extract fragment
    local fragment
    for i, p in ipairs url_parts
      if p\match "^#"
        fragment = table.concat {unpack url_parts, i}, "/"
        url_parts = { unpack url_parts, 1, i - 1 }

    out_path = url_parts[1] and table.concat url_parts, "/"

    if out_path
      url_out ..= "/#{out_path}"

    if fragment
      url_out ..= fragment

    url_out


