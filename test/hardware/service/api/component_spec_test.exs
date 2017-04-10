defmodule Helix.Hardware.Service.API.ComponentSpecTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Service.API.ComponentSpec, as: API
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

      assert {:ok, %ComponentSpec{}} = API.create(spec_map)
    end

    test "fails when input is invalid" do
      params = %{}

      assert {:error, cs} = API.create(params)
      refute cs.valid?

      spec_map = %{
        spec_code: "invalid",
        spec_type: "INVALID",
        name: "non invalid, but whatever"
      }

      assert {:error, cs} = API.create(spec_map)
      refute cs.valid?
    end
  end

  describe "fetch/1" do
    test "succeeds by id" do
      cs = Factory.insert(:component_spec)
      assert %ComponentSpec{} = API.fetch(cs.spec_id)
    end

    test "fails when it doesn't exist'" do
      refute API.fetch(Random.pk())
    end
  end

  test "find/2 succeeds by type list" do
    type = Factory.random_component_type()
    specs = Factory.insert_list(4, :component_spec, component_type: type)

    found = API.find(type: type)
    found_ids = Enum.map(found, &(&1.spec_id))

    assert Enum.all?(specs, &(&1.spec_id in found_ids))
  end

  describe "delete/1" do
    test "succeeds by struct" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)

      API.delete(cs)

      refute Repo.get(ComponentSpec, cs.spec_id)
    end

    test "succeeds by id" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)

      API.delete(cs.spec_id)

      refute Repo.get(ComponentSpec, cs.spec_id)
    end

    test "is idempotent" do
      cs = Factory.insert(:component_spec)

      assert Repo.get(ComponentSpec, cs.spec_id)

      API.delete(cs.spec_id)
      API.delete(cs.spec_id)

      refute Repo.get(ComponentSpec, cs.spec_id)
    end
  end
end
