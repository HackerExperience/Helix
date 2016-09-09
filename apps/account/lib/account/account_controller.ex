defmodule HELM.Account.Controller do
  import Ecto.Changeset
  import Ecto.Query

  alias HeBroker.Publisher

  alias HELF.{Broker, Error}
  alias HELM.Account.{Repo, Model}

  def find_account(account_id) do
    Model
    |> where([a], a.account_id == ^account_id)
    |> select([a], map(a, [:account_id, :confirmed, :email]))
    |> Repo.one()
    |> case do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  def new_account(account) do
    Model.create_changeset(account)
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
    Model
    |> where([a], a.email == ^email and a.password == ^password)
    |> select([a], map(a, [:account_id, :confirmed, :email]))
    |> Repo.one()
    |> case do
      nil -> {:error, :notfound}
      account -> {:ok, account}
    end
  end

  defp do_new_account(changeset) do
    Repo.insert(changeset)
  end

  defp do_login({:ok, account}) do
    # TODO Call `jwt:account:create` hebroker topic
    account["account_id"]
  end

  defp do_login(err), do: err

end
