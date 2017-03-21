defmodule Helix.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  setup do
    type = Enum.random(["cpu", "ram", "hdd", "nic"])
    params = %{
      component_type: type,
      spec: spec_for(type)
    }
    component_spec =
      params
      |> ComponentSpec.create_changeset()
      |> Repo.insert!()

    {:ok, component_spec: component_spec}
  end

  describe "find" do
    test "fetching component_spec by id", %{component_spec: cs} do
      assert {:ok, _} = ComponentSpecController.find(cs.spec_id)
    end

    test "returns error when spec doesn't exists" do
      assert {:error, :notfound} === ComponentSpecController.find(Random.pk())
    end
  end

  describe "update" do
    test "overrides the spec", %{component_spec: cs} do
      update_params = %{spec: %{"test" => Burette.Color.name()}}
      {:ok, spec} = ComponentSpecController.update(cs, update_params)

      assert update_params.spec === spec.spec
      Repo.delete(spec)
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
      "spec_code": String.upcase(Random.string(min: 12)),
      "spec_type": "CPU",
      "name": Random.string(min: 12),
      "clock": Random.number(66..3200),
      "cores": Random.number(1..4)
    }
  end

  defp spec_for("ram") do
    %{
      "spec_code": String.upcase(Random.string(min: 12)),
      "spec_type": "RAM",
      "name": Random.string(min: 12),
      "clock": Random.number(66..3200),
      "ram_size": Random.number(256..8192)
    }
  end

  defp spec_for("hdd") do
    %{
      "spec_code": String.upcase(Random.string(min: 12)),
      "spec_type": "HDD",
      "name": Random.string(min: 12),
      "hdd_size": Random.number(256..8192)
    }
  end

  defp spec_for("nic") do
    %{
      "spec_code": String.upcase(Random.string(min: 12)),
      "spec_type": "NIC",
      "name": Random.string(min: 12)
    }
  end
end