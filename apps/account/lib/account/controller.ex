defmodule HELM.Account.Controller do
  import Ecto.Changeset
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Account.Repo
  alias HELM.Account.Schema, as: AccountSchema

  def create(email, password, confirmation) do
    %{email: email, password: password,
      password_confirmation: confirmation}
    |> create()
  end

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
      do: Repo.delete(account)
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
        email_errors = Keyword.get(changeset.errors, :email, {})
        passwd_errors = Keyword.get(changeset.errors, :password, {})
        confirm_errors = Keyword.get(changeset.errors, :password_confirmation, {})

        email_taken? = {} != email_errors
        passwd_short? = {} != passwd_errors
        wrong_confirm? = {} != confirm_errors

        cond do
          email_taken? -> {:error, :email_taken}
          passwd_short? -> {:error, :password_too_short}
          wrong_confirm? -> {:error, :wrong_password_confirmation}
          true -> {:error, :internal}
        end
    end
  end
end
