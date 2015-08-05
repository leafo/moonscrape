db = require "lapis.db"
schema = require "lapis.db.schema"

import add_column, create_index, drop_index, drop_column, create_table from schema

{
  :serial, :boolean, :varchar, :integer, :text, :foreign_key, :double, :time,
  :numeric, :enum
} = schema.types

{
  [1438794661]: ->
    create_table "queued_urls", {
      {"id", serial}
      {"url", text}
      {"depth", integer}
      {"status", enum}

      {"created_at", time}
      {"updated_at", time}
    }

    create_index "queued_urls", "status", "depth", "id"

    create_table "pages", {
      {"id", serial}
      {"created_at", time}
      {"updated_at", time}
      {"body", text}
    }

}
