defmodule Helix.Account.Event.Account do

  alias Helix.Account.Model.Account.AccountCreatedEvent
  alias Helix.Account.Action.Flow.Account, as: AccountFlow

  require Logger

  def account_create(event = %AccountCreatedEvent{}) do
    case AccountFlow.setup_account(event.account_id) do
      {:ok, _} ->
        :ok
      _ ->
        Logger.error "Failed to setup account for account id #{inspect event.account_id}"
    end
  end
end
