defmodule Helix.Hardware.Controller.HardwareService do

  use GenServer

  alias HELF.Broker
  alias Helix.Hardware.Controller.Motherboard, as: CtrlMobos
  alias Helix.Hardware.Controller.MotherboardSlot, as: CtrlMoboSlots
  alias Helix.Hardware.Controller.Component, as: CtrlComps
  alias Helix.Hardware.Controller.ComponentSpec, as: CtrlCompSpec
  alias Helix.Hardware.Model.MotherboardSlot, as: MotherboardSlot
  alias Helix.Hardware.Model.Component, as: Component
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
    {:ok, motherboard} =
      Repo.transaction(fn ->
        with \
          {:ok, motherboard} <- create_motherboard("MOBO01", request),
          # FIXME: remove hardcoded components
          components = [
            {"cpu", "CPU01"},
            {"ram", "RAM01"},
            {"hdd", "HDD01"},
            {"nic", "NIC01"}],
          :ok <- setup_motherboard(motherboard, components, request)
        do
          motherboard
        else
          {:error, _} ->
            Repo.rollback(:internal_error)
        end
      end)

    msg = %{
      motherboard_id: motherboard.motherboard_id,
      server_id: server_id}
    Broker.cast("event:motherboard:setup", msg, request: request)

    {:reply, {:ok, motherboard}, state}
  end

  @spec create_motherboard(PK.t, HeBroker.Request.t) :: Motherboard.t
  defp create_motherboard(spec_id, request) do
    case create_component("mobo", spec_id, request) do
      {:ok, component} ->
        params = %{motherboard_id: component.component_id}

        case CtrlMobos.create(params) do
          {:ok, motherboard} ->
            msg = %{motherboard_id: motherboard.motherboard_id}
            Broker.cast("event:motherboard:created", msg, request: request)

            {:ok, motherboard}
          {:error, error} ->
            {:error, error}
        end
      {:error, error} ->
        {:error, error}
    end
  end

  @spec setup_motherboard(
    PK.t,
    [{component_type :: String.t, spec_id :: String.t}],
    HeBroker.Request.t) :: :ok | {:error, Ecto.Changeset.t}
  defp setup_motherboard(motherboard, components, request) do
    slots = slots_map(motherboard.motherboard_id)

    components
    |> Enum.reduce_while(slots, fn {component_type, spec_id}, slots ->
      with \
        {:ok, comp} <- create_component(component_type, spec_id, request),
        [slot | remaining_slots] = Map.fetch!(slots, component_type),
        {:ok, _} <- CtrlMoboSlots.link(slot.slot_id, comp.component_id)
      do
        slots = Map.put(slots, component_type, remaining_slots)
        {:cont, slots}
      else
        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
    |> case do
      {:error, error} ->
        {:error, error}
      _ ->
        :ok
    end
  end

  @spec create_component(String.t, PK.t, HeBroker.Request.t) :: Component.t
  defp create_component(component_type, spec_id, request) do
    params = %{
      component_type: component_type,
      spec_id: spec_id}

    case CtrlComps.create(params) do
      {:ok, component} ->
        msg = %{component_id: component.component_id}
        Broker.cast("event:component:created", msg, request: request)

        {:ok, component}
      {:error, error} ->
        {:error, error}
    end
  end

  @spec slots_map(PK.t) :: %{optional(String.t) => MotherboardSlot.t}
  defp slots_map(motherboard_id) do
    slots = CtrlMoboSlots.find_by(motherboard_id: motherboard_id)
    Enum.reduce(slots, %{}, fn slot, acc ->
      list =
        acc
        |> Map.get(slot.link_component_type, [])
        |> (fn slots -> [slot | slots] end).()

      Map.put(acc, slot.link_component_type, list)
    end)
  end
end