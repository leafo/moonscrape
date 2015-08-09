socket = require "socket"
http = require "socket.http"

math.randomseed os.time!

import clean_url, normalize_url, random_normal from require "moonscrape.util"
import QueuedUrls, Runs from require "moonscrape.models"

class Scraper
  project: nil
  sleep: nil

  user_agent: "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405"

  new: (opts={}) =>
    for k in *{
      "project", "user_agent", "sleep", "filter_page", "filter_url",
      "normalize_url", "default_handler", "silent"
    }
      @[k] = opts[k]

    @callbacks = {}

  reset: =>
    QueuedUrls\reset @project

  normalize_url: (url) =>
    normalize_url url

  has_url: (url) =>
    QueuedUrls\has_url @, url

  filter_page: (queued_url, status, body, headers) =>
    unless status == 200
      return false, "non 200"

    unless (headers["content-type"] or "")\match "text"
      return false, "non-text content type"

    true

  -- queue all urls
  filter_url: (url) => true

  refilter_queued: =>
    count = 0
    for url in *QueuedUrls\select "where project = ? and status = 1", @project or db.NULL
      unless @filter_url url.url
        url\delete!
        count += 1

    count

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
      return nil, reason or "skipping filter_page"

    if not url_opts.force and @has_url url_opts.url
      return nil, "skipping URL already fetched"

    url_opts.scraper = @
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
