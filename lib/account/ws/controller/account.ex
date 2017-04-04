defmodule Helix.Account.WS.Controller.Account do

  alias Helix.Account.Service.API.Account, as: AccountAPI
  alias Helix.Account.Model.Session

  @typep json_response ::
    {:ok, map}
    | {:error, status :: integer, map}
    | {:error, atom}

  @spec register(term, %{:email => String.t, :username => String.t, :password => String.t, optional(atom) => any}) ::
    json_response
  # Plug-like format
  def register(_request, params) do
    case AccountAPI.create(params) do
      {:ok, account} ->
        # In the future we'll just pass the return to a protocol

        # Note that we are wrapping it in a 2-tuple because Router expects it
        # that way
        {:ok, Helix.Account.WS.View.Account.format(account)}
      {:error, changeset} ->
        # Note that we are wrapping it in a 2-tuple because Router expects it
        # that way
        {:error, {400, Helix.Account.WS.View.Account.format(changeset)}}
    end
  end

  @spec login(term, %{:username => String.t, :password => String.t, optional(atom) => any}) ::
    json_response
  def login(_request, %{username: username, password: password}) do
    case AccountAPI.login(username, password) do
      {:ok, jwt} ->
        {:ok, %{:token => jwt}}
      {:error, :notfound} ->
        {:error, :notfound}
    end
  end

  def login(_, _) do
    {:error, :bad_request}
  end

  @spec logout(%{jwt: Session.t}, term) :: json_response
  def logout(%{jwt: session}, _) do
    case AccountAPI.logout(session) do
      :ok ->
        {:ok, %{}}
      {:error, changeset} ->
        {:error, {400, Helix.Account.WS.View.Account.format(changeset)}}
    end
  end

  def logout(_, _) do
    {:error, :bad_request}
  end
end
