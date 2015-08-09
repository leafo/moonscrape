import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

db = require "lapis.db"

import QueuedUrls from require "moonscrape.models"
import Scraper from require "moonscrape"

describe "moonscrape.models.queued_urls", ->
  use_test_env!

  before_each ->
    truncate_tables QueuedUrls

  it "it gets next queued url", ->
    scraper = Scraper!

    QueuedUrls\create {
      url: "http://leafo.net"
      :scraper
    }

    QueuedUrls\create {
      url: "http://leafo.net/stuff"
      depth: 1
      :scraper
    }

    url = QueuedUrls\get_next scraper
    assert.same url.url, "http://leafo.net"

  describe "has_url", ->
    for scraper_fn in *{(-> Scraper(project: "cool")), Scraper}
      local scraper

      before_each ->
        scraper = scraper_fn!

      it "detects regular url", ->
        QueuedUrls\create {
          url: "http://leafo.net"
          :scraper
        }

        assert.true QueuedUrls\has_url scraper, "http://leafo.net"
        assert.false QueuedUrls\has_url scraper, "http://leafo.net/butt"

      it "detects redirect url", ->
        QueuedUrls\create {
          url: "http://leafo.net"
          redirects: db.array {"http://leafo.net/yeah"}
          :scraper
        }

        assert.true QueuedUrls\has_url scraper, "http://leafo.net/yeah"
        assert.false QueuedUrls\has_url scraper, "http://leafo.net/okay"

      it "detects normalize_url url", ->
        url = "http://leafo.net:80?hello=world&a=b"

        QueuedUrls\create {
          url: url
          normalized_url: scraper\normalize_url url
          :scraper
        }

        assert.true QueuedUrls\has_url scraper, "http://leafo.net/?a=b&hello=world"
        assert.false QueuedUrls\has_url scraper, "http://leafo.net/?a=c&hello=world"

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

      {"http://leafo.net/dir/hello", "world", "http://leafo.net/dir/world"}
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

