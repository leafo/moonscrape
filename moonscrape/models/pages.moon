
import Model from require "lapis.db.model"

class Pages extends Model
  @timestamp: true

  @get_relation_model: (name) =>
    require("moonscrape.models")[name]

  @relations: {
    {"queued_url", belongs_to: "QueuedUrls"}
  }
