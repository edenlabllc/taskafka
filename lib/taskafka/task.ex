defmodule TasKafka.Task do
  @moduledoc false
  alias TasKafka.Jobs

  @callback consume(:term) :: :ok | {:error, :term}

  defmacro __using__(topic: topic) do
    quote do
      @behaviour TasKafka.Task

      use KafkaEx.GenConsumer
      alias KafkaEx.Protocol.Fetch.Message
      require Logger

      @idle Application.get_env(:taskafka, :idle, false)

      def produce_without_job(data, partition \\ 0) do
        produce_to_kafka(@idle, unquote(topic), partition, data)
      end

      def produce(kafka_data, job_meta_data, partition \\ 0) do
        with {:ok, job} <- Jobs.create(job_meta_data),
             :ok <- produce_to_kafka(@idle, unquote(topic), partition, Map.put(kafka_data, :job_id, job.id)) do
          {:ok, job}
        end
      end

      def handle_message_set(message_set, state) do
        for %Message{value: message, offset: offset} <- message_set do
          value = :erlang.binary_to_term(message)
          Logger.debug(fn -> "message: " <> inspect(value) end)
          Logger.info(fn -> "offset: #{offset}" end)
          :ok = consume(value)
        end

        {:async_commit, state}
      end

      # do not produce message to Kafka for test cases
      defp produce_to_kafka(true, _topic, _partition, _task), do: :ok

      defp produce_to_kafka(false, topic, partition, task),
        do: KafkaEx.produce(topic, partition, :erlang.term_to_binary(task))
    end
  end
end
