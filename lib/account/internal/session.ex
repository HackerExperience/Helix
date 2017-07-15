defmodule Helix.Account.Internal.Session do

  alias Phoenix.Token
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Repo

  import Ecto.Query, only: [where: 3]

  # 1 Week
  @max_age 7 * 24 * 60 * 60

  @spec generate_token(Account.t) ::
    AccountSession.token
  def generate_token(account) do
    changeset = AccountSession.create(account)

    account_session = Repo.insert!(changeset)

    sign(account_session.session_id)
  end

  @spec validate_token(AccountSession.token) ::
    {:ok, Account.t, AccountSession.session}
    | {:error, :unauthorized}
  def validate_token(token) do
    with \
      {:ok, session} <- verify(token),
      account_session = %{} <- Repo.get(AccountSession, session)
    do
      account = Repo.preload(account_session, :account).account

      {:ok, account, session}
    else
      _ ->
        {:error, :unauthorized}
    end
  end

  @spec invalidate_token(AccountSession.token) ::
    :ok
  def invalidate_token(token) do
    with {:ok, session} <- verify(token) do
      invalidate_session(session)
    end

    :ok
  end

  @spec invalidate_session(AccountSession.session) ::
    :ok
  def invalidate_session(session) do
    AccountSession
    |> where([s], s.session_id == ^session)
    |> Repo.delete_all()

    :ok
  end

  defp sign(session),
    do: Token.sign(Helix.Endpoint, "player", session)

  defp verify(token),
    do: Token.verify(Helix.Endpoint, "player", token, max_age: @max_age)
end
