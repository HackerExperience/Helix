defmodule HELM.Account.Controller.Account do
  import Ecto.Query

  alias Comeonin.Bcrypt, as: Crypt

  alias HELM.Account.Repo
  alias HELM.Account.Model.Account, as: MdlAccount

  def create(params) do
    MdlAccount.create_changeset(params)
    |> Repo.insert()
  end

  def find(account_id) do
    case Repo.get_by(MdlAccount, account_id: account_id) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  def find_by(email: email) do
    email = String.downcase(email)

    case Repo.get_by(MdlAccount, email: email) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  def delete(account_id) do
    MdlAccount
    |> where([s], s.account_id == ^account_id)
    |> Repo.delete_all()

    :ok
  end

  def login(nil, _),
    do: {:error, :notfound}
  def login(_, nil),
    do: {:error, :notfound}
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