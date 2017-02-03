defmodule Helix.Account.Controller.Account do

  alias Comeonin.Bcrypt
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  import Ecto.Query, only: [where: 3, select: 3]

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
    Account
    |> where([a], a.account_id == ^account_id)
    |> Repo.delete_all()

    :ok
  end

  @spec login(Account.email, Account.password) :: {:ok, Account.id} | {:error, :notfound}
  def login(email, password) do
    email = String.downcase(email)

    Account
    |> where([a], a.email == ^email)
    |> select([a], map(a, [:password, :account_id]))
    |> Repo.one()
    |> case do
      nil ->
        {:error, :notfound}
      account ->
        if Bcrypt.checkpw(password, account.password),
          do: {:ok, account.account_id},
          else: {:error, :notfound}
    end
  end
end