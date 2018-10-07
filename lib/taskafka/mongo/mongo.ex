defmodule TasKafka.Mongo do
  @moduledoc false

  alias DBConnection.Poolboy
  alias Mongo, as: M

  defdelegate start_link(opts), to: M
  defdelegate object_id, to: M

  defp execute(fun, args) do
    opts =
      args
      |> List.last()
      |> Keyword.put(:pool, Poolboy)

    enriched_args =
      args
      |> List.replace_at(Enum.count(args) - 1, opts)
      |> List.insert_at(0, :taskafka_mongo)

    apply(M, fun, enriched_args)
  end

  def command(query, opts \\ []) do
    execute(:command, [query, opts])
  end

  def command!(query, opts \\ []) do
    execute(:command!, [query, opts])
  end

  def find(coll, filter, opts \\ []) do
    execute(:find, [coll, filter, opts])
  end

  def find_one(coll, filter, opts \\ []) do
    execute(:find_one, [coll, filter, opts])
  end

  def insert_one(%{__meta__: %{collection: collection}} = doc, opts \\ []) do
    insert_one(collection, prepare_doc(doc), opts)
  end

  def insert_one(coll, doc, opts) do
    execute(:insert_one, [coll, doc, opts])
  end

  def update_one(coll, %{"_id" => _} = filter, update, opts \\ []) do
    execute(:update_one, [coll, filter, update, opts])
  end

  defp prepare_doc([%{__struct__: _, __meta__: _} | _] = docs) do
    Enum.map(docs, &prepare_doc/1)
  end

  defp prepare_doc(%{__meta__: _} = doc) do
    doc
    |> Map.from_struct()
    |> Map.drop(~w(__meta__ __validations__)a)
    |> Enum.into(%{}, fn {k, v} -> {k, prepare_doc(v)} end)
  end

  defp prepare_doc(%DateTime{} = doc), do: doc

  defp prepare_doc(%Date{} = doc) do
    date = Date.to_erl(doc)
    {date, {0, 0, 0}} |> NaiveDateTime.from_erl!() |> DateTime.from_naive!("Etc/UTC")
  end

  defp prepare_doc(%BSON.Binary{} = doc), do: doc
  defp prepare_doc(%BSON.ObjectId{} = doc), do: doc

  defp prepare_doc(%{} = doc) do
    Enum.into(doc, %{}, fn {k, v} -> {k, prepare_doc(v)} end)
  end

  defp prepare_doc(doc), do: doc

  def generate_id do
    Mongo.IdServer.new()
  end
end
