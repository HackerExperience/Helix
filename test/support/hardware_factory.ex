defmodule Helix.Hardware.Factory do

  use ExMachina.Ecto, repo: Helix.Hardware.Repo

  alias HELL.MacAddress
  alias HELL.TestHelper.Random
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Component.CPU
  alias Helix.Hardware.Model.Component.HDD
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Model.Component.RAM
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot

  alias HELL.TestHelper.Random

  def random_component_type,
    do: Enum.random(ComponentType.possible_types())

  def motherboard_slot_factory do
    motherboard = build(:motherboard, slots: [])
    {id, slot} = Enum.random(motherboard.component.component_spec.spec.slots)

    component_type =
      slot.type
      |> String.downcase()
      |> String.to_existing_atom()

    %MotherboardSlot{
      motherboard: motherboard,
      slot_internal_id: String.to_integer(id),
      link_component_type: component_type
    }
  end

  def motherboard_factory do
    component = prepare(:component, component_type: :mobo)
    specs = component.component_spec.spec.slots

    motherboard_slots =
      Enum.map(specs, fn {id, spec} ->
        component_type =
          spec.type
          |> String.downcase()
          |> String.to_existing_atom()

        %MotherboardSlot{
          slot_internal_id: String.to_integer(id),
          link_component_type: component_type
        }
      end)

    %Motherboard{
      component: component,
      slots: motherboard_slots
    }
  end

  def cpu_factory do
    component = prepare(:component, component_type: :cpu)

    %CPU{
      component: component,
      clock: component.component_spec.spec.clock,
      cores: component.component_spec.spec.cores,
    }
  end

  def ram_factory do
    component = prepare(:component, component_type: :ram)

    %RAM{
      component: component,
      ram_size: component.component_spec.spec.ram_size,
    }
  end

  def hdd_factory do
    component = prepare(:component, component_type: :hdd)

    %HDD{
      component: component,
      hdd_size: component.component_spec.spec.hdd_size,
    }
  end

  def nic_factory do
    component = prepare(:component, component_type: :nic)

    %NIC{
      component: component,
      mac_address: MacAddress.generate()
    }
  end

  def component_factory,
    do: prepare(:component)

  def component_spec_factory,
    do: prepare(:component_spec)

  def mobo_spec_factory,
    do: prepare(:component_spec, component_type: :mobo)

  def cpu_spec_factory,
    do: prepare(:component_spec, component_type: :cpu)

  def ram_spec_factory,
    do: prepare(:component_spec, component_type: :ram)

  def hdd_spec_factory,
    do: prepare(:component_spec, component_type: :hdd)

  def nic_spec_factory,
    do: prepare(:component_spec, component_type: :nic)

  defp prepare(thing, params \\ [])

  defp prepare(:component, params) do
    spec = Keyword.get(
      params,
      :component_spec,
      prepare(:component_spec, params))

    component_id = Random.pk()

    %Component{
      component_id: component_id,
      component_type: spec.component_type,
      component_spec: spec
    }
  end

  defp prepare(:component_spec, params) do
    spec_type = Keyword.get(params, :component_type, random_component_type())
    spec = Keyword.get(params, :spec, spec_struct_for(spec_type))

    %ComponentSpec{
      spec_id: spec.spec_code,
      component_type: spec_type,
      spec: spec
    }
  end

  defp spec_struct_for(component_type) do
    base = %{
      spec_type: spec_type(component_type),
      spec_code: String.upcase(Random.string(min: 12)),
      name: Random.string(min: 12)
    }

    generate_mobo_slots = fn ->
      %{
        "0" => %{type: "CPU"},
        "1" => %{type: "HDD", limit: 2000},
        "2" => %{type: "HDD", limit: 2000},
        "3" => %{type: "RAM", limit: 4096},
        "4" => %{type: "RAM", limit: 4096},
        "5" => %{type: "NIC", limit: 1000},
        "6" => %{type: "NIC", limit: 1000}
      }
    end

    specialization =
      case component_type do
        :mobo ->
          %{display: "xml-esque description", slots: generate_mobo_slots.()}
        :cpu ->
          %{clock: Random.number(66..3200), cores: Random.number(1..4)}
        :ram ->
          %{clock: Random.number(66..3200), ram_size: Random.number(256..8192)}
        :hdd ->
          %{hdd_size: Random.number(256..8192)}
        :nic ->
          %{link: Random.number(1024..2048)}
      end

    Map.merge(base, specialization)
  end

  defp spec_type(:cpu),
    do: "CPU"
  defp spec_type(:hdd),
    do: "HDD"
  defp spec_type(:ram),
    do: "RAM"
  defp spec_type(:nic),
    do: "NIC"
  defp spec_type(:mobo),
    do: "MOBO"
end
