defmodule Helix.Entity.Internal.Database do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Repo

  @type entry_server_repo_return ::
    {:ok, Database.Server.t}
    | {:error, Database.Server.changeset}

  @type entry_bank_account_repo_return ::
    {:ok, Database.BankAccount.t}
    | {:error, Database.BankAccount.changeset}

  @type full_database ::
    %{
      servers: [Database.Server.t],
      bank_accounts: [Database.BankAccount.t]
    }

  @spec fetch_server(Entity.idt, Network.idt, IPv4.t) ::
    Database.Server.t
    | nil
  def fetch_server(entity, network, server_ip) do
    entity
    |> Database.Server.Query.by_entity()
    |> Database.Server.Query.by_nip(network, server_ip)
    |> Repo.one()
  end

  @spec fetch_bank_account(Entity.t, BankAccount.t) ::
    Database.BankAccount.t
    | nil
  def fetch_bank_account(entity, acc) do
    entity
    |> Database.BankAccount.Query.by_entity()
    |> Database.BankAccount.Query.by_account(acc.atm_id, acc.account_number)
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
    [Database.Server.t]
  defp get_server_entries(entity) do
    entity
    |> Database.Server.Query.by_entity()
    |> Database.Server.Query.order_by_last_update()
    |> Repo.all()
  end

  @spec get_bank_account_entries(Entity.t) ::
    [Database.BankAccount.t]
  defp get_bank_account_entries(entity) do
    entity
    |> Database.BankAccount.Query.by_entity()
    |> Database.BankAccount.Query.order_by_last_update()
    |> Repo.all()
  end

  @spec add_server(
    Entity.idt, Network.idt, IPv4.t, Server.idt, Database.Server.server_type)
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
    |> Database.Server.create_changeset()
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
    |> Database.BankAccount.create_changeset()
    |> Repo.insert()
  end

  @spec update_server_password(Database.Server.t, Server.password) ::
    entry_server_repo_return
  def update_server_password(entry, password),
    do: update_server(entry, %{password: password})

  @spec update_server(Database.Server.t, Database.Server.update_params) ::
    entry_server_repo_return
  defp update_server(entry, params) do
    entry
    |> Database.Server.update_changeset(params)
    |> Repo.update()
  end

  @spec update_bank_password(Database.BankAccount.t, String.t) ::
    entry_bank_account_repo_return
  def update_bank_password(entry, password),
    do: update_bank_account(entry, %{password: password})

  @spec update_bank_token(Database.BankAccount.t, BankToken.id) ::
    entry_bank_account_repo_return
  def update_bank_token(entry, token),
    do: update_bank_account(entry, %{token: token})

  @spec update_bank_login(
    Database.BankAccount.t, BankAccount.t, BankToken.id | nil)
  ::
    entry_bank_account_repo_return
  def update_bank_login(entry, account, token_id) do
    account_info = %{
      known_balance: account.balance,
      last_login_date: DateTime.utc_now()
    }

    login_info =
      if token_id do
        %{token: token_id}
      else
        %{password: account.password}
      end

    params = Map.merge(account_info, login_info)

    update_bank_account(entry, params)
  end

  @spec update_bank_account(
    Database.BankAccount.t, Database.BankAccount.update_params)
  ::
    entry_bank_account_repo_return
  defp update_bank_account(entry, params) do
    entry
    |> Database.BankAccount.update_changeset(params)
    |> Repo.update()
  end

  @spec delete_server(Database.Server.t) ::
    :ok
  def delete_server(entry = %Database.Server{}) do
    Repo.delete(entry)

    :ok
  end

  @spec delete_bank_account(Database.BankAccount.t) ::
    :ok
  def delete_bank_account(entry = %Database.BankAccount{}) do
    Repo.delete(entry)

    :ok
  end
end
