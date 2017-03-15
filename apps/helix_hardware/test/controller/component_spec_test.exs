defmodule Helix.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  # REVIEW: Refactor me, use factories

  describe "fetching component_spec" do
    test "succeeds by id" do
      cs = Factory.insert(:component_spec)

      assert {:ok, found} = ComponentSpecController.find(cs.spec_id)
      assert cs.spec_id == found.spec_id
    end

    test "fails when spec doesn't exists" do
      cs = Factory.build(:component_spec)
      assert {:error, :notfound} == ComponentSpecController.find(cs.spec_id)
    end
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
