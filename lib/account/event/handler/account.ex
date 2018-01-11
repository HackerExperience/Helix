defmodule Helix.Account.Event.Handler.Account do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Event.Account.Verified, as: AccountVerifiedEvent

  @doc """
  When an account is verified, we must set up its initial server, storyline etc.

  Emits EntityCreatedEvent
  """
  def account_created(event = %AccountVerifiedEvent{}),
    do: AccountFlow.setup_account(event.account, event)
end
