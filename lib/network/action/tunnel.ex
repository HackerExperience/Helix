defmodule Helix.Network.Action.Tunnel do

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Internal.Tunnel, as: TunnelInternal
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer

  @spec connect(Network.t, Server.id, Server.id, [Server.id], term) ::
    {:ok, Connection.t, [event :: struct]}
    | {:error, Changeset.t}
  @doc """
  Starts a connection between `gateway` and `destination` through `network`.

  The connection type is `connection_type`, and it shall pass by `bounces`.

  If there is already a tunnel with this configuration, it'll be reused,
  otherwise a new Tunnel will be created
  """
  def connect(network, gateway, destination, bounces, connection_type) do
    tunnel = TunnelInternal.get_tunnel(network, gateway, destination, bounces)
    context = if tunnel do
      {:ok, tunnel}
    else
      create_tunnel(network, gateway, destination, bounces)
    end

    with {:ok, tunnel} <- context do
      TunnelInternal.start_connection(tunnel, connection_type)
    end
  end

  @spec create_tunnel(Network.t, Server.id, Server.id, [Server.id]) ::
    {:ok, Tunnel.t}
    | {:error, Changeset.t}
  # Checks if gateway, destination and bounces are valid servers, and if they
  # are connected to network
  # Note that those are more or less redundant since the interface (WS or HTTP)
  # have to convert the input IPs into server_ids anyway
  defp create_tunnel(network, gateway, destination, bounces) do
    with \
      exists? = &ServerHenforcer.server_exists?/1,
      true <- exists?.(gateway) || {:gateway_id, :notfound},
      true <- exists?.(destination) || {:destination_id, :notfound},
      true <- Enum.all?(bounces, exists?) || {:links, :notfound},
      connected? = &NetworkHenforcer.node_connected?(&1, network.network_id),
      true <- connected?.(gateway) || {:gateway_id, :disconnected},
      true <- connected?.(destination) || {:destination_id, :disconnected},
      true <- Enum.all?(bounces, connected?) || {:links, :disconnected}
    do
      TunnelInternal.create(network, gateway, destination, bounces)
    else
      {field, :notfound} ->
        # TODO: produce error somewhere else ?
        changeset =
          %Tunnel{}
          |> Changeset.change()
          |> Changeset.add_error(field, "doesnt exist")
        {:error, changeset}
      {field, :disconnected} ->
        # TODO: produce error somewhere else ?
        changeset =
          %Tunnel{}
          |> Changeset.change()
          |> Changeset.add_error(field, "not connected to the network")
        {:error, changeset}
    end
  end

  @spec delete(Tunnel.t | Tunnel.id) ::
    :ok
  defdelegate delete(tunnel),
    to: TunnelInternal

  @spec start_connection(Tunnel.t, term) ::
    {:ok, Connection.t, [event :: struct]}
    | {:error, Ecto.Changeset.t}
  defdelegate start_connection(tunnel, connection_type),
    to: TunnelInternal

  @spec close_connection(Connection.t, Connection.close_reasons) ::
    [event :: struct]
  defdelegate close_connection(connection, reason \\ :normal),
    to: TunnelInternal
end
