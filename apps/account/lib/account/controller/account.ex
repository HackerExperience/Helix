defmodule Helix.Account.Controller.Account do

  alias Comeonin.Bcrypt
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  @spec create(Account.creation_params) ::
    {:ok, Account.t}
    | {:error, Ecto.Changeset.t}
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

  @spec find_by([email: Account.email]) :: {:ok, Account.t} | {:error, :notfound}
  def find_by(email: email) do
    email = String.downcase(email)

    case Repo.get_by(Account, email: email) do
      nil ->
        {:error, :notfound}
      account ->
        {:ok, account}
    end
  end

  @spec update(Account.id, Account.update_params) :: {:ok, Account}
    | {:error, Ecto.Changeset.t}
    | {:error, :notfound}
  def update(account_id, params) do
    with {:ok, account} <- find(account_id) do
      account
      |> Account.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec delete(Account.id) :: no_return
  def delete(account_id) do
    account_id
    |> Account.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec login(Account.username, Account.password) ::
  {:ok, Account.t}
  | {:error, :notfound}
  def login(username, password) do
    account =
      username
      |> String.downcase()
      |> Account.Query.by_username()
      |> Repo.one()

    if account && Bcrypt.checkpw(password, account.password) do
      {:ok, account}
    else
      {:error, :notfound}
    end
  end
end