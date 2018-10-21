# credo:disable-for-this-file Credo.Check.Refactor.FunctionArity
defmodule Helix.Log.Action.Flow.Forge do

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Tunnel
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Log.Model.Log

  alias Helix.Log.Process.Forge, as: LogForgeProcess

  @spec create(
    Server.t,
    Server.t,
    Log.info,
    File.t,
    {Tunnel.t, Connection.ssh} | nil,
    Event.relay
  ) ::
    term
  def create(
    gateway = %Server{},
    endpoint = %Server{},
    log_info,
    forger = %File{software_type: :log_forger},
    conn,
    relay
  ) do
    start_process(gateway, endpoint, nil, log_info, forger, nil, conn, relay)
  end

  @spec edit(
    Server.t,
    Server.t,
    Log.t,
    Log.info,
    File.t,
    Entity.id,
    {Tunnel.t, Connection.ssh} | nil,
    Event.relay
  ) ::
    term
  def edit(
    gateway = %Server{},
    endpoint = %Server{},
    log = %Log{},
    log_info,
    forger = %File{software_type: :log_forger},
    entity_id = %Entity.ID{},
    conn,
    relay
  ) do
    start_process(
      gateway, endpoint, log, log_info, forger, entity_id, conn, relay
    )
  end

  defp start_process(
    gateway = %Server{},
    endpoint = %Server{},
    log,
    log_info,
    forger = %File{software_type: :log_forger},
    entity_id,
    conn_info,
    relay
  ) do
    action =
      if is_nil(log) do
        :create
      else
        :edit
      end

    {network_id, ssh} =
      if is_nil(conn_info) do
        {nil, nil}
      else
        {tunnel, ssh} = conn_info
        {tunnel.network_id, ssh}
      end

    params = %{log_info: log_info}

    meta =
      %{
        forger: forger,
        log: log,
        action: action,
        ssh: ssh,
        entity_id: entity_id,
        network_id: network_id
      }

    LogForgeProcess.execute(gateway, endpoint, params, meta, relay)
  end
end
