defmodule Helix.Account.Service.API.Session do

  alias Helix.Account.Controller.Session, as: SessionController

  @type session :: SessionController.session
  @type token :: SessionController.token

  defdelegate generate_token(account),
    to: SessionController

  defdelegate validate_token(token),
    to: SessionController

  defdelegate invalidate_token(token),
    to: SessionController

  defdelegate invalidate_session(session),
    to: SessionController
end
