local db = require("lapis.db")
local schema = require("lapis.db.schema")
local add_column, create_index, drop_index, drop_column, create_table
add_column, create_index, drop_index, drop_column, create_table = schema.add_column, schema.create_index, schema.drop_index, schema.drop_column, schema.create_table
local serial, boolean, varchar, integer, text, foreign_key, double, time, numeric, enum
do
  local _obj_0 = schema.types
  serial, boolean, varchar, integer, text, foreign_key, double, time, numeric, enum = _obj_0.serial, _obj_0.boolean, _obj_0.varchar, _obj_0.integer, _obj_0.text, _obj_0.foreign_key, _obj_0.double, _obj_0.time, _obj_0.numeric, _obj_0.enum
end
return {
  [1438794661] = function()
    db.query("CREATE EXTENSION IF NOT EXISTS btree_gin")
    create_table("queued_urls", {
      {
        "id",
        serial
      },
      {
        "project",
        text({
          null = true
        })
      },
      {
        "url",
        text
      },
      {
        "depth",
        integer
      },
      {
        "parent_queued_url_id",
        foreign_key({
          null = true
        })
      },
      {
        "status",
        enum
      },
      {
        "created_at",
        time
      },
      {
        "updated_at",
        time
      },
      {
        "tags",
        text({
          array = true,
          null = true
        })
      },
      {
        "redirects",
        text({
          array = true,
          null = true
        })
      }
    })
    create_index("queued_urls", "project", "status", "depth", "id")
    create_index("queued_urls", "project", "url")
    create_index("queued_urls", "tags", {
      method = "GIN"
    })
    create_index("queued_urls", "project", "redirects", {
      method = "GIN",
      where = "redirects is not null"
    })
    return create_table("pages", {
      {
        "id",
        serial
      },
      {
        "created_at",
        time
      },
      {
        "updated_at",
        time
      },
      {
        "status",
        integer
      },
      {
        "body",
        text
      },
      {
        "content_type",
        text({
          null = true
        })
      },
      {
        "queued_url_id",
        foreign_key
      }
    })
  end
}
