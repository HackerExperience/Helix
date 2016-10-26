defmodule HELM.Account.Controller do
  import Ecto.Changeset
  import Ecto.Query

  alias Comeonin.Bcrypt, as: Crypt

  alias HELF.{Broker, Error}
  alias HELM.Account.Repo
  alias HELM.Account.Schema, as: AccountSchema

  def create(account) do
    AccountSchema.create_changeset(account)
    |> do_create()
  end

  def find(account_id) do
    case Repo.get_by(AccountSchema, account_id: account_id) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  def find_by(email: email) do
    case Repo.get_by(AccountSchema, email: email) do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  def delete(account_id) do
    with {:ok, account} <- find(account_id),
         {:ok, _} <- Repo.delete(account) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end

  def login(email, password) do
    AccountSchema
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
        errors = do_check_errors(changeset)
        {:error, errors}
    end
  end

  defp do_check_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(msg, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
