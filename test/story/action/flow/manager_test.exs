defmodule Helix.Story.Action.Flow.ManagerTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Action.Flow.Manager, as: ManagerFlow

  alias Helix.Test.Entity.Setup, as: EntitySetup

  describe "setup_story_network/1" do
    test "prepares the storyline network" do
      {entity, _} = EntitySetup.entity()

      assert {:ok, network, nc} = ManagerFlow.setup_story_network(entity)

      # Created a Network of type `story`
      assert network.type == :story

      # Also created a NetworkConnection on that Network
      assert nc.network_id == network.network_id
      assert nc.entity_id == entity.entity_id
    end
  end
end
