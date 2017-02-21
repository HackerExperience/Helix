defmodule Helix.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  # REVIEW: Refactor me, use factories

  setup do
    type = Enum.random(["cpu", "ram", "hdd", "nic"])
    component_spec =
      type
      |> spec_for()
      |> ComponentSpec.create_from_spec()
      |> Repo.insert!()

    {:ok, component_spec: component_spec}
  end

  describe "fetching component_spec" do
    test "succeeds by id" do
      cs = Factory.insert(:component_spec)
      assert {:ok, _} = ComponentSpecController.find(cs.spec_id)
    end

    test "fails when spec doesn't exists" do
      assert {:error, :notfound} === ComponentSpecController.find(Random.pk())
    end
  end

  test "delete is idempotent", %{component_spec: cs} do
    assert Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
    ComponentSpecController.delete(cs.spec_id)
    ComponentSpecController.delete(cs.spec_id)
    ComponentSpecController.delete(cs.spec_id)
    refute Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
  end

  defp spec_for("cpu") do
    %{
      spec_code: String.upcase(Random.string(min: 12)),
      spec_type: "CPU",
      name: Random.string(min: 12),
      clock: Random.number(66..3200),
      cores: Random.number(1..4)
    }
  end

  defp spec_for("ram") do
    %{
      spec_code: String.upcase(Random.string(min: 12)),
      spec_type: "RAM",
      name: Random.string(min: 12),
      clock: Random.number(66..3200),
      ram_size: Random.number(256..8192)
    }
  end

  defp spec_for("hdd") do
    %{
      spec_code: String.upcase(Random.string(min: 12)),
      spec_type: "HDD",
      name: Random.string(min: 12),
      hdd_size: Random.number(256..8192)
    }
  end

  defp spec_for("nic") do
    %{
      spec_code: String.upcase(Random.string(min: 12)),
      spec_type: "NIC",
      name: Random.string(min: 12),
      link: Random.number(1024..2048)
    }
  end

  describe "deleting component_spec" do
    test "is idempotent" do
      cs = Factory.insert(:component_spec)

      assert Repo.get_by(ComponentSpec, spec_id: cs.spec_id)

      :ok = ComponentSpecController.delete(cs.spec_id)
      :ok = ComponentSpecController.delete(cs.spec_id)

      refute Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
    end

    test "works by id and by struct" do
      cs = Factory.insert(:component_spec)
      :ok = ComponentSpecController.delete(cs)

      refute Repo.get_by(ComponentSpec, spec_id: cs.spec_id)

      cs = Factory.insert(:component_spec)
      :ok = ComponentSpecController.delete(cs.spec_id)

      refute Repo.get_by(ComponentSpec, spec_id: cs.spec_id)
    end
  end
end
