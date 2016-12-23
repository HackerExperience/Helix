defmodule Helix.Hardware.Controller.HardwareService do

  use GenServer

  alias HELF.Broker
  alias Helix.Hardware.Controller.Motherboard, as: CtrlMobos
  alias Helix.Hardware.Controller.MotherboardSlot, as: CtrlMoboSlots
  alias Helix.Hardware.Controller.Component, as: CtrlComps
  alias Helix.Hardware.Controller.ComponentSpec, as: CtrlCompSpec
  alias Helix.Hardware.Repo

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

  def handle_call({:setup, server_id, request}, _from, state) do
    response =
      Repo.transaction(fn ->
        motherboard = motherboard_create("MOBO01", request)
        slots = CtrlMoboSlots.find_by(motherboard_id: motherboard.motherboard_id)
        [
          {"cpu", "CPU01"},
          {"ram", "RAM01"},
          {"hdd", "HDD01"},
          {"usb", "USB01"},
          {"nic", "NIC01"}]
        |> Enum.map(fn {component_type, spec_code} ->
            create_component(component_type, spec_code, request)
          end)
        |> link_all(slots)
        motherboard
      end)

    case response do
      {:ok, motherboard} ->
        Broker.cast("event:motherboard:setup", {motherboard.motherboard_id, server_id}, request: request)
        {:reply, {:ok, motherboard}, state}
      error ->
        {:reply, error, state}
    end
  end

  @spec motherboard_create(PK.t, HeBroker.Request.t) :: Motherboard.t
  defp motherboard_create(spec_id, request) do
    component = create_component("mobo", spec_id, request)
    params = %{motherboard_id: component.component_id}

    case CtrlMobos.create(params) do
      {:ok, motherboard} ->
        Broker.cast("event:motherboard:created", motherboard.motherboard_id, request: request)
        motherboard
      {:error, error} ->
        Repo.rollback(error)
    end
  end

  @spec create_component(String.t, PK.t, HeBroker.Request.t) :: Component.t
  defp create_component(component_type, spec_id, request) do
    params = %{
      component_type: component_type,
      spec_id: spec_id
    }

    case CtrlComps.create(params) do
      {:ok, component} ->
        Broker.cast("event:component:created", component.component_id, request: request)
        component
      {:error, error} ->
        Repo.rollback(error)
    end
  end

  defp link_all(components, slot_list) do
    # FIXME: refactor this method
    slots =
      slot_list
      |> Enum.map(fn slot -> {slot.link_component_type, slot} end)
      |> Map.new()

    Enum.each(components, fn component ->
      slot = slots[component.component_type]
      case CtrlMoboSlots.link(slot.slot_id, component.component_id) do
        {:ok, _} ->
          Broker.cast("event:component:linked", {component.component_id, slot.slot_id})
        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end
end