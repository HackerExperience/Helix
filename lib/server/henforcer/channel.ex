defmodule Helix.Server.Henforcer.Channel do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  @spec account_owns_server_check(Account.t, Server.id) ::
    :ok
    | {:error, :not_owner}
  def account_owns_server_check(account, server_id) do
    owner = EntityQuery.fetch_server_owner(server_id)
    owner_id = EntityQuery.get_entity_id(owner)

    account_id = EntityQuery.get_entity_id(account)

    (owner_id == account_id)
    && :ok
    || {:error, :not_owner}
  end

  @spec server_password_check(Server.t | Server.id, String.t) ::
    :ok
    | {:error, :password}
  def server_password_check(%Server{password: password}, password),
    do: :ok
  def server_password_check(server_id, password) when is_binary(server_id),
    do: server_password_check(ServerQuery.fetch(server_id), password)
  def server_password_check(_, _),
    do: {:error, :password}

  @spec server_exists_check(Server.id) ::
    :ok
    | {:error, :not_found}
  def server_exists_check(server_id) do
    ServerHenforcer.exists?(server_id)
    && :ok
    || {:error, :not_found}
  end

  @spec server_functioning_check(Server.id) ::
    :ok
    | {:error, :not_assembled}
  def server_functioning_check(server_id) do
    ServerHenforcer.functioning?(server_id)
    && :ok
    || {:error, :not_assembled}
  end
end
