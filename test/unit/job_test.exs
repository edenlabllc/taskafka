defmodule TasKafka.JobsTest do
  @moduledoc false

  use TasKafka.ModelCase
  alias BSON.ObjectId
  alias TasKafka.Job
  alias TasKafka.Jobs
  alias TestModule.Meta
  alias TestModule.Failed

  describe "create job" do
    test "success create and process job" do
      now = DateTime.utc_now()

      meta = %{
        "merged_from_legal_entity" => %{
          "id" => UUID.uuid4(),
          "name" => "merged from legal entity",
          "edrpou" => "1234567890"
        },
        "merged_to_legal_entity" => %{
          "id" => UUID.uuid4(),
          "name" => "merged to legal entity",
          "edrpou" => "0987654321"
        }
      }

      assert {:ok, %{meta: ^meta} = job} = Jobs.create(meta)
      job_id = ObjectId.encode!(job._id)

      result = %{"status_code" => 202, "result" => "successfully created related legal entity"}
      assert {:ok, _} = Jobs.processed(job_id, result)

      assert {:ok, %Job{} = updated_job} = Jobs.get_by_id(job_id)
      assert Job.status(:processed) == updated_job.status
      assert meta == updated_job.meta
      assert result == updated_job.result
      assert :gt == DateTime.compare(updated_job.ended_at, now)
    end

    test "job failed" do
      meta =
        struct(Meta, %{
          id: UUID.uuid4(),
          params: %{"option" => 1},
          settings: [%{enabled: true}]
        })

      assert {:ok, job} = Jobs.create(meta)
      job_id = ObjectId.encode!(job._id)

      result = struct(Failed, %{status_code: 200, response: "Operation failed"})
      assert {:ok, _} = Jobs.failed(job_id, result)

      assert {:ok, %Job{} = updated_job} = Jobs.get_by_id(job_id)
      assert Job.status(:failed) == updated_job.status
      assert meta.id == updated_job.meta["id"]
      assert meta.params == updated_job.meta["params"]
      assert [%{"enabled" => true}] == updated_job.meta["settings"]
      assert %{"response" => "Operation failed", "status_code" => 200} == updated_job.result
    end
  end
end
