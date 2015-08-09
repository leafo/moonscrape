import use_test_env from require "lapis.spec"

describe "moonscrape.util", ->
  use_test_env!

  describe "is_relative_url", ->
    import is_relative_url from require "moonscrape.util"

    for {url, expected} in *{
      {"http://leafo.net", false}
      {"http://leafo.net/hi", false}
      {"https://leafo.net/hi", false}
      {"ftp://leafo.net/hi", false}
      {"//leafo.net/hi", false}

      {"leafo.net", true}
      {"leafo/world", true}
      {"leafo/world#okay", true}
      {"/foot", true}
      {"./foot", true}
      {"../foot", true}

      {"mailto:leaf@leafo", false}
    }
      it "#{url} is #{expected}", ->
        assert.same expected, is_relative_url url

  describe "clean_url", ->
    import clean_url from require "moonscrape.util"

    for {url, expected} in *{
      {"http://leafo.net", "http://leafo.net"}
      {"http://leafo.net/", "http://leafo.net"}
      {"http://leafo.net/#hello", "http://leafo.net"}

      {"http://leafo.net/hello", "http://leafo.net/hello"}
      {"http://leafo.net/hello/", "http://leafo.net/hello/"}
    }
      it "clean_url(#{url}) should be #{expected}", ->
        assert.same expected, clean_url url

  describe "decode_html_entities" ,->
    import decode_html_entities from require "moonscrape.util"

    it "decodes string", ->
      assert.same "mailto:leafot@gmail.com",
        decode_html_entities "&#x6d;&#x61;&#x69;&#108;&#x74;&#x6f;&#x3a;&#108;&#101;&#x61;&#x66;&#x6f;&#x74;&#x40;&#x67;&#109;&#97;&#105;&#108;&#x2e;&#x63;&#x6f;&#x6d;"


  describe "normalize_url", ->
    import normalize_url from require "moonscrape.util"

    for {url, expected} in *{
      {"http://leafo.net", "leafo.net"}
      {"http://leafo.net#yeah", "leafo.net"}
      {"http://leafo.net/#yeah", "leafo.net"}
      {"http://leafo.net/?hello=world", "leafo.net?hello=world"}
      {"http://leafo.net/one/two?hello=world&a=b", "leafo.net/one/two?a=b&hello=world"}
    }
      it "normalize_url(#{url}) should be #{expected}", ->
        assert.same expected, normalize_url url
