defmodule Helix.Entity.Public.Index.Database do

  alias HELL.ClientUtils
  alias HELL.HETypes
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  @type index ::
    %{
      bank_accounts: [Database.BankAccount.t],
      servers: [Database.Server.t]
    }

  @type rendered_index ::
    %{
      bank_accounts: [rendered_bank_account],
      servers: [rendered_server],
    }

  @typep rendered_bank_account ::
    %{
      atm_id: String.t,
      atm_ip: String.t,
      account_number: pos_integer,
      password: String.t | nil,
      token: String.t | nil,
      notes: String.t | nil,
      known_balance: non_neg_integer | nil,
      last_login_date: DateTime.t | nil,
      last_update: HETypes.client_timestamp
    }

  @typep rendered_server ::
    %{
      network_id: String.t,
      ip: String.t,
      type: String.t,
      password: String.t | nil,
      alias: String.t | nil,
      notes: String.t | nil,
      last_update: HETypes.client_timestamp
    }

  @spec index(Entity.t) ::
    index
  def index(entity),
    do: DatabaseQuery.get_database(entity)

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    %{
      bank_accounts: Enum.map(index.bank_accounts, &render_bank_account/1),
      servers: Enum.map(index.servers, &render_server/1),
    }
  end

  @spec render_bank_account(Database.BankAccount.t) ::
    rendered_bank_account
  defp render_bank_account(entry = %Database.BankAccount{}) do
    last_login_date =
      if is_map(entry.last_login_date) do
        ClientUtils.to_timestamp(entry.last_login_date)
      else
        nil
      end

    %{
      atm_id: to_string(entry.atm_id),
      atm_ip: to_string(entry.atm_ip),
      account_number: entry.account_number,
      password: entry.password,
      token: entry.token,
      notes: entry.notes,
      known_balance: entry.known_balance,
      last_login_date: last_login_date,
      last_update: ClientUtils.to_timestamp(entry.last_update)
    }
  end

  @spec render_server(Database.Server.t) ::
    rendered_server
  defp render_server(entry = %Database.Server{}) do
    %{
      network_id: to_string(entry.network_id),
      ip: to_string(entry.server_ip),
      type: to_string(entry.server_type),
      password: entry.password,
      alias: entry.alias,
      notes: entry.notes,
      last_update: ClientUtils.to_timestamp(entry.last_update)
    }
  end
end
