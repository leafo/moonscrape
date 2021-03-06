
db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import is_relative_url, clean_url from require "moonscrape.util"

class QueuedUrls extends Model
  @timestamp: true

  @statuses: enum {
    queued: 1
    running: 2
    complete: 3
    failed: 4
  }

  @get_relation_model: (name) =>
    require("moonscrape.models")[name]

  @relations: {
    {"page", has_one: "Pages"}
  }

  @has_url: (scraper, url) =>
    normalized = scraper\normalize_url url

    url_match = db.encode_clause :url
    normalized_match = db.encode_clause normalized_url: normalized
    redirect_match = db.interpolate_query "(redirects is not null and ? <@ redirects)", db.array({url})

    not not QueuedUrls\find {
      project: scraper.project or db.NULL
      [db.TRUE]: db.raw "(#{url_match} OR #{normalized_match} OR #{redirect_match})"
    }

  @reset: (project) =>
    db.delete @table_name!, {
      project: project or db.NULL
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

    scraper = opts.scraper
    opts.project = scraper and scraper.project or db.NULL

    opts.scraper = nil

    with Model.create @, opts
      .scraper = scraper

  @get_next: (scraper) =>
    clause = db.encode_clause {
      project: scraper.project or db.NULL
      status: @statuses.queued
    }

    res = db.update @table_name!, {
      status: @statuses.running
    }, "
      id in (
        select id from #{db.escape_identifier @table_name!}
        where #{clause}
        order by priority desc, depth asc limit 1 for update
      ) returning *
    "

    res = unpack res

    if res
      with @load res
        .scraper = scraper
    else
      nil, "queue empty"

  queue: (url_opts, ...) =>
    assert @scraper, "missing scraper for QueuedUrls\\queue"

    if type(url_opts) == "string"
      url_opts = { url: url_opts }

    url_opts.parent_queued_url_id = @id
    url_opts.depth = @depth + 1

    assert url_opts.url, "missing URL for fetch"
    url_opts.url = @join url_opts.url

    @scraper\queue url_opts, ...

  fetch: =>
    assert @status == @@statuses.running, "invalid status for fetch"
    import Pages from require "moonscrape.models"

    colors = require "ansicolors"
    unless @scraper.silent
      io.stdout\write colors "%{bright}%{cyan}Fetching:%{reset} #{@url}"

    redirects = {}
    redirects_set = {}

    local status, body, headers

    current_url = @url
    max_redirects = 10

    finish_log = ->
      status_color = switch math.floor(status/100)
        when 2
          "green"
        when 3
          "yellow"
        else
          "red"

      unless @scraper.silent
        print colors " [%{#{status_color}}#{status}%{reset}]"

    while true
      max_redirects -= 1
      if max_redirects == 0
        @mark_failed!
        finish_log!
        return nil, "too many redirects"

      body, status, headers = @scraper\request current_url

      if math.floor(status/100) == 3
        new_url = headers.location

        unless new_url
          @mark_failed!
          finish_log!
          return nil, "missing location"

        new_url = clean_url new_url

        if redirects_set[new_url]
          @mark_failed!
          finish_log!
          return nil, "redirect loop"

        table.insert redirects, new_url
        redirects_set[new_url] = true
        current_url = new_url
      else
        break

    if next redirects
      unless @scraper.silent
        io.stdout\write " (redirects: #{#redirects})"

    finish_log!

    save_page, filter_reason = if @scraper.filter_page
      @scraper\filter_page @, status, body, headers
    else
      true

    page = if save_page
      Pages\create {
        :body
        :status
        content_type: headers["content-type"]
        queued_url_id: @id
      }

    url_status = if "#{status}"\match "^5"
      "failed"
    else
      "complete"

    @update {
      status: QueuedUrls.statuses\for_db url_status
      redirects: redirects[1] and db.array redirects
    }

    page, filter_reason or "filtered page"

  mark_failed: =>
    @update status: QueuedUrls.statuses.failed

  -- calculate absolute url from relative path
  join: (path) =>
    base_url = @redirects and @redirects[#@redirects] or @url

    -- TODO: support scheme relative URLs
    return path unless is_relative_url path
    return base_url if path == ""

    scheme, host, rest = base_url\match "(%w+)://([^/]+)(.*)$"
    error "couldn't parse url: #{base_url}" unless scheme

    rest = rest\gsub "[?#].*$", ""
    in_directory = rest == "" or rest\match "/$"

    url_parts = [p for p in rest\gmatch "[^/]+"]

    path_head, path_tail = path\match "(.-)(/?[?#].*)$"
    path = path_head if path_head

    if path\match "^/"
      url_parts = {(path\gsub "^/", "")}
    else
      for path_part in path\gmatch "[^/]+"
        switch path_part
          when "."
            nil
          when ".."
            table.remove url_parts
          else
            unless in_directory
              table.remove url_parts
              in_directory = true

            table.insert url_parts, path_part

    url_out = "#{scheme}://#{host}"

    out_path = url_parts[1] and table.concat url_parts, "/"

    if out_path
      url_out ..= "/#{out_path}"

    if path_tail
      url_out ..= path_tail

    url_out


