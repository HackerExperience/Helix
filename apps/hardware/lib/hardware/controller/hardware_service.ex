defmodule HELM.Hardware.Controller.HardwareService do

  use GenServer

  alias HELF.Broker
  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobos
  alias HELM.Hardware.Controller.MotherboardSlot, as: CtrlMoboSlots
  alias HELM.Hardware.Controller.Component, as: CtrlComps
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec

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

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_args) do
    Broker.subscribe("hardware:get", call: &handle_broker_call/4)
    Broker.subscribe("hardware:motherboard:create", call: &handle_broker_call/4)

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
    state) :: {:reply, {:ok, HELM.Hardware.Model.Motherboard.t}
              | {:error, :notfound}, state}
  @spec handle_call(
    {:motherboard_slot, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, HELM.Hardware.Model.MotherboardSlot.t}
              | {:error, :notfound}, state}
  @spec handle_call(
    {:component, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, HELM.Hardware.Model.Component.t}
              | {:error, :notfound}, state}
  @spec handle_call(
    {:component_spec, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, HELM.Hardware.Model.ComponentSpec.t}
              | {:error, :notfound}, state}
  @doc false
  def handle_call({:motherboard, :create, _params}, _from, state) do
    with {:ok, mobo} <- CtrlMobos.create() do
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
end