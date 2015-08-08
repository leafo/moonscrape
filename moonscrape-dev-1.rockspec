package = "moonscrape"
version = "dev-1"
source = {
  url = "git://github.com/leafo/moonscrape.git",
  branch = "master"
}
description = {
  homepage = "http://github.com/leafo/moonscrape",
  license = "MIT"
}
dependencies = {
  "lua ~> 5.1",
  "lapis",
  "ansicolors",
  "luasocket",
  "slnunicode",
  "web_sanitize",
}

build = {
  type = "builtin",
  modules = {
    ["moonscrape"] = "moonscrape/init.lua",
    ["moonscrape.migrations"] = "moonscrape/migrations.lua",
    ["moonscrape.models"] = "moonscrape/models.lua",
    ["moonscrape.models.pages"] = "moonscrape/models/pages.lua",
    ["moonscrape.models.queued_urls"] = "moonscrape/models/queued_urls.lua",
    ["moonscrape.util"] = "moonscrape/util.lua",
  }
}
