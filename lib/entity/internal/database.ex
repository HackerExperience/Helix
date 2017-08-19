defmodule Helix.Entity.Internal.Database do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.DatabaseBankAccount
  alias Helix.Entity.Model.DatabaseServer
  alias Helix.Entity.Repo

  @type entry_server_repo_return ::
    {:ok, DatabaseServer.t}
    | {:error, DatabaseServer.changeset}

  @type entry_bank_account_repo_return ::
    {:ok, DatabaseBankAccount.t}
    | {:error, DatabaseBankAccount.changeset}

  @type full_database ::
    %{
      servers: [DatabaseServer.t],
      bank_accounts: [DatabaseBankAccount.t]
    }

  @spec fetch_server(Entity.idt, Network.idt, IPv4.t) ::
    DatabaseServer.t
    | nil
  def fetch_server(entity, network, server_ip) do
    entity
    |> DatabaseServer.Query.by_entity()
    |> DatabaseServer.Query.by_nip(network, server_ip)
    |> Repo.one()
  end

  @spec fetch_bank_account(Entity.t, BankAccount.t) ::
    DatabaseBankAccount.t
    | nil
  def fetch_bank_account(entity, acc) do
    entity
    |> DatabaseBankAccount.Query.by_entity()
    |> DatabaseBankAccount.Query.by_bank_account(acc.atm_id, acc.account_number)
    |> Repo.one()
  end

  @spec get_database(Entity.t) ::
    full_database
  def get_database(entity) do
    %{
      servers: get_server_entries(entity),
      bank_accounts: get_bank_account_entries(entity)
    }
  end

  @spec get_server_entries(Entity.t) ::
    [DatabaseServer.t]
  defp get_server_entries(entity) do
    entity
    |> DatabaseServer.Query.by_entity()
    |> DatabaseServer.Query.order_by_last_update()
    |> Repo.all()
  end

  @spec get_bank_account_entries(Entity.t) ::
    [DatabaseBankAccount.t]
  defp get_bank_account_entries(entity) do
    entity
    |> DatabaseBankAccount.Query.by_entity()
    |> DatabaseBankAccount.Query.order_by_last_update()
    |> Repo.all()
  end

  @spec add_server(
    Entity.idt, Network.idt, IPv4.t, Server.idt, DatabaseServer.server_type)
  ::
    entry_server_repo_return
  def add_server(entity, network, ip, server, server_type) do
    params = %{
      entity_id: entity,
      network_id: network,
      server_ip: ip,
      server_id: server,
      server_type: server_type
    }

    params
    |> DatabaseServer.create_changeset()
    |> Repo.insert()
  end

  @spec add_bank_account(Entity.t, BankAccount.t, IPv4.t) ::
    entry_bank_account_repo_return
  def add_bank_account(entity, bank_account, atm_ip) do
    params = %{
      entity_id: entity,
      atm_id: bank_account.atm_id,
      account_number: bank_account.account_number,
      atm_ip: atm_ip
    }

    params
    |> DatabaseBankAccount.create_changeset()
    |> Repo.insert()
  end

  @spec update_bank_password(DatabaseBankAccount.t, String.t) ::
    entry_bank_account_repo_return
  def update_bank_password(entry, password),
    do: update_bank_account(entry, %{password: password})

  @spec update_bank_token(DatabaseBankAccount.t, BankToken.id) ::
    entry_bank_account_repo_return
  def update_bank_token(entry, token),
    do: update_bank_account(entry, %{token: token})

  @spec update_bank_login(DatabaseBankAccount.t, BankAccount.t) ::
    entry_bank_account_repo_return
  def update_bank_login(entry, account) do
    params = %{
      password: account.password,
      known_balance: account.balance,
      last_login_date: DateTime.utc_now()
    }

    update_bank_account(entry, params)
  end

  @spec update_bank_account(
    DatabaseBankAccount.t, DatabaseBankAccount.update_params)
  ::
    entry_bank_account_repo_return
  defp update_bank_account(entry, params) do
    entry
    |> DatabaseBankAccount.update_changeset(params)
    |> Repo.update()
  end

  @spec delete_server(DatabaseServer.t) ::
    :ok
  def delete_server(entry = %DatabaseServer{}) do
    Repo.delete(entry)

    :ok
  end

  @spec delete_bank_account(DatabaseBankAccount.t) ::
    :ok
  def delete_bank_account(entry = %DatabaseBankAccount{}) do
    Repo.delete(entry)

    :ok
  end
end
