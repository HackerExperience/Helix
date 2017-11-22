defmodule Helix.Account.Event.Handler.Account do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Event.Account.Created, as: AccountCreatedEvent

  def account_created(event = %AccountCreatedEvent{}),
    do: AccountFlow.setup_account(event.account, event)
end
