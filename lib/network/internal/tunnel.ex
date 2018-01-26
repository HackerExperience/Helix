defmodule Helix.Network.Internal.Tunnel do

  alias Helix.Server.Model.Server
  alias Helix.Network.Internal.Bounce, as: BounceInternal
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  @spec fetch(Tunnel.id) ::
    Tunnel.t
    | nil
  def fetch(tunnel_id) do
    result =
      tunnel_id
      |> Tunnel.Query.by_tunnel()
      |> Repo.one()

    with tunnel = %Tunnel{} <- result do
      tunnel
      |> load_bounce()
      |> Tunnel.format()
    end
  end

  @spec fetch_connection(Connection.id) ::
    Connection.t
    | nil
  def fetch_connection(id),
    do: Repo.get(Connection, id)

  @spec get_tunnel(Server.id, Server.id, Network.idt, Tunnel.bounce_idt) ::
    Tunnel.t
    | nil
  @doc """
  Returns the tunnel identified by the given params
  """
  def get_tunnel(gateway_id, endpoint_id, network, bounce) do
    result =
      gateway_id
      |> Tunnel.Query.by_gateway()
      |> Tunnel.Query.by_target(endpoint_id)
      |> Tunnel.Query.by_network(network)
      |> Tunnel.Query.by_bounce(bounce, nullable: true)
      |> Repo.one()

    with tunnel = %Tunnel{} <- result do
      tunnel
      |> load_bounce()
      |> Tunnel.format()
    end
  end

  @spec get_tunnels_on_bounce(Bounce.id) ::
    [Tunnel.t]
  def get_tunnels_on_bounce(bounce_id) do
    bounce_id
    |> Tunnel.Query.by_bounce(nullable: false)
    |> Repo.all()
    |> Enum.map(&Tunnel.format/1)
  end

  @spec get_links(Tunnel.idt) ::
    [Link.t]
  @doc """
  Returns all links going within the tunnel. Result is sorted (as defined by the
  underlying Bounce sequence).

  NOTE: This returns a list of Link.t`. On most cases you'll want `get_hops/1`.
  """
  def get_links(tunnel) do
    tunnel
    |> Link.Query.by_tunnel()
    |> Link.Query.order_by_sequence()
    |> Repo.all()
  end

  @doc """
  Returns all bounce hops on the tunnel. Return tuple includes Server.ID and NIP

  NOTE: If the association is not loaded, `get_hops/1` will return the initial
  format, which is pretty much invalid. It's up to the caller to make sure the
  Bounce association has been loaded. Use `load_bounce/1`.

  NOTE: hops are intermediary nodes. It does not include the Tunnel's
  `gateway_id` and `target_id`.
  """
  def get_hops(%Tunnel{bounce_id: nil}),
    do: []
  def get_hops(tunnel = %Tunnel{bounce: %Bounce{}}),
    do: Tunnel.get_hops(tunnel)

  @doc """
  Returns all connections that exist within the tunnel.
  """
  def get_connections(tunnel = %Tunnel{}) do
    tunnel
    |> load_connections()
    |> Map.fetch!(:connections)
  end

  @doc """
  Given a connection, return its Tunnel. It may be loaded, in which case this
  method simply retrieves the value from the struct. Otherwise, it loads the
  tunnel and then returns the underlying value.
  """
  def get_tunnel(connection = %Connection{tunnel: %Tunnel{}}),
    do: connection.tunnel
  def get_tunnel(connection = %Connection{tunnel: _}) do
    connection
    |> load_tunnel()
    |> Map.fetch!(:tunnel)
  end

  @spec create(Network.t, Server.id, Server.id, Tunnel.bounce) ::
    {:ok, Tunnel.t}
    | {:error, :internal}
  @doc """
  Creates a new tunnel
  """
  def create(network, gateway_id, target_id, bounce) do
    Repo.transaction fn ->
      with \
        {:ok, tunnel} <- create_tunnel(network, gateway_id, target_id, bounce),
        tunnel = Tunnel.format(tunnel),
        :ok <- create_links(tunnel)
      do
        tunnel
      else
        _ ->
          Repo.rollback(:internal)
      end
    end
  end

  @spec create_tunnel(Network.t, Server.id, Server.id, Tunnel.bounce) ::
    {:ok, Tunnel.t}
    | {:error, Tunnel.changeset}
  defp create_tunnel(network, gateway_id, endpoint_id, bounce) do
    params = %{
      network_id: network.network_id,
      gateway_id: gateway_id,
      target_id: endpoint_id
    }

    params
    |> Tunnel.create(bounce)
    |> Repo.insert()
  end

  @spec create_links(Tunnel.t) ::
    :ok
    | :error
  defp create_links(tunnel = %Tunnel{}) do
    result =
      tunnel
      |> Link.create()
      |> Enum.map(&Repo.insert/1)

    case Enum.find(result, fn {status, _} -> status == :error end) do
      nil ->
        :ok

      {:error, _} ->
        :error
    end
  end
  @spec delete(Tunnel.t) ::
    :ok
  def delete(tunnel) do
    Repo.delete(tunnel)

    :ok
  end

  @spec tunnels_between(Server.id, Server.id, Network.id | nil) ::
    [Tunnel.t]
  @doc """
  Checks whether there is a tunnel between `gateway_id` and `target_id`.
  """
  def tunnels_between(gateway_id, endpoint_id, network_id \\ nil) do
    query =
      Tunnel
      |> Tunnel.Query.by_gateway(gateway_id)
      |> Tunnel.Query.by_target(endpoint_id)

    # Filter by `network_id` (if specified)
    query =
      network_id
      && Tunnel.Query.by_network(query, network_id)
      || query

    query
    |> Repo.all()
    |> Enum.map(&load_bounce/1)
    |> Enum.map(&Tunnel.format/1)
  end

  @spec connections_through_node(Server.idt) ::
    [Connection.t]
  @doc """
  Returns all connections going through `server_id` (inbound or outbound).
  """
  def connections_through_node(server_id) do
    server_id
    |> Connection.Query.through_node()
    |> Repo.all()
  end

  @spec inbound_connections(Server.idt) ::
    [Connection.t]
  @doc """
  Returns all connections that are inbound to `server_id`.

  It may include connections that did not *originate* on `server_id`.
  """
  def inbound_connections(server_id) do
    server_id
    |> Connection.Query.inbound_to()
    |> Repo.all()
  end

  @spec outbound_connections(Server.idt) ::
    [Connection.t]
  @doc """
  Returns all connections that are outbound from `server_id`.

  It may include connections that do not have `server_id` as its *final* target.
  """
  def outbound_connections(server_id) do
    server_id
    |> Connection.Query.outbound_from()
    |> Repo.all()
  end

  @spec connections_originating_from(Server.idt) ::
    [Connection.t]
  @doc """
  Returns all connections that originated at `gateway_id`, i.e. `gateway_id` is
  the very first hop.
  """
  def connections_originating_from(gateway_id) do
    gateway_id
    |> Tunnel.Query.by_gateway()
    |> Tunnel.Query.select_connection()
    |> Repo.all()
  end

  @spec connections_destined_to(Server.idt) ::
    [Connection.t]
  @doc """
  Returns all connections that have `target_id` as its final target.
  """
  def connections_destined_to(target_id) do
    target_id
    |> Tunnel.Query.by_target()
    |> Tunnel.Query.select_connection()
    |> Repo.all()
  end

  @spec start_connection(Tunnel.t, Connection.type, Connection.meta) ::
    {:ok, Connection.t}
    | {:error, Ecto.Changeset.t}
  def start_connection(tunnel, connection_type, meta \\ nil) do
    result =
      tunnel
      |> Connection.create(connection_type, meta)
      |> Repo.insert()

    with {:ok, connection} <- result do
      {:ok, connection}
    end
  end

  @spec close_connection(Connection.t) ::
    :ok
  @doc """
  Closes `connection`

  This can simply mean deleting the connection and, as an event reaction,
  canceling any action that depends on this process.

  `reason` is an atom to "justify" why the connection is being closed.
  This is used by the event handlers to provide meaningful side-effects based on
  what happened.

  The current reasons are valid: #{inspect Connection.close_reasons()}
  """
  def close_connection(connection = %Connection{}) do
    Repo.delete!(connection)

    :ok
  end

  @spec connections_on_tunnels_between(Server.id, Server.id) ::
    [Connection.t]
  def connections_on_tunnels_between(gateway_id, endpoint_id) do
    gateway_id
    |> Connection.Query.from_gateway_to_endpoint(endpoint_id)
    |> Repo.all()
  end

  @spec get_remote_endpoints([Server.idt]) ::
    Tunnel.gateway_endpoints
  def get_remote_endpoints(servers) do
    servers
    |> Tunnel.Query.get_remote_endpoints()
    |> Repo.all()
    |> Enum.map(&Tunnel.format/1)
    |> Enum.reduce(%{}, fn tunnel, acc ->
      Map.put(
        acc, tunnel.gateway_id, [tunnel] ++ Map.get(acc, tunnel.gateway_id, [])
      )
    end)
  end

  @spec load_bounce(Tunnel.t) ::
    Tunnel.t
  defp load_bounce(tunnel = %Tunnel{bounce: %Bounce{}}),
    do: Tunnel.format(tunnel)
  defp load_bounce(tunnel = %Tunnel{bounce_id: nil}),
    do: Tunnel.format(tunnel)
  defp load_bounce(tunnel = %Tunnel{}),
    do: %{tunnel| bounce: BounceInternal.fetch(tunnel.bounce_id)}

  @spec load_connections(Tunnel.t) ::
    Tunnel.t
  defp load_connections(tunnel = %Tunnel{}),
    do: Repo.preload(tunnel, :connections)

  @spec load_tunnel(Connection.t) ::
    Connection.t
  defp load_tunnel(connection = %Connection{}),
    do: Repo.preload(connection, :tunnel)
end
