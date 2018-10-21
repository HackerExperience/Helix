defmodule Helix.Log.Henforcer.Log.Recover do

  import Helix.Henforcer

  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Model.File
  alias Helix.Log.Henforcer.Log, as: LogHenforcer
  alias Helix.Log.Model.Log

  @type can_recover_global_relay :: %{gateway: Server.t, recover: File.t}
  @type can_recover_global_relay_partial :: map
  @type can_recover_global_error ::
    ServerHenforcer.server_exists_error
    | exists_recover_error

  @spec can_recover_global?(Server.id) ::
    {true, can_recover_global_relay}
    | can_recover_global_error
  @doc """
  Henforces that the player can start a global LogRecover process.

  In order to recover globally, all a user needs to have is:
  - SSH access to the server
  - a valid LogRecover file on his gateway filesystem
  """
  def can_recover_global?(gateway_id) do
    with \
      {true, r1} <- ServerHenforcer.server_exists?(gateway_id),
      r1 = replace(r1, :server, :gateway),
      gateway = r1.gateway,
      {true, r2} <- exists_recover?(gateway),
      r2 = replace(r2, :file, :recover, only: true)
    do
      [r1, r2]
      |> relay()
      |> reply_ok()
    end
  end

  @type can_recover_custom_relay ::
    %{log: Log.t, gateway: Server.t, recover: File.t}
  @type can_recover_custom_relay_partial :: map
  @type can_recover_custom_error ::
    LogHenforcer.log_exists_error
    | LogHenforcer.belongs_to_server_error
    | ServerHenforcer.server_exists_error
    | exists_recover_error

  @spec can_recover_custom?(Log.id, Server.id, Server.id) ::
    {true, can_recover_custom_relay}
    | can_recover_custom_error
  @doc """
  Henforces that the player can start a custom LogRecover process.

  In order to recover a specific (custom) log, the player must have the same
  requirements of a `global` recover (SSH access and valid LogRecover file), and
  also the given `log_id` must exist, and it must exist on the target server.
  """
  def can_recover_custom?(log_id = %Log.ID{}, gateway_id, target_id) do
    with \
      {true, r1} <- LogHenforcer.log_exists?(log_id),
      log = r1.log,

      {true, _} <- LogHenforcer.belongs_to_server?(log, target_id),

      {true, r2} <- ServerHenforcer.server_exists?(gateway_id),
      r2 = replace(r2, :server, :gateway),
      gateway = r2.gateway,

      {true, r3} <- exists_recover?(gateway),
      r3 = replace(r3, :file, :recover, only: true)
    do
      [r1, r2, r3]
      |> relay()
      |> reply_ok()
    end
  end

  @type exists_recover_relay :: FileHenforcer.exists_software_module_relay
  @type exists_recover_relay_partial ::
    FileHenforcer.exists_software_module_relay_partial
  @type exists_recover_error ::
    {false, {:recover, :not_found}, exists_recover_relay_partial}

  @spec exists_recover?(Server.t) ::
    {true, exists_recover_relay}
    | exists_recover_error
  @doc """
  Ensures that exists a Recover file on `server`, sorting the result by `module`
  (only `:log_recover` in this context).

  It's simply a wrapper over `FileHenforcer.exists_software_module?` used to
  generate a more meaningful error message ("recover_not_found") instead of
  "module_not_found".
  """
  def exists_recover?(server = %Server{}) do
    henforce_else(
      FileHenforcer.exists_software_module?(:log_recover, server),
      {:recover, :not_found}
    )
  end
end
