defmodule HELM.Account.Controller.Account do

  import Ecto.Query

  alias Comeonin.Bcrypt, as: Crypt
  alias HELM.Account.Repo
  alias HELM.Account.Model.Account, as: MdlAccount

  @spec create(MdlAccount.create_params) :: {:ok, MdlAccount.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    MdlAccount.create_changeset(params)
    |> Repo.insert()
  end

  @spec find(MdlAccount.id) :: {:ok, MdlAccount.t} | {:error, :notfound}
  def find(account_id) do
    case Repo.get_by(MdlAccount, account_id: account_id) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  @spec find_by([email: MdlAccount.email]) :: {:ok, MdlAccount.t} | {:error, :notfound}
  def find_by(email: email) do
    email = String.downcase(email)

    case Repo.get_by(MdlAccount, email: email) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  @spec delete(MdlAccount.id) :: :ok
  def delete(account_id) do
    MdlAccount
    |> where([s], s.account_id == ^account_id)
    |> Repo.delete_all()

    :ok
  end

  @spec login(MdlAccount.email, MdlAccount.password) :: {:ok, MdlAccount.id} | {:error, :notfound}
  def login(email, password) do
    email = String.downcase(email)

    MdlAccount
    |> where([a], a.email == ^email)
    |> select([a], map(a, [:password, :account_id]))
    |> Repo.one()
    |> case do
      nil ->
        {:error, :notfound}
      account ->
        if Crypt.checkpw(password, account.password),
          do: {:ok, account.account_id},
          else: {:error, :notfound}
    end
  end
end