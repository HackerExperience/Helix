defmodule Helix.Process.Model.TOP.SchedulerTest do

  use ExUnit.Case, async: true

  alias HELL.Utils
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.TOP.Scheduler

  alias Helix.Test.Process.Setup.TOP, as: TOPSetup

  @slack 5

  describe "simulate/1" do
    test "simulates progress" do
      # The process below has an objective of cpu: 100, ram: 100; and have
      # allocated to it cpu: 1, ram: 5. The allocation part will be added to the
      # process every second (but with a millisecond-grade precision).
      process =
        %{
          processed: nil,
          objective: %{cpu: 100, ram: 100, dlk: %{}, ulk: %{}},
          l_allocated: %{cpu: 1, ram: 5, dlk: %{}, ulk: %{}},
          last_checkpoint_time: nil,
          creation_time: Utils.date_before(10),
          state: :running
        }

      # Notice that we've set the creation time to 10 seconds in the past, so
      # the process should have some ~10 MHz allocated to the `processed`, and
      # as such it should not be deemed completed.
      assert {:running, p} = Scheduler.simulate(process)

      # As part of the simulation, the `processed` field of the process was
      # updated, with the expected processed (accounting for delays, since this
      # is a set of floating-point operations at millisecond scale).
      assert_in_delta p.processed.cpu, 10, @slack
      assert_in_delta p.processed.ram, 50, @slack

      # Now we'll update the original process to be marked as created 20 seconds
      # ago. This means it should have ~125 processed RAM and ~25 CPU.
      # That's enough RAM but not enough CPU.
      process = %{process| creation_time: Utils.date_before(25)}

      assert {:running, p} = Scheduler.simulate(process)
      assert_in_delta p.processed.cpu, 25, @slack
      assert_in_delta p.processed.ram, 125, @slack

      # OK, 10 minutes should be enough
      process = %{process| creation_time: Utils.date_before(600)}
      assert {:completed, p} = Scheduler.simulate(process)

      assert p.processed.cpu > p.objective.cpu
      assert p.processed.ram > p.objective.ram
    end

    test "simulate progress (with DLK/ULK)" do
      process =
        %{
          processed: nil,
          objective: %{cpu: 10, ram: 5, dlk: %{net: 100}, ulk: %{net: 50}},
          l_allocated: %{cpu: 1, ram: 5, dlk: %{net: 1}, ulk: %{net: 0.5}},
          last_checkpoint_time: nil,
          creation_time: Utils.date_before(10),
          state: :running
        }

      # Ran for 10 seconds... Not enough
      assert {:running, p} = Scheduler.simulate(process)

      # CPU and RAM are done
      assert p.processed.cpu > p.objective.cpu
      assert p.processed.ram > p.objective.ram

      # But there's still a long way to go for DLK and ULK
      assert_in_delta p.processed.dlk.net, 10, @slack
      assert_in_delta p.processed.ulk.net, 5, @slack

      # But given enough time...
      process = %{process| creation_time: Utils.date_before(100)}

      assert {:completed, p} = Scheduler.simulate(process)
      assert p.processed.cpu > p.objective.cpu
      assert p.processed.ram > p.objective.ram
      assert p.processed.dlk.net > p.objective.dlk.net
      assert p.processed.ulk.net > p.objective.ulk.net
    end

    test "simulate loading a process from DB (has `last_checkpoint_time`)" do
      # See, the process below was started over a day ago, but that date will be
      # ignored by the simulator, since we have a `last_checkpoint_time`. This
      # means that the progress of the process was saved on the DB for some
      # reason. It may be the case that the user paused her process. This would
      # lead to an `last_checkpoint_time` being set, with the previous processed
      # resources saved. If the process keeps paused for a year, it still
      # should not be marked as completed. Capisce?
      process =
        %{
          processed: nil,
          objective: %{cpu: 100, ram: 100, dlk: %{}, ulk: %{}},
          l_allocated: %{cpu: 1, ram: 5, dlk: %{}, ulk: %{}},
          last_checkpoint_time: Utils.date_before(10),
          creation_time: Utils.date_before(86_400),
          state: :running
        }

      # Still running
      assert {:running, p} = Scheduler.simulate(process)

      assert_in_delta p.processed.cpu, 10, @slack
      assert_in_delta p.processed.ram, 50, @slack

      # Give it enough time...
      process = %{process| last_checkpoint_time: Utils.date_before(100)}

      # Aaaaand we are done.
      assert {:completed, _} = Scheduler.simulate(process)
    end

    test "ignores paused processes" do
      process = %{state: :paused}

      assert {:paused, _p} = Scheduler.simulate(process)
    end
  end

  describe "estimate_completion/1" do
    test "estimates completion time of running process" do
      # Never processed anything; needs 100 MHz at 1 MHz per second.
      process =
        %{
          processed: nil,
          objective: %{cpu: 100, ram: 100, dlk: %{}, ulk: %{}},
          l_allocated: %{cpu: 1, ram: 5, dlk: %{}, ulk: %{}},
          next_allocation: %{cpu: 1, ram: 5, dlk: %{}, ulk: %{}},
          last_checkpoint_time: nil,
          creation_time: DateTime.utc_now(),
          state: :running
        }

      assert {p, estimation} = Scheduler.estimate_completion(process)

      # At this rate, it would take ~100 seconds to complete the process
      assert_in_delta estimation, 100, 0.1

      # The returned process has gone through a simulation
      assert p.processed

      # Now this new process has already processed 95 MHz, so it would need 5s
      # of CPU usage in order to complete it.. However, it still needs ~20s of
      # RAM usage in order to be fully processed.
      process = %{process| processed: %{cpu: 95, ram: 0, dlk: %{}, ulk: %{}}}

      assert {_p, estimation} = Scheduler.estimate_completion(process)
      assert_in_delta estimation, 20, 0.1

      process =
        %{
          processed: nil,
          objective: %{cpu: 1, ram: 10, dlk: %{net: 100}, ulk: %{net: 50}},
          l_allocated: %{cpu: 1, ram: 50, dlk: %{net: 20}, ulk: %{net: 25}},
          next_allocation: %{cpu: 1, ram: 50, dlk: %{net: 20}, ulk: %{net: 25}},
          last_checkpoint_time: nil,
          creation_time: DateTime.utc_now(),
          state: :running
        }

      # This is a variation of the above test in order to verify that this
      # behaviour holds true for KV resources (DLK/ULK)
      assert {_p, estimation} = Scheduler.estimate_completion(process)

      # ~5s to fill DLK up
      assert_in_delta estimation, 5, 0.1
    end

    test "estimates completion time of completed processes" do
      # This process is already completed!!11!
      process =
        %{
          processed: %{cpu: 11, ram: 11, dlk: %{}, ulk: %{}},
          objective: %{cpu: 10, ram: 10, dlk: %{}, ulk: %{}},
          l_allocated: %{cpu: 1, ram: 1, dlk: %{}, ulk: %{}},
          next_allocation: %{cpu: 1, ram: 1, dlk: %{}, ulk: %{}},
          last_checkpoint_time: nil,
          creation_time: DateTime.utc_now(),
          state: :running
        }

      assert {_p, estimation} = Scheduler.estimate_completion(process)
      assert estimation == -1
    end

    test "estimates completion time of paused processes" do
      process =
        %{
          processed: :i,
          objective: :dont,
          l_allocated: :care,
          state: :paused
        }

      assert {_p, estimation} = Scheduler.estimate_completion(process)
      assert estimation == :infinity
    end
  end

  describe "forecast/1" do
    test "figures out the next process that will be completed" do
      # Note: we'll be comparing processes with their identifier keys (`id`)
      # because, once a process goes through `forecast/1`, it will be simulated,
      # which will change its model.

      # p1 would take ~10s to complete
      p1 = p1()

      # p2 would take ~5s to complete
      p2 = p2()

      # Forecasting only `p1`.. Obviously it's the next one to be completed
      assert %{
        completed: [],
        next: {next, time_left},
        running: running
      } =
        Scheduler.forecast([p1])

      # P1 should take some 10 seconds to complete
      assert_in_delta time_left, 10, 0.1
      assert next.id == p1.id
      assert Enum.find(running, &(&1.id == p1.id))
      assert length(running) == 1

      # Forecasting `p1` and `p2`. `p2` shall complete first, in 5 seconds
      assert %{
        completed: [],
        next: {next, time_left},
        running: running
      } = Scheduler.forecast([p1, p2])

      assert_in_delta time_left, 5, 0.1
      assert next.id == p2.id
      assert length(running) == 2

      # Forecasting repeated processes `p1` and `p2`. The Scheduler doesn't know
      # they are the same (and it's not the Scheduler's job anyway). The catch
      # here is that some process will have completion time identical to others,
      # so we must make sure the Scheduler only picks one to be the `next`.
      assert %{
        completed: [],
        next: {next, time_left},
        running: running
      } = Scheduler.forecast([p1, p1, p2, p2])

      assert_in_delta time_left, 5, 0.1
      assert next.id == p2.id
      assert length(running) == 4
    end

    test "filters completed processes" do
      # p1 would take ~10s to complete
      p1 = p1()
      # p2 would take ~5s to complete
      p2 = p2()
      # p3 has already processed what it was supposed to
      p3 = p3()

      assert %{
        completed: [proc_completed],
        next: {next, time_left},
        running: running
      } = Scheduler.forecast([p1, p2, p3])

      assert proc_completed.id == p3.id
      assert next.id == p2.id
      assert_in_delta time_left, 5, 0.1
      assert length(running) == 2
    end

    test "filters paused processes" do
      # p1 will be completed in 10s
      p1 = p1()
      # p2 will be completed in 5s
      p2 = p2()
      # p3 is completed
      p3 = p3()
      # p4 is paused
      p4 = p4()

      assert %{
        completed: [proc_completed],
        next: {next, time_left},
        running: running,
        paused: [proc_paused]
      } = Scheduler.forecast([p1, p2, p3, p4])

      assert proc_completed.id == p3.id
      assert next.id == p2.id
      assert_in_delta time_left, 5, 0.1
      assert length(running) == 2
      assert proc_paused.id == p4.id
    end

    test "empty list" do
      assert %{completed: [], next: nil, running: [], paused: []} =
        Scheduler.forecast([])
    end

    test "with processes, but none of them will be completed `next`" do
      # p3 is completed
      p3 = p3()
      # p4 is paused
      p4 = p4()

      assert %{
        completed: completed,
        paused: paused,
        running: [],
        next: nil
      } = Scheduler.forecast([p3, p3, p3, p4, p4, p4])

      assert length(completed) == 3
      assert length(paused) == 3
    end

    test "processes 'waiting_allocation' are accurately forecast" do
      # Describe the problem

      # p5 represents a recently created process, going through the allocator
      # (and forecast) for the very first time.
      # Without using the `next_allocation` virtual field of process, we'd lose
      # this iteration, and on the forecast the `p5` would be marked as `paused`
      # (since its state is `waiting_allocation`).
      # However, when it goes through the forecast, it has already gone through
      # the Allocator, so it *must have received* the allocation, it simply
      # wasn't saved yet to the process model.
      # That's why we use `waiting_allocation`: With this field, the `forecast`
      # method knows that it should estimate the completion of this process
      # based on its `next_allocation`, even though `allocated` is nil.
      p5 = p5()

      %{completed: [], next: {process, time_left}, paused: []} =
        Scheduler.forecast([p5])

      # ~3.3s to complete
      assert_in_delta time_left, 3.3, 0.1
      assert process.state == :running
    end

    test "tricky scenario" do
      # Context: the process below has processed very little. At the current
      # rate (presented on `allocated`), it would complete in ~4 seconds, being
      # CPU the bottleneck. Since the last processed time was 2 seconds ago,
      # the correct result would be two seconds left for completion....
      # HOWEVER, on the `next_allocation`, the CPU allocation would skyrocket to
      # `80`, reducing the CPU completion to less than a second, but the DLK
      # allocation would go down to 1 unit per second, meaning it would take
      # ~9 seconds for completion. This is the correct result.
      # (After simulation, DLK would go to 40; then, on forecast estimation,
      # an extra 10 units would be needed. At 1 unit/s, it takes 10 seconds.
      # However, one unit of DLK has already been processed before. Hence, 9s).
      p =
        %{
          processed: %{cpu: 1, ram: 1, dlk: %{net: 1}, ulk: %{}},
          objective: %{cpu: 100, ram: 20, dlk: %{net: 50}, ulk: %{}},
          l_allocated: %{cpu: 25, ram: 10, dlk: %{net: 20}, ulk: %{}},
          next_allocation: %{cpu: 80, ram: 5, dlk: %{net: 1}, ulk: %{}},
          last_checkpoint_time: Utils.date_before(2000, :millisecond),
          creation_time: nil,
          state: :running
        }

      assert %{next: {_, time_left}} = Scheduler.forecast([p])

      assert_in_delta time_left, 9, 0.1
    end

    defp p1 do
      # P1 is running and takes about ~10 seconds to complete
      %{
        id: 1,
        processed: nil,
        objective: %{cpu: 10, ram: 15, dlk: %{}, ulk: %{}},
        l_reserved: %{cpu: 1, ram: 5, dlk: %{}, ulk: %{}},
        l_allocated: %{cpu: 1, ram: 5, dlk: %{}, ulk: %{}},
        next_allocation: %{cpu: 1, ram: 5, dlk: %{}, ulk: %{}},
        last_checkpoint_time: nil,
        creation_time: DateTime.utc_now(),
        state: :running
      }
    end

    defp p2 do
      # P2 is running and takes about ~5 seconds to complete
      %{
        id: 2,
        processed: nil,
        objective: %{cpu: 10, ram: 0, dlk: %{net: 10}, ulk: %{net: 10}},
        l_reserved: %{cpu: 5, ram: 0, dlk: %{net: 2}, ulk: %{net: 3}},
        l_allocated: %{cpu: 5, ram: 0, dlk: %{net: 2}, ulk: %{net: 3}},
        next_allocation: %{cpu: 5, ram: 0, dlk: %{net: 2}, ulk: %{net: 3}},
        last_checkpoint_time: nil,
        creation_time: DateTime.utc_now(),
        state: :running
      }
    end

    defp p3 do
      # P3 already processed what it was supposed to (it's completed!)
      %{
        id: 3,
        processed: %{cpu: 100, ram: 100, dlk: %{net: 100}, ulk: %{}},
        objective: %{cpu: 99, ram: 99, dlk: %{net: 99}, ulk: %{}},
        l_reserved: %{cpu: 10, ram: 10, dlk: %{}, ulk: %{}},
        l_allocated: %{cpu: 10, ram: 10, dlk: %{}, ulk: %{}},
        next_allocation: %{cpu: 10, ram: 10, dlk: %{}, ulk: %{}},
        last_checkpoint_time: nil,
        creation_time: DateTime.utc_now(),
        state: :running
      }
    end

    defp p4 do
      # P4 would complete in less than 1 second... if only it wasn't paused
      %{
        id: 4,
        processed: nil,
        objective: %{cpu: 10, ram: 0, dlk: %{net: 10}, ulk: %{net: 10}},
        l_allocated: %{cpu: 9, ram: 0, dlk: %{net: 9}, ulk: %{net: 9}},
        l_reserved: %{cpu: 9, ram: 0, dlk: %{net: 9}, ulk: %{net: 9}},
        next_allocation: %{cpu: 9, ram: 0, dlk: %{net: 9}, ulk: %{net: 9}},
        last_checkpoint_time: nil,
        creation_time: DateTime.utc_now(),
        state: :paused
      }
    end

    defp p5 do
      # P5 was recently created and is going through the forecast/simulation for
      # the very first time.
      %{
        id: 5,
        processed: nil,
        objective: %{cpu: 10, ram: 0, dlk: %{net: 10}, ulk: %{net: 10}},
        l_reserved: %{},
        next_allocation: %{cpu: 5, ram: 0, dlk: %{net: 10}, ulk: %{net: 3}},
        last_checkpoint_time: nil,
        creation_time: DateTime.utc_now(),
        state: :waiting_allocation
      }
    end
  end

  describe "checkpoint/1" do
    test "sets allocation; last_checkpoint_time" do
      # This is the new allocation of p1, given by the Allocator
      next_allocation = %{cpu: 100, ram: 0, dlk: %{}, ulk: %{}}

      # P1 was never processed nor allocated before. It represents a recently
      # created process.
      [p1] =
        TOPSetup.fake_process(next_allocation: next_allocation, local?: true)

      refute p1.processed
      assert p1.l_reserved == %{}
      assert p1.l_allocated == Process.Resources.initial()
      refute p1.last_checkpoint_time
      assert p1.next_allocation

      # `checkpoint/2` is telling us that the process should be updated
      assert {true, changeset} = Scheduler.checkpoint(p1)

      new_proc = Ecto.Changeset.apply_changes(changeset)

      # The given allocation was saved on the process
      assert new_proc.l_reserved == next_allocation

      # Checkpoint time was set
      assert new_proc.last_checkpoint_time

      # The given process was not simulated inside `checkpoint`. The `processed`
      # entry remains unchanged
      refute new_proc.processed
    end

    test "does not change the model when the allocation remains unchanged" do
      allocated = %{cpu: 100, ram: 0, dlk: %{}, ulk: %{}}

      [p1] =
        TOPSetup.fake_process(
          l_reserved: allocated, next_allocation: allocated, local?: true
        )

      # The process and the resulting allocation are the same
      assert p1.l_reserved == allocated

      # Returns `false`, meaning "do not update"
      refute Scheduler.checkpoint(p1)
    end
  end
end
