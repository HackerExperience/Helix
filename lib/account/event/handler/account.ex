defmodule Helix.Account.Event.Handler.Account do

  alias Helix.Account.Event.Account.Created, as: AccountCreatedEvent
  alias Helix.Account.Action.Flow.Account, as: AccountFlow

  require Logger

  def account_created(event = %AccountCreatedEvent{}) do
    case AccountFlow.setup_account(event.account) do
      {:ok, _} ->
        :ok
      _ ->
        Logger.error "Failed to setup account for account id #{inspect event.account_id}"
    end
  end
end
