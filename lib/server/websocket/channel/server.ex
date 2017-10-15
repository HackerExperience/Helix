import Helix.Websocket.Channel

channel Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  `ServerChannel` handles incoming and outgoing messages between players and
  servers.

  Base errors (applicable to all requests expected to reply something):

  - "bad_request" - One or more request params are invalid.
  - "internal" - Something unexpected happened.
  """

  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState

  alias Helix.Network.Websocket.Requests.Browse,
    as: BrowseRequest

  alias Helix.Software.Websocket.Requests.Cracker.Bruteforce,
    as: CrackerBruteforceRequest
  alias Helix.Software.Websocket.Requests.File.Download,
    as: FileDownloadRequest
  alias Helix.Software.Websocket.Requests.PFTP.File.Add,
    as: PFTPFileAddRequest
  alias Helix.Software.Websocket.Requests.PFTP.File.Download,
    as: PFTPFileDownloadRequest
  alias Helix.Software.Websocket.Requests.PFTP.File.Remove,
    as: PFTPFileRemoveRequest
  alias Helix.Software.Websocket.Requests.PFTP.Server.Disable,
    as: PFTPServerDisableRequest
  alias Helix.Software.Websocket.Requests.PFTP.Server.Enable,
    as: PFTPServerEnableRequest

  alias Helix.Server.Websocket.Channel.Server.Join,
    as: ServerJoin
  alias Helix.Server.Websocket.Channel.Server.Requests.Bootstrap,
    as: BootstrapRequest

  @doc """
  Joins a server.

  Topic:
  "server:<network_id>@<destination_ip>[#<counter>]"

  [#<counter>] denotes optional argument. If omitted, Helix will automatically
  grab the correct counter.

  `counter` must be set by the client if:
  1) the player joins the same server multiple times, using different gateways
  2) the client must know the topic name in advance

  Otherwise, simply ignore `counter` and everything will be fine.

  Params:
  - gateway_ip: Notifies which gateway ip this connection is originating from.
    If no `gateway_ip` is passed, a local gateway connection is assumed.
  - password: Target server password. Required if the connection is remote.

  Returns: ServerBootstrap

  Errors:
  - "nip_not_found": The `destination_ip` with `network_id` was not found.
  - "bad_counter": The given counter is not valid.
  + base errors
  """
  join "server:" <> _, ServerJoin

  @doc """
  Starts the download of a file.

  Params:
  - *file_id: Which file to download. Duh.
  - storage_id: Specify which storage the file should be downloaded to. Defaults
    to the main storage.

  Returns: RenderedProcess.t

  Errors:
  - "file_not_found": Requested file to be downloaded was not found
  - "storage_full": Not enough space on device to download the file
  - "storage_not_found": Requested storage is invalid / could not be found. This
    This error is most likely NOT the user's fault, maybe some bad handling on
    the client side.
  - "download_self": Trying to download a file from yourself
  + base errors
  """
  topic "file.download", FileDownloadRequest

  @doc """
  Activates/enables the PublicFTP server of the player. Creates a new PublicFTP
  server if it's the first time being called.

  Params: none

  Returns: %{}

  Errors:
  - "pftp_already_enabled": Trying to enable an already enabled PFTP server.
  - "pftp_must_be_local": PFTP operations must happen at the local socket.
  - Henforcer errors.
  """
  topic "pftp.server.enable", PFTPServerEnableRequest

  @doc """
  Disables the PublicFTP server of the player.

  Params: none
  
  Returns: %{}

  Errors:
  - "pftp_already_disabled": Trying to disable an already disabled PFTP server.
  - "pftp_must_be_local": PFTP operations must happen at the local socket.
  - Henforcer errors.
  """
  topic "pftp.server.disable", PFTPServerDisableRequest

  @doc """
  Adds a file into the player's PublicFTP.

  Params:
  - *file_id: Which file to add to the player's PFTP.

  Errors:
  - "pftp_must_be_local": PFTP operations must happen at the local socket.
  - Henforcer errors
  """
  topic "pftp.file.add", PFTPFileAddRequest

  @doc """
  Removes a file from the player's PublicFTP.

  Params:
  - *file_id: Which file should be removed from the player's PFTP.

  Errors:
  - "pftp_must_be_local": PFTP operations must happen at the local socket.
  - Henforcer errors
  """
  topic "pftp.file.remove", PFTPFileRemoveRequest

  @doc """
  Downloads a file from a PublicFTP server.

  Params:
  - *ip: IP address of the PublicFTP server.
  - *network_id: Network ID of the PublicFTP server.
  - *file_id: ID of the file being downloaded.
  - storage_id: Specify which storage the file should be downloaded to. Defaults
    to the main storage.

  Returns: RenderedProcess.t

  Errors:
  - "pftp_must_be_local": PFTP operations must happen at the local socket.
  - "nip_not_found": Could not find a server with the given NIP.
  - Henforcer errors
  """
  topic "pftp.file.download", PFTPFileDownloadRequest

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
  + base errors
  """
  topic "network.browse", BrowseRequest

  @doc """
  Starts a bruteforce attack.

  Params:
  *network_id: Network ID in which the target server resides.
  *ip: Target server IP address
  *bounces: List of hops between the origin and the target.

  Note that all bruteforce attacks must originate from a server owned by the
  entity starting the attack.

  Returns: RenderedProcess.t

  Errors:
  - "cracker_not_found" - Player attempting the attack does not have a valid
    cracker on her system
  - "target_noob_protection" - Target is under temporary noob protection and
    cannot be attacked.
  - "target_self" - Player is trying to hack herself...
  - "bad_attack_src" - Request originated from a remote server channel
  + base errors
  """
  topic "cracker.bruteforce", CrackerBruteforceRequest

  @doc """
  Forces a bootstrap to happen. It is the exact same operation ran during join.
  Useful if the client wants to force a resynchronization of the local data.

  Params: none

  Returns: ServerBootstrap

  Errors:
  - "own_server_bootstrap": You can only request the bootstrap of remote servers
  (obsolete, let me know if you need local server bootstrap)
  """
  topic "bootstrap", BootstrapRequest

  @doc """
  Intercepts and handles outgoing events.
  """
  event_handler "event"

  @doc """
  When the client disconnects/leaves the Channel, we update the
  ServerWebsocketChannelState.
  """
  def terminate(_reason, socket) do
    entity_id = socket.assigns.gateway.entity_id
    server_id = socket.assigns.destination.server_id
    counter = socket.assigns.meta.counter
    network_id = socket.assigns.meta.network_id
    ip = socket.assigns.destination.ip

    ServerWebsocketChannelState.leave(
      entity_id,
      server_id,
      {network_id, ip},
      counter
    )
  end
end
