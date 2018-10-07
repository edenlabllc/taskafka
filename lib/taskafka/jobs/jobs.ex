defmodule TasKafka.Jobs do
  @moduledoc false

  alias BSON.ObjectId
  alias TasKafka.Job
  alias TasKafka.Mongo

  @collection Job.metadata().collection

  def get_by_id(id) when is_binary(id) do
    object_id = ObjectId.decode!(id)

    with %{} = job <- Mongo.find_one(@collection, %{"_id" => object_id}) do
      {:ok, map_to_job(job)}
    end
  rescue
    _ in FunctionClauseError -> nil
  end

  def new(data) do
    %Job{
      _id: Mongo.generate_id(),
      status: Job.status(:pending),
      started_at: DateTime.utc_now(),
      ended_at: DateTime.from_unix!(0),
      eta: count_eta()
    }
    |> Map.merge(data)
    |> Job.encode_fields_with_variable_length()
  end

  def create(meta) do
    hash = :md5 |> :crypto.hash(:erlang.term_to_binary(meta)) |> Base.url_encode64(padding: false)

    case Mongo.find_one(@collection, %{"hash" => hash, "status" => Job.status(:pending)}, projection: [_id: true]) do
      %{"_id" => id} ->
        {:job_exists, to_string(id)}

      _ ->
        job = new(%{hash: hash, meta: meta, result: ""})

        with {:ok, _} <- Mongo.insert_one(job) do
          {:ok, Job.decode_fields_with_variable_length(job)}
        end
    end
  end

  def processed(id, result), do: update(id, Job.status(:processed), result)
  def failed(id, result), do: update(id, Job.status(:failed), result)

  def update(id, status, result) do
    set_data =
      Job.encode_result(%{
        "result" => result,
        "status" => status,
        "ended_at" => DateTime.utc_now()
      })

    Mongo.update_one(@collection, %{"_id" => ObjectId.decode!(id)}, %{"$set" => set_data})
  rescue
    _ in FunctionClauseError -> nil
  end

  # ToDo: count real eta based on kafka performance testing. Temporary hardcoded to 10 minutes.
  defp count_eta do
    time = :os.system_time(:millisecond) + 60_000

    time
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_naive()
    |> NaiveDateTime.to_iso8601()
  end

  defp map_to_job(data) do
    Job
    |> struct(Enum.map(data, fn {k, v} -> {String.to_atom(k), v} end))
    |> Job.decode_fields_with_variable_length()
  end
end
