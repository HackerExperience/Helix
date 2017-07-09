defmodule Helix.Account.Action.Session do

  alias Helix.Account.Internal.Session, as: SessionInternal

  # REVIEW: Move below to a Session model? Seems more appropriate
  @type session :: SessionInternal.session
  @type token :: SessionInternal.token

  defdelegate generate_token(account),
    to: SessionInternal

  defdelegate validate_token(token),
    to: SessionInternal

  defdelegate invalidate_token(token),
    to: SessionInternal

  defdelegate invalidate_session(session),
    to: SessionInternal
end
