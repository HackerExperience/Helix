defmodule Helix.Log.Henforcer.Log.Forge do

  import Helix.Henforcer

  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Log.Model.Log
  alias Helix.Log.Henforcer.Log, as: LogHenforcer

  @type can_edit_relay :: %{log: Log.t, gateway: Server.t, forger: File.t}
  @type can_edit_relay_partial :: map
  @type can_edit_error ::
    LogHenforcer.log_exists_error
    | LogHenforcer.belongs_to_server_error
    | ServerHenforcer.server_exists_error
    | exists_forger_error

  @spec can_edit?(Log.id, Server.id, Server.id) ::
    {true, can_edit_relay}
    | can_edit_error
  @doc """
  Henforces that the player can edit the given `log_id`.

  Among other things, it makes sure the log exists and the player have a valid
  LogForger on her gateway.
  """
  def can_edit?(log_id = %Log.ID{}, gateway_id, target_id) do
    with \
      {true, r1} <- LogHenforcer.log_exists?(log_id),
      log = r1.log,

      {true, _} <- LogHenforcer.belongs_to_server?(log, target_id),

      {true, r2} <- ServerHenforcer.server_exists?(gateway_id),
      r2 = replace(r2, :server, :gateway),
      gateway = r2.gateway,

      {true, r3} <- exists_forger?(:log_edit, gateway),
      r3 = replace(r3, :file, :forger, only: true)
    do
      [r1, r2, r3]
      |> relay()
      |> reply_ok()
    end
  end

  @type can_create_relay :: %{gateway: Server.t, forger: File.t}
  @type can_create_relay_partial :: map
  @type can_create_error ::
    ServerHenforcer.server_exists_error
    | exists_forger_error

  @spec can_create?(Server.id) ::
    {true, can_create_relay}
    | can_create_error
  @doc """
  Henforces that the player can create a log. Basically it ensures the player
  have a valid LogForger.
  """
  def can_create?(gateway_id) do
    with \
      {true, r1} <- ServerHenforcer.server_exists?(gateway_id),
      r1 = replace(r1, :server, :gateway),
      gateway = r1.gateway,
      {true, r2} <- exists_forger?(:log_create, gateway),
      r2 = replace(r2, :file, :forger, only: true)
    do
      [r1, r2]
      |> relay()
      |> reply_ok()
    end
  end

  @type exists_forger_relay :: FileHenforcer.exists_software_module_relay
  @type exists_forger_relay_partial ::
    FileHenforcer.exists_software_module_relay_partial
  @type exists_forger_error ::
    {false, {:forger, :not_found}, exists_forger_relay_partial}

  @spec exists_forger?(:log_create | :log_edit, Server.t) ::
    {true, exists_forger_relay}
    | exists_forger_error
  @doc """
  Ensures that exists a Forger file on `server`, sorting the result by `module`
  (either `:log_edit` or `:log_create` in this context).

  It's simply a wrapper over `FileHenforcer.exists_software_module?` used to
  generate a more meaningful error message ("forger_not_found") instead of
  "module_not_found".
  """
  def exists_forger?(module, server = %Server{}) do
    henforce_else(
      FileHenforcer.exists_software_module?(module, server),
      {:forger, :not_found}
    )
  end
end
