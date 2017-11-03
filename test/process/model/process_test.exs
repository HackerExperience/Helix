defmodule Helix.Process.Model.ProcessTest do

  use ExUnit.Case, async: true

  alias Helix.Process.Model.Process

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.FakeFileTransfer
  alias Helix.Test.Process.Setup.TOP, as: TOPSetup

  @internet_id NetworkHelper.internet_id()

  describe "infer_usage/1" do
    test "infers usage on remote process" do
      [proc] = TOPSetup.fake_process()

      # Process below is probably a file transfer
      # Locally, it uses DLK and has reserved 50 units of it
      # On the remote, however, it is limited by the remote's ULK, at 20 units
      # The actual allocated resources are 20 DLK for local, 20 ULK for remote
      # (Plus the other unrelated stuff that was reserved before)
      proc =
        proc
        |> Map.put(:l_limit, %{})
        |> Map.put(:l_reserved, %{cpu: 72, ram: 20, dlk: %{net: 50}, ulk: %{}})
        |> Map.put(:r_limit, %{ulk: %{net: 20}})
        |> Map.put(:r_reserved, %{dlk: %{}, cpu: 0, ram: 0, ulk: %{net: 20}})

      process = Process.infer_usage(proc)

      assert process.l_allocated.cpu == 72
      assert process.l_allocated.ram == 20.0
      assert process.l_allocated.dlk.net == 20
      assert process.l_allocated.ulk == %{}

      assert process.r_allocated.ulk.net == 20
      assert process.r_allocated.cpu == 0
      assert process.r_allocated.ram == 0
      assert process.r_allocated.dlk == %{}
    end

    test "ignores r_allocated when remote resources are not relevant" do
      [proc] = TOPSetup.fake_process()

      # Process below has its own rules for limitations and allocation, but it's
      # completely independent of the remote server's behaviour/resources.
      proc =
        proc
        |> Map.put(:l_limit, %{ram: 10})
        |> Map.put(:l_reserved, %{cpu: 72, ram: 20, dlk: %{net: 50}, ulk: %{}})
        |> Map.put(:r_limit, %{})
        |> Map.put(:r_reserved, %{})

      process = Process.infer_usage(proc)

      assert process.l_allocated.cpu == 72
      assert process.l_allocated.ram == 10
      assert process.l_allocated.dlk.net == 50
      assert process.l_allocated.ulk == %{}

      assert process.r_allocated.ulk == %{}
      assert process.r_allocated.cpu == 0
      assert process.r_allocated.ram == 0
      assert process.r_allocated.dlk == %{}
    end

    test "mirrors DLK and ULK resources" do
      # Notice that in `proc`, both DLK and ULK are being limited by remote
      [proc] =
        TOPSetup.fake_process(
          l_limit: %{ram: 30},
          r_limit: %{dlk: %{net: 20}},
          l_reserved: %{cpu: 0, ram: 40, ulk: %{net: 30}, dlk: %{}},
          r_reserved: %{cpu: 10, ram: 20, ulk: %{net: 15}, dlk: %{net: 20}},
        )

      process = Process.infer_usage(proc)

      assert process.l_allocated.cpu == 0
      assert process.l_allocated.ram == 30
      assert process.l_allocated.ulk.net == 20
      assert process.l_allocated.dlk.net == 15

      assert process.r_allocated.cpu == 10
      assert process.r_allocated.ram == 20
      assert process.r_allocated.dlk.net == 20
      assert process.r_allocated.ulk.net == 15

      # We'll now modify `proc` so that the `l_reserved` is the min value
      # (this means DLK/ULK will be limited by local resources)

      proc =
        %{proc|
          l_limit: %{},
          r_limit: %{},
          l_reserved: %{cpu: 10, ram: 20, ulk: %{net: 15}, dlk: %{net: 20}},
          r_reserved: %{cpu: 0, ram: 40, ulk: %{net: 30}, dlk: %{}}
         }

      process = Process.infer_usage(proc)

      assert process.l_allocated.cpu == 10
      assert process.l_allocated.ram == 20
      assert process.l_allocated.ulk.net == 15
      assert process.l_allocated.dlk.net == 20

      assert process.r_allocated.cpu == 0
      assert process.r_allocated.ram == 40
      assert process.r_allocated.ulk.net == 30
      assert process.r_allocated.dlk == %{}
    end
  end

  describe "format/1" do
    test "formats the process data" do

      [proc] =
        TOPSetup.fake_process(
          l_limit: %{ram: 30},
          r_limit: %{dlk: %{"::" => 20}, cpu: 10},
          l_reserved: %{cpu: 0, ram: 20, ulk: %{"::" => 50}, dlk: %{}},
          r_reserved: %{cpu: 30, ram: 30, ulk: %{}, dlk: %{"::" => 20}},
          l_dynamic: [:ulk],
          r_dynamic: [:dlk],
          objective: %{cpu: 0, ram: 0, dlk: %{}, ulk: %{"::" => 9999}},
          network_id: "::",
          data: FakeFileTransfer.new()
        )

      process = Process.format(proc)

      assert process.data == proc.data

      # Never went through a checkpoint
      refute process.last_checkpoint_time

      ### Formatted resources

      # Objective

      assert process.objective.cpu == 0
      assert process.objective.ram == 0
      assert process.objective.dlk == %{}
      assert process.objective.ulk[@internet_id] == 9999

      # Limits

      assert process.l_limit.ram == 30
      refute Map.has_key?(process.l_limit, :cpu)
      refute Map.has_key?(process.l_limit, :dlk)
      refute Map.has_key?(process.l_limit, :ulk)

      assert process.r_limit.cpu == 10
      assert process.r_limit.dlk[@internet_id] == 20
      refute Map.has_key?(process.r_limit, :ram)
      refute Map.has_key?(process.r_limit, :ulk)

      # Reservation

      assert process.l_reserved.cpu == 0
      assert process.l_reserved.ram == 20
      assert process.l_reserved.dlk == %{}
      assert process.l_reserved.ulk[@internet_id] == 50

      assert process.r_reserved.cpu == 30
      assert process.r_reserved.ram == 30
      assert process.r_reserved.dlk[@internet_id] == 20
      assert process.r_reserved.ulk == %{}

      ### Virtual data

      # The process has reserved resources and it's not paused, so it's running
      assert process.state == :running

      # Correct allocation (see more tests on `infer_usage/1`)
      assert process.l_allocated.cpu == 0
      assert process.l_allocated.ram == 20
      assert process.l_allocated.dlk == %{}
      assert process.l_allocated.ulk[@internet_id] == 20

      assert process.r_allocated.cpu == 10
      assert process.r_allocated.ram == 30
      assert process.r_allocated.dlk[@internet_id] == 20
      assert process.r_allocated.ulk == %{}
    end

    test "gives :waiting_allocation state when process hasn't received alloc" do
      [proc] =
        TOPSetup.fake_process(
          l_limit: %{ram: 30},
          r_limit: %{dlk: %{"::" => 20}, cpu: 10},
          l_reserved: %{},
          r_reserved: %{},
          l_dynamic: [:dlk],
          r_dynamic: [:ulk],
          network_id: "::",
          data: FakeFileTransfer.new()
        )

      process = Process.format(proc)

      assert process.state == :waiting_allocation
    end

    test "gives :paused state when process priority is 0" do
      [proc] =
        TOPSetup.fake_process(
          priority: 0,
          l_limit: %{ram: 30},
          r_limit: %{dlk: %{"::" => 20}, cpu: 10},
          l_reserved: %{cpu: 0, ram: 20, ulk: %{"::" => 50}, dlk: %{}},
          r_reserved: %{cpu: 30, ram: 30, ulk: %{}, dlk: %{"::" => 20}},
          r_dynamic: [:ulk],
          network_id: "::",
          data: FakeFileTransfer.new()
        )

      process = Process.format(proc)

      assert process.state == :paused
    end
  end
end
