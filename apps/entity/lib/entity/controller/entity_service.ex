defmodule HELM.Controller.EntityService do

  use GenServer

  alias HELF.Broker
  alias HELM.Entity.Controller.Entity, as: EntityController

  @typep state :: nil

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :entity_service)
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_args) do
    Broker.subscribe("event:entity:create", cast: &handle_broker_cast/4)
    Broker.subscribe("entity:find", call: &handle_broker_call/4)
    {:ok, nil}
  end

  @doc false
  def handle_broker_call(pid, "entity:find", entity_id, req) do
    GenServer.cast(pid, {:entity, :find, entity_id, req})
  end

  @doc false
  def handle_broker_cast(pid, "event:entity:create", {:account, ref}, req) do
    GenServer.cast(pid, {:entity, :create, :account, ref, req})
  end

  @spec handle_call(
    {:entity, :find, PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Entity.t} | {:error, :notfound}, state}
  @doc false
  def handle_call({:entity, :find, id}, _from, state) do
    response = EntityController.find(id)
    {:reply, response, state}
  end


  @spec handle_cast(
    {:entity, :create, :account, HeBroker.Request.t},
    state) :: {:noreply, state}
  def handle_cast({:entity, :create, :account, ref, request}, state) do
    case EntityController.create(%{entity_type: "account"}) do
      {:ok, entity} ->
        Broker.cast("event:entity:created", {:account, ref, entity.entity_id}, request: request)
      _ ->
        nil
    end

    {:noreply, state}
  end
end