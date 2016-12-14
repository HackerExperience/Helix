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
    Broker.subscribe("entity:create", cast: &handle_broker_call/4)
    Broker.subscribe("entity:find", call: &handle_broker_call/4)
    {:ok, nil}
  end

  @doc false
  def handle_broker_call(pid, "entity:create", :account, req) do
    GenServer.call(pid, {:entity, :create, :account, req})
  end

  @spec handle_call(
    {:entity, :create, :account, HeBroker.Request.t},
    GenServer.from,
    state) :: {:reply, {:ok, Entity.t} | {:error, Ecto.Changeset.t}, state}
  @spec handle_call(
    {:entity, :find, PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Entity.t} | {:error, :notfound}, state}
  @doc false
  def handle_call({:entity, :create, :account, request}, _from, state) do
    %{entity_type: "account"}
    |> EntityController.create()
    |> case do
      {:ok, entity} ->
        Broker.cast("event:entity:created", entity.entity_id, request: request)
        {:reply, {:ok, entity}, state}
      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end
  def handle_call({:entity, :find, id}, _from, state) do
    response = EntityController.find(id)
    {:reply, response, state}
  end
end