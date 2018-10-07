defmodule TasKafka.Migrations.CreateSchemaMigrations do
  @moduledoc false

  alias TasKafka.Mongo
  alias TasKafka.Mongo.SchemaMigration

  def change do
    {:ok, _} =
      Mongo.command(
        createIndexes: SchemaMigration.metadata().collection,
        indexes: [
          %{
            key: %{
              version: 1
            },
            name: "unique_version_idx",
            unique: true
          }
        ]
      )
  end
end
