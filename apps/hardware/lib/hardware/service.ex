defmodule HELM.Hardware.Service do
  use GenServer

  alias HELM.Hardware, warn: false
  alias HELF.Broker

  alias HELM.Hardware.Motherboard.Controller, as: MoboCtrl
  alias HELM.Hardware.Motherboard.Slot.Controller, as: MoboSlotCtrl
  alias HELM.Hardware.Component.Controller, as: CompCtrl
  alias HELM.Hardware.Component.Spec.Controller, as: CompSpecCtrl
  alias HELM.Hardware.Component.Type.Controller, as: CompTypeCtrl

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :hardware)
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

  def init(_args) do
    Broker.subscribe("hardware:get", call: &handle_broker_call/4)
    Broker.subscribe("hardware:motherboard:create", call: &handle_broker_call/4)

    {:ok, nil}
  end

  def handle_call({:motherboard, :create, _params}, _from, state) do
    case MoboCtrl.create() do
      {:ok, mobo} -> {:reply, {:ok, mobo.motherboard_id}, state}
      {:error, _} -> {:reply, :error, state}
    end
  end

  def handle_call({:motherboard, :get, id}, _from, state) do
    response = MoboCtrl.find(id)
    {:reply, response, state}
  end

  def handle_call({:motherboard_slot, :get, id}, _from, state) do
    response = MoboSlotCtrl.find(id)
    {:reply, response, state}
  end

  def handle_call({:component, :get, id}, _from, state) do
    response = CompCtrl.find(id)
    {:reply, response, state}
  end

  def handle_call({:component_spec, :get, id}, _from, state) do
    response = CompSpecCtrl.find(id)
    {:reply, response, state}
  end

  def handle_call({:component_types, :get}, _from, state) do
    response = CompTypeCtrl.all()
    {:reply, response, state}
  end
end
