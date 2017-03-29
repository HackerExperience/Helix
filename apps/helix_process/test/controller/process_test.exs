defmodule Helix.Process.Controller.ProcessTest do
  use ExUnit.Case

  alias Helix.Process.Controller.Process, as: ProcessController
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Repo

  alias HELL.TestHelper.Random
  alias Helix.Process.Factory

  @moduletag :integration

  def generate_params do
    process = Factory.build(:process)

    %{
      gateway_id: process.gateway_id,
      target_server_id: process.target_server_id,
      process_data: %Factory.NaiveProcessType{},
      process_type: process.process_type,
      software: %{}
    }
  end

  test "creating succeeds with valid params" do
    params = generate_params()
    assert {:ok, _} = ProcessController.create(params)
  end

  describe "fetching" do
    test "succeeds by id" do
      process = Factory.insert(:process)

      assert {:ok, got} = ProcessController.find(process.process_id)
      assert process.process_id == got.process_id
    end

    test "fails when account with id doesn't exist" do
      assert {:error, :notfound} = ProcessController.find(Random.pk())
    end
  end

  describe "deleting" do
    test "is idempotent" do
      process = Factory.insert(:process)

      assert Repo.get(ProcessModel, process.process_id)
      ProcessController.delete(process.process_id)
      ProcessController.delete(process.process_id)
      refute Repo.get(ProcessModel, process.process_id)
    end

    test "can be done by its id" do
      process = Factory.insert(:process)

      assert Repo.get(ProcessModel, process.process_id)
      ProcessController.delete(process.process_id)
      refute Repo.get(ProcessModel, process.process_id)
    end

    test "can be done by its struct" do
      process = Factory.insert(:process)

      assert Repo.get(ProcessModel, process.process_id)
      ProcessController.delete(process)
      refute Repo.get(ProcessModel, process.process_id)
    end
  end
end
