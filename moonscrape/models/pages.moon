
import Model from require "lapis.db.model"

class Pages extends Model
  @timestamp: true

  @relations: {
    {"queued_url", belongs_to: "QueuedUrls"}
  }
