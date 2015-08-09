import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import QueuedUrls, Runs from require "moonscrape.models"
import Scraper from require "moonscrape"

describe "models.runs", ->
  use_test_env!

  before_each ->
    truncate_tables Runs, QueuedUrls

  it "creates a run", ->
    r = Runs\create {
      project: "leafo.net"
    }

    assert r
    assert.same r.project, "leafo.net"

    assert.nil r\check_message!

    r\update message: "hello world!"

    assert.same "hello world!", r\check_message!
    assert.nil r\check_message!

    r\increment!
    r\increment!
    assert.same 2, r.processed_count

    r\finish!
    assert.truthy r.finished_at

