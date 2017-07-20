defmodule Helix.Account.Internal.Account do

  import Ecto.Query, only: [select: 3]

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Account.AccountCreatedEvent
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  @spec create(Account.creation_params) ::
    {:ok, Account.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    changeset = Account.create_changeset(params)

    case Repo.insert(changeset) do
      {:ok, account} ->
        # FIXME: The internal API should not emit events
        event = %AccountCreatedEvent{account_id: account.account_id}
        Event.emit(event)

        {:ok, account}
      error ->
        error
    end
  end

  @spec fetch(Account.id) ::
    Account.t
    | nil
  def fetch(account_id),
    do: Repo.get(Account, account_id)

  @spec fetch_by_email(Account.email) ::
    Account.t
    | nil
  def fetch_by_email(email),
    do: Repo.get_by(Account, email: String.downcase(email))

  @spec fetch_by_username(Account.username) ::
    Account.t
    | nil
  def fetch_by_username(username),
    do: Repo.get_by(Account, username: String.downcase(username))

  @spec update(Account.t, Account.update_params) ::
    {:ok, Account.t}
    | {:error, Ecto.Changeset.t}
  def update(account, params) do
    account
    |> Account.update_changeset(params)
    |> Repo.update()
  end

  @spec delete(Account.id | Account.t) ::
    :ok
  def delete(account = %Account{}),
    do: delete(account.account_id)
  def delete(account_id) do
    account_id
    |> Account.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec put_settings(Account.t, map) ::
    {:ok, Setting.t}
    | {:error, reason :: term}
  def put_settings(account, settings) do
    id = account.account_id
    account_settings = Repo.get(AccountSetting, id) || %AccountSetting{}
    params = %{account_id: account.account_id, settings: settings}

    changeset = AccountSetting.changeset(account_settings, params)

    case Repo.insert_or_update(changeset) do
      {:ok, %{settings: settings}} ->
        {:ok, settings}
      error = {:error, _} ->
        error
    end
  end

  @spec get_settings(Account.t | Account.id) ::
    Setting.t
  def get_settings(account) do
    settings =
      account
      |> AccountSetting.Query.from_account()
      |> select([as], as.settings)
      |> Repo.one()

    settings || %Setting{}
  end
end
