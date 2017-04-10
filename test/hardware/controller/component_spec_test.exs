defmodule Helix.Hardware.Controller.ComponentSpecTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  describe "fetching" do
    test "succeeds by id" do
      cs = Factory.insert(:component_spec)
      assert %ComponentSpec{} = ComponentSpecController.fetch(cs.spec_id)
    end

    test "fails when spec doesn't exists" do
      refute ComponentSpecController.fetch(Random.pk())
    end
  end

  test "finding every spec of given type" do
    type = Enum.random(ComponentType.possible_types())

    specs = Factory.insert_list(4, :component_spec, component_type: type)
    found = ComponentSpecController.find(type: type)
    found_ids = Enum.map(found, &(&1.spec_id))

    assert Enum.all?(specs, &(&1.spec_id in found_ids))
    assert Enum.all?(found, &(&1.component_type == type))
  end

  describe "deleting" do
    test "succeeds by struct" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)
      ComponentSpecController.delete(cs)
      refute Repo.get(ComponentSpec, cs.spec_id)
    end

    test "succeeds by id" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)
      ComponentSpecController.delete(cs.spec_id)
      refute Repo.get(ComponentSpec, cs.spec_id)
    end

    test "is idempotent" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)
      ComponentSpecController.delete(cs.spec_id)
      ComponentSpecController.delete(cs.spec_id)
      refute Repo.get(ComponentSpec, cs.spec_id)
    end
  end
end
