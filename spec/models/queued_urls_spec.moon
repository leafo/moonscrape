import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import QueuedUrls from require "models"

describe "models.queued_urls", ->
  use_test_env!

  before_each ->
    truncate_tables QueuedUrls

  it "it gets next queued url", ->
    QueuedUrls\create {
      url: "http://leafo.net"
    }

    QueuedUrls\create {
      url: "http://leafo.net/stuff"
      depth: 1
    }

    url = QueuedUrls\get_next!
    assert.same url.url, "http://leafo.net"


  describe "join", ->
    it "parses url with no path", ->
      url = QueuedUrls\load url: "http://butt.leafo.net"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "./coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "../coolthings"

    it "parses url with path", ->
      url = QueuedUrls\load url: "http://butt.leafo.net/hi"

      assert.same "http://butt.leafo.net/hi/coolthings",
        url\join "./coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "../coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "./././../coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "../../coolthings"



