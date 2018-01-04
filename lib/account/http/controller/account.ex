defmodule Helix.Account.HTTP.Controller.Account do

  use Phoenix.Controller

  import Plug.Conn

  alias Helix.Account.Action.Account, as: AccountAction

  def register(conn, _) do
    # When enabling registration:
    #  - Remove `pending` tag from this method's test
    #  - Refer to the Onboarding test, so we can test from an external request
    #    rather than directly using `AccountFlow`
    conn
    |> put_status(:forbidden)
    |> json(%{message: "Registration is temporarily disabled"})
  end

  def login(conn, %{"username" => username, "password" => password}) do
    case AccountAction.login(username, password) do
      {:ok, account, token} ->
        result = %{
          account_id: account.account_id,
          token: token
        }

        conn
        |> put_status(:ok)
        |> json(result)
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{reason: "not found"})
    end
  end
end
