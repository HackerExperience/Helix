defmodule Helix.Hardware.Service.API.ComponentTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Service.API.Component, as: API
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  describe "create_from_spec/1" do
    defp random_spec do
      Enum.random([:cpu_spec, :hdd_spec, :nic_spec, :ram_spec])
    end

    test "succeeds with valid input" do
      spec = Factory.insert(random_spec())
      assert {:ok, %Component{}} = API.create_from_spec(spec)
    end

    test "returns changeset when input is invalid" do
      bogus_spec = Factory.build(random_spec())
      assert {:error, %Ecto.Changeset{}} = API.create_from_spec(bogus_spec)
    end
  end

  describe "fetch/1" do
    test "succeeds by id" do
      component = Factory.insert(:component)
      assert %Component{} = API.fetch(component.component_id)
    end

    test "fails with inexistent id" do
      refute API.fetch(Random.pk())
    end
  end

  describe "find/2" do
    test "succeeds by id list" do
      components =
        3
        |> Factory.insert_list(:component)
        |> Enum.map(&(&1.component_id))
        |> Enum.sort()

      found =
        [id: components]
        |> API.find()
        |> Enum.map(&(&1.component_id))
        |> Enum.sort()

      assert components == found
    end

    test "succeeds by type" do
      type = Enum.random([:cpu, :hdd, :nic, :ram])
      components = Factory.insert_list(4, type)

      found = API.find(type: type)
      found_ids = Enum.map(found, &(&1.component_id))

      assert Enum.all?(components, &(&1.component.component_id in found_ids))
    end

    test "succeeds by type list" do
      components = Factory.insert_list(4, :component)
      types =
        components
        |> Enum.map(&(&1.component_type))
        |> Enum.uniq()

      found = API.find(type: types)
      found_ids = Enum.map(found, &(&1.component_id))

      assert Enum.all?(components, &(&1.component_id in found_ids))
    end
  end

  describe "delete/1" do
    test "succeeds by struct" do
      component = Factory.insert(:component)

      assert Repo.get(Component, component.component_id)
      API.delete(component)

      refute Repo.get(Component, component.component_id)
    end

    test "succeeds by id" do
      component = Factory.insert(:component)

      assert Repo.get(Component, component.component_id)
      API.delete(component.component_id)

      refute Repo.get(Component, component.component_id)
    end

    test "is idempotent" do
      component = Factory.insert(:component)

      assert Repo.get(Component, component.component_id)
      API.delete(component.component_id)
      API.delete(component.component_id)

      refute Repo.get(Component, component.component_id)
    end
  end
end
