defmodule Helix.Test.Event.Setup.Account do

  alias Helix.Account.Event.Account.Created, as: AccountCreatedEvent
  alias Helix.Account.Event.Account.Verified, as: AccountVerifiedEvent

  alias Helix.Test.Account.Setup, as: AccountSetup

  def created do
    {account, _} = AccountSetup.account(with_server: true)

    AccountCreatedEvent.new(account)
  end

  def verified do
    {account, _} = AccountSetup.account()

    AccountVerifiedEvent.new(account)
  end
end
