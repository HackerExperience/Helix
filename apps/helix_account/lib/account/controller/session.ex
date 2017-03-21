defmodule Helix.Account.Controller.Session do

  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Session

  @spec create(Account.t) :: {:ok, Session.session} | {:error, :unauthorized}
  def create(account) do
    case Guardian.encode_and_sign(account, :access) do
      {:ok, jwt, _claims} ->
        {:ok, jwt}
      _ ->
        {:error, :unauthorized}
    end
  end

  @spec valid?(Session.session) :: boolean
  def valid?(jwt),
    do: match?({:ok, _}, Guardian.decode_and_verify(jwt))
end