defmodule TasKafka.Mongo.SchemaMigration do
  @moduledoc false

  use TasKafka.Mongo.Schema

  @primary_key :name
  schema :schema_migrations do
    field(:version, presence: true)
    field(:inserted_at, presence: true)
  end
end
