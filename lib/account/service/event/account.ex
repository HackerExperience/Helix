defmodule Helix.Account.Service.Event.Account do

  alias Helix.Account.Model.Account.AccountCreatedEvent
  alias Helix.Account.Service.Flow.Account, as: Flow

  require Logger

  def account_create(event = %AccountCreatedEvent{}) do
    case Flow.setup_account(event.account_id) do
      {:ok, _} ->
        :ok
      _ ->
        Logger.error "Failed to setup account for account id #{inspect event.account_id}"
    end
  end
end
