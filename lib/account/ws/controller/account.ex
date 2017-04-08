defmodule Helix.Account.WS.Controller.Account do

  alias Helix.Account.Model.Session
  alias Helix.Account.Service.API.Account, as: AccountAPI
  alias Helix.Account.WS.View.Account, as: AccountView

  @typep json_response ::
    {:ok, map}
    | {:error, map}

  @spec register(term, %{optional(String.t) => any}) ::
    json_response
  def register(
    _request,
    %{"username" => username, "password" => password, "email" => email})
  do
    case AccountAPI.create(email, username, password) do
      {:ok, account} ->
        # In the future we'll just pass the return to a protocol

        {:ok, AccountView.format(account)}
      {:error, changeset} ->
        {:error, AccountView.format(changeset)}
    end
  end

  @spec login(term, %{optional(String.t) => any}) ::
    json_response
  def login(_request, %{"username" => username, "password" => password}) do
    case AccountAPI.login(username, password) do
      {:ok, jwt} ->
        {:ok, %{token: jwt}}
      {:error, :notfound} ->
        {:error, %{message: "not found"}}
    end
  end

  def login(_, _) do
    {:error, %{message: "bad request"}}
  end

  @spec logout(%{token: Session.t}, map) :: json_response
  def logout(%{token: token}, _) do
    AccountAPI.logout(token)

    {:ok, %{}}
  end
end
