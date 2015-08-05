
class Runner
  get_next_url: =>
    import QueuedUrls from require "models"
    url = QueuedUrls\get_next!

run = ->
  -- fetch from queue

queue = (url, callback) ->

