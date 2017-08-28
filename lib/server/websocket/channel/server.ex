defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  `ServerChannel` handles incoming and outgoing messages between players and
  servers.

  Common errors (applicable to all requests expected to reply something):

  - "bad_request" - One or more request params are invalid.
  - "internal" - Something unexpected happened.
  """

  use Phoenix.Channel

  alias Phoenix.Socket
  alias Helix.Websocket.Socket, as: Websocket
  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Event.Notificable
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Server.Public.Server, as: ServerPublic
  alias Helix.Server.Websocket.View.ServerChannel, as: ChannelView

  # HEnforcers
  alias Helix.Server.Henforcer.Channel, as: ChannelHenforcer

  # Requests
  alias Helix.Server.Websocket.Channel.Server.Requests.Browse,
    as: BrowseRequest
  alias Helix.Server.Websocket.Channel.Server.Requests.Bruteforce,
    as: BruteforceRequest

  @type socket :: Socket.t

  # Joining into player's own gateway
  def join("server:" <> gateway_id, %{"gateway_id" => gateway_id}, socket) do
    with \
      account = socket.assigns.account,
      {:ok, gateway_id} <- Server.ID.cast(gateway_id),
      :ok <- ChannelHenforcer.validate_gateway(account, gateway_id),
      gateway_entity = %{} <- EntityQuery.fetch_by_server(gateway_id),
      {:ok, nips} <- CacheQuery.from_server_get_nips(gateway_id)
    do
      gateway_data = %{
        server_id: gateway_id,
        entity_id: gateway_entity.entity_id,
        ips: format_nips(nips)
      }

      socket =
        socket
        |> assign(:access_type, :local)
        |> assign(:gateway, gateway_data)
        |> assign(:destination, gateway_data)

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
      {:ok, network_id} <- Network.ID.cast(network_id),
      :ok <- ChannelHenforcer.validate_gateway(account, gateway_id),
      :ok <- ChannelHenforcer.validate_server(destination_id, password),
      gateway_entity = %{} <- EntityQuery.fetch_by_server(gateway_id),
      destination_entity = %{} <- EntityQuery.fetch_by_server(destination_id),
      {:ok, gateway_nips} <- CacheQuery.from_server_get_nips(gateway_id),
      {:ok, destination_nips} <-
         CacheQuery.from_server_get_nips(destination_id),
      {:ok, tunnel} <- ServerPublic.connect_to_server(
        gateway_id,
        destination_id,
        [])
    do
      gateway_data = %{
        server_id: gateway_id,
        entity_id: gateway_entity.entity_id,
        ips: format_nips(gateway_nips)
      }

      destination_data = %{
        server_id: destination_id,
        entity_id: destination_entity.entity_id,
        ips: format_nips(destination_nips)
      }

      socket =
        socket
        |> assign(:network_id, network_id)
        |> assign(:tunnel, tunnel)
        |> assign(:access_type, :remote)
        |> assign(:gateway, gateway_data)
        |> assign(:destination, destination_data)

      {:ok, socket}
    else
      error ->
        {:error, ChannelView.render_join_error(error)}
    end
  end

  defp format_nips(nips) do
    nips
    |> Enum.reduce(%{}, fn nip, acc ->
      Map.put(acc, nip.network_id, nip.ip)
    end)
  end

  @doc false
  def handle_in("file.index", _, socket) do
    destination_id = socket.assigns.destination.server_id

    message = %{data: %{files: ServerPublic.file_index(destination_id)}}

    {:reply, {:ok, message}, socket}
  end

  def handle_in("file.download", %{file_id: file_id}, socket) do
    if socket.assigns.access_type == :remote do
      gateway_id = socket.assigns.gateway.server_id
      destination_id = socket.assigns.destination.server_id
      tunnel = socket.assigns.tunnel

      download =
        ServerPublic.file_download(gateway_id, destination_id, tunnel, file_id)

      case download do
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
    destination_id = socket.assigns.destination.server_id

    message = %{data: %{logs: ServerPublic.log_index(destination_id)}}

    {:reply, {:ok, message}, socket}
  end

  def handle_in("process.index", _, socket) do
    destination_id = socket.assigns.destination.server_id
    entity_id = socket.assigns.destination.entity_id

    index = ServerPublic.process_index(destination_id, entity_id)

    return = %{data: %{
      owned_processes: index.owned,
      affecting_processes: index.affecting
    }}

    {:reply, {:ok, return}, socket}
  end

  @doc """
  Browses to the specified address, which may be an IPv4 or domain name.

  Params:
  - *network_id: Network ID in use.
  - *address: IP or website the user is trying to browse to.
  - origin: Force the request to originate from the given ID. By default, the
    destination_id is always used. This is useful in the scenario where user is
    remotely logged into someone and wants to browse to a website using his own
    gateway server as origin. Origin must be one of (gateway_id, destination_id)

  Returns:
    %{
      password: nil | String.t,
      webserver: {:npc, NPCWebContent.t} | {:vpc | VPCWebContent.t}
    }

  Errors:
  - "web_not_found" - The given address was not be found.
  - "bad_origin" - The given origin is neither `gateway_id` nor `destination_id`
  """
  def handle_in("network.browse", params, socket) do
    request = BrowseRequest.new(socket, params)
    Websocket.handle_request(request, socket)
  end

  @doc """
  Starts a bruteforce attack.

  Params:
  *network_id: Network ID in which the target server resides.
  *ip: Target server IP address
  *bounces: List of hops between the origin and the target.

  Note that all bruteforce attacks must originate from a server owned by the
  entity starting the attack.

  Returns:
    %{
      process_id: Process.id,
      type: Process.type,
      network_id: Network.id,
      file_id: File.id | nil,
      connection_id: Connection.id | nil,
      source_ip: IPv4.t,
      target_ip: IPv4.t
    }

  Errors:
  - "cracker_not_found" - Player attempting the attack does not have a valid
    cracker on her system
  - "target_noob_protection" - Target is under temporary noob protection and
    cannot be attacked.
  - "target_self" - Player is trying to hack herself...
  - "bad_attack_src" - Request originated from a remote server channel
  """
  def handle_in("bruteforce", params, socket) do
    request = BruteforceRequest.new(socket, params)
    Websocket.handle_request(request, socket)
  end

  intercept ["event"]

  def handle_out("event", event, socket) do
    case Notificable.generate_payload(event, socket) do
      {:ok, data} ->
        push socket, "event", data

        WebsocketUtils.no_reply(socket)
      _ ->
        WebsocketUtils.no_reply(socket)
    end
  end
end
