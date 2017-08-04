defmodule Helix.Account.Internal.AccountSession do

  alias Helix.Account.Internal.Account, as: AccountInternal
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Repo

  @spec fetch(AccountSession.id) ::
    {:ok, AccountSession.t}
    | nil
  def fetch(id),
    do: Repo.one(AccountSession, id)

  @spec get_account(AccountSession.t) ::
    Account.t
  def get_account(session = %AccountSession{}),
    do: AccountInternal.fetch(session.account_id)

  @spec create(Account.t) ::
    {:ok, AccountSession.t}
    | {:error, Ecto.Changeset.t}
  def create(account) do
    account
    |> AccountSession.create_changeset()
    |> Repo.insert()
  end

  @spec delete(AccountSession.t) ::
    :ok
  def delete(session) do
    Repo.delete(session)

    :ok
  end
end
