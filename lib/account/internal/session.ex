defmodule Helix.Account.Internal.Session do

  alias Phoenix.Token
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Internal.AccountSession, as: AccountSessionInternal

  # 1 Week
  @max_age 7 * 24 * 60 * 60

  @spec generate_token(Account.t) ::
    {:ok, AccountSession.token}
    | {:error, Ecto.Changeset.t}
  def generate_token(account) do
    case AccountSessionInternal.create(account) do
      {:ok, session} ->
        {:ok, sign(session.session_id)}
      error ->
        error
    end
  end

  @spec validate_token(AccountSession.token) ::
    {:ok, Account.t, AccountSession.id}
    | {:error, :unauthorized}
  def validate_token(token) do
    with \
      {:ok, session} <- verify(token),
      account_session = %{} <- AccountSessionInternal.fetch(session),
      account = %{} <- AccountSessionInternal.get_account(account_session)
    do
      {:ok, account, session}
    else
      _ ->
        {:error, :unauthorized}
    end
  end

  # Review: @charlots `invalidate_token` is never called; `invalidate_session`
  # is called directly. Shouldn't it be the opposite?
  @spec invalidate_token(AccountSession.token) ::
    :ok
  def invalidate_token(token) do
    with \
      {:ok, session} <- verify(token),
      session = %{} <- AccountSessionInternal.fetch(session)
    do
      invalidate_session(session)
    end

    :ok
  end

  @spec invalidate_session(AccountSession.t | AccountSession.id) ::
    :ok
  defdelegate invalidate_session(session_or_session_id),
    to: AccountSessionInternal,
    as: :delete

  @spec sign(AccountSession.id) ::
    AccountSession.token
  defp sign(session),
    do: Token.sign(Helix.Endpoint, "player", session)

  @spec verify(AccountSession.token) ::
    {:ok, AccountSession.id}
    | {:error, :invalid | :expired}
  defp verify(token),
    do: Token.verify(Helix.Endpoint, "player", token, max_age: @max_age)
end
