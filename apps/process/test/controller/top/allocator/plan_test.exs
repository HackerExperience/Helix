defmodule Helix.Process.Controller.TableOfProcesses.Allocator.PlanTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Process.Model.Process, as: ProcessModel
  # alias Helix.Process.Controller.TableOfProcesses
  alias Helix.Process.Controller.TableOfProcesses.Allocator.Plan
  alias Helix.Process.Controller.TableOfProcesses.ServerResources
  alias Helix.Process.TestHelper.SoftwareTypeExample
  alias Helix.Process.TestHelper.StaticSoftwareTypeExample

  test "allocating to a static process doesn't affects it" do
    pparams = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      software: %StaticSoftwareTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    pparams2 = %{
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
      pparams
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(pparams2)
      |> Ecto.Changeset.apply_changes()

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    [xs] =
      [process]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)

    # Static processes doesn't receive dynamic allocations.
    # Note that with "static process" i mean a process whose software_type
    # doesn't allows dynamic allocation to any resources (unlike dynamic
    # processes that allow dynamic allocation to some or all of their resources)
    assert process.allocated === xs.allocated
  end

  test "allocating to a dynamic process" do
    pparams = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      software: %SoftwareTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    pparams2 = %{
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
      pparams
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(pparams2)
      |> Ecto.Changeset.apply_changes()

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    [xs] =
      [process]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)

    # 100 were already allocated at the start, 9_000 were added by the
    # allocation
    assert 9_100 === xs.allocated.cpu
    assert 100 === xs.allocated.ram
  end

  test "resources are divided between different dynamic processes" do
    pparams = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      software: %SoftwareTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    pparams2 = %{
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
      pparams
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(pparams2)
      |> Ecto.Changeset.apply_changes()

    process1 = %{process0| process_id: Random.pk()}

    resources = %ServerResources{
      cpu: 9_000,
      ram: 9_000,
      net: %{"::" => %{dlk: 9_000, ulk: 9_000}}
    }

    [xs0, xs1] =
      [process0, process1]
      |> Plan.allocate(resources)
      |> Enum.map(&Ecto.Changeset.apply_changes/1)

    # Half of 9000 plus 100 already allocated
    assert 4600 = xs0.allocated.cpu
    assert 4600 = xs1.allocated.cpu
  end

  test "processes with higher priority receive bigger shares" do
    pparams = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      software: %SoftwareTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    pparams2 = %{
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
      pparams
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(pparams2)
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
    assert 1_800 === processes[process0.process_id].allocated.cpu
    assert 7_200 === processes[process1.process_id].allocated.cpu
  end

  test "complex allocation using limits" do
    pparams = %{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      software: %SoftwareTypeExample{},
      objective: %{
        cpu: 100_000
      }
    }

    pparams2 = %{
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
      pparams
      |> ProcessModel.create_changeset()
      |> ProcessModel.update_changeset(pparams2)
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
    assert_in_delta processes[process0.process_id].allocated.cpu, 4_250, 90
    assert processes[process0.process_id].allocated.cpu == processes[process1.process_id].allocated.cpu
    assert 500 === processes[process2.process_id].allocated.cpu
  end
end