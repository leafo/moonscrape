
config = require "lapis.config"

config "development", ->
  postgres {
    database: "moonscrape"
  }
