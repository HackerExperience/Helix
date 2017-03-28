defmodule Helix.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  describe "fetching" do
    test "succeeds by id" do
      cs = Factory.insert(:component_spec)
      assert %ComponentSpec{} = ComponentSpecController.fetch(cs.spec_id)
    end

    test "fails when spec doesn't exists" do
      bogus = Factory.build(:component_spec)
      refute ComponentSpecController.fetch(bogus.spec_id)
    end
  end

  test "finding every spec of given component_type" do
    spec_type = Enum.random(ComponentType.possible_types())

    specs =
      4
      |> Factory.insert_list(:component_spec, component_type: spec_type)
      |> Enum.map(&(&1.spec_id))

    found =
      [component_type: spec_type]
      |> ComponentSpecController.find()
      |> Enum.map(&(&1.spec_id))

    result = Enum.reject(specs, &(&1 in found))
    assert Enum.empty?(result)
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
