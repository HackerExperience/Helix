defmodule Helix.Process.Controller.ProcessTest do
  use ExUnit.Case

  alias Helix.Process.Controller.Process, as: ProcessController
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Repo

  alias HELL.TestHelper.Random
  alias Helix.Process.Factory

  @moduletag :integration

  test "creating succeeds with valid params" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %Factory.NaiveProcessType{},
      process_type: Random.string(min: 20, max: 20)
    }

    assert {:ok, _} = ProcessController.create(params)
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

  describe "finding" do
    test "succeeds by gateway" do
      gateway = Random.pk()

      processes = Factory.insert_list(3, :process, gateway_id: gateway)
      found = ProcessController.find(gateway: gateway)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.gateway_id == gateway))
    end

    test "succeeds by target" do
      target = Random.pk()
      processes = Factory.insert_list(3, :process, target_server_id: target)

      found = ProcessController.find(target: target)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.target_server_id == target))
    end

    test "succeeds by file" do
      file = Random.pk()
      processes = Factory.insert_list(3, :process, file_id: file)

      found = ProcessController.find(file: file)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.file_id == file))
    end

    test "succeeds by network" do
      network = Random.pk()
      processes = Factory.insert_list(3, :process, network_id: network)

      found = ProcessController.find(network: network)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.network_id == network))
    end

    test "succeeds by type" do
      type = Random.string(min: 20, max: 20)
      processes = Factory.insert_list(3, :process, process_type: type)

      found = ProcessController.find(type: type)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.process_type == type))
    end

    test "succeeds by type list" do
      processes = Factory.insert_list(3, :process)
      types = Enum.map(processes, &(&1.process_type))

      found = ProcessController.find(type: types)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.process_type in types))
    end

    test "succeeds by state" do
      state = Factory.random_process_state()
      processes = Factory.insert_list(3, :process, state: state)

      found = ProcessController.find(state: state)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.state == state))
    end

    test "succeeds by state list" do
      processes = Factory.insert_list(3, :process)
      states = Enum.map(processes, &(&1.state))

      found = ProcessController.find(state: states)
      found_ids = Enum.map(found, &(&1.process_id))

      assert Enum.all?(processes, &(&1.process_id in found_ids))
      assert Enum.all?(found, &(&1.state in states))
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
