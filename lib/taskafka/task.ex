defmodule TasKafka.Task do
  @moduledoc false
  alias TasKafka.Jobs

  @callback consume(:term) :: :ok | {:error, :term}

  defmacro __using__(topic: topic) do
    quote do
      @behaviour TasKafka.Task

      alias BSON.ObjectId
      require Logger

      @idle Application.get_env(:taskafka, :idle, false)
      @defaults %{partition: 0, type: 100}

      def produce_without_job(data, opts \\ []) do
        opts = Enum.into(opts, @defaults)
        produce_to_kafka(@idle, unquote(topic), opts.partition, data)
      end

      def produce(kafka_data, job_meta_data, opts \\ []) do
        opts = Enum.into(opts, @defaults)

        with {:ok, job} <- Jobs.create(job_meta_data, opts.type),
             job_id <- ObjectId.encode!(job._id),
             :ok <- produce_to_kafka(@idle, unquote(topic), opts.partition, Map.put(kafka_data, :job_id, job_id)) do
          {:ok, job}
        end
      end

      def handle_messages(messages) do
        for %{offset: offset, value: message} <- messages do
          value = :erlang.binary_to_term(message)
          Logger.debug(fn -> "message: " <> inspect(value) end)
          Logger.info(fn -> "offset: #{offset}" end)
          :ok = consume(value)
        end

        # Important!
        :ok
      end

      # do not produce message to Kafka for test cases
      defp produce_to_kafka(true, _topic, _partition, _task), do: :ok

      defp produce_to_kafka(false, topic, partition, task),
        do: Producer.produce_sync(topic, partition, "", :erlang.term_to_binary(task))
    end
  end
end
