defmodule Helix.Process.Model.Process.Resources.DLKTest do

  use ExUnit.Case, async: true

  alias Helix.Process.Model.Process.Resources.DLK, as: ResourceDLK

  describe "build/1" do
    test "builds correctly" do
      # Empty resource (same as initial)
      assert %{} == ResourceDLK.build([])

      # With map
      assert %{net_id: 100} == ResourceDLK.build(%{net_id: 100})
      assert %{net1: 1, net2: 2} == ResourceDLK.build(%{net1: 1, net2: 2})

      # Created %{network_id => 100}
      assert %{net_id: 100} == ResourceDLK.build([{:net_id, 100}])

      # Created multiple networks
      assert %{net1: 1, net2: 2} == ResourceDLK.build([{:net1, 1}, {:net2, 2}])
    end
  end

  describe "sum/2" do
    test "valid data" do

      a = %{net1: 100, net2: 200}
      b = %{net1: 1, net2: 2}

      assert %{net1: 101, net2: 202} == ResourceDLK.sum(a, b)
    end

    test "non-overlapping keys" do

      a = %{net1: 50, net2: 2}
      b = %{net1: 50, net3: 3}

      assert %{net1: 100, net2: 2, net3: 3} == ResourceDLK.sum(a, b)
    end

    test "empty keys" do
      initial = ResourceDLK.initial()
      assert %{} == ResourceDLK.sum(initial, initial)

      a = %{netA: 1}
      b = %{netB: 2}

      assert %{netA: 1} == ResourceDLK.sum(a, initial)
      assert %{netB: 2} == ResourceDLK.sum(initial, b)
    end
  end

  describe "mul/2" do
    test "multiplies overlapping keys" do
      a = %{net1: 3, net2: 2}
      b = %{net1: 4, net2: 0}

      assert %{net1: 12, net2: 0} == ResourceDLK.mul(a, b)
    end

    test "handles missing keys" do
      a = %{net1: 2, net2: 2}
      b = %{net1: 5, net3: 3}

      assert %{net1: 10, net2: 2, net3: 3} == ResourceDLK.mul(a, b)
    end
  end

  describe "div/2" do
    test "divides" do
      a = %{net1: 10, net2: 5}
      b = %{net1: 2, net2: 5}

      assert %{net1: 5, net2: 1} == ResourceDLK.div(a, b)
    end
  end

  describe "allocate_static/1" do
    test "returns the expected format" do
      process =
        %{
          static: %{running: %{dlk: 100}},
          state: :running,
          network_id: :net_id
        }

      assert %{net_id: 100} == ResourceDLK.allocate_static(process)
    end

    test "ignores if resource is not requested statically" do
      process =
        %{
          static: %{running: %{ulk: 100}},
          state: :running,
          network_id: :net_id
        }

      assert %{net_id: 0} == ResourceDLK.allocate_static(process)
    end

    test "ignores if resource is on different state" do
      process =
        %{
          static: %{running: %{ulk: 100}},
          state: :paused,
          network_id: :net_id
        }

      assert %{net_id: 0} == ResourceDLK.allocate_static(process)
    end

    test "ignores if network_id is nil" do
      process =
        %{
          static: %{running: %{dlk: 100}},
          state: :running,
          network_id: nil
        }

      assert %{} == ResourceDLK.allocate_static(process)
    end
  end

  describe "completed?/2" do
    test "true when all processed values are greater than their objectives" do
      processed = %{net1: 200, net2: 1}
      objective = %{net1: 101, net2: 10}

      result = ResourceDLK.completed?(processed, objective)

      assert result == %{net1: true, net2: false}
    end

    test "true when there is no objective" do
      processed = %{net: 100}
      objective = %{}

      assert %{net: true} == ResourceDLK.completed?(processed, objective)
    end
  end

  describe "map/2" do
    test "applies to each value" do

      res = %{net1: true, net2: false, net3: true}

      function = fn val -> not val end

      result = ResourceDLK.map(res, function)

      assert result == %{net1: false, net2: true, net3: false}
    end
  end

  describe "reduce/2" do
    test "works" do
      r1 = %{net1: 100, net2: 300}
      f1 = fn acc, v -> acc + v end
      i1 = 0

      assert 400 == ResourceDLK.reduce(r1, i1, f1)

      r2 = %{net1: true, net2: true, net3: true}
      f2 = fn acc, v -> acc && v || false end
      i2 = true

      assert ResourceDLK.reduce(r2, i2, f2)

      r3 = %{net1: true, net2: true, net3: false}

      refute ResourceDLK.reduce(r3, i2, f2)
    end
  end
end
