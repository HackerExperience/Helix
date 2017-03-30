defmodule Helix.Account.Service.API.Session do

  alias Helix.Account.Controller.Session, as: SessionController
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Session

  @spec generate_token(Account.t) :: Session.session
  def generate_token(account) do
    {:ok, jwt} = SessionController.create(account)
    jwt
  end

  @spec validate_token(Session.session) ::
  {:ok, claims :: map}
  | {:error, :unauthorized}
  def validate_token(token) do
    SessionController.validate(token)
  end
end
