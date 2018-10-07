defmodule Mix.Tasks.Drop do
  @moduledoc false

  use Mix.Task
  alias TasKafka.Mongo
  require Logger

  def run(_) do
    {:ok, _} = Application.ensure_all_started(:mongodb)

    {:ok, pid} =
      Mongo.start_link(
        name: :taskafka_mongo,
        url: Application.get_env(:taskafka, :mongo)[:url],
        pool: DBConnection.Poolboy
      )

    Mongo.command!(dropDatabase: 1)
    Logger.info(IO.ANSI.green() <> "Database dropped" <> IO.ANSI.default_color())

    GenServer.stop(pid)
  end
end
