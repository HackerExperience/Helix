defmodule Helix.Process.Model.Process.ResourcesTest do

  use ExUnit.Case, async: true

  alias Helix.Network.Model.Network
  alias Helix.Process.Model.Process

  alias Helix.Test.Process.Setup.TOP, as: TOPSetup

  defp gen_resource do
    {res, _} = TOPSetup.Resources.resources()
    res
  end

  describe "sum/2" do
    test "sums all resources" do
      res1 = gen_resource()
      res2 = gen_resource()

      sum = Process.Resources.sum(res1, res2)

      # Returned sum of each resource matches the sum of each resource.
      assert sum.cpu == Process.Resources.CPU.sum(res1.cpu, res2.cpu)
      assert sum.ram == Process.Resources.RAM.sum(res1.ram, res2.ram)
      assert sum.dlk == Process.Resources.DLK.sum(res1.dlk, res2.dlk)
      assert sum.ulk == Process.Resources.ULK.sum(res1.ulk, res2.ulk)
    end
  end

  describe "sub/2" do
    test "subs all resources" do
      res1 = gen_resource()
      res2 = gen_resource()

      sub = Process.Resources.sub(res1, res2)

      # Returned sub of each resource matches the sub of each resource.
      assert sub.cpu == Process.Resources.CPU.sub(res1.cpu, res2.cpu)
      assert sub.ram == Process.Resources.RAM.sub(res1.ram, res2.ram)
      assert sub.dlk == Process.Resources.DLK.sub(res1.dlk, res2.dlk)
      assert sub.ulk == Process.Resources.ULK.sub(res1.ulk, res2.ulk)
    end
  end

  describe "div/2" do
    test "divs all resources" do
      res1 = gen_resource()
      res2 = gen_resource()

      div = Process.Resources.div(res1, res2)

      # Returned div of each resource matches the div of each resource.
      assert div.cpu == Process.Resources.CPU.div(res1.cpu, res2.cpu)
      assert div.ram == Process.Resources.RAM.div(res1.ram, res2.ram)
      assert div.dlk == Process.Resources.DLK.div(res1.dlk, res2.dlk)
      assert div.ulk == Process.Resources.ULK.div(res1.ulk, res2.ulk)
    end
  end

  describe "mul/2" do
    test "muls all resources" do
      res1 = gen_resource()
      res2 = gen_resource()

      mul = Process.Resources.mul(res1, res2)

      # Returned mul of each resource matches the mul of each resource.
      assert mul.cpu == Process.Resources.CPU.mul(res1.cpu, res2.cpu)
      assert mul.ram == Process.Resources.RAM.mul(res1.ram, res2.ram)
      assert mul.dlk == Process.Resources.DLK.mul(res1.dlk, res2.dlk)
      assert mul.ulk == Process.Resources.ULK.mul(res1.ulk, res2.ulk)
    end
  end

  describe "min/1" do
    test "returns minimum value of resources" do
      res1 =
        %{
          cpu: 100,
          ram: 30,
          dlk: %{net: 150},
          ulk: %{net: 250}
        }

      res2 =
        %{
          cpu: 50,
          ram: 90,
          dlk: %{net: 240},
          ulk: %{net: 0}
        }

      min = Process.Resources.min(res1, res2)

      assert min == %{cpu: 50, ram: 30, dlk: %{net: 150}, ulk: %{net: 0}}
    end

    test "fills missing keys" do
      res1 =
        %{
          cpu: 100,
          dlk: %{net: 150},
          ulk: %{net: 250}
        }

      res2 =
        %{
          cpu: 50,
          ram: 90,
          dlk: %{net: 240, net2: 500},
          ulk: %{}
        }

      assert %{
        cpu: 50,
        ram: 90,
        dlk: %{net: 150, net2: 500},
        ulk: %{net: 250}
      } == Process.Resources.min(res1, res2)
    end

    test "handles empty resource" do
      res1 =
        %{
          cpu: 100,
          dlk: %{net: 150},
          ulk: %{net: 250}
        }

      res2 = %{}

      assert %{
        cpu: 100,
        ram: 0,
        dlk: %{net: 150},
        ulk: %{net: 250}
      } == Process.Resources.min(res1, res2)
    end
  end

  describe "initial/0" do
    test "initializes all resources" do
      initial = Process.Resources.initial()

      assert initial.cpu == Process.Resources.CPU.initial()
      assert initial.ram == Process.Resources.RAM.initial()
      assert initial.dlk == Process.Resources.DLK.initial()
      assert initial.ulk == Process.Resources.ULK.initial()
    end
  end

  describe "format/1" do
    test "converts string keys to atoms" do
      res =
        %{
          "cpu" => 100,
          "ram" => 200,
          "ulk" => %{},
          "dlk" => %{}
        }

      assert %{
        cpu: 100,
        ram: 200,
        ulk: %{},
        dlk: %{}
      } == Process.Resources.format(res)
    end

    test "fills up undefined/missing resources with their initial values" do
      res =
        %{
          cpu: 100,
          dlk: %{}
        }

      assert %{
        cpu: 100,
        ram: Process.Resources.RAM.initial(),
        dlk: %{},
        ulk: Process.Resources.ULK.initial()
      } == Process.Resources.format(res)
    end

    test "network-related keys are converted to Helix.IDs" do
      network_id = Network.ID.cast!("::")
      res =
        %{
          dlk: %{"::" => 100},
          ulk: Map.put(%{}, network_id, 200),
          cpu: 0,
          ram: 0
        }

      assert %{
        dlk: Map.put(%{}, network_id, 100),
        ulk: Map.put(%{}, network_id, 200),
        ram: 0,
        cpu: 0
      } == Process.Resources.format(res)
    end
  end
end
