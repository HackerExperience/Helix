defmodule Helix.Account.Internal.AccountSession do

  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Repo

  @spec fetch(AccountSession.t | AccountSession.id) ::
    {:ok, AccountSession.t}
    | nil
  def fetch(session) do
    session
    |> AccountSession.Query.by_session()
    |> Repo.one()
  end

  @spec get_account(AccountSession.t | AccountSession.id) ::
    Account.t
    | nil
  def get_account(nil),
    do: nil
  def get_account(account_session = %AccountSession{}) do
    account_session
    |> Repo.preload(:account)
    |> Map.get(:account)
  end
  def get_account(session) do
    session
    |> fetch()
    |> get_account()
  end

  @spec create(Account.t) ::
    {:ok, AccountSession.t}
    | {:error, Ecto.Changeset.t}
  def create(account) do
    account
    |> AccountSession.create_changeset()
    |> Repo.insert
  end

  @spec delete(AccountSession.t | AccountSession.id) ::
    :ok
  def delete(session) do
    session
    |> AccountSession.Query.by_session()
    |> Repo.delete_all()

    :ok
  end
end
