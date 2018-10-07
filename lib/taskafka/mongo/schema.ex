defmodule TasKafka.Mongo.Schema do
  @moduledoc false

  defmodule Metadata do
    @moduledoc false

    defstruct collection: nil, primary_key: nil, fields: %{}
  end

  defmacro __using__(_) do
    quote do
      import TasKafka.Mongo.Schema
    end
  end

  defmacro schema(collection, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :__metadata__, %Metadata{
        collection: to_string(unquote(collection)),
        primary_key: Module.get_attribute(__MODULE__, :primary_key)
      })

      unquote(block)
      metadata = Module.get_attribute(__MODULE__, :__metadata__)

      defstruct metadata.fields
                |> Map.keys()
                |> Keyword.new(fn x -> {x, nil} end)
                |> Keyword.put(:__meta__, metadata)
                |> Keyword.put(:__validations__, metadata.fields)

      defimpl Vex.Extract, for: __MODULE__ do
        def settings(%{__validations__: field_validations}) do
          Enum.reduce(field_validations, %{}, fn {k, %{"validations" => validations}}, acc ->
            Map.put(acc, k, validations)
          end)
        end

        def attribute(map, [root_attr | path]) do
          get_in(Map.get(map, root_attr), path)
        end

        def attribute(map, name) do
          Map.get(map, name)
        end
      end

      def metadata, do: @__metadata__
    end
  end

  defmacro field(name, validations \\ []) do
    quote do
      metadata = Module.get_attribute(__MODULE__, :__metadata__)
      primary_key = metadata.primary_key
      validations = unquote(validations)
      name = unquote(name)
      validations = if name == primary_key, do: Keyword.put(validations, :presence, true), else: validations

      Module.put_attribute(__MODULE__, :__metadata__, %{
        metadata
        | fields: Map.put(metadata.fields, name, %{"validations" => validations})
      })
    end
  end
end
