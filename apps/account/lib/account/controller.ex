defmodule HELM.Account.Controller do
  import Ecto.Changeset
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Account.Repo
  alias HELM.Account.Schema, as: AccountSchema

  def create(account) do
    AccountSchema.create_changeset(account)
    |> do_new_account
  end

  def find(account_id) do
    case Repo.get_by(AccountSchema, account_id: account_id) do
      nil -> {:error, "Account not found."}
      res -> {:ok, res}
    end
  end

  def find_with_email(email) do
    case Repo.get_by(AccountSchema, email: email) do
      nil -> {:error, Error.format_reply(:not_found, "Account with given email not found")}
      res -> {:ok, res}
    end
  end

  def delete(account_id) do
    case find(account_id) do
      {:ok, account} -> do_delete(account)
      error -> error
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

  def get(request) do
    case Broker.call("auth:account:verify", request.args["jwt"]) do
      :ok -> find(request.args["email"])
      {:error, reason} -> {:reply, {:error, reason}}
    end
  end

  defp do_new_account(changeset) do
    case Repo.insert(changeset) do
      {:ok, struct} ->
        Broker.cast("event:account:created", struct.account_id)
        {:ok, struct}
      {:error, changeset} ->
        email_taken? = Enum.any?(changeset.errors, &(&1 == {:email, "has already been taken"}))
        if email_taken? do
          {:error, Error.format_reply({:bad_request, "Email has already been taken"})}
        else
          {:error, Error.format_reply({:internal, "Could not create the account"})}
        end
    end
  end

  defp do_delete(account) do
    case Repo.delete(account) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end

  defp do_login({:ok, account}) do
    Broker.call("jwt:create", account.account_id)
  end

  defp do_login({:error, err}) do
    case err do
      :notfound ->
        {:error, Error.format_reply(:unauthorized, "Account not found.")}
      _ ->
        {:error, Error.format_reply(:unspecified, "oh god")}
    end
  end
end
