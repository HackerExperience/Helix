defmodule Helix.Hardware.Action.ComponentSpecTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Action.ComponentSpec, as: ComponentSpecAction
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  describe "create/1" do
    test "succeeds with valid input" do
      cpu_num = Random.digits(min: 10)

      spec_map = %{
        "spec_code" => "CPU" <> cpu_num,
        "spec_type" => "CPU",
        "name" => "Sample CPU " <> cpu_num,
        "clock" => 3000,
        "cores" => 7
      }

      assert {:ok, %ComponentSpec{}} = ComponentSpecAction.create(spec_map)
    end

    test "fails when input is invalid" do
      params = %{}

      assert {:error, cs} = ComponentSpecAction.create(params)
      refute cs.valid?

      spec_map = %{
        spec_code: "invalid",
        spec_type: "INVALID",
        name: "non invalid, but whatever"
      }

      assert {:error, cs} = ComponentSpecAction.create(spec_map)
      refute cs.valid?
    end
  end

  describe "delete/1" do
    test "succeeds by struct" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)

      ComponentSpecAction.delete(cs)

      refute Repo.get(ComponentSpec, cs.spec_id)
    end

    test "succeeds by id" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)

      ComponentSpecAction.delete(cs.spec_id)

      refute Repo.get(ComponentSpec, cs.spec_id)
    end

    test "is idempotent" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)

      ComponentSpecAction.delete(cs.spec_id)
      ComponentSpecAction.delete(cs.spec_id)

      refute Repo.get(ComponentSpec, cs.spec_id)
    end
  end
end
