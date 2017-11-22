defmodule Helix.Test.Event.Setup.Account do

  alias Helix.Account.Event.Account.Created, as: AccountCreatedEvent

  alias Helix.Test.Account.Setup, as: AccountSetup

  def created do
    {account, _} = AccountSetup.account()

    AccountCreatedEvent.new(account)
  end

  # TODO #335
  def verified do
    created()
  end
end
