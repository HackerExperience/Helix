defmodule Helix.Test.Network.Setup do

  alias Ecto.Changeset
  alias Helix.Network.Internal.Bounce, as: BounceInternal
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Network.Repo, as: NetworkRepo

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet NetworkHelper.internet_id()

  @doc """
  See doc on `fake_tunnel/1`
  """
  def tunnel(opts \\ []) do
    {tunnel, related} = fake_tunnel(opts)

    # Insert Tunnel
    inserted =
      tunnel
      |> NetworkRepo.insert!()
      |> Tunnel.format()

    # Insert Links
    inserted
    |> Link.create()
    |> Enum.each(&NetworkRepo.insert/1)

    {inserted, related}
  end

  def tunnel!(opts \\ []) do
    {tunnel, _} = tunnel(opts)
    tunnel
  end

  @doc """
  - tunnel_id: set a specific tunnel_id
  - network_id: set a specific network_id. Defaults to the internet.
  - bounce_id: set Bounce ID. Defaults to nil (no bounce).
  - gateway_id: set the tunnel gateway. Server.id
  - target_id: set the tunnel target. Server.id
  - fake_servers: If true, will not create the corresponding servers. Useful
      when they are not actually needed. Defaults to false.

  Related: gateway :: Server.(id|t), target :: Server.(id|t)
    (When `fake_servers` is true, it will only return the server ids.)
  """
  def fake_tunnel(opts \\ []) do
    {gateway_id, target_id, related} =
      if opts[:fake_servers] do
        gateway_id = Keyword.get(opts, :gateway_id, ServerHelper.id())
        target_id = Keyword.get(opts, :target_id, ServerHelper.id())
        related = %{gateway: gateway_id, target: target_id}

        {gateway_id, target_id, related}
      else
        gateway = ServerSetup.create_or_fetch(opts[:gateway_id])
        target = ServerSetup.create_or_fetch(opts[:target_id])
        related = %{gateway: gateway, target: target}

        {gateway.server_id, target.server_id, related}
      end

    bounce_id = Keyword.get(opts, :bounce_id, nil)
    network_id = Keyword.get(opts, :network_id, @internet)
    tunnel_id = Keyword.get(opts, :tunnel_id, NetworkHelper.tunnel_id())

    bounce =
      if bounce_id do
        BounceInternal.fetch(bounce_id)
      else
        nil
      end

    tunnel_params =
      %{
        network_id: network_id,
        gateway_id: gateway_id,
        target_id: target_id
      }

    changeset = Tunnel.create(tunnel_params, bounce)
    tunnel = Changeset.apply_changes(changeset)

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

    connection_id =
      Keyword.get(opts, :connection_id, NetworkHelper.connection_id())
    type = Keyword.get(opts, :type, :ssh)
    meta = Keyword.get(opts, :meta, nil)

    connection =
      %Connection{
        connection_id: connection_id,
        tunnel_id: tunnel.tunnel_id,
        connection_type: type,
        meta: meta
      }

    {connection, %{tunnel: tunnel}}
  end

  @doc """
  See doc on `fake_network/1`
  """
  def network(opts \\ []) do
    {_, related = %{changeset: changeset}} = fake_network(opts)
    {:ok, inserted} = NetworkRepo.insert(changeset)
    {inserted, related}
  end

  @doc """
  - network_id: specify network id. Defaults to random one
  - name: Specify network name. Defaults to "LAN"
  - type: Set network type. Defaults to `lan`.
  """
  def fake_network(opts \\ []) do
    network_id = Keyword.get(opts, :network_id, NetworkHelper.id())
    name = Keyword.get(opts, :name, "LAN")
    type = Keyword.get(opts, :type, :lan)

    network =
      %Network{
        network_id: network_id,
        name: name,
        type: type
      }

    related = %{changeset: Changeset.change(network)}

    {network, related}
  end

  @doc """
  Generates a random Tunnel.ID
  """
  def tunnel_id,
    do: NetworkHelper.tunnel_id()
end
