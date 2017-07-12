defmodule Helix.Server.Henforcer.Channel do

  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Network.Repo, as: NetworkRepo
  alias Helix.Network.Action.Tunnel, as: TunnelAction

  def join_external?(account_id, server_id, gateway_id, password) do
    with \
      true <- ServerHenforcer.exists?(server_id) || {:error, :not_found},
      true <- ServerHenforcer.exists?(gateway_id) || {:error, :not_found},
      true <- ServerHenforcer.functioning?(server_id) || {:error, :not_assembled},
      true <- ServerHenforcer.functioning?(gateway_id) || {:error, :not_assembled},
      owner = EntityQuery.fetch_server_owner(gateway_id),
      account_id = EntityQuery.get_entity_id(account_id),
      owner_id = EntityQuery.get_entity_id(owner),
      true <- owner_id == account_id || {:error, :not_owner},

      destination = %{} <- ServerQuery.fetch(server_id),
      true <- password == destination.password || {:error, :password},

      # FIXME: Using other Repo directly, nono
      network = NetworkRepo.get(Network, "::"),
      {:ok, connection, events} <- TunnelAction.connect(
        network,
        gateway_id,
        server_id,
        [],
        "ssh"),
      tunnel = NetworkRepo.preload(connection, :tunnel).tunnel
    do
      # FIXME charlots
      Helix.Event.emit(events)

      assigns = [
        %{key: :servers, data: %{gateway: gateway_id, destination: server_id}},
        %{key: :tunnel, data: tunnel}
      ]
      {:ok, assigns}
    else
      error ->
        error
    end
  end

  def join_connected?(account_id, server_id, gateway_id) do
    # FIXME: this doesn't belongs here
    get_tunnel_for_ssh = fn ->
      connections_between = TunnelQuery.connections_on_tunnels_between(
      gateway_id,
      server_id)

      case Enum.find(connections_between, &(&1.connection_type == "ssh")) do
        connection = %{} ->
          {:ok, TunnelQuery.fetch(connection.tunnel_id)}
        _ ->
          {:error, :not_connected}
      end
    end

    with \
      true <- ServerHenforcer.exists?(server_id) || {:error, :not_found},
      true <- ServerHenforcer.exists?(gateway_id) || {:error, :not_found},
      true <- ServerHenforcer.functioning?(server_id) || {:error, :not_assembled},
      true <- ServerHenforcer.functioning?(gateway_id) || {:error, :not_assembled},
      owner = EntityQuery.fetch_server_owner(gateway_id),
      account_id = EntityQuery.get_entity_id(account_id),
      owner_id = EntityQuery.get_entity_id(owner),
      true <- owner_id == account_id || {:error, :not_owner},
      {:ok, tunnel} <- get_tunnel_for_ssh.()
    do
      assigns = [
        %{key: :servers, data: %{gateway: gateway_id, destination: server_id}},
        %{key: :tunnel, data: tunnel}
      ]
      {:ok, assigns}
    else
      error ->
        error
    end
  end

  def join_own_gateway?(account_id, server_id) do
    with \
      true <- ServerHenforcer.exists?(server_id) || {:error, :not_found},
      true <- ServerHenforcer.functioning?(server_id) || {:error, :not_assembled},
      owner = EntityQuery.fetch_server_owner(server_id),
      owner_id = EntityQuery.get_entity_id(owner),
      account_id = EntityQuery.get_entity_id(account_id),
      true <- owner_id == account_id || {:error, :not_owner}
    do
      assigns = [
        %{servers: %{gateway: server_id, destination: server_id}}
      ]
      {:ok, assigns}
    else
      error ->
        error
    end
  end
end
