defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  Channel to notify all players connected to a certain server about events
  regarding said server
  """

  use Phoenix.Channel

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Server.Public.Server, as: ServerPublic
  alias Helix.Server.Websocket.View.ServerChannel, as: ChannelView

  # Events
  alias Helix.Log.Model.Log.LogCreatedEvent
  alias Helix.Log.Model.Log.LogDeletedEvent
  alias Helix.Log.Model.Log.LogModifiedEvent
  alias Helix.Process.Model.Process.ProcessConclusionEvent
  alias Helix.Process.Model.Process.ProcessCreatedEvent

  # Joining into player's own gateway
  def join("server:" <> gateway_id, %{"gateway_id" => gateway_id}, socket) do
    with \
      account = socket.assigns.account,
      {:ok, gateway_id} <- Server.ID.cast(gateway_id),
      :ok <- ChannelHenforcer.validate_gateway(account, gateway_id)
    do
      servers = %{gateway_id: gateway_id, destination_id: gateway_id}

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
      "network_id" => network_id,
      # "bounces" => bounce_list,
      "password" => password
    },
    socket)
  do
    with \
      account = socket.assigns.account,
      {:ok, gateway_id} <- Server.ID.cast(gateway_id),
      {:ok, destination_id} <- Server.ID.cast(destination_id),
      :ok <- ChannelHenforcer.validate_gateway(account, gateway_id),
      :ok <- ChannelHenforcer.validate_server(destination_id, password),
      {:ok, tunnel} <- ServerPublic.connect_to_server(
        gateway_id,
        destination_id,
        [])
    do
      servers = %{gateway_id: gateway_id, destination_id: destination_id}

      socket =
        socket
        |> assign(:network_id, network_id)
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
    server_id = socket.assigns.servers.destination_id

    message = %{data: %{files: ServerPublic.file_index(server_id)}}

    {:reply, {:ok, message}, socket}
  end

  def handle_in("file.download", %{file_id: file_id}, socket) do
    if socket.assigns.access_type == :remote do
      destination = socket.assigns.servers.destination_id
      gateway = socket.assigns.servers.gateway_id
      tunnel = socket.assigns.tunnel

      case ServerPublic.file_download(gateway, destination, tunnel, file_id) do
        :ok ->
          {:reply, :ok, socket}
        :error ->
          {:reply, :error, socket}
      end
    else
      message = %{
        type: "error",
        data: %{message: "Can't download from own gateway"}
      }
      {:reply, {:error, message}, socket}
    end
  end

  # TODO: Paginate
  def handle_in("log.index", _, socket) do
    server_id = socket.assigns.servers.destination_id

    message = %{data: %{logs: ServerPublic.log_index(server_id)}}

    {:reply, {:ok, message}, socket}
  end

  def handle_in("process.index", _, socket) do
    server_id = socket.assigns.servers.destination_id
    entity_id = EntityQuery.get_entity_id(socket.assigns.account)

    index = ServerPublic.process_index(server_id, entity_id)

    return = %{data: %{
      owned_processes: index.owned,
      affecting_processes: index.affecting
    }}

    {:reply, {:ok, return}, socket}
  end

  def handle_in("network.browse", %{address: address}, socket) do
    network_id = socket.assigns.network_id
    gateway_id = socket.assigns.servers.gateway_id

    case ServerPublic.network_browse(network_id, address, gateway_id) do
      {:ok, return} ->
        data = %{data: return}
        {:reply, {:ok, data}, socket}
      {:error, %{message: msg}} ->
        {:reply, {:error, ChannelView.error(msg)}, socket}
    end
  end

  defp notify(server_id, :processes_changed, _params) do
    # TODO: Use a view to always follow an standardized format
    notify(server_id, %{
      event: "processes_changed",
      data: %{}
    })
  end

  defp notify(server_id, :logs_changed, _params) do
    # TODO: Use a view to always follow an standardized format
    notify(server_id, %{
      event: "logs_changed",
      data: %{}
    })
  end

  defp notify(server_id, notification) do
    topic = "server:" <> to_string(server_id)

    Helix.Endpoint.broadcast(topic, "event", notification)
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
