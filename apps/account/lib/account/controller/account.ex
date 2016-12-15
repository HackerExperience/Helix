defmodule HELM.Account.Controller.Account do

  alias Comeonin.Bcrypt
  alias HELM.Account.Repo
  alias HELM.Account.Model.Account, as: MdlAccount
  import Ecto.Query, only: [where: 3, select: 3]

  @spec create(Ecto.Changeset.t) :: {:ok, MdlAccount.t} | {:error, Ecto.Changeset.t}
  @spec create(MdlAccount.creation_params) :: {:ok, MdlAccount.t} | {:error, Ecto.Changeset.t}
  def create(changeset = %Ecto.Changeset{}),
    do: Repo.insert(changeset)

  def create(params) do
    params
    |> MdlAccount.create_changeset()
    |> MdlAccount.put_primary_key(params)
    |> Repo.insert()
  end

  @spec find(MdlAccount.id) :: {:ok, MdlAccount.t} | {:error, :notfound}
  def find(account_id) do
    case Repo.get_by(MdlAccount, account_id: account_id) do
      nil ->
        {:error, :notfound}
      account ->
        {:ok, account}
    end
  end

  @spec find_by([email: MdlAccount.email]) :: {:ok, MdlAccount.t} | {:error, :notfound}
  def find_by(email: email) do
    email = String.downcase(email)

    case Repo.get_by(MdlAccount, email: email) do
      nil ->
        {:error, :notfound}
      account ->
        {:ok, account}
    end
  end

  @spec update(MdlAccount.id, MdlAccount.update_params) :: {:ok, MdlAccount}
    | {:error, Ecto.Changeset.t}
    | {:error, :notfound}
  def update(account_id, params) do
    with {:ok, account} <- find(account_id) do
      account
      |> MdlAccount.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec delete(MdlAccount.id) :: no_return
  def delete(account_id) do
    MdlAccount
    |> where([a], a.account_id == ^account_id)
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
        if Bcrypt.checkpw(password, account.password),
          do: {:ok, account.account_id},
          else: {:error, :notfound}
    end
  end
end