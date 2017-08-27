defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  `ServerChannel` handles incoming and outgoing messages between players and
  servers.
  """

  use Phoenix.Channel

  alias Phoenix.Socket
  alias HELL.IPv4
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
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
      :ok <- ChannelHenforcer.validate_gateway(account, gateway_id),
      gateway_entity = %{} <- EntityQuery.fetch_by_server(gateway_id)
    do
      gateway_data = %{
        server_id: gateway_id,
        entity_id: gateway_entity.entity_id
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
      {:ok, tunnel} <- ServerPublic.connect_to_server(
        gateway_id,
        destination_id,
        [])
    do
      gateway_data = %{
        server_id: gateway_id,
        entity_id: gateway_entity.entity_id
      }

      destination_data = %{
        server_id: destination_id,
        entity_id: destination_entity.entity_id
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
  - *address: IP or website the user is trying to browse to.
  - origin: Force the request to originate from the given ID. By default, the
    destination_id is always used. This is useful in the scenario where user is
    remotely logged into someone and wants to browse to a website using his own
    gateway server as origin. Origin must be one of (gateway_id, destination_id)

  In case the address could not be found, returns `web_not_found` error.

  Returns `bad_origin` when the given origin is neither `gateway_id` nor
    `destination_id`
  """
  def handle_in("network.browse", params = %{"address" => address}, socket) do
    gateway_id = socket.assigns.gateway.server_id
    destination_id = socket.assigns.destination.server_id

    network_id =
      if socket.assigns.access_type == :local do
        NetworkQuery.internet().network_id
      else
        socket.assigns.network_id
      end

    origin_id =
      if Map.has_key?(params, "origin") do
        Server.ID.cast!(params["origin"])
      else
        socket.assigns.destination.server_id
      end

    with \
      true <- NetworkHenforcer.valid_origin?(origin_id, servers) || :badorigin,
      {:ok, web} <- ServerPublic.network_browse(network_id, address, origin_id)
    do
      reply_ok(web, socket)
    else
      :badorigin ->
        reply_error("bad_origin", socket)
      {:error, %{message: msg}} ->
        reply_error(msg, socket)
    end
  end

  alias HELL.IPv4
  alias Helix.Software.Henforcer.File, as: FileHenforcer

  @doc """
  Starts a bruteforce attack.

  Params:

  *network_id: Network ID in which the target server resides.
  *ip: Target server IP address
  *bounces: List of hops between the origin and the target.

  Note that all bruteforce attacks must originate from a server owned by the
  entity starting the attack.
  """
  def handle_in("bruteforce", params, socket) do
    source_id = socket.assigns.gateway.server_id

    with \
      {:ok, network_id} <- Network.ID.cast(params["network_id"]),
      true <- IPv4.valid?(params["ip"]),
      {:ok, bounces} = cast_bounces(params["bounces"]),
      true <- socket.assigns.access_type == :local || :bad_attack_src
    do
      bruteforce(source_id, network_id, params["ip"], bounces, socket)
    else
      :bad_attack_src ->
        reply_error("bad_attack_src", socket)
      _ ->
        reply_error("bad_param", socket)
    end
  end

  intercept ["event"]

  alias Helix.Event.Notificable
  def handle_out("event", event, socket) do
    case Notificable.generate_payload(event, socket) do
      {:ok, data} ->
        push socket, "event", data
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  @spec network_browse(Network.id, String.t | IPv4.t, Server.id, socket) ::
    {:reply, {:ok, term}, socket}
    | term
  defp network_browse(network_id, address, origin_id, socket) do
    case ServerPublic.network_browse(network_id, address, origin_id) do
      {:ok, web} ->
        reply_ok(web, socket)
      {:error, %{message: msg}} ->
        reply_error(msg, socket)
    end
  end

  @spec bruteforce(Server.id, Network.id, IPv4.t, [Server.id], socket) ::
    {:reply, {:ok, :ok}, socket}
    | term  # TODO
  defp bruteforce(source_id, network_id, target_ip, bounces, socket) do
    with \
      :ok <- FileHenforcer.Cracker.can_bruteforce(),
      {:ok, _process} <-
        ServerPublic.bruteforce(source_id, network_id, target_ip, bounces)
    do
      # TODO: What to return?
      {:reply, {:ok, :ok}, socket}
    else
      _ ->
        reply_error("internal", socket)
    end
  end

  defp cast_bounces(bounces) when is_list(bounces),
    do: {:ok, Enum.map(bounces, &(Server.ID.cast!(&1)))}
  defp cast_bounces(_),
    do: :error

  defp reply_error(msg, socket),
    do: {:reply, {:error, ChannelView.error(msg)}, socket}

  defp reply_ok(data = %{data: _}, socket),
    do: {:reply, {:ok, data}, socket}
  defp reply_ok(data, socket),
    do: reply_ok(%{data: data}, socket)

end
