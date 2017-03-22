defmodule Helix.Process.Controller.TableOfProcesses.Allocator.PlanTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Controller.TableOfProcesses.Allocator.Plan
  alias Helix.Process.Controller.TableOfProcesses.ServerResources
  alias Helix.Process.TestHelper.ProcessTypeExample
  alias Helix.Process.TestHelper.StaticProcessTypeExample

  @moduletag :unit

  # NOTE THAT MOST TESTS ASSERT THAT THE VALUE IS INSIDE A RANGE. THIS IS DONE
  # BECAUSE THE ALLOCATION ALGORITHM MIGHT NOT ALLOCATE 100% OF THE RESOURCES
  # BECAUSE IT'S ALLOCATION LOGIC IS NAIVE (i might fix it or worsen it in the
  # future)

  test "allocating to a static process doesn't affects it" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %StaticProcessTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    params2 = %{
      state: :running,
      allocated: %{
        cpu: 100,
        ram: 100
      },
      minimum: %{
        running: %{
          cpu: 100,
          ram: 100
        }
      }
    }

    process =
      params
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(params2)
      |> Ecto.Changeset.apply_changes()

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    [allocated_process] =
      [process]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)

    # Static processes doesn't receive dynamic allocations.
    # Note that with "static process" i mean a process whose process_type
    # doesn't allows dynamic allocation to any resources (unlike dynamic
    # processes that allow dynamic allocation to some or all of their resources)
    assert process.allocated === allocated_process.allocated
  end

  test "allocating to a dynamic process" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %ProcessTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    params2 = %{
      state: :running,
      allocated: %{
        cpu: 100,
        ram: 100
      },
      minimum: %{
        running: %{
          cpu: 100,
          ram: 100
        }
      }
    }

    process =
      params
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(params2)
      |> Ecto.Changeset.apply_changes()

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    [allocated_process] =
      [process]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)

    assert allocated_process.allocated.cpu in 8_950..9_000
    assert 100 === allocated_process.allocated.ram
  end

  test "resources are divided between different dynamic processes" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %ProcessTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    params2 = %{
      state: :running,
      allocated: %{
        cpu: 100,
        ram: 100
      },
      minimum: %{
        running: %{
          cpu: 100,
          ram: 100
        }
      }
    }

    process0 =
      params
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(params2)
      |> Ecto.Changeset.apply_changes()

    process1 = %{process0| process_id: Random.pk()}

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    [allocated_process0, allocated_process1] =
      [process0, process1]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)

    assert allocated_process0.allocated.cpu in 4_450..4_500
    assert allocated_process1.allocated.cpu in 4_450..4_500
  end

  test "processes with higher priority receive bigger shares" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %ProcessTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    params2 = %{
      state: :running,
      priority: 1,
      allocated: %{
        ram: 100
      },
      minimum: %{
        running: %{
          ram: 100
        }
      }
    }

    process0 =
      params
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(params2)
      |> Ecto.Changeset.apply_changes()

    process1 =
      %{process0| process_id: Random.pk()}
      |> ProcessModel.update_changeset(%{priority: 4})
      |> Ecto.Changeset.apply_changes()

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    processes =
      [process0, process1]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)
      |> Enum.map(&({&1.process_id, &1}))
      |> :maps.from_list()

    # Process0 has priority 1, process1 has priority 4, thus the resources will
    # be split in 5 parts, process0 receives 1/5 of the total resources and
    # process1 receives 4/5
    assert processes[process0.process_id].allocated.cpu in 1_750..1_800
    assert processes[process1.process_id].allocated.cpu in 7_150..7_200
  end

  test "complex allocation using limits" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %ProcessTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    params2 = %{
      state: :running,
      allocated: %{
        ram: 100
      },
      minimum: %{
        running: %{
          ram: 100
        }
      }
    }

    process0 =
      params
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(params2)
      |> Ecto.Changeset.apply_changes()

    process1 = %{process0| process_id: Random.pk()}

    process2 =
      %{process0| process_id: Random.pk()}
      |> ProcessModel.update_changeset(%{limitations: %{cpu: 500}})
      |> Ecto.Changeset.apply_changes()

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    processes =
      [process0, process1, process2]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)
      |> Enum.map(&({&1.process_id, &1}))
      |> :maps.from_list()

    # We expect the following to happen: 500 cpu to process2 because it has
    # limit and (8500/2) to process0 and process1 because they receive the rest.
    # So, we expect process0 and process1 to have aproximately 4250, but since
    # there are several ways to execute the allocation algorithm, we should
    # expect allocator to fail to allocate a part of the resources left
    assert processes[process0.process_id].allocated.cpu in 4_200..4_250
    assert processes[process0.process_id].allocated.cpu == processes[process1.process_id].allocated.cpu
    assert 500 === processes[process2.process_id].allocated.cpu
  end

  test "returns error when resources can't handle processes at minimum" do
    params = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %ProcessTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    process0 =
      params
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(%{state: :running})
      |> ProcessModel.update_changeset(%{minimum: %{running: %{ram: 2_000}}})
      |> Ecto.Changeset.apply_changes()

    process1 =
      %{params| gateway_id: Random.pk()}
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(%{state: :running})
      |> ProcessModel.update_changeset(%{minimum: %{running: %{ram: 2_000}}})
      |> Ecto.Changeset.apply_changes()

    resources = %ServerResources{
      cpu: 9_000,
      # Note that the server only has 3k Ram total and the processes together
      # requires a minimum of 4k ram
      ram: 3_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    assert {:error, {:resources, :lack, :ram}} === Plan.allocate([process0, process1], resources)
  end
end