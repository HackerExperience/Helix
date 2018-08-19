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

  alias Helix.Log.Websocket.Requests.Forge, as: LogForgeRequest
  alias Helix.Log.Websocket.Requests.Recover, as: LogRecoverRequest

  alias Helix.Network.Websocket.Requests.Browse, as: BrowseRequest

  alias Helix.Software.Websocket.Requests.Cracker.Bruteforce,
    as: CrackerBruteforceRequest
  alias Helix.Software.Websocket.Requests.File.Download,
    as: FileDownloadRequest
  alias Helix.Software.Websocket.Requests.File.Upload,
    as: FileUploadRequest
  alias Helix.Software.Websocket.Requests.File.Install,
    as: FileInstallRequest
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

  alias Helix.Server.Websocket.Channel.Server.Join, as: ServerJoin
  alias Helix.Server.Websocket.Requests.Bootstrap, as: BootstrapRequest
  alias Helix.Server.Websocket.Requests.Config.Check, as: ConfigCheckRequest
  alias Helix.Server.Websocket.Requests.Config.Set, as: ConfigSetRequest
  alias Helix.Server.Websocket.Requests.MotherboardUpdate,
    as: MotherboardUpdateRequest
  alias Helix.Server.Websocket.Requests.SetHostname, as: SetHostnameRequest

  @doc """
  Joins a server.

  ### Local join (gateway)

  Topic: "server:<server_id>"

  Params: %{}

  Returns: ServerBootstrap

  Errors:
  - base errors

  ### Remote join (endpoint)

  Topic: "server:<network_id>@<destination_ip>[#<counter>]"

  [#<counter>] denotes optional argument. If omitted, Helix will automatically
  grab the correct counter.

  `counter` must be set by the client if:
  1) the player joins the same server multiple times, using different gateways
  2) the client must know the topic name in advance

  Otherwise, simply ignore `counter` and everything will be fine.

  Params:
  - *gateway_ip: Which gateway ip this connection is originating from.
  - *password: Target server password. Required if the connection is remote.
  - bounce_id: Which bounce to use on remote connections.

  Returns: ServerBootstrap

  Errors:

  Henforcer:
  - "password_invalid": Password is invalid.
  - "bounce_not_belongs": Requested bounce does not belong to the player.
  - "bounce_not_found": Requested bounce could not be found

  Input:
  - "nip_not_found": The `destination_ip` with `network_id` was not found.
  - "bad_counter": The given counter is not valid.
  + base errors
  """
  join "server:" <> _, ServerJoin

  @doc """
  Sets one or more server-related configuration

  - <config_key>: <config_params> where:

  `config_key` denotes what is being set/configured, and `config_params` is the
  new value.

  Valid config_keys:
  - hostname: See docs on request `set_hostname`
  - location: TODO

  Params:
  - hostname: Specify server hostname. Expected data: %{hostname: String}
  - location: Specify server location. Expected data: %{lat: Float, lon: Float}

  Errors:
  For each key that fails to be set, the corresponding error will be returned.

  Example:

  Supposed the client asked to `config.set` both `location` and `hostname`, and
  Helix replies with the following error:

    %{"hostname" => "invalid_hostname"}

  Notice that `location` was not included. This means only `hostname` is wrong.
  However, if an error was returned, no configs were updated, even if some of
  them were correct.

  + base errors
  """
  topic "config.set", ConfigSetRequest

  @doc """
  Checks / verifies that the value set at `value` is valid for the config
  defined at `key`. Used as a companion of `config.set`, mostly to increase UX.

  Params:
  - *key: Valid config keys (see docs on `config.set`)
  - *value: Expected values (see docs on `config.set`)

  Errors:
  May return the corresponding permission error defined for each key.
  """
  topic "config.check", ConfigCheckRequest

  @doc """
  Starts a LogForgeProcess. When forging, the player may want to edit an
  existing log, or create a brand new log.

  Params (create):
    - *log_type: Type of the desired log revision.
    - *log_data: Data of the desired log revision.
    - *action: Explicitly set action to "create".

  Params (edit):
    - *log_id: ID of the log that will be edited.
    - *log_type: Type of the desired log revision.
    - *log_data: Data of the desired log revision.
    - *action: Explicitly set action to "edit".

  Errors:

  Input validation:
  - "bad_action" - Action is neither "edit" or "create".
  - "bad_log_type" - The given `log_type` is not valid.
  - "bad_log_data" - The given `log_data` is not valid for the `log_type`.

  Henforcer:
  - "forger_not_found" - Player does not have a valid LogForger software.
  - "log_not_found" (edit) - The given log ID was not found.
  - "log_not_belongs" (edit) - Attempting to edit a log that does not belong to
    the open channel.

  - base errors
  """
  topic "log.forge", LogForgeRequest

  @doc """
  Starts a LogRecoverProcess. When recovering, the player may either start the
  process using the `global` method or the `custom` method.

  The `global` method scans all logs on the server, randomly selects a
  recoverable log and starts working on it. The `custom` method works on a
  specific log defined by the user.

  Params (global):
    - *method: Explicitly set method to "global"

  Params (custom):
    - *log_id: ID of the log that will be recovered.
    - *method: Explicitly set method to "custom"

  Errors:

  Henforcer:
  - "recover_not_found" - Player does not have a valid LogRecover software.
  - "log_not_found" (custom) - The given log ID was not found.
  - "log_not_belongs" (custom) - Attempting to recover a log that does not
    belong to the open channel.

  Input Validation:
  - "bad_method" - Method is neither "global" or "custom"
  + base errors
  """
  topic "log.recover", LogRecoverRequest

  @doc """
  Updates the player's motherboard. May be used to attach, detach or update the
  mobo components.

  Params (detach):
  - *cmd: "detach"

  Params (update):
  - *motherboard_id: ID of the motherboard selected by the player.
  - *slots: Map with the mobo `slot_id` as key and the component selected for
    such slot. Empty slots may be ignored or set as `nil`.
  - *network_connections: Map with the `nic_id` as key and the nip selected for
    such nic. Non-assigned NICs may be ignored.

  Example:
    %{
      "motherboard_id" => "::1",
      "slots" => %{
        "cpu_1" => "::f",
        "ram_1" => nil,
      },
      "network_connections" => %{
        "::5" => %{
          "network_id" => "::",
          "ip" => "1.2.3.4"
        }
      }
    }

  All components (including the mobo) and the NIPs must belong to the player.

  Returns: :ok

  Errors:

  Henforcer:
  - component_not_found: One of the specified components were not found
  - motherboard_wrong_slot_type: Buraco errado
  - motherboard_bad_slot: Specified invalid slot ID
  - component_not_belongs: One of the components do not belong to the player
  - motherboard_missing_initial_components: So large it's self explanatory
  - network_connection_not_belongs: One of the NCs do not belong to the player
  - motherboard_missing_public_nip: Mobos must have at least one public NIP
  - component_not_motherboard: Wrong tool for the job

  Input validation:
  - bad_slot_data: slot data (input) is invalid
  - bad_network_connections: network connections data (input) is invalid
  - bad_src: this request may only be run on `local` channels
  + base errors
  """
  topic "motherboard.update", MotherboardUpdateRequest

  @doc """
  Updates the server hostname.

  Params:
  - *hostname: Desired hostname

  Returns: :ok

  Errors:
  - invalid_hostname
  + base errors
  """
  topic "set_hostname", SetHostnameRequest

  @doc """
  Starts the download of a file.

  Params:
  - *file_id: Which file to download. Duh.
  - storage_id: Specify which storage the file should be downloaded to. Defaults
    to the main storage.

  Returns: :ok

  Errors:
  - "file_not_found": Requested file to be downloaded was not found
  - "storage_full": Not enough space on device to download the file
  - "storage_not_found": Requested storage is invalid / could not be found. This
    error is most likely NOT the user's fault, maybe some bad handling on the
    client side.
  - "download_self": Trying to download a file from yourself
  + base errors
  """
  topic "file.download", FileDownloadRequest

  @doc """
  Starts the upload of a file.

  Params:
  - *file_id: Which file to upload.
  - storage_id: Specify which storage the file should be uploaded to. Defaults
    to the remote server's main storage.

  Returns: :ok

  Errors:
  - "file_not_found": Requested file to be uploaded was not found
  - "storage_full": Not enough space on device to upload the file
  - "storage_not_found": Requested storage is invalid / could not be found. This
    error is most likely NOT the user's fault, maybe some bad handling on the
    client side.
  - "upload_self": Trying to upload a file to yourself
  + base errors
  """
  topic "file.upload", FileUploadRequest

  @doc """
  Installs a file.

  This endpoint allows some files to be installed in a generic fashion. Only
  some files can be installed using this endpoint, they are:
  - Viruses (:virus_*)

  Params:
  - *file_id: Which file to install.

  Returns: :ok

  Errors:

  Henforcer (all):
  - "file_not_installabe": Given file is not installable.

  Henforcer (virus):
  - "entity_has_virus_on_storage": Entity already has one virus # TODO ERRADO
  - "virus_active": Trying to install a virus that is already installed
  - "virus_self_install": Trying to install a virus on a server owned by the
    same player who is installing the virus

  Input validation:
  + base_errors
  """
  topic "file.install", FileInstallRequest

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

  Returns: :ok

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
  *bounce_id: Bounce to be used during the attack.

  Note that all bruteforce attacks must originate from a server owned by the
  entity starting the attack.

  Returns: :ok

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

  Errors: none?
  """
  topic "bootstrap", BootstrapRequest

  @doc """
  Intercepts and handles outgoing events.
  """
  event_handler "event"

  @doc """
  When the client disconnects/leaves a remote Channel, we update the
  ServerWebsocketChannelState.
  """
  def terminate(_reason, socket) do
    if socket.assigns.meta.access == :remote do
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
end
