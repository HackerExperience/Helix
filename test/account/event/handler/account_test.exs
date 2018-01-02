defmodule Helix.Account.Event.Handler.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Event.Setup, as: EventSetup

  describe "account_created" do
    test "creates initial server for account" do
      event = EventSetup.Account.verified()

      # Simulate the AccountVerifiedEvent
      Event.emit(event)

      # Entity was created
      entity =
        event.account.account_id
        |> EntityQuery.get_entity_id()
        |> EntityQuery.fetch()

      assert %Entity{} = entity

      # Server too!
      [_story_server, server_id] = EntityQuery.get_servers(entity)
      server = ServerQuery.fetch(server_id)

      assert %Server{} = server

      # Motherboard is fine
      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      # Each sub component is valid too
      Enum.each(motherboard.slots, fn {_slot_id, component} ->
        assert ComponentQuery.fetch(component.component_id)
      end)
    end
  end
end
