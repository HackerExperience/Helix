defmodule Helix.Account.Internal.AccountSession do

  alias Helix.Account.Internal.Account, as: AccountInternal
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Repo

  @spec fetch(AccountSession.id) ::
    {:ok, AccountSession.t}
    | nil
  def fetch(id),
    do: Repo.get(AccountSession, id)

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

  @spec delete(AccountSession.t | AccountSession.id) ::
    :ok
  def delete(%AccountSession{session_id: id}),
    do: delete(id)
  def delete(session_id) do
    session_id
    |> AccountSession.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end
