defmodule Helix.Account.HTTP.Controller.Webhook do

  use Phoenix.Controller

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Account.AccountCreatedEvent
  alias Helix.Account.Repo

  import Plug.Conn

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
          event = %AccountCreatedEvent{account_id: account.account_id}

          {account, [event]}
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
