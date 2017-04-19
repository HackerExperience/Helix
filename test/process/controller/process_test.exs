defmodule Helix.Process.Controller.ProcessTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.Controller.Process, as: ProcessController
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Repo

  alias HELL.TestHelper.Random
  alias Helix.Process.Factory

  test "creating succeeds with valid params" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %Factory.DummyProcessType{},
      process_type: Random.string(min: 20, max: 20)
    }

    assert {:ok, _, _} = ProcessController.create(params)
  end

  describe "fetching" do
    test "succeeds by id" do
      process = Factory.insert(:process)
      assert %ProcessModel{} = ProcessController.fetch(process.process_id)
    end

    test "fails when process doesn't exists" do
      refute ProcessController.fetch(Random.pk())
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
