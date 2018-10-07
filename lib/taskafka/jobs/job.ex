defmodule TasKafka.Job do
  @moduledoc """
  Request is stored in capped collection, so document size can't change on update.
  That means all fields on update should have the same size
  """

  use TasKafka.Mongo.Schema

  @variable_field_length 1800

  @status_pending 0
  @status_processed 1
  @status_failed 2
  @status_failed_with_error 3

  def status_to_string(@status_pending), do: "pending"
  def status_to_string(@status_processed), do: "processed"
  def status_to_string(@status_failed), do: "failed"
  def status_to_string(@status_failed_with_error), do: "failed_with_error"

  def status(:pending), do: @status_pending
  def status(:processed), do: @status_processed
  def status(:failed), do: @status_failed
  def status(:failed_with_error), do: @status_failed_with_error

  @primary_key :_id
  schema :jobs do
    field(:_id)
    field(:hash, presence: true)
    field(:eta, presence: true)
    field(:status, presence: true, inclusion: [@status_pending, @status_processed, @status_failed])
    field(:meta, length: [is: @variable_field_length])
    field(:meta_size, presence: true)
    field(:result, length: [is: @variable_field_length])
    field(:result_size, presence: true)
    field(:started_at, presence: true)
    field(:ended_at)
  end

  def encode_fields_with_variable_length(%__MODULE__{} = job) do
    meta = Jason.encode!(job.meta)
    result = Jason.encode!(job.result)

    %{
      job
      | result: pad_field_value(result),
        result_size: byte_size(result),
        meta: pad_field_value(meta),
        meta_size: byte_size(meta)
    }
  end

  def encode_result(%{"result" => value} = data) do
    result = Jason.encode!(value)

    Map.merge(data, %{
      "result" => pad_field_value(result),
      "result_size" => byte_size(result)
    })
  end

  def decode_fields_with_variable_length(%__MODULE__{} = job) do
    %{
      job
      | meta: Jason.decode!(binary_part(job.meta, 0, job.meta_size)),
        result: Jason.decode!(binary_part(job.result, 0, job.result_size))
    }
  end

  defp pad_field_value(value), do: String.pad_trailing(value, @variable_field_length, ".")
end
