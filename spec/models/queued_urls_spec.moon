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

    for {url, path, expected, tag} in *{
      {"http://butt.leafo.net", "./coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net", "../coolthings", "http://butt.leafo.net/coolthings"}

      {"http://butt.leafo.net/hi", "coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi", "./coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi", "../coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi", "./././../coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi", "../../coolthings", "http://butt.leafo.net/coolthings"}

      {"http://butt.leafo.net/hi/", "coolthings", "http://butt.leafo.net/hi/coolthings"}
      {"http://butt.leafo.net/hi/", "./coolthings", "http://butt.leafo.net/hi/coolthings"}
      {"http://butt.leafo.net/hi/", "../coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi/", "./././../coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi/", "../../coolthings", "http://butt.leafo.net/coolthings"}

      {"http://butt.leafo.net/hi/bi", "./coolthings", "http://butt.leafo.net/hi/coolthings"}
      {"http://butt.leafo.net/hi/bi", "../coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi/bi", "./././../coolthings", "http://butt.leafo.net/coolthings"}
      {"http://butt.leafo.net/hi/bi", "../../coolthings", "http://butt.leafo.net/coolthings"}

      {"http://butt.leafo.net/hi/bi", "/okay", "http://butt.leafo.net/okay"}

      {"http://leafo.net/dir/hello", "world", "http://leafo.net/dir/world", "#ddd"}
    }
      it "#{url} + #{path} -> #{expected} #{tag or ""}", ->
        assert.same expected, u(url)\join path

    describe "joins fragments", ->
      for {url, path, expected} in *{
        {"http://leafo.net", "#hello", "http://leafo.net#hello"}
        {"http://leafo.net", "#hello/world", "http://leafo.net#hello/world"}
        {"http://leafo.net/", "#hello", "http://leafo.net#hello"}
        {"http://leafo.net/yeah", "#hello", "http://leafo.net/yeah#hello"}
        {"http://leafo.net/yeah", "./#hello", "http://leafo.net/yeah/#hello"}
        {"http://leafo.net/yeah", "../#hello", "http://leafo.net/#hello"}
        {"http://leafo.net/yeah", "../okay#hello/world", "http://leafo.net/okay#hello/world"}
        {"http://leafo.net/yeah#okay", "#whazz", "http://leafo.net/yeah#whazz"}
        {"http://leafo.net/#okay", "#whazz", "http://leafo.net#whazz"}
        {"http://leafo.net/a/#okay", "#whazz", "http://leafo.net/a#whazz"}
      }
        it "#{url} + #{path} -> #{expected}", ->
          assert.same expected, u(url)\join path

    describe "joins query params", ->
      for {url, path, expected} in *{
        {"http://leafo.net", "?hello", "http://leafo.net?hello"}
        {"http://leafo.net/?world", "./", "http://leafo.net"}
        {"http://leafo.net/?world", "?hello", "http://leafo.net?hello"}
        {"http://leafo.net/?world=yes", "/good/?no=please", "http://leafo.net/good/?no=please"}

        {"http://leafo.net/dir", "?yeah", "http://leafo.net/dir?yeah"}
        {"http://leafo.net/dir/", "?yeah", "http://leafo.net/dir?yeah"}
      }
        it "#{url} + #{path} -> #{expected}", ->
          assert.same expected, u(url)\join path






