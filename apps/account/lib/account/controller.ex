defmodule HELM.Account.Controller do
  import Ecto.Changeset
  import Ecto.Query

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

  def login(email: email, password: password) do
    AccountSchema
    |> where([a], a.email == ^email and a.password == ^password)
    |> select([a], map(a, [:account_id, :confirmed, :email]))
    |> Repo.one()
    |> case do
      nil -> {:error, :notfound}
      account -> {:ok, account}
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
