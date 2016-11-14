defmodule HELM.Account.Controller.Account do
  import Ecto.Query

  alias Comeonin.Bcrypt, as: Crypt

  alias HELM.Account.Repo
  alias HELM.Account.Model.Account, as: MdlAccount

  @type not_found :: {:error, :notfound}
  @type create_t :: {:ok, Ecto.Schema.t} | {:error, Ecto.Changeset.t}

  @spec create(params :: MdlAccount.create_params) :: {:ok, Ecto.Schema.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    MdlAccount.create_changeset(params)
    |> Repo.insert()
  end

  @spec find(account_id :: String.t) :: {:ok, Ecto.Schema.t} | not_found
  def find(account_id) do
    case Repo.get_by(MdlAccount, account_id: account_id) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  @spec find_by([email: String.t]) :: {:ok, Ecto.Schema.t} | not_found
  def find_by(email: email) do
    email = String.downcase(email)

    case Repo.get_by(MdlAccount, email: email) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  @spec delete(account_id :: String.t) :: :ok
  def delete(account_id) do
    MdlAccount
    |> where([s], s.account_id == ^account_id)
    |> Repo.delete_all()

    :ok
  end

  @spec login(email :: String.t, password :: String.t) :: {:ok, String.t} | not_found
  def login(email, password) do
    email = String.downcase(email)

    MdlAccount
    |> where([a], a.email == ^email)
    |> select([a], map(a, [:password, :account_id]))
    |> Repo.one()
    |> case do
      nil -> {:error, :notfound}
      account ->
        if Crypt.checkpw(password, account.password),
          do: {:ok, account.account_id},
          else: {:error, :notfound}
    end
  end
end