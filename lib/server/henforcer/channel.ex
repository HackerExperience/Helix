defmodule Helix.Server.Henforcer.Channel do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Network
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  @spec validate_gateway(Entity.id, Server.id) ::
    :ok
    | {:error, {:server, :bad_owner | :not_assembled}}
  def validate_gateway(entity_id, gateway_id) do
    with \
      :ok <- account_owns_server_check(entity_id, gateway_id),
      :ok <- server_functioning_check(gateway_id)
    do
      :ok
    end
  end

  @spec validate_server(Server.id, Server.password, Network.id, IPv4.t) ::
    :ok
    | {:error, {:server, :bad_password | :not_assembled | :not_found}}
    | {:error, {:nip, :not_found}}
  def validate_server(server_id, password, network_id, ip) do
    with \
      :ok <- server_exists_check(server_id),
      :ok <- server_functioning_check(server_id),
      :ok <- server_password_check(server_id, password),
      :ok <- server_nip_check(server_id, network_id, ip)
    do
      :ok
    end
  end

  @spec account_owns_server_check(Entity.id, Server.id) ::
    :ok
    | {:error, {:server, :bad_owner}}
  defp account_owns_server_check(entity_id, server_id) do
    owner = EntityQuery.fetch_by_server(server_id)

    owner && (owner.entity_id == entity_id)
    && :ok
    || {:error, {:server, :bad_owner}}
  end

  @spec server_password_check(Server.idtb, Server.password) ::
    :ok
    | {:error, {:server, :bad_password}}
  defp server_password_check(%Server{password: password}, password),
    do: :ok
  defp server_password_check(id = %Server.ID{}, password),
    do: server_password_check(ServerQuery.fetch(id), password)
  defp server_password_check(_, _),
    do: {:error, {:server, :bad_password}}

  @spec server_exists_check(Server.id) ::
    :ok
    | {:error, :not_found}
  defp server_exists_check(server_id) do
    ServerHenforcer.exists?(server_id)
    && :ok
    || {:error, {:server, :not_found}}
  end

  @spec server_functioning_check(Server.id) ::
    :ok
    | {:error, {:server, :not_assembled}}
  defp server_functioning_check(server_id) do
    ServerHenforcer.functioning?(server_id)
    && :ok
    || {:error, {:server, :not_assembled}}
  end

  defp server_nip_check(server_id, network_id, ip) do
    {:ok, [server_nip]} = CacheQuery.from_server_get_nips(server_id)

    (server_nip.network_id == network_id && server_nip.ip == ip)
    && :ok
    || {:error, {:nip, :not_found}}
  end
end
