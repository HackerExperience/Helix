defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  Channel to notify all players connected to a certain server about events
  regarding said server
  """

  use Phoenix.Channel

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Software.API.File, as: FileAPI
  alias Helix.Process.API.Process, as: ProcessAPI
  alias Helix.Log.API.Log, as: LogAPI
  alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer
  alias Helix.Server.Public.Server, as: ServerPublic
  alias Helix.Server.Websocket.View.ServerChannel, as: ChannelView

  # Events
  alias Helix.Process.Model.Process.ProcessCreatedEvent
  alias Helix.Process.Model.Process.ProcessConclusionEvent
  alias Helix.Log.Model.Log.LogCreatedEvent
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent

  # Joining into player's own gateway
  def join("server:" <> gateway_id, %{"gateway_id" => gateway_id}, socket) do
    with \
      account = socket.assigns.account,
      :ok <- ChannelHenforcer.validate_gateway(account, gateway_id)
    do
      servers = %{gateway: gateway_id, destination: gateway_id}

      socket =
        socket
        |> assign(:servers, servers)
        |> assign(:access_type, :local)

      {:ok, socket}
    else
      error ->
        {:error, ChannelView.render_join_error(error)}
    end
  end

  # Joining a remote server
  def join(
    "server:" <> destination_id,
    %{
      "gateway_id" => gateway_id,
      # "network_id" => network_id,
      # "bounces" => bounce_list,
      "password" => password
    },
    socket)
  do
    with \
      account = socket.assigns.account,
      :ok <- ChannelHenforcer.validate_gateway(account, gateway_id),
      :ok <- ChannelHenforcer.validate_server(destination_id, password),
      {:ok, tunnel} <- ServerPublic.connect_to_server(
        gateway_id,
        destination_id,
        [])
    do
      servers = %{gateway: gateway_id, destination: destination_id}

      socket =
        socket
        |> assign(:tunnel, tunnel)
        |> assign(:servers, servers)
        |> assign(:access_type, :remote)

      {:ok, socket}
    else
      error ->
        {:error, ChannelView.render_join_error(error)}
    end
  end

  @doc false
  def handle_in("file.index", _, socket) do
    destination = socket.assigns.servers.destination
    index = FileAPI.index(destination)

    {:reply, {:ok, index}, socket}
  end

  # TODO: Paginate
  def handle_in("log.index", _message, socket) do
    server_id = socket.assigns.servers.destination

    data = %{logs: LogAPI.index(server_id)}

    {:reply, {:ok, %{data: data}}, socket}
  end

  def handle_in("log.delete", %{log_id: log_id}, socket) do
    target_id = socket.assigns.servers.destination
    gateway_id = socket.assigns.servers.gateway
    network_id = "::"

    case LogAPI.delete(gateway_id, target_id, network_id, log_id) do
      :ok ->
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: Atom.to_string(reason)}}}
    end
  end

  def handle_in("process.index", _message, socket) do
    server = socket.assigns.servers.destination
    entity = EntityQuery.get_entity_id(socket.assigns.account)

    index = ProcessAPI.index(server, entity)

    return = %{
      owned_processes: index[:owned],
      affecting_processes: index[:affecting]
    }

    {:reply, {:ok, return}, socket}
  end

  def handle_in("file.download", %{file_id: file_id}, socket) do
    destination = socket.assigns.servers.destination
    gateway = socket.assigns.servers.gateway
    tunnel = socket.assigns.tunnel

    case FileAPI.download(gateway, destination, tunnel, file_id) do
      :ok ->
        {:reply, :ok, socket}
      :error ->
        {:reply, :error, socket}
    end
  end

  def notify(server_id, :processes_changed, _params) do
    # TODO: Use a view to always follow an standardized format
    notify(server_id, %{
      event: "processes_changed",
      data: %{}
    })
  end

  def notify(server_id, :logs_changed, _params) do
    # TODO: Use a view to always follow an standardized format
    notify(server_id, %{
      event: "logs_changed",
      data: %{}
    })
  end

  defp notify(server_id, notification) do
    topic = "server:" <> server_id

    Helix.Endpoint.broadcast(topic, "notification", notification)
  end

  @doc false
  def event_process_created(
    %ProcessCreatedEvent{gateway_id: gateway, target_id: gateway})
  do
    notify(gateway, :processes_changed, %{})
  end
  def event_process_created(
    %ProcessCreatedEvent{gateway_id: gateway, target_id: target})
  do
    notify(gateway, :processes_changed, %{})
    notify(target, :processes_changed, %{})
  end

  @doc false
  def event_process_conclusion(
    %ProcessConclusionEvent{gateway_id: gateway, target_id: gateway})
  do
    notify(gateway, :processes_changed, %{})
  end
  def event_process_conclusion(
    %ProcessConclusionEvent{gateway_id: gateway, target_id: target})
  do
    notify(gateway, :processes_changed, %{})
    notify(target, :processes_changed, %{})
  end

  @doc false
  def event_log_created(%LogCreatedEvent{server_id: server}),
    do: notify(server, :logs_changed, %{})

  @doc false
  def event_log_modified(%LogModifiedEvent{server_id: server}),
    do: notify(server, :logs_changed, %{})

  @doc false
  def event_log_deleted(%LogDeletedEvent{server_id: server}),
    do: notify(server, :logs_changed, %{})
end
