defmodule Helix.Process.Model.ProcessTest do

  use ExUnit.Case

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Process.ProcessType

  alias Helix.Test.Process.ProcessTypeExample
  alias Helix.Test.Process.StaticProcessTypeExample

  @moduletag :unit

  setup do
    process =
      %{
        gateway_id: Server.ID.generate(),
        target_server_id: Server.ID.generate(),
        process_data: %ProcessTypeExample{}
      }
      |> Process.create_changeset()
      |> Changeset.apply_changes()

    {:ok, process: process}
  end

  defp error_fields(changeset) do
    changeset
    |> Changeset.traverse_errors(&(&1))
    |> Map.keys()
  end

  describe "process data" do
    test "process data must be a struct" do
      p = Process.create_changeset(%{process_data: %{foo: :bar}})

      assert :process_data in error_fields(p)
    end

    test "a struct is only valid if it implements ProcessType protocol" do
      p = Process.create_changeset(%{process_data: %File.Stream{}})

      assert :process_data in error_fields(p)
    end

    test "as long as the struct implements ProcessType, everything will be alright" do
      params = %{process_data: %ProcessTypeExample{}}
      p = Process.create_changeset(params)

      refute :process_data in error_fields(p)
    end
  end

  describe "objective" do
    test "objective is optional" do
      p = Process.create_changeset(%{})
      refute :objective in error_fields(p)
    end

    test "objective is a map whose values are integers" do
      p = Process.create_changeset(%{objective: %{cpu: :foo}})
      assert :objective in error_fields(p)

      p = Process.create_changeset(%{objective: :foo})
      assert :objective in error_fields(p)

      p = Process.create_changeset(%{objective: %{cpu: 0.5}})
      assert :objective in error_fields(p)

      p = Process.create_changeset(%{objective: %{cpu: 50}})
      refute :objective in error_fields(p)
    end

    test "objective values must be non-negative" do
      p = Process.create_changeset(%{objective: %{cpu: -50}})
      assert :objective in error_fields(p)
    end
  end

  describe "ttl" do
    test "seconds_to_change defaults to :infinity if nothing is going to change" do
      now = DateTime.from_unix!(1_470_000_000)

      params = %{allocated: %{cpu: 0, dlk: 0}, updated_time: now}

      process =
        %{objective: %{cpu: 50}}
        |> Process.create_changeset()
        |> Process.update_changeset(params)
        |> Changeset.apply_changes()

      assert :infinity == Process.seconds_to_change(process)
    end

    test "seconds_to_change returns amount of seconds to the next change on a process resource consumption" do
      now = DateTime.from_unix!(1_470_000_000)

      params = %{allocated: %{cpu: 10, dlk: 10}, updated_time: now}

      process =
        %{objective: %{cpu: 50, dlk: 100}}
        |> Process.create_changeset()
        |> Process.update_changeset(params)
        |> Changeset.apply_changes()

      assert 5 === Process.seconds_to_change(process)
    end

    test "estimate_conclusion is the value of the longest-to-complete objective (or nil if infinity)" do
      now = DateTime.from_unix!(1_470_000_000)

      p =
        %{objective: %{cpu: 50, dlk: 100}}
        |> Process.create_changeset()
        |> Process.update_changeset(%{allocated: %{dlk: 10}, updated_time: now})
        |> Changeset.apply_changes()

      p1 = Process.estimate_conclusion(p)

      refute p1.estimated_time

      p2 =
        p
        |> Process.update_changeset(%{allocated: %{cpu: 1, dlk: 10}})
        |> Changeset.apply_changes()
        |> Process.estimate_conclusion()

      future = DateTime.from_unix!(1_470_000_050)

      assert :eq === DateTime.compare(future, p2.estimated_time)
    end
  end

  describe "allocation_shares" do
    test "returns 0 when paused", %{process: process} do
      process =
        process
        |> Process.pause()
        |> elem(0)
        |> Changeset.apply_changes()

      assert 0 === Process.allocation_shares(process)
    end

    test \
      "returns the priority value when the process still requires resources",
      %{process: process}
    do
      priority = 2
      process =
        process
        |> Changeset.cast(%{priority: priority}, [:priority])
        |> Changeset.put_embed(:objective, %{cpu: 1_000})
        |> Changeset.apply_changes()

      assert 2 === Process.allocation_shares(process)
    end

    test "can only allocate if the ProcessType allows", %{process: process} do
      priority = 2
      process =
        process
        |> Changeset.cast(%{priority: priority}, [:priority])
        |> Changeset.put_embed(:objective, %{cpu: 1_000})
        |> Changeset.apply_changes()

      assert 2 === Process.allocation_shares(process)
      p2 = %{process| process_data: %StaticProcessTypeExample{}}

      process_type = %StaticProcessTypeExample{}
      assert [] === ProcessType.dynamic_resources(process_type)
      assert 0 === Process.allocation_shares(p2)
    end
  end

  describe "pause" do
    test "pause changes the state of the process", %{process: process} do
      process =
        process
        |> Process.update_changeset(%{state: :running})
        |> Changeset.apply_changes()
        |> Process.pause()
        |> elem(0)
        |> Changeset.apply_changes()

      assert :paused === process.state
    end

    test "on pause allocates minimum", %{process: process} do
      params = %{
        objective: %{cpu: 1_000},
        allocated: %{cpu: 100, ram: 200},
        minimum: %{paused: %{ram: 155}}
      }

      process =
        process
        |> Changeset.cast(params, [:minimum])
        |> Changeset.cast_embed(:objective)
        |> Changeset.cast_embed(:allocated)
        |> Changeset.apply_changes()
        |> Process.pause()
        |> elem(0)
        |> Changeset.apply_changes()

      assert 0 === process.allocated.cpu
      assert 155 === process.allocated.ram
    end
  end

  describe "completeness" do
    test "is complete if state is :complete", %{process: process} do
      process =
        process
        |> Process.update_changeset(%{state: :complete})
        |> Changeset.apply_changes()

      assert Process.complete?(process)
    end

    test "is complete if objective has been reached", %{process: process} do
      params = %{
        objective: %{cpu: 100, dlk: 20},
        processed: %{cpu: 100, dlk: 20}
      }

      process =
        process
        |> Process.update_changeset(params)
        |> Changeset.apply_changes()

      assert Process.complete?(process)
    end

    test \
      "is not complete if state is not complete and objective not reached",
      %{process: process}
    do
      params = %{
        state: :running,
        processed: %{cpu: 10},
        objective: %{cpu: 500}
      }

      process =
        process
        |> Process.update_changeset(params)
        |> Changeset.apply_changes()

      refute Process.complete?(process)
    end
  end

  describe "minimum allocation" do
    test \
      "defaults to 0 when a value is not specified for the state",
      %{process: process}
    do
      resources = %Resources{cpu: 100}

      process =
        process
        |> Process.allocate(resources)
        |> Process.update_changeset(%{minimum: %{}})
        |> Changeset.apply_changes()

      assert 100 === process.allocated.cpu

      process =
        process
        |> Process.allocate_minimum()
        |> Changeset.apply_changes()

      assert 0 === process.allocated.cpu
    end

    test "uses the values for each specified state", %{process: process} do
      resources = %Resources{cpu: 900, ram: 600}
      minimum = %{paused: %{ram: 300}, running: %{cpu: 100, ram: 600}}

      process =
        process
        |> Process.allocate(resources)
        |> Process.update_changeset(%{state: :running, minimum: minimum})
        |> Changeset.apply_changes()

      assert 900 === process.allocated.cpu
      assert 600 === process.allocated.ram

      process =
        process
        |> Process.allocate_minimum()
        |> Changeset.apply_changes()

      assert 100 === process.allocated.cpu
      assert 600 === process.allocated.ram

      process =
        process
        |> Process.update_changeset(%{state: :paused})
        |> Process.allocate_minimum()
        |> Changeset.apply_changes()

      assert 0 === process.allocated.cpu
      assert 300 === process.allocated.ram

      process =
        process
        |> Process.update_changeset(%{state: :complete})
        |> Process.allocate_minimum()
        |> Changeset.apply_changes()

      # When a value is not specified for a certain state, it assumes that
      # everything should be 0
      assert 0 === process.allocated.cpu
      assert 0 === process.allocated.ram
    end
  end

  describe "resume" do
    test "doesn't change when process is not paused", %{process: process} do
      changeset =
        process
        |> Process.update_changeset(%{state: :running, allocated: %{cpu: 100}})
        |> Changeset.apply_changes()
        |> Process.resume()

      # IE: no changes on the changeset
      assert 0 === map_size(changeset.changes)
    end

    test \
      "changes state and updated_time and allocates minimum",
      %{process: process}
    do
      resources = %Resources{ram: 300}
      minimum = %{running: %{ram: 600}}
      last_updated =
        {{2000, 01, 01}, {01, 01, 01}}
        |> NaiveDateTime.from_erl!()
        |> DateTime.from_naive!("Etc/UTC")
      params = %{state: :paused, minimum: minimum, updated_time: last_updated}
      now = DateTime.utc_now()

      process =
        process
        |> Process.allocate(resources)
        |> Process.update_changeset(params)
        |> Changeset.apply_changes()

      assert :paused === process.state
      assert 300 === process.allocated.ram
      assert 2000 === process.updated_time.year

      process =
        process
        |> Process.resume()
        |> elem(0)
        |> Changeset.apply_changes()

      assert :running === process.state
      assert 600 === process.allocated.ram
      assert now.year === process.updated_time.year
    end
  end
end
