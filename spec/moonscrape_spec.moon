import use_test_env from require "lapis.spec"
import request from require "lapis.spec.server"
import truncate_tables from require "lapis.spec.db"

import QueuedUrls, Runs, Pages from require "moonscrape.models"
import Scraper from require "moonscrape"

describe "moonscrape", ->
  use_test_env!

  local scraper

  before_each ->
    truncate_tables QueuedUrls, Runs, Pages
    scraper = Scraper project: "test", silent: true

    scraper.request = =>
      "hello", 200, {["content-type"]: "text"}

  it "runs scraper with no urls", ->
    scraper\run!
    assert.same 0, QueuedUrls\count!
    runs = Runs\select!
    assert.same 1, #runs
    run = unpack runs
    assert.same Runs.statuses.finished, run.status

  it "runs scraper with a url", ->
    scraper\queue "http://leafo.net"
    scraper\run!

    assert.same 1, QueuedUrls\count!

    runs = Runs\select!
    assert.same 1, #runs
    run = unpack runs
    assert.same Runs.statuses.finished, run.status


  it "cancels scraper run due to message", ->
    scraper\queue "http://leafo.net/1"
    scraper\queue "http://leafo.net/2"

    scraper.default_handler = ->
      coroutine.yield!

    fn = coroutine.wrap ->
      scraper\run!

    fn!
    run = assert (unpack Runs\select!), "missing run"
    assert.same 1, run.processed_count
    run\update message: "stop please"

    fn!

    run\refresh!
    assert.same Runs.statuses.canceled, run.status
    assert.same 1, run.processed_count


