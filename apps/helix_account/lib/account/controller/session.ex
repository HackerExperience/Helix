defmodule Helix.Account.Controller.Session do

  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Session

  @spec create(Account.t) :: {:ok, Session.session}
  def create(account) do
    {:ok, jwt, _claims} = Guardian.encode_and_sign(account, :access)
    {:ok, jwt}
  end

  @spec validate(Session.session) ::
  {:ok, claims :: map}
  | {:error, :unauthorized}
  def validate(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, claims} ->
        {:ok, claims}
      {:error, _} ->
        {:error, :unauthorized}
    end
  end
end
