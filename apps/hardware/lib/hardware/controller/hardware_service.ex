defmodule Helix.Hardware.Controller.HardwareService do

  use GenServer

  alias HELF.Broker
  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.MotherboardSlot
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

  def handle_broker_call(pid, "hardware:motherboard:create", params = %{}, _request) do
    case params do
      %{spec_id: sid} ->
        response = GenServer.call(pid, {:motherboard, :create, {:component_spec, :id, sid}})
        {:reply, response}
      _ ->
        {:reply, {:error, :invalid_request}}
    end
  end

  def handle_broker_call(pid, "hardware:motherboard:resources", %{motherboard_id: mid}, _) do
    response = GenServer.call(pid, {:motherboard, :resources, mid})

    {:reply, response}
  end

  def handle_broker_cast(pid, "event:server:created", {server_id, _entity_id}, request) do
    # FIXME: remove hardcoded data
    bundle = %{
      motherboard: "MOBO01",
      components:  [
        {"cpu", "CPU01"},
        {"ram", "RAM01"},
        {"hdd", "HDD01"},
        {"nic", "NIC01"}
      ],
      network: [
        {"::", uplink: 100, downlink: 100}
      ]
    }

    GenServer.call(pid, {:setup, server_id, bundle, request})
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_args) do
    Broker.subscribe("hardware:get", call: &handle_broker_call/4)
    Broker.subscribe("hardware:motherboard:create", call: &handle_broker_call/4)
    Broker.subscribe("hardware:motherboard:resources", call: &handle_broker_call/4)
    Broker.subscribe("event:server:created", cast: &handle_broker_cast/4)

    {:ok, nil}
  end

  @spec handle_call(
    {:motherboard, :create, {:component_spec, :id, HELL.PK.t}},
    GenServer.from,
    state) :: {:reply, {:ok, Motherboard.t} | error :: term, state}
  @spec handle_call(
    {:motherboard, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Motherboard.t} | {:error, :notfound}, state}
  @spec handle_call(
    {:motherboard_slot, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, MotherboardSlot.t} | {:error, :notfound}, state}
  @spec handle_call(
    {:component, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, Component.t} | {:error, :notfound}, state}
  @spec handle_call(
    {:component_spec, :get, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, ComponentSpec.t} | {:error, :notfound}, state}
  @spec handle_call(
    {:setup, HELL.PK.t, %{motherboard: String.t, components: [{String.t, String.t}]}},
    GenServer.from,
    state) :: {:reply, {:ok, Motherboard.t} | {:error, :internal_error}, state}
  @spec handle_call(
    {:motherboard, :resources, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, %{any => any}} | {:error, :notfound}, state}
  @doc false
  def handle_call({:motherboard, :create, {:component_spec, :id, spec_id}}, _from, state) do
    with \
      {:ok, cs} <- ComponentSpecController.find(spec_id),
      {:ok, mobo} <- MotherboardController.create_from_spec(cs)
    do
      message = %{motherboard_id: mobo.motherboard_id}

      Broker.cast("hardware:motherboard:created", message)

      {:reply, {:ok, mobo}, state}
    else
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:motherboard, :get, id}, _from, state) do
    response = MotherboardController.find(id)
    {:reply, response, state}
  end

  def handle_call({:motherboard_slot, :get, id}, _from, state) do
    response = MotherboardSlotController.find(id)
    {:reply, response, state}
  end

  def handle_call({:component, :get, id}, _from, state) do
    response = ComponentController.find(id)
    {:reply, response, state}
  end

  def handle_call({:component_spec, :get, id}, _from, state) do
    response = ComponentSpecController.find(id)
    {:reply, response, state}
  end

  def handle_call({:setup, server_id, bundle, request}, _from, state) do
    create_components = fn components ->
      Enum.reduce_while(components, {:ok, [], []}, fn {_type, id}, {:ok, acc0, acc1} ->
        case create_component(id) do
          {:ok, c, e} ->
            {:cont, {:ok, [c| acc0], e ++ acc1}}
          error ->
            {:halt, error}
        end
      end)
    end

    result = Repo.transaction(fn ->
      with \
        {:ok, motherboard, ev0} <- create_motherboard(bundle.motherboard),
        {:ok, components, ev1} <- create_components.(bundle.components),
        # TODO: Create and install Network connection
        {:ok, motherboard, ev2} <- setup_motherboard(motherboard, components)
      do
        {motherboard, ev0 ++ ev1 ++ ev2}
      else
        {:error, _} ->
          Repo.rollback(:internal_error)
      end
    end)

    case result do
      {:ok, {motherboard, deferred_events}} ->
        # FIXME: this should be handled by Eventually.flush(events)
        Enum.each(deferred_events, fn {topic, params} ->
          Broker.cast(topic, params, request: request)
        end)

        msg = %{
          motherboard_id: motherboard.motherboard_id,
          server_id: server_id
        }
        Broker.cast("event:motherboard:setup", msg, request: request)

        {:reply, {:ok, motherboard}, state}
      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:motherboard, :resources, mib}, _from, state) do
    with \
      {:ok, mb} <- MotherboardController.find(mib)
    do
      resources = MotherboardController.resources(mb)

      {:reply, {:ok, resources}, state}
    else
      _ ->
        {:reply, {:error, :notfound}, state}
    end
  end

  @spec create_motherboard(HELL.PK.t) ::
    {:ok, Motherboard.t, deferred_events :: [{String.t, map}]}
    | {:error, Ecto.Changeset.t}
  defp create_motherboard(spec_id) do
    with \
      {:ok, cs} <- ComponentSpecController.find(spec_id),
      {:ok, motherboard} <- MotherboardController.create_from_spec(cs)
    do
      msg = %{motherboard_id: motherboard.motherboard_id}
      ev = [{"event:motherboard:created", msg}]

      {:ok, motherboard, ev}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec create_component(String.t) ::
    {:ok, Component.t, deferred_events :: [{String.t, map}]}
    | {:error, Ecto.Changeset.t}
  defp create_component(spec_id) do
    component_spec = Repo.get_by(ComponentSpec, spec_id: spec_id)

    case ComponentController.create_from_spec(component_spec) do
      {:ok, component} ->
        msg = %{component_id: component.component_id}
        deferred_events = [{"event:component:created", msg}]

        {:ok, component, deferred_events}
      {:error, error} ->
        {:error, error}
    end
  end

  @spec setup_motherboard(Motherboard.t, [Component.t]) ::
    {:ok, Motherboard.t, deferred_events :: [{String.t, map}]}
    | {:error, Ecto.Changeset.t}
  defp setup_motherboard(motherboard, components) do
    grouped_components = Enum.group_by(components, &(&1.component_type))
    grouped_slots =
      motherboard
      |> Repo.preload(:slots)
      |> Map.fetch!(:slots)
      |> Enum.group_by(&(&1.link_component_type))

    grouped_slots
    |> Map.keys()
    |> Enum.flat_map(fn k ->
      grouped_slots
      |> Map.fetch!(k)
      |> Enum.zip(Map.get(grouped_components, k, []))
    end)
    |> Enum.reduce_while(:ok, fn {slot, component}, :ok ->
      case MotherboardSlotController.link(slot, component) do
        {:ok, _} ->
          {:cont, :ok}
        err ->
          {:halt, err}
      end
    end)
    |> case do
      :ok ->
        {:ok, motherboard, []}
      err ->
        err
    end
  end
end