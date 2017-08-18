defmodule Helix.Entity.Action.Database do
  @moduledoc """
  API used to modify the Hacked Database.
  """

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.DatabaseBankAccount
  alias Helix.Entity.Model.DatabaseServer
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  @spec add_server(
    Entity.idt, Network.idt, IPv4.t, Server.idt, DatabaseServer.server_type)
  ::
    {:ok, DatabaseServer.t}
    | {:error, DatabaseServer.changeset}
  @doc """
  Adds a new server entry to the database.

  Note that the default addition is naive, in the sense that it won't bother
  with extra information like password or notes. Modifying these extra data
  should be done by with `update_*` functions.
  """
  defdelegate add_server(entity, network, ip, server, server_type),
    to: DatabaseInternal

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

  @spec update_bank_password(Entity.idt, BankAccount.t, String.t) ::
    {:ok, DatabaseBankAccount.t}
    | {:error, DatabaseBankAccount.changeset}
  @doc """
  Updates the password of the bank account entry.

  If the requested entry does not exist, it is created.
  """
  def update_bank_password(entity, account, password) do
    entry =
      case DatabaseQuery.fetch_bank_account(entity, account) do
        entry = %{} ->
          entry
        nil ->
          {:ok, entry} = add_bank_account(entity, account)
          entry
      end

    DatabaseInternal.update_bank_password(entry, password)
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
end
