defmodule TasKafka.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(
        Mongo,
        [
          [name: :taskafka_mongo, url: mongo_url(), pool: DBConnection.Poolboy]
        ],
        id: :taskafka_mongo
      )
    ]

    opts = [strategy: :one_for_one, name: TasKafka.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def mongo_url do
    if url = Application.get_env(:taskafka, :mongo, [])[:url] do
      url
    else
      raise ArgumentError,
            "configuration for Mongo not specified. Add `:taskafka, :mongo, :url: \"%MONGO_URL%\"` in your environment"
    end
  end
end
