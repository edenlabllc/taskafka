defmodule TasKafka.JobsTest do
  @moduledoc false

  use TasKafka.ModelCase
  alias BSON.ObjectId
  alias TasKafka.Job
  alias TasKafka.Jobs
  alias TestModule.Failed

  describe "create job" do
    test "success create and process job" do
      now = DateTime.utc_now()
      merger_to_id = UUID.uuid4()

      meta = %{
        "merged_from_legal_entity" => %{
          "id" => UUID.uuid4(),
          "name" => "merged from legal entity",
          "edrpou" => "1234567890"
        },
        "merged_to_legal_entity" => %{
          "id" => merger_to_id,
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

      jobs =
        Job.metadata().collection
        |> Mongo.find(%{"meta.merged_to_legal_entity.id" => merger_to_id})
        |> Enum.to_list()

      assert job._id == hd(jobs)["_id"]
    end

    test "job failed" do
      meta = %{
        "id" => UUID.uuid4(),
        "params" => %{"option" => 1},
        "settings" => [%{"enabled" => true}]
      }

      assert {:ok, job} = Jobs.create(meta)
      job_id = ObjectId.encode!(job._id)

      result = struct(Failed, %{status_code: 200, response: "Operation failed"})
      assert {:ok, _} = Jobs.failed(job_id, result)

      assert {:ok, %Job{} = updated_job} = Jobs.get_by_id(job_id)
      assert Job.status(:failed) == updated_job.status
      assert meta == updated_job.meta
      assert %{"response" => "Operation failed", "status_code" => 200} == updated_job.result
    end
  end

  describe "get jobs list" do
    test "success" do
      for _ <- 1..10 do
        assert {:ok, _} = Jobs.create(%{"id" => UUID.uuid4()}, 110)
      end

      list = Jobs.get_list(%{"type" => 110})
      assert 10 == length(list)

      Enum.each(list, fn job ->
        assert %Job{} = job
      end)
    end

    test "filter by type" do
      assert {:ok, _} = Jobs.create(%{"id" => UUID.uuid4()}, 120)
      assert {:ok, _} = Jobs.create(%{"id" => UUID.uuid4()}, 200)
      assert {:ok, _} = Jobs.create(%{"id" => UUID.uuid4()}, 300)

      assert [%Job{type: 120}] = Jobs.get_list(%{"type" => 120})
      assert [%Job{type: 300}] = Jobs.get_list(%{"type" => 300})
      assert [] = Jobs.get_list(%{"type" => 150})
    end

    test "sort by type" do
      assert {:ok, _} = Jobs.create(%{"id" => UUID.uuid4()}, 101)
      assert {:ok, _} = Jobs.create(%{"id" => UUID.uuid4()}, 102)
      assert {:ok, _} = Jobs.create(%{"id" => UUID.uuid4()}, 103)

      list = Jobs.get_list(%{type: %{"$in": [101, 102, 103]}}, sort: %{"type" => 1})
      assert 3 = length(list)
      assert [%{type: 101}, %{type: 102}, %{type: 103}] = list

      list = Jobs.get_list(%{}, sort: %{"type" => -1})
      assert 3 = length(list)
      assert [%{type: 103}, %{type: 102}, %{type: 101}] = list
    end
  end
end
