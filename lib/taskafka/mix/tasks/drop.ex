defmodule Mix.Tasks.Drop do
  @moduledoc false

  use Mix.Task
  alias TasKafka.Mongo
  require Logger

  def run(_) do
    {:ok, _} = Application.ensure_all_started(:mongodb)
    pid = start_mongo()

    Mongo.command!(dropDatabase: 1)
    Logger.info(IO.ANSI.green() <> "Database dropped" <> IO.ANSI.default_color())

    GenServer.stop(pid)
  end

  def start_mongo do
    opts = [
      name: :taskafka_mongo,
      url: Application.get_env(:taskafka, :mongo)[:url],
      pool: DBConnection.Poolboy
    ]

    case Mongo.start_link(opts) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
