db = require "lapis.db"
schema = require "lapis.db.schema"

import add_column, create_index, drop_index, drop_column, create_table from schema

{
  :serial, :boolean, :varchar, :integer, :text, :foreign_key, :double, :time,
  :numeric, :enum
} = schema.types

{
  [1438794661]: ->
    db.query "CREATE EXTENSION IF NOT EXISTS btree_gin"

    create_table "queued_urls", {
      {"id", serial}
      {"project", text null: true}
      {"url", text}
      {"depth", integer}
      {"parent_queued_url_id", foreign_key null: true}

      {"status", enum}

      {"created_at", time}
      {"updated_at", time}

      {"tags", text array: true, null: true}
      {"redirects", text array: true, null: true}
    }

    create_index "queued_urls", "project", "status", "depth", "id"
    create_index "queued_urls", "project", "url"
    create_index "queued_urls", "tags", method: "GIN"
    create_index "queued_urls", "project", "redirects", {
      method: "GIN"
      where: "redirects is not null"
    }

    create_table "pages", {
      {"id", serial}
      {"created_at", time}
      {"updated_at", time}
      {"status", integer}
      {"body", text}
      {"content_type", text null: true}

      {"queued_url_id", foreign_key}
    }

}
