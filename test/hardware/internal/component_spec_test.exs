defmodule Helix.Hardware.Internal.ComponentSpecTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.ComponentSpec, as: ComponentSpecInternal
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  describe "fetching" do
    test "succeeds by id" do
      cs = Factory.insert(:component_spec)
      assert %ComponentSpec{} = ComponentSpecInternal.fetch(cs.spec_id)
    end

    test "fails when spec doesn't exists" do
      refute ComponentSpecInternal.fetch("foobarbaz")
    end
  end

  describe "deleting" do
    @tag :pending
    test "is idempotent" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)
      ComponentSpecInternal.delete(cs)
      ComponentSpecInternal.delete(cs)
      refute Repo.get(ComponentSpec, cs.spec_id)
    end
  end
end
