defmodule Helix.Account.HTTP.Controller.Webhook do

  use Phoenix.Controller

  import Plug.Conn

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  alias Helix.Account.Event.Account.Created, as: AccountCreatedEvent
  alias Helix.Account.Event.Account.Verified, as: AccountVerifiedEvent

  plug :authenticate

  defp get_token do
    case Application.get_env(:helix, :migration_token) do
      "${HELIX_MIGRATION_TOKEN}" ->
        raise "Migration token not set"
      token when is_binary(token) ->
        token
      _ ->
        raise "Migration token not set"
    end
  end

  # Ensures that the request has the expected authorization bearer token,
  # otherwise blocks it
  defp authenticate(conn, _) do
    token = get_token()
    case get_req_header(conn, "authorization") do
      ["Bearer " <> ^token] ->
        # Request has expected token and thus is valid
        conn
      _ ->
        # Request does not include expected token and must be halted
        conn
        |> put_status(:forbidden)
        |> json(%{status: :error, message: "invalid token"})
        |> halt()
    end
  end

  def import_from_migration(conn, params) do
    %{"username" => username, "password" => password, "email" => email} = params

    # HACK: The account controller should (and will) always hash the creation
    #   password but since we are receiving an already hashed password, we have
    #   to force our way into creating an account without the hashing part
    #   (actually without any check at all) because an external agent (the
    #   HEBornMigration application) already did all necessary checks to ensure
    #   this input is valid.
    #   TL;DR: we'll force-insert this data as a new account and repeat the
    #   controller code to ensure we cause the same side-effect as if the user
    #   was created the "expected way"
    {:ok, {acc, events}} = Repo.transaction fn ->
      case Repo.get_by(Account, username: String.downcase(username)) do
        nil ->
          # Account does not exists
          account = %Account{
            password: password,
            email: String.downcase(email),
            username: String.downcase(username),
            display_name: username,
            confirmed: true
          }
          account = Repo.insert!(account)
          e1 = AccountCreatedEvent.new(account)
          e2 = AccountVerifiedEvent.new(account)

          {account, [e1, e2]}
        account ->
          # Account exists, so creation is ignored
          {account, []}
      end
    end

    Event.emit(events)

    conn
    |> put_status(:ok)
    |> json(%{status: :success, data: acc})
  end
end
