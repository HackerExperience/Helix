defmodule Helix.Story.Event.Handler.ManagerTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Context, as: ContextQuery
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "handling of EntityCreatedEvent" do
    test "storyline server/hardware/network is set up properly" do
      event = %{entity: entity} = EventSetup.Entity.created(source: :account)

      EventHelper.emit(event)

      # Storyline server was created
      assert [server_id] = EntityQuery.get_servers(entity)
      server = ServerQuery.fetch(server_id)

      assert server
      assert server.type == :desktop_story

      # NetworkConnection is valid too
      assert [story_nc] = EntityQuery.get_network_connections(entity)

      # Storyline Network was created
      story_network = NetworkQuery.fetch(story_nc.network_id)
      assert story_network.type == :story

      motherboard = MotherboardQuery.fetch(server.motherboard_id)
      [nic] = MotherboardQuery.get_nics(motherboard)

      # NC was assigned to server NIC
      assert story_nc.nic_id == nic.component_id

      # Server NIC points to the Story network
      assert nic.custom.network_id == story_nc.network_id

      # Now we'll make sure that the newly created Entity has joined a step
      assert [%{entry: _story_step, object: step}] =
        StoryQuery.get_steps(entity.entity_id)

      # Which happens to be the first one
      assert step.name == Step.first_step_name()

      # And the Story.Context entry has been created for that Entity
      assert ContextQuery.fetch(entity.entity_id)
    end
  end
end
