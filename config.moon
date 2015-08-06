
config = require "lapis.config"

config "development", ->
  postgres {
    database: "moonscrape"
  }

config "test", ->
  postgres {
    database: "moonscrape_test"
  }


