defmodule Helix.Process.Controller.ProcessTest do
  use ExUnit.Case

  alias Helix.Process.Controller.Process, as: ProcessController
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Repo

  alias HELL.TestHelper.Random
  alias Helix.Process.Factory

  @moduletag :integration

  test "creating succeeds with valid params" do
    p = Factory.params_for(:process)

    params = %{
      gateway_id: p.gateway_id,
      target_server_id: p.target_server_id,
      process_data: p.process_data,
      process_type: p.process_type
    }

    assert {:ok, _} = ProcessController.create(params)
  end

  describe "fetching" do
    test "succeeds by id" do
      process = Factory.insert(:process)

      assert {:ok, got} = ProcessController.find(process.process_id)
      assert process.process_id == got.process_id
    end

    test "fails when process with id doesn't exist" do
      assert {:error, :notfound} = ProcessController.find(Random.pk())
    end
  end

  describe "delete/1" do
    test "is idempotent" do
      process = Factory.insert(:process)

      assert Repo.get(ProcessModel, process.process_id)
      ProcessController.delete(process.process_id)
      ProcessController.delete(process.process_id)
      refute Repo.get(ProcessModel, process.process_id)
    end

    test "accepts id" do
      process = Factory.insert(:process)

      assert Repo.get(ProcessModel, process.process_id)
      ProcessController.delete(process.process_id)
      refute Repo.get(ProcessModel, process.process_id)
    end

    test "accepts process struct" do
      process = Factory.insert(:process)

      assert Repo.get(ProcessModel, process.process_id)
      ProcessController.delete(process)
      refute Repo.get(ProcessModel, process.process_id)
    end
  end
end
