defmodule HELM.Account.Controller.Accounts do
  import Ecto.Changeset
  import Ecto.Query

  alias Comeonin.Bcrypt, as: Crypt

  alias HELF.{Broker, Error}
  alias HELM.Account.Model.Repo
  alias HELM.Account.Model.Accounts, as: MdlAccount

  def create(account) do
    MdlAccount.create_changeset(account)
    |> do_create()
  end

  def find(account_id) do
    case Repo.get_by(MdlAccount, account_id: account_id) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  def find_by(email: email) do
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

  def login(email, password) do
    MdlAccount
    |> where([a], a.email == ^email)
    |> select([a], map(a, [:password]))
    |> Repo.one()
    |> case do
      nil -> {:error, :notfound}
      account ->
        if Crypt.checkpw(password, account.password),
          do: :ok,
          else: {:error, :notfound}
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, struct} ->
        Broker.cast("event:account:created", struct.account_id)
        {:ok, struct}
      {:error, changeset} ->
        {:error, changeset.errors}
    end
  end
end