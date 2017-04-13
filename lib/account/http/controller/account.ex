defmodule Helix.Account.HTTP.Controller.Account do

  use Phoenix.Controller

  alias Helix.Account.Service.API.Account, as: AccountAPI

  import Plug.Conn

  def register(conn, params) do
    %{"username" => username, "password" => password, "email" => email} = params

    case AccountAPI.create(email, username, password) do
      {:ok, account} ->
        # In the future we'll just pass the return to a protocol
        account =
          account
          |> Map.take([:account_id, :email])
          |> Map.put(:username, account.display_name)

        conn
        |> put_status(:ok)
        |> json(account)
      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _} ->
          message
        end)

        conn
        |> put_status(:bad_request)
        |> json(errors)
    end
  end

  def login(conn, %{"username" => username, "password" => password}) do
    case AccountAPI.login(username, password) do
      {:ok, account, token} ->

        result =
          account
          |> Map.take([:account_id])
          |> Map.put(:token, token)

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
