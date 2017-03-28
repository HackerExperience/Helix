defmodule Helix.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  describe "fetching" do
    # REVIEW: Refactor me, use fetch instead of find

    test "succeeds by id" do
      cs = Factory.insert(:component_spec)
      assert {:ok, _} = ComponentSpecController.find(cs.spec_id)
    end

    test "fails when spec doesn't exists" do
      bogus = Factory.build(:component_spec)
      assert {:error, :notfound} == ComponentSpecController.find(bogus.spec_id)
    end
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
