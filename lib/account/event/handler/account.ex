defmodule Helix.Account.Event.Handler.Account do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Event.Account.Created, as: AccountCreatedEvent

  @doc """
  When an account is created, we must set up its initial server, storyline etc.

  TODO: It should be on AccountVerifiedEvent. #335.
  """
  def account_created(event = %AccountCreatedEvent{}),
    do: AccountFlow.setup_account(event.account, event)
end
