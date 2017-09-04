defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  `ServerChannel` handles incoming and outgoing messages between players and
  servers.

  Common errors (applicable to all requests expected to reply something):

  - "bad_request" - One or more request params are invalid.
  - "internal" - Something unexpected happened.
  """

  use Phoenix.Channel

  alias Helix.Websocket.Socket, as: Websocket
  alias Helix.Server.Public.Server, as: ServerPublic

  # Requests
  alias Helix.Server.Websocket.Channel.Server.Join, as: ServerJoin
  alias Helix.Server.Websocket.Channel.Server.Requests.Browse,
    as: BrowseRequest
  alias Helix.Server.Websocket.Channel.Server.Requests.Bruteforce,
    as: BruteforceRequest

  def join(topic = "server:" <> server_id, params, socket) do
    access_type =
      if server_id == params["gateway_id"] do
        :local
      else
        :remote
      end

    request = ServerJoin.new(topic, params, access_type)
    Websocket.handle_join(request, socket, &assign/3)
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
    request = BrowseRequest.new(params)
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
    request = BruteforceRequest.new(params)
    Websocket.handle_request(request, socket)
  end

  intercept ["event"]

  def handle_out("event", event, socket),
    do: Websocket.handle_event(event, socket, &push/3)
end
