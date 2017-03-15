defmodule Helix.Hardware.Factory do

  use ExMachina.Ecto, repo: Helix.Hardware.Repo

  alias HELL.MacAddress
  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Component.CPU
  alias Helix.Hardware.Model.Component.HDD
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Model.Component.RAM
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot

  def component_of_type(component_type) do
    radical =
      case component_type do
        "cpu" ->
          insert(:cpu)
        "hdd" ->
          insert(:hdd)
        "nic" ->
          insert(:nic)
        "ram" ->
          insert(:ram)
      end

    radical.component
  end

  def motherboard_factory do
    motherboard = prepare_motherboard()
    slots_spec = motherboard.component.component_spec.spec["slots"]

    slots =
      Enum.map(slots_spec, fn {id, spec} ->
        %MotherboardSlot{
          slot_internal_id: String.to_integer(id),
          link_component_type: String.downcase(spec["type"])
        }
      end)

    %Motherboard{motherboard | slots: slots}
  end

  def cpu_factory do
    id = PK.pk_for(CPU)

    component = %Component{
      component_id: id,
      component_type: "cpu",
      component_spec: build(:cpu_spec)
    }

    %CPU{
      cpu_id: id,
      component: component,
      clock: component.component_spec.spec["clock"],
      cores: component.component_spec.spec["cores"]
    }
  end

  def hdd_factory do
    id = PK.pk_for(CPU)
    component = %Component{
      component_id: id,
      component_type: "hdd",
      component_spec: build(:hdd_spec)
    }

    %HDD{
      hdd_id: id,
      component: component,
      hdd_size: component.component_spec.spec["hdd_size"]
    }
  end

  def nic_factory do
    id = PK.pk_for(CPU)
    component = %Component{
      component_id: id,
      component_type: "nic",
      component_spec: build(:nic_spec)
    }

    %NIC{
      nic_id: id,
      component: component,
      mac_address: MacAddress.generate()
    }
  end

  def ram_factory do
    id = PK.pk_for(CPU)
    component = %Component{
      component_id: id,
      component_type: "ram",
      component_spec: build(:ram_spec)
    }

    %RAM{
      ram_id: id,
      component: component,
      ram_id: component.component_id,
      ram_size: component.component_spec.spec["ram_size"]
    }
  end

  def motherboard_slot_factory do
    mobo = prepare_motherboard()
    {slot_id, spec} = Enum.random(mobo.component.component_spec.spec["slots"])

    %MotherboardSlot{
      motherboard: mobo,
      motherboard_id: mobo.motherboard_id,
      slot_internal_id: String.to_integer(slot_id),
      link_component_type: String.downcase(spec["type"])
    }
  end

  def component_factory do
    type = random_component_type()

    %Component{
      component_id: PK.pk_for(Enum.random([Motherboard, CPU, RAM, NIC, HDD])),
      component_type: type,
      component_spec: build(:component_spec)
    }
  end

  def component_spec_factory do
    case random_component_type() do
      "cpu" ->
        cpu_spec_factory()
      "hdd" ->
        hdd_spec_factory()
      "nic" ->
        nic_spec_factory()
      "ram" ->
        ram_spec_factory()
    end
  end

  def mobo_spec_factory do
    component_slots =
      ["CPU", "RAM", "HDD", "NIC"]
      |> List.duplicate(3)
      |> Enum.flat_map(&(&1))
      |> Enum.with_index()

    slots = for {component, index} <- component_slots, into: %{} do
      {to_string(index), %{"type" => component}}
    end

    spec = %{
      "spec_code" => String.upcase(Random.string(min: 12)),
      "spec_type" => "MOBO",
      "name" => Random.string(),
      "slots" => slots
    }

    %ComponentSpec{
      spec_id: spec["spec_code"],
      component_type: "mobo",
      spec: spec
    }
  end

  def cpu_spec_factory do
    spec = %{
      "spec_code" => String.upcase(Random.string(min: 12)),
      "spec_type" => "CPU",
      "name" => "",
      "clock" => Random.number(1000..3200),
      "cores" => Random.number(1..7)
    }

    %ComponentSpec{
      spec_id: spec["spec_code"],
      component_type: "cpu",
      spec: spec
    }
  end

  def hdd_spec_factory do
    spec = %{
      "spec_code" => String.upcase(Random.string(min: 12)),
      "spec_type" => "HDD",
      "name" => "",
      "hdd_size" => Random.number(1024..10024)
    }

    %ComponentSpec{
      spec_id: spec["spec_code"],
      component_type: "hdd",
      spec: spec
    }
  end

  def nic_spec_factory do
    spec = %{
      "spec_code" => String.upcase(Random.string(min: 12)),
      "spec_type" => "NIC",
      "name" => "",
      "link" => Random.number(1000..10000)
    }

    %ComponentSpec{
      spec_id: spec["spec_code"],
      component_type: "nic",
      spec: spec
    }
  end

  def ram_spec_factory do
    spec = %{
      "spec_code" => random_spec_code(),
      "spec_type" => "RAM",
      "name" => "",
      "clock" => Random.number(1600..1866),
      "ram_size" => Random.number(1048..16768)
    }

    %ComponentSpec{
      spec_id: spec["spec_code"],
      component_type: "nic",
      spec: spec
    }
  end

  defp random_component_type,
    do: Enum.random(["cpu", "hdd", "nic", "ram"])

  defp random_spec_code,
    do: String.upcase(Random.string(min: 12))

  defp prepare_motherboard do
    pk = PK.pk_for(Motherboard)

    component = %Component{
      component_id: pk,
      component_type: "mobo",
      component_spec: build(:mobo_spec)
    }

    %Motherboard{
      motherboard_id: pk,
      component: component
    }
  end
end
