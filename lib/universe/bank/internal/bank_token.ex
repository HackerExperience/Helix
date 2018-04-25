defmodule Helix.Universe.Bank.Internal.BankToken do

  alias Helix.Network.Model.Connection
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Repo

  @spec fetch(BankToken.id) ::
    BankToken.t
    | nil
  def fetch(token) do
    token
    |> BankToken.Query.by_token()
    #|> BankToken.Query.filter_expired()
    |> Repo.one()
  end

  @spec fetch_by_connection(Connection.idt) ::
    BankToken.t
    | nil
  def fetch_by_connection(connection) do
    connection
    |> BankToken.Query.by_connection()
    |> BankToken.Query.filter_expired()
    |> Repo.one()
  end

  @spec generate(BankAccount.t, Connection.idt) ::
    {:ok, BankToken.t}
    | {:error, Ecto.Changeset.t}
  def generate(account, connection) do
    params = %{
      atm_id: account.atm_id,
      account_number: account.account_number,
      connection_id: connection
    }

    params
    |> BankToken.create_changeset()
    |> Repo.insert()
    end

  @spec set_expiration(BankToken.t) ::
    {:ok, BankToken.t}
    | {:error, Ecto.Changeset.t}
  def set_expiration(token) do
    token
    |> BankToken.set_expiration_date()
    |> Repo.update()
  end
end
