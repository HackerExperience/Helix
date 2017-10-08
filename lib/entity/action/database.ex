defmodule Helix.Entity.Action.Database do
  @moduledoc """
  API used to modify the Hacked Database.
  """

  import HELL.Macros

  alias HELL.IPv4
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.DatabaseBankAccount
  alias Helix.Entity.Model.DatabaseServer
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  @spec add_server(Entity.idt, Network.idt, IPv4.t, Server.idt) ::
    {:ok, DatabaseServer.t}
    | {:error, DatabaseServer.changeset}
  @doc """
  Adds a new server entry to the database.

  Note that the default addition is naive, in the sense that it won't bother
  with extra information like password or notes. Modifying these extra data
  should be done by with `update_*` functions.
  """
  def add_server(entity, network, ip, server) do
    DatabaseInternal.add_server(entity, network, ip, server, :npc)
  end

  @spec add_bank_account(Entity.idt, BankAccount.t) ::
    {:ok, DatabaseBankAccount.t}
    | {:error, DatabaseBankAccount.changeset}
  @doc """
  Adds a new bank account entry to the database.

  Note that the default addition is naive, in the sense that it won't bother
  with extra information like password or token. Modifying these extra data
  should be done by with `update_*` functions.
  """
  def add_bank_account(entity, bank_account) do
    atm_ip = ServerQuery.get_ip(bank_account.atm_id, NetworkQuery.internet())
    DatabaseInternal.add_bank_account(entity, bank_account, atm_ip)
  end

  @spec update_server_password(
    Entity.idt,
    Network.idt,
    IPv4.t,
    Server.id,
    Server.password)
  ::
    {:ok, DatabaseServer.t}
    | {:error, DatabaseServer.changeset}
    | {:error, {:server, :belongs_to_entity}}
  @doc """
  Updates the password of the server entry. It is usually called when:

  - Bruteforce process has finished, and a new password was acquired
    (PasswordAcquiredEvent)
  - Player changed his server password (not implemented yet)
  """
  def update_server_password(entity, network_id, ip, server_id, password) do
    if not object_belongs_to_entity?(entity, server_id) do
      entry = fetch_or_create_server(entity, network_id, ip, server_id)

      DatabaseInternal.update_server_password(entry, password)
    else
      {:error, {:server, :belongs_to_entity}}
    end
  end

  @spec update_bank_password(Entity.idt, BankAccount.t, String.t) ::
    {:ok, DatabaseBankAccount.t}
    | {:error, DatabaseBankAccount.changeset}
    | {:error, {:bank_account, :belongs_to_entity}}
  @doc """
  Updates the password of the bank account entry.

  If the requested entry does not exist, it is created.
  """
  def update_bank_password(entity, account, password) do
    if not object_belongs_to_entity?(entity, account) do
      entry = fetch_or_create_bank_entry(entity, account)

      DatabaseInternal.update_bank_password(entry, password)
    else
      {:error, {:bank_account, :belongs_to_entity}}
    end
  end

  @spec update_bank_token(Entity.idt, BankAccount.t, BankToken.id) ::
    {:ok, DatabaseBankAccount.t}
    | {:error, DatabaseBankAccount.changeset}
    | {:error, {:bank_account, :belongs_to_entity}}
  @doc """
  Updates the token of the bank account entry.

  If the requested entry does not exist, it is created.
  """
  def update_bank_token(entity, account, token) do
    if not object_belongs_to_entity?(entity, account) do
      entry = fetch_or_create_bank_entry(entity, account)

      DatabaseInternal.update_bank_token(entry, token)
    else
      {:error, {:bank_account, :belongs_to_entity}}
    end
  end

  @spec update_bank_login(Entity.idt, BankAccount.t, BankToken.id | nil) ::
    {:ok, DatabaseBankAccount.t}
    | {:error, DatabaseBankAccount.changeset}
    | {:error, {:bank_account, :belongs_to_entity}}
  @doc """
  Updates the bank account entry after a login. This step is the one that adds
  the most information on the entry, namely, the known account balance. It also
  updates the `last_login_date` and `password` or `token`, depending on the
  login method.

  If the requested entry does not exist, it is created.
  """
  def update_bank_login(entity, account, token_id) do
    if not object_belongs_to_entity?(entity, account) do
      entry = fetch_or_create_bank_entry(entity, account)

      DatabaseInternal.update_bank_login(entry, account, token_id)
    else
      {:error, {:bank_account, :belongs_to_entity}}
    end
  end

  @spec object_belongs_to_entity?(Entity.idt, BankAccount.t | Server.id) ::
    boolean
  docp """
  Helper function to determine whether the object belongs to the given entity.

  It's useful because, in some cases, we do not want to create/update an entry
  if that entry's object already belongs to the entity. It's because of this
  function that, when the player logins on his *own* account, it won't be saved
  on the Hacked Database. Because, you know, it's the *hacked* database.
  """
  defp object_belongs_to_entity?(entity = %Entity{}, obj),
    do: object_belongs_to_entity?(entity.entity_id, obj)
  defp object_belongs_to_entity?(entity_id, acc = %BankAccount{}),
    do: EntityQuery.get_entity_id(acc.owner_id) == entity_id
  defp object_belongs_to_entity?(entity_id, server_id = %Server.ID{}) do
    owner = EntityQuery.fetch_by_server(server_id)

    owner.entity_id == entity_id
  end

  @spec delete_server(Entity.idt, Network.idt, IPv4.t) ::
    :ok
    | {:error, {:entry, :notfound}}
  @doc """
  Deletes a server entry from the database.
  """
  def delete_server(entity, network, server_ip) do
    case DatabaseQuery.fetch_server(entity, network, server_ip) do
      entry = %{} ->
        DatabaseInternal.delete_server(entry)
      nil ->
        {:error, {:entry, :notfound}}
    end
  end

  @spec delete_bank_account(Entity.idt, BankAccount.t) ::
    :ok
    | {:error, {:entry, :notfound}}
  @doc """
  Deletes a bank account entry from the database.
  """
  def delete_bank_account(entity, account) do
    case DatabaseQuery.fetch_bank_account(entity, account) do
      entry = %{} ->
        DatabaseInternal.delete_bank_account(entry)
      nil ->
        {:error, {:entry, :notfound}}
    end
  end

  @spec fetch_or_create_bank_entry(Entity.t, BankAccount.t) ::
    DatabaseBankAccount.t
  defp fetch_or_create_bank_entry(entity, account) do
    case DatabaseQuery.fetch_bank_account(entity, account) do
      entry = %{} ->
        entry
      nil ->
        {:ok, entry} = add_bank_account(entity, account)
        entry
    end
  end

  @spec fetch_or_create_server(Entity.t, Network.idt, IPv4.t, Server.id) ::
    DatabaseServer.t
  defp fetch_or_create_server(entity, network_id, ip, server_id) do
    case DatabaseQuery.fetch_server(entity, network_id, ip) do
      entry = %{} ->
        entry
      nil ->
        {:ok, entry} = add_server(entity, network_id, ip, server_id)
        entry
    end
  end
end
