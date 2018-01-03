defmodule Helix.Software.Henforcer.File.PublicFTP do
  @moduledoc """
  Henforcers for PublicFTP operations.
  """

  import Helix.Henforcer

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Network.Model.Network
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Query.PublicFTP, as: PublicFTPQuery

  @type pftp_exists_relay :: %{pftp: PublicFTP.t, server: Server.t}
  @type pftp_exists_relay_partial :: %{server: Server.t}
  @type pftp_exists_error ::
    {false, {:pftp, :not_found}, pftp_exists_relay_partial}
    | ServerHenforcer.server_exists_error

  @spec pftp_exists?(Server.idt) ::
    {true, pftp_exists_relay}
    | pftp_exists_error
  def pftp_exists?(server_id = %Server.ID{}) do
    henforce(ServerHenforcer.server_exists?(server_id)) do
      pftp_exists?(relay.server)
    end
  end

  def pftp_exists?(server = %Server{}) do
    with pftp = %{} <- PublicFTPQuery.fetch_server(server) do
      reply_ok(%{pftp: pftp})
    else
      _ ->
        reply_error({:pftp, :not_found})
    end
  end

  @type file_exists_relay ::
    %{file: File.t, server: Server.t, pftp_file: PublicFTP.File.t}
  @type file_exists_relay_partial :: %{file: File.t, server: Server.t}
  @type file_exists_error ::
    {false, {:pftp_file, :not_found}, file_exists_relay_partial}
    | FileHenforcer.file_exists_error
    | ServerHenforcer.server_exists_error

  @spec file_exists?(Server.idt, File.idt) ::
    {true, file_exists_relay}
    | file_exists_error
  @doc """
  Henforces that the given file exists on the PublicFTP server running at
  `server` (if any).

  If there are no running PublicFTP servers, or if it's disabled, then this
  henforce will return `false`.
  """
  def file_exists?(server, file_id = %File.ID{}) do
    henforce(FileHenforcer.file_exists?(file_id)) do
      file_exists?(server, relay.file)
    end
  end

  def file_exists?(server_id = %Server.ID{}, file) do
    henforce(ServerHenforcer.server_exists?(server_id)) do
      file_exists?(relay.server, file)
    end
  end

  def file_exists?(server = %Server{}, file = %File{}) do
    case PublicFTPQuery.fetch_file(file) do
      pftp_file = %PublicFTP.File{} ->
        reply_ok(%{pftp_file: pftp_file})

      _ ->
        reply_error({:pftp_file, :not_found})
    end
    |> wrap_relay(%{server: server, file: file})
  end

  @type not_file_exists_relay :: file_exists_relay_partial
  @type not_file_exists_relay_partial :: file_exists_relay
  @type not_file_exists_error ::
    {false, {:file, :exists}, not_file_exists_relay_partial}
    | file_exists_error

  @spec not_file_exists?(Server.idt, File.idt) ::
    {true, not_file_exists_relay}
    | not_file_exists_error
  def not_file_exists?(server, file) do
    henforce_not(file_exists?(server, file), {:file, :exists})
  end

  @type pftp_enabled_relay :: %{pftp: PublicFTP.t, server: Server.t}
  @type pftp_enabled_relay_partial :: pftp_enabled_relay
  @type pftp_enabled_error ::
    {false, {:pftp, :disabled}, pftp_enabled_relay_partial}
    | pftp_exists_error
    | ServerHenforcer.server_exists_error

  @spec pftp_enabled?(Server.idt | PublicFTP.t) ::
    {true, pftp_enabled_relay}
    | pftp_enabled_error
  def pftp_enabled?(server_id = %Server.ID{}) do
    henforce ServerHenforcer.server_exists?(server_id) do
      pftp_enabled?(relay.server)
    end
  end

  def pftp_enabled?(server = %Server{}) do
    henforce pftp_exists?(server) do
      pftp_enabled?(relay.pftp)
    end
  end

  def pftp_enabled?(%PublicFTP{is_active: true}),
    do: reply_ok()
  def pftp_enabled?(%PublicFTP{is_active: false}),
    do: reply_error({:pftp, :disabled})

  @type pftp_disabled_relay ::
    %{pftp: PublicFTP.t, server: Server.t}
  @type pftp_disabled_relay_partial :: %{server: Server.t, pftp: PublicFTP.t}
  @type pftp_disabled_error ::
    {false, {:pftp, :enabled}, pftp_disabled_relay_partial}
    | pftp_exists_error
    | ServerHenforcer.server_exists_error

  @spec pftp_disabled?(Server.idt | PublicFTP.t) ::
    {true, pftp_disabled_relay}
    | pftp_disabled_error
  @doc """
  Verifies whether a PublicFTP server is disabled.

  It may be disabled if:
  - There's an entry on the database, but the `is_active` field is `false`
  - There's no entry on the database.
  """
  def pftp_disabled?(server_id = %Server.ID{}) do
    henforce ServerHenforcer.server_exists?(server_id) do
      pftp_disabled?(relay.server)
    end
  end

  def pftp_disabled?(server = %Server{}) do
    case pftp_exists?(server) do
      {true, relay} ->
        wrap_relay(pftp_disabled?(relay.pftp), relay)
      {false, _, relay} ->
        reply_ok(relay)
    end
  end

  def pftp_disabled?(%PublicFTP{is_active: false}),
    do: reply_ok()
  def pftp_disabled?(%PublicFTP{is_active: true}),
    do: reply_error({:pftp, :enabled})

  @type can_add_file_relay ::
    %{
      file: File.t,
      pftp: PublicFTP.t,
      server: Server.t,
      entity: Entity.t,
      storage: Storage.t
    }
  @type can_add_file_error ::
    pftp_enabled_error
    | not_file_exists_error
    | EntityHenforcer.owns_server_error
    | FileHenforcer.belongs_to_server_error

  @spec can_add_file?(Entity.id, Server.id, File.id) ::
    {true, can_add_file_relay}
    | can_add_file_error
  @doc """
  Verifies whether a file can be added to the server's PublicFTP.
  Among other things, verifies that:
  - The PublicFTP server is enabled
  - The file is not already on the PublicFTP
  - The entity owns that server
  - The file belongs to that server.
  """
  def can_add_file?(entity_id, server_id, file_id) do
    with \
      {true, r1} <- pftp_enabled?(server_id),
      server = r1.server,
      {true, r2} <- not_file_exists?(server, file_id),
      file = r2.file,
      {true, r3} <- EntityHenforcer.owns_server?(entity_id, server),
      {true, r4} <- FileHenforcer.belongs_to_server?(file, server)
    do
      reply_ok(relay([r1, r2, r3, r4]))
    end
  end

  @type can_remove_file_relay ::
    %{
      file: File.t,
      pftp: PublicFTP.t,
      pftp_file: PublicFTP.File.t,
      server: Server.t,
      entity: Entity.t
    }
  @type can_remove_file_error ::
    pftp_enabled_error
    | file_exists_error
    | EntityHenforcer.owns_server_error

  @spec can_remove_file?(Entity.id, Server.id, File.id) ::
    {true, can_remove_file_relay}
    | can_remove_file_error
  @doc """
  Verifies whether a file can be removed from a PublicFTP server.
  Among other things, verifies that:
  - The PublicFTP server is enabled
  - The file exists on the PublicFTP
  - The PublicFTP server belongs to the entity
  """
  def can_remove_file?(entity_id, server_id, file_id) do
    with \
      {true, r1} <- pftp_enabled?(server_id),
      server = r1.server,
      {true, r2} <- file_exists?(server, file_id),
      {true, r3} <- EntityHenforcer.owns_server?(entity_id, server)
    do
      reply_ok(relay([r1, r2, r3]))
    end
  end

  @type can_enable_server_relay :: %{entity: Entity.t, server: Server.t}
  @type can_enable_server_error ::
    pftp_exists_error
    | pftp_disabled_error

  @spec can_enable_server?(Entity.id, Server.id) ::
    {true, can_enable_server_relay}
    | can_enable_server_error
  @doc """
  Henforces an Entity can enable a PublicFTP server. This is the case if:

  - The PublicFTP server is disabled;
  - The Entity owns that server
  """
  def can_enable_server?(entity_id, server_id) do
    with \
      {true, r1} <- pftp_disabled?(server_id),
      server = r1.server,
      {true, r2} <- EntityHenforcer.owns_server?(entity_id, server)
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type can_disable_server_relay ::
    %{pftp: PublicFTP.t, entity: Entity.t, server: Server.t}
  @type can_disable_server_error ::
    pftp_enabled_error
    | EntityHenforcer.owns_server_error

  @spec can_disable_server?(Entity.id, Server.id) ::
    {true, can_disable_server_relay}
    | can_disable_server_error
  @doc """
  Henforcers an Entity can disable a PublicFTP server. This is the case if:

  - The PublicFTP server is enabled;
  - The Entity owns that server.
  """
  def can_disable_server?(entity_id, server_id) do
    with \
      {true, r1} <- pftp_enabled?(server_id),
      server = r1.server,
      {true, r2} <- EntityHenforcer.owns_server?(entity_id, server)
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type valid_network_relay :: NetworkHenforcer.network_exists_relay
  @type valid_network_relay_partial :: %{}
  @type valid_network_error ::
    {false, {:network, :invalid}, valid_network_relay_partial}
    | NetworkHenforcer.network_exists_error

  @doc """
  PFTP downloads must only happen on the Internet (public network) or within a
  storyline network. LANs or Mission networks shall not pass.
  """
  def valid_network?(network_id = %Network.ID{}) do
    henforce NetworkHenforcer.network_exists?(network_id) do
      valid_network?(relay.network)
    end
  end

  def valid_network?(network = %Network{type: :internet}) do
    reply_ok()
    |> wrap_relay(%{network: network})
  end
  def valid_network?(network = %Network{type: :story}) do
    reply_ok()
    |> wrap_relay(%{network: network})
  end
  def valid_network?(%Network{type: _}),
    do: reply_error({:network, :invalid})
end
