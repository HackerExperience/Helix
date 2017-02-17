defmodule Helix.Account.Controller.Account do

  alias Comeonin.Bcrypt
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  @spec create(Account.creation_params) ::
    {:ok, Account.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Account.create_changeset()
    |> Repo.insert()
  end

  @spec find(Account.id) :: {:ok, Account.t} | {:error, :notfound}
  def find(account_id) do
    result =
      account_id
      |> Account.Query.by_id()
      |> Repo.one()

    case result do
      nil ->
        {:error, :notfound}
      account ->
        {:ok, account}
    end
  end

  @spec find_by([{:email, Account.email} | {:username, Account.username}]) ::
    {:ok, Account.t} | {:error, :notfound}
  def find_by(email: email) do
    result =
      email
      |> String.downcase()
      |> Account.Query.by_email()
      |> Repo.one()

    case result do
      nil ->
        {:error, :notfound}
      account ->
        {:ok, account}
    end
  end
  def find_by(username: username) do
    result =
      username
      |> String.downcase()
      |> Account.Query.by_username()
      |> Repo.one()

    case result do
      nil ->
        {:error, :notfound}
      account ->
        {:ok, account}
    end
  end

  @spec update(Account.t, Account.update_params) ::
    {:ok, Account} | {:error, Ecto.Changeset.t | :notfound}
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
      {:ok, account} ->
        if Bcrypt.checkpw(password, account.password),
          do: {:ok, account},
          else: {:error, :notfound}
      error ->
        error
    end
  end
end