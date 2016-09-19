defmodule HELM.Account.Controller do
  import Ecto.Changeset
  import Ecto.Query

  alias HeBroker.Publisher

  alias HELF.{Broker, Error}
  alias HELM.Account.{Repo, Schema}

  def find_account(account_id) do
    Schema
    |> where([a], a.account_id == ^account_id)
    |> select([a], map(a, [:account_id, :confirmed, :email]))
    |> Repo.one()
    |> case do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  def new_account(account) do
    Schema.create_changeset(account)
    |> do_new_account()
  end

  def login_with(account = %{"email" => email, "password" => pass}) do
    do_find_account(email: email, password: pass)
    |> do_login
  end

  def find(email) do
    case Repo.get_by(Account, email: email) do
      nil -> {:reply, {:error, Error.format_reply(:not_found, "Account with given email not found")}}
      res -> {:reply, {:ok, res}}
    end
  end

  def get(request) do
    case Broker.call("jwt:account:verify", request.args["jwt"]) do
      :ok -> find(request.args["email"])
      {:error, reason} -> {:reply, {:error, reason}}
    end
  end

  defp do_find_account(email: email, password: password) do
    Schema
    |> where([a], a.email == ^email and a.password == ^password)
    |> select([a], map(a, [:account_id, :confirmed, :email]))
    |> Repo.one()
    |> case do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  defp do_new_account(changeset) do
    result = Repo.insert(changeset)
    Broker.cast("event:account:created", changeset.changes.account_id)
    result
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
