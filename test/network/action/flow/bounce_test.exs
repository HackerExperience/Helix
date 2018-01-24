defmodule Helix.Network.Action.Flow.BounceTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros

  alias Helix.Network.Action.Flow.Bounce, as: BounceFlow
  alias Helix.Network.Query.Bounce, as: BounceQuery

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @relay nil

  describe "create/4" do
    test "creates a bounce entry with the given links" do
      entity_id = EntitySetup.id()
      links = NetworkHelper.Bounce.links(total: 3)
      name = NetworkHelper.Bounce.name()

      assert {:ok, bounce} = BounceFlow.create(entity_id, name, links, @relay)

      assert bounce.links == links
      assert bounce.name == name
      assert bounce.entity_id == entity_id

      assert_map bounce, BounceQuery.fetch(bounce.bounce_id), skip: :sorted
    end
  end
end
