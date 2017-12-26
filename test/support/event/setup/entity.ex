defmodule Helix.Test.Event.Setup.Entity do

  alias Helix.Entity.Action.Entity, as: EntityAction

  alias Helix.Test.Account.Setup, as: AccountSetup

  def created(source: :account) do
    {:ok, _, [event]} =
      AccountSetup.account!()
      |> EntityAction.create_from_specialization()

    event
  end
end
