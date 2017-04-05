defmodule Helix.Account.Service.API.Session do

  alias Helix.Account.Controller.Session, as: SessionController
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Session

  @spec generate_token(Account.t) :: {Session.t, claims :: map}
  def generate_token(account) do
    {:ok, jwt, claims} = SessionController.create(account)
    {jwt, claims}
  end

  @spec validate_token(Session.t) ::
    {:ok, claims :: map}
    | {:error, :unauthorized}
  def validate_token(token) do
    SessionController.validate(token)
  end

  @spec invalidate_token(Session.t) :: :ok
  def invalidate_token(token),
    do: SessionController.invalidate(token)
end
