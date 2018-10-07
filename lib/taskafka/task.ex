defmodule TasKafka.Task do
  @moduledoc false
  alias TasKafka.Jobs

  defmacro __using__(topic: topic) do
    quote do
      use KafkaEx.GenConsumer

      @idle Application.get_env(:taskafka, :idle, false)

      def produce_without_job(data, partition \\ 0) do
        produce_to_kafka(@idle, unquote(topic), partition, data)
      end

      def produce(kafka_data, job_meta_data, partition \\ 0) do
        with {:ok, job} <- Jobs.create(job_meta_data),
             :ok <- produce_to_kafka(@idle, unquote(topic), partition, kafka_data) do
          {:ok, job}
        end
      end

      def produce_with_task(task_module, task_data, partition \\ 0) do
        with {:ok, job, task} <- Jobs.create(task_module, task_data),
             :ok <- produce_to_kafka(@idle, unquote(topic), partition, task) do
          {:ok, job}
        end
      end

      # do not produce message to Kafka for test cases
      defp produce_to_kafka(true, _topic, _partition, _task), do: :ok

      defp produce_to_kafka(false, topic, partition, task),
        do: KafkaEx.produce(topic, partition, :erlang.term_to_binary(task))
    end
  end
end
