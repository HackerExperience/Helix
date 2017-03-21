defmodule Helix.Account.Controller.Session do

  alias Helix.Account.Model.Account

  @spec create(Account.id) :: {:ok, String.t} | {:error, :unauthorized}
  def create(account_id) do
    session = %{account_id: account_id}
    case Guardian.encode_and_sign(session, :access) do
      {:ok, jwt, _claims} ->
        {:ok, jwt}
      _ ->
        {:error, :unauthorized}
    end
  end

  @spec valid?(String.t) :: boolean
  def valid?(jwt),
    do: match?({:ok, _}, Guardian.decode_and_verify(jwt))
end