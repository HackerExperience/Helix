defmodule Helix.Account.Controller.Account do

  alias Comeonin.Bcrypt
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting
  alias Helix.Account.Model.Setting
  alias Helix.Account.Repo

  import Ecto.Query, only: [select: 3]

  @type find_params :: [find_param]
  @type find_param :: {:email, Account.email} | {:username, Account.username}

  @spec create(Account.creation_params) ::
    {:ok, Account.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Account.create_changeset()
    |> Repo.insert()
  end

  @spec find(Account.id) :: {:ok, Account.t} | {:error, :notfound}
  def find(account_id) do
    case Repo.get_by(Account, account_id: account_id) do
      nil ->
        {:error, :notfound}
      account ->
        {:ok, account}
    end
  end

  @spec find_by(find_params) :: [Account.t]
  def find_by(params) do
    query = Enum.reduce(params, Account, &reduce_find_params/2)

    Repo.all(query)
  end

  @spec reduce_find_params(find_param, Ecto.Queryable.t) :: Ecto.Queryable.t
  defp reduce_find_params({:email, email}, query),
    do: Account.Query.by_email(query, email)
  defp reduce_find_params({:username, username}, query),
    do: Account.Query.by_username(query, username)

  @spec update(Account.t, Account.update_params) ::
    {:ok, Account.t} | {:error, Ecto.Changeset.t}
  def update(account, params) do
    account
    |> Account.update_changeset(params)
    |> Repo.update()
  end

  @spec delete(Account.id | Account.t) :: no_return
  def delete(account = %Account{}),
    do: delete(account.account_id)
  def delete(account_id) do
    account_id
    |> Account.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec login(Account.username, Account.password) ::
    {:ok, Account.t} | {:error, :notfound}
  def login(username, password) do
    case find_by(username: username) do
      [account] ->
        if Bcrypt.checkpw(password, account.password),
          do: {:ok, account},
          else: {:error, :notfound}
      [] ->
        {:error, :notfound}
    end
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

  @spec get_settings(Account.t | Account.id) :: Setting.t
  def get_settings(account) do
    settings =
      account
      |> AccountSetting.Query.from_account()
      |> select([as], as.settings)
      |> Repo.one()

    settings || %Setting{}
  end
end
