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

  describe "normalize_url", ->
    import normalize_url from require "moonscrape.util"

    for {url, expected} in *{
      {"http://leafo.net", "http://leafo.net"}
      {"http://leafo.net/", "http://leafo.net/"}
      {"http://leafo.net/#hello", "http://leafo.net/"}
    }
      it "normalize_url(#{url}) should be #{expected}", ->
        assert.same expected, normalize_url url


