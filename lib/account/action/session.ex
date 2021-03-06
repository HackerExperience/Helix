defmodule Helix.Account.Action.Session do

  alias Helix.Account.Internal.Session, as: SessionInternal
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSession

  @spec generate_token(Account.t) ::
    {:ok, AccountSession.token}
    | {:error, Ecto.Changeset.t}
  defdelegate generate_token(account),
    to: SessionInternal

  @spec validate_token(AccountSession.token) ::
    {:ok, Account.t, AccountSession.id}
    | {:error, :unauthorized}
  defdelegate validate_token(token),
    to: SessionInternal

  @spec invalidate_session(AccountSession.id) ::
    :ok
  defdelegate invalidate_session(session),
    to: SessionInternal
end
