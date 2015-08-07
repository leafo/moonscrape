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
    u = (url) -> QueuedUrls\load(:url)

    it "parses url with no path", ->
      url = u "http://butt.leafo.net"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "./coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "../coolthings"

    it "parses url with path", ->
      url = u "http://butt.leafo.net/hi"

      assert.same "http://butt.leafo.net/hi/coolthings",
        url\join "./coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "../coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "./././../coolthings"

      assert.same "http://butt.leafo.net/coolthings",
        url\join "../../coolthings"

      assert.same "http://butt.leafo.net/hi#hello",
        url\join "#hello"

    it "parses fragments", ->
      assert.same "http://leafo.net#hello",
        u("http://leafo.net")\join "#hello"

      assert.same "http://leafo.net#hello/world",
        u("http://leafo.net")\join "#hello/world"

      assert.same "http://leafo.net#hello",
        u("http://leafo.net/")\join "#hello"

      assert.same "http://leafo.net/yeah#hello",
        u("http://leafo.net/yeah")\join "#hello"

      assert.same "http://leafo.net/yeah#hello",
        u("http://leafo.net/yeah")\join "./#hello"

      assert.same "http://leafo.net#hello",
        u("http://leafo.net/yeah")\join "../#hello"

      assert.same "http://leafo.net/okay#hello/world",
        u("http://leafo.net/yeah")\join "../okay#hello/world"


