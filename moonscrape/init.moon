socket = require "socket"
http = require "socket.http"

math.randomseed os.time!

import clean_url, normalize_url, random_normal from require "moonscrape.util"
import QueuedUrls, Pages, Runs from require "moonscrape.models"

class Scraper
  project: nil
  sleep: nil

  user_agent: "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405"

  new: (opts={}) =>
    for k in *{
      "project", "user_agent", "sleep", "filter_page", "filter_url",
      "normalize_url", "default_handler", "silent", "url_priority"
    }
      @[k] = opts[k]

    @callbacks = {}

  reset: =>
    QueuedUrls\reset @project

  normalize_url: (url) =>
    normalize_url url

  has_url: (url) =>
    QueuedUrls\has_url @, url

  url_priority: (url) => 0

  filter_page: (queued_url, status, body, headers) =>
    unless status == 200
      return false, "non 200"

    unless (headers["content-type"] or "")\match "text"
      return false, "non-text content type"

    true

  -- queue all urls
  filter_url: (url) => true

  _url_clause: =>
    db = require "lapis.db"
    db.encode_clause { project: @project or db.NULL }

  all_queued: =>
    QueuedUrls\select "
      where #{@_url_clause!} and status = ?
    ", QueuedUrls.statuses.queued

  reprioritize_queued: =>
    count = 0
    for url in *@all_queued!
      priority = @url_priority url.url
      if priority != url.priority
        url\update(:priority)
        count += 1

    count

  refilter_queued: =>
    count = 0
    for url in *@all_queued!
      unless @filter_url url.url
        url\delete!
        count += 1

    count

  requeue_failed: =>
    db = require "lapis.db"
    db.query "
      delete from pages where queued_url_id in (
        select id from queued_urls where #{@_url_clause!} and status = ?
      )
    ", QueuedUrls.statuses.failed

    res = db.update QueuedUrls\table_name!, {
      status: QueuedUrls.statuses.queued
    }, "#{@_url_clause!} and status = ?", QueuedUrls.statuses.failed

    res.affected_rows

  rescan_complete: =>
    count = ->
      QueuedUrls\count "#{@_url_clause!} and status = ?", QueuedUrls.statuses.queued

    before_count = count!

    pager = QueuedUrls\paginated "
      where #{@_url_clause!} and status = ?
      and url like '%/stats'

    ", QueuedUrls.statuses.complete, {
        per_page: 200
        prepare_results: (urls) ->
          Pages\include_in urls, "queued_url_id", flip: true
          urls
      }

    for group in pager\each_page!
      for url in *group
        continue unless url.page
        url.scraper = @
        @default_handler url, url.page

    count! - before_count

  run: =>
    run = Runs\create project: @project

    start_time = socket.gettime!
    count = 0

    local finish_status

    while true
      if msg = run\check_message!
        finish_status = "canceled"
        break

      next_url = QueuedUrls\get_next @
      break unless next_url
      count += 1
      run\increment!

      page, err = next_url\fetch!

      unless page
        colors = require "ansicolors"
        unless @silent
          print colors "%{bright}%{yellow}Skipped:%{reset} #{err}"
        continue

      if cb = @callbacks[next_url.id] or @default_handler
        cb @, next_url, page

    elapsed = socket.gettime! - start_time
    run\finish finish_status

    unless @silent
      print "Processed #{count} urls in #{"%.2f"\format elapsed} seconds"

  queue: (url_opts, callback) =>
    if type(url_opts) == "string"
      url_opts = { url: url_opts }

    url_opts.url = clean_url url_opts.url
    url_opts.normalized_url = @normalize_url url_opts.url

    save, reason = @filter_url url_opts.url
    unless save
      return nil, reason or "skipping from filter_url"

    if not url_opts.force and @has_url url_opts.url
      return nil, "skipping URL already fetched"


    url_opts.scraper = @
    url_opts.priority or= @url_priority url_opts.url

    url = QueuedUrls\create url_opts

    @callbacks[url.id] = callback
    true

  request: (url) =>
    http = if url\match "^https:"
      require "ssl.https"
    else
      require "socket.http"

    ltn12 = require "ltn12"

    if seconds = @sleep
      if type(seconds) == "table"
        {target, spread} = seconds
        seconds = target + math.abs random_normal spread

      socket.sleep seconds

    buffer = {}
    success, status, headers = http.request {
      :url
      sink: ltn12.sink.table buffer
      redirect: false
      headers: {
        "User-Agent": @user_agent
      }
    }

    assert success, status
    table.concat(buffer), status, headers

default_scraper = Scraper!

{
  run: default_scraper\run
  queue: default_scraper\queue
  has_url: default_scraper\has_url
  :default_scraper

  :Scraper
}
