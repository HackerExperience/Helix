defmodule Helix.Hardware.Controller.HardwareService do

  use GenServer

  alias HELF.Broker
  alias Helix.Hardware.Controller.Motherboard, as: CtrlMobos
  alias Helix.Hardware.Controller.MotherboardSlot, as: CtrlMoboSlots
  alias Helix.Hardware.Controller.Component, as: CtrlComps
  alias Helix.Hardware.Controller.ComponentSpec, as: CtrlCompSpec
  # FIXME
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.Component, as: ComponentController

  @typep state :: nil

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :hardware)
  end

  @doc false
  def handle_broker_call(pid, "hardware:get", {subject, id}, _request) when is_atom(subject) do
    response = GenServer.call(pid, {subject, :get, id})
    {:reply, response}
  end

  def handle_broker_call(pid, "hardware:get", all_of_kind, _request) when is_atom(all_of_kind) do
    response = GenServer.call(pid, {all_of_kind, :get})
    {:reply, response}
  end

  def handle_broker_call(pid, "hardware:motherboard:create", params, _request) do
    response = GenServer.call(pid, {:motherboard, :create, params})
    {:reply, response}
  end

  def handle_broker_call(pid, "event:server:created", {server_id, _entity_id}, request) do
    GenServer.call(pid, {:setup, server_id, request})
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_args) do
    Broker.subscribe("hardware:get", call: &handle_broker_call/4)
    Broker.subscribe("hardware:motherboard:create", call: &handle_broker_call/4)
    Broker.subscribe("event:server:created", cast: &handle_broker_call/4)

    {:ok, nil}
  end

  @spec handle_call(
    {:motherboard, :create, any},
    GenServer.from,
    state) :: {:reply, {:ok, HELL.PK.t}
              | error :: term, state}
  @spec handle_call(
    {:motherboard, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Helix.Hardware.Model.Motherboard.t}
              | {:error, :notfound}, state}
  @spec handle_call(
    {:motherboard_slot, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Helix.Hardware.Model.MotherboardSlot.t}
              | {:error, :notfound}, state}
  @spec handle_call(
    {:component, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Helix.Hardware.Model.Component.t}
              | {:error, :notfound}, state}
  @spec handle_call(
    {:component_spec, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Helix.Hardware.Model.ComponentSpec.t}
              | {:error, :notfound}, state}
  @spec handle_call(
    {:setup, PK.t, HeBroker.Request.t},
    GenServer.from,
    state) :: {:reply, {:ok | :error}, state}
  @doc false
  def handle_call({:motherboard, :create, params}, _from, state) do
    with {:ok, mobo} <- CtrlMobos.create(params) do
      Broker.cast("hardware:motherboard:created", mobo.motherboard_id)
      {:reply, {:ok, mobo.motherboard_id}, state}
    else
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:motherboard, :get, id}, _from, state) do
    response = CtrlMobos.find(id)
    {:reply, response, state}
  end

  def handle_call({:motherboard_slot, :get, id}, _from, state) do
    response = CtrlMoboSlots.find(id)
    {:reply, response, state}
  end

  def handle_call({:component, :get, id}, _from, state) do
    response = CtrlComps.find(id)
    {:reply, response, state}
  end

  def handle_call({:component_spec, :get, id}, _from, state) do
    response = CtrlCompSpec.find(id)
    {:reply, response, state}
  end

  def handle_call({:setup, _server_id, _request}, _from, state) do
    response =
      Repo.transaction(fn ->
        # FIXME: remove hardcoded spec_id, it will just work here, also
        # I don't think this code is what we intented it to be.
        motherboard = motherboard_create("3::8FFF:8953:270F:EF66:5366")
        slots = MotherboardSlotController.find_by(motherboard_id: motherboard.motherboard_id)

        cpu = cpu_create("3::EFBC:2E32:6B01:456C:EB6D")
        ram = ram_create("3::EDD5:B4B8:F5F6:3784:9A12")
        hdd = hdd_create("3::A8CC:8D15:B5B2:A50A:EC2D")
        usb = usb_create("3::B144:36D7:4C43:6CB1:38A5")
        nic = nic_create("3::2858:4E6:593F:24F5:1FCB")

        link_all(slots, [cpu, ram, hdd, usb, nic])
        motherboard
      end)

    case response do
      {:ok, motherboard} ->
        Broker.cast("event:motherboard:created", motherboard.motherboard_id)
        {:reply, {:ok, motherboard}, state}
      error ->
        {:reply, error, state}
    end
  end

  @spec motherboard_create(PK.t) :: Motherboard.t
  defp motherboard_create(spec_id) do
    component = create_component("mobo", spec_id)
    params = %{motherboard_id: component.component_id}

    case MotherboardController.create(params) do
      {:ok, motherboard} ->
        motherboard
      {:error, error} ->
        Repo.rollback(error)
    end
  end

  @spec cpu_create(PK.T) :: Component.t
  defp cpu_create(spec_id),
    do: create_component("cpu", spec_id)

  @spec ram_create(PK.T) :: Component.t
  defp ram_create(spec_id),
    do: create_component("ram", spec_id)

  @spec hdd_create(PK.T) :: Component.t
  defp hdd_create(spec_id),
    do: create_component("hdd", spec_id)

  @spec usb_create(PK.T) :: Component.t
  defp usb_create(spec_id),
    do: create_component("usb", spec_id)

  @spec nic_create(PK.T) :: Component.t
  defp nic_create(spec_id),
    do: create_component("nic", spec_id)

  @spec create_component(String.t, PK.t) :: Component.t
  defp create_component(component_type, spec_id) do
    params = %{
      component_type: component_type,
      spec_id: spec_id
    }

    case ComponentController.create(params) do
      {:ok, component} ->
        Broker.cast("event:component:created", component.component_id)
        component
      {:error, error} ->
        Repo.rollback(error)
    end
  end

  defp link_all(slot_list, components) do
    # FIXME: maybe there's a better way for doing that
    slots =
      slot_list
      |> Enum.map(fn slot -> {slot.link_component_type, slot} end)
      |> Map.new()

    Enum.each(components, fn component ->
      slot = slots[component.component_type]
      case MotherboardSlotController.link(slot.slot_id, component.component_id) do
        {:ok, _} ->
          Broker.cast("event:component:linked", {component.component_id, slot.slot_id})
        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end
end