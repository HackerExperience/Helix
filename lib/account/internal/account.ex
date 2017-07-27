defmodule Helix.Account.Internal.Account do

  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  @spec fetch(Account.id) ::
    Account.t
    | nil
  def fetch(account_id) do
    account_id
    |> Account.Query.by_id()
    |> Repo.one()
  end

  @spec fetch_by_email(Account.email) ::
    Account.t
    | nil
  def fetch_by_email(email) do
    String.downcase(email)
    |> Account.Query.by_email()
    |> Repo.one()
  end

  @spec fetch_by_username(Account.username) ::
    Account.t
    | nil
  def fetch_by_username(username) do
    String.downcase(username)
    |> Account.Query.by_username()
    |> Repo.one()
  end

  @spec get_settings(Account.t | Account.id) ::
    Setting.t
  def get_settings(account) do
    settings =
      account
      |> AccountSetting.Query.from_account()
      |> AccountSetting.Query.select_settings()
      |> Repo.one()

    settings || %Setting{}
  end

  @spec create(Account.creation_params) ::
    {:ok, Account.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Account.create_changeset()
    |> Repo.insert
  end

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
end
