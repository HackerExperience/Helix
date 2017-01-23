defmodule Helix.Controller.EntityService do

  use GenServer

  alias HELF.Broker
  alias HELL.PK
  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Controller.EntityComponent, as: EntityComponentController
  alias Helix.Entity.Controller.EntityServer, as: EntityServerController
  alias Helix.Entity.Model.Entity

  @typep state :: nil

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :entity_service)
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_args) do
    Broker.subscribe("entity:create", call: &handle_broker_call/4)
    Broker.subscribe("entity:find", call: &handle_broker_call/4)
    Broker.subscribe("event:server:created", cast: &handle_broker_cast/4)
    Broker.subscribe("event:component:created", cast: &handle_broker_cast/4)
    {:ok, nil}
  end

  @doc false
  def handle_broker_call(pid, "entity:find", entity_id, _req) do
    response = GenServer.call(pid, {:entity, :find, entity_id})
    {:reply, response}
  end
  def handle_broker_call(pid, "entity:create", entity_type, req) do
    params = %{entity_type: entity_type}
    response = GenServer.call(pid, {:entity, :create, params, req})
    {:reply, response}
  end

  @doc false
  def handle_broker_cast(pid, "event:server:created", {server_id, entity_id}, _req) do
    GenServer.cast(pid, {:server, :created, server_id, entity_id})
  end

  def handle_broker_cast(pid, "event:component:created", msg, _req) do
    entity_id = msg.entity_id
    component_id = msg.component_id
    GenServer.call(pid, {:entity, :component, :add, entity_id, component_id})
  end

  @spec handle_call(
    {:entity, :create, Entity.creation_params, HeBroker.Request.t},
    GenServer.from,
    state) :: {:reply, {:ok, Entity.t} | {:error, Ecto.Changeset.t}, state}
  @spec handle_call(
    {:entity, :find, PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Entity.t} | {:error, :notfound}, state}
  @spec handle_call(
    {:entity, :component, :add, Entity.id, PK.t},
    GenServer.from,
    state) :: {:reply, :ok | {:error, :internal}, state}
  @doc false
  def handle_call({:entity, :create, params, request}, _from, state) do
    case EntityController.create(params) do
      {:ok, entity} ->
        Broker.cast("event:entity:created", entity.entity_id, request: request)
        {:reply, {:ok, entity}, state}
      error ->
        {:reply, error, state}
    end
  end
  def handle_call({:entity, :find, id}, _from, state) do
    response = EntityController.find(id)
    {:reply, response, state}
  end
  def handle_call({:entity, :component, :add, entity_id, comp_id}, _, state) do
    case EntityComponentController.create(entity_id, comp_id) do
      {:ok, _} ->
        {:reply, :ok, state}
      {:error, _} ->
        {:reply, {:error, :internal}, state}
    end
  end

  @spec handle_cast(
    {:server, :created, {PK.t, PK.t}, HeBroker.Request.t},
    state) :: {:noreply, state}
  def handle_cast({:server, :created, server_id, entity_id}, state) do
    EntityServerController.create(entity_id, server_id)
    {:noreply, state}
  end
end