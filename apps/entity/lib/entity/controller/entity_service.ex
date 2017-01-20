defmodule Helix.Controller.EntityService do

  use GenServer

  alias HELF.Broker
  alias HELL.PK
  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Controller.EntityComponent, as: EntityComponentController
  alias Helix.Entity.Controller.EntityServer, as: EntityServerController
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Repo

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
    # FIXME: should subscribe to event:component:created instead
    Broker.subscribe("event:motherboard:setup", cast: &handle_broker_cast/4)
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

  # FIXME: should subscribe to event:component:created instead
  def handle_broker_cast(pid, "event:motherboard:setup", msg, _req) do
    server_id = msg.server_id
    components = msg.components
    GenServer.cast(pid, {:entity, :add, :components, server_id, components})
  end

  @spec handle_call(
    {:entity, :create, Entity.creation_params, HeBroker.Request.t},
    GenServer.from,
    state) :: {:reply, {:ok, Entity.t} | {:error, Ecto.Changeset.t}, state}
  @spec handle_call(
    {:entity, :find, PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Entity.t} | {:error, :notfound}, state}
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

  @spec handle_cast(
    {:server, :created, {PK.t, PK.t}, HeBroker.Request.t},
    state) :: {:noreply, state}
  def handle_cast({:server, :created, server_id, entity_id}, state) do
    EntityServerController.create(entity_id, server_id)
    {:noreply, state}
  end

  # FIXME: receiving entity_id looks more correct than server_id
  @spec handle_cast(
    {:entity, :add, :components, PK.t, [PK.t]}, state) :: {:noreply, state}
  def handle_cast({:entity, :add, :components, server_id, components}, state) do
    entity = EntityServerController.get_entity(server_id)
    Repo.transaction(fn ->
      Enum.each(components, fn component_id ->
        case EntityComponentController.create(entity.entity_id, component_id) do
          {:ok, _} ->
            :ok
          {:error, _} ->
            Repo.rollback(:internal_error)
        end
      end)
    end)

    {:noreply, state}
  end
end