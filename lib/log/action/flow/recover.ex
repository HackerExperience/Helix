# credo:disable-for-this-file Credo.Check.Refactor.FunctionArity
defmodule Helix.Log.Action.Flow.Recover do

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Tunnel
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Log.Model.Log

  alias Helix.Log.Process.Recover, as: LogRecoverProcess

  @spec global(
    Server.t,
    Server.t,
    File.t,
    Entity.id,
    {Tunnel.t, Connection.ssh} | nil,
    Event.relay
  ) ::
    term
  def global(
    gateway = %Server{},
    endpoint = %Server{},
    recover = %File{software_type: :log_recover},
    entity_id = %Entity.ID{},
    conn,
    relay
  ) do
    start_process(gateway, endpoint, nil, recover, entity_id, conn, relay)
  end

  @spec custom(
    Server.t,
    Server.t,
    Log.t,
    File.t,
    Entity.id,
    {Tunnel.t, Connection.ssh} | nil,
    Event.relay
  ) ::
    term
  def custom(
    gateway = %Server{},
    endpoint = %Server{},
    log = %Log{},
    recover = %File{software_type: :log_recover},
    entity_id = %Entity.ID{},
    conn,
    relay
  ) do
    start_process(
      gateway, endpoint, log, recover, entity_id, conn, relay
    )
  end

  defp start_process(
    gateway = %Server{},
    endpoint = %Server{},
    log,
    recover = %File{software_type: :log_recover},
    entity_id = %Entity.ID{},
    conn_info,
    relay
  ) do
    method =
      if is_nil(log) do
        :global
      else
        :custom
      end

    {network_id, ssh} =
      if is_nil(conn_info) do
        {nil, nil}
      else
        {tunnel, ssh} = conn_info
        {tunnel.network_id, ssh}
      end

    params = %{}

    meta =
      %{
        recover: recover,
        log: log,
        method: method,
        ssh: ssh,
        entity_id: entity_id,
        network_id: network_id
      }

    LogRecoverProcess.execute(gateway, endpoint, params, meta, relay)
  end
end
