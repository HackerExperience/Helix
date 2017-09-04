defmodule Helix.Test.Network.Setup do

  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Network.Repo, as: NetworkRepo

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet NetworkHelper.internet_id()

  @doc """
  See doc on `fake_tunnel/1`
  """
  def tunnel(opts \\ []) do
    {tunnel, related} = fake_tunnel(opts)
    {:ok, inserted} = NetworkRepo.insert(tunnel)
    {inserted, related}
  end

  def tunnel!(opts \\ []) do
    {tunnel, _} = tunnel(opts)
    tunnel
  end

  @doc """
  - tunnel_id: set a specific tunnel_id
  - network_id: set a specific network_id. Defaults to the internet.
  - bounces: list of bounces (Server.id). Defaults to empty.
  - gateway_id: set the tunnel gateway. Server.id
  - destination_id: set the tunnel destination. Server.id
  - fake_servers: If true, will not create the corresponding servers. Useful
      when they are not actually needed. Creating servers takes some time.

  Related: gateway :: Server.(id|t), destination :: Server.(id|t)
    (When `fake_servers` is true, it will only return the server ids.)
  """
  def fake_tunnel(opts \\ []) do
    {gateway_id, destination_id, related} =
      if opts[:fake_servers] do
        gateway_id = Access.get(opts, :gateway_id, Server.ID.generate())
        destination_id = Access.get(opts, :destination_id, Server.ID.generate())
        related = %{gateway: gateway_id, destination: destination_id}

        {gateway_id, destination_id, related}
      else
        gateway = ServerSetup.create_or_fetch(opts[:gateway_id])
        destination = ServerSetup.create_or_fetch(opts[:destination_id])
        related = %{gateway: gateway, destination: destination}

        {gateway.server_id, destination.server_id, related}
      end

    bounces = Access.get(opts, :bounces, [])
    network_id = Access.get(opts, :network_id, @internet)
    tunnel_id = Access.get(opts, :tunnel_id, Tunnel.ID.generate())

    tunnel = Tunnel.create(network_id, gateway_id, destination_id, bounces)

    # Insert the tunnel_id, if specified
    tunnel =
      if opts[:tunnel_id] do
        %{tunnel| tunnel_id: tunnel_id}
      else
        tunnel
      end

    {tunnel, related}
  end

  @doc """
  Helper to create_or_fetch tunnels in a single command.
  """
  def create_or_fetch_tunnel(nil),
    do: tunnel!()
  def create_or_fetch_tunnel(tunnel_id) do
    TunnelQuery.fetch(tunnel_id)
  end

  @doc """
  See doc on `fake_connection/1`
  """
  def connection(opts \\ []) do
    {connection, related} = fake_connection(opts)
    {:ok, inserted} = NetworkRepo.insert(connection)
    {inserted, related}
  end

  def connection!(opts \\ []) do
    {connection, _} = fake_connection(opts)
    {:ok, inserted} = NetworkRepo.insert(connection)
    inserted
  end

  @doc """
  - connection_id: set a specific connection_id
  - tunnel_id: set the tunnel_id that connection belongs to.
  - type: set the connection type. Defaults to :ssh
  - meta: set the connection meta map. Defaults to nil.
  - tunnel_opts: Instructions for tunnel creation. Must be a list.

  Related: Tunnel.t
  """
  def fake_connection(opts \\ []) do
    tunnel =
      if opts[:tunnel_opts] do
        tunnel!(opts[:tunnel_opts])
      else
        create_or_fetch_tunnel(opts[:tunnel_id])
      end

    connection_id = Access.get(opts, :connection_id, Connection.ID.generate())
    type = Access.get(opts, :type, :ssh)
    meta = Access.get(opts, :meta, nil)

    connection =
      %Connection{
        connection_id: connection_id,
        tunnel_id: tunnel.tunnel_id,
        connection_type: type,
        meta: meta
      }

    {connection, %{tunnel: tunnel}}
  end
end
