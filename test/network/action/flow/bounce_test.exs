defmodule Helix.Network.Action.Flow.BounceTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Action.Flow.Bounce, as: BounceFlow
  alias Helix.Network.Query.Bounce, as: BounceQuery

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

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

      assert bounce == BounceQuery.fetch(bounce.bounce_id)
    end
  end

  describe "update/4" do
    test "updates an existing bounce with the given changes" do
      {bounce, _} = NetworkSetup.Bounce.bounce()

      new_name = NetworkHelper.Bounce.name()
      new_links = NetworkHelper.Bounce.links(total: 3)

      assert {:ok, new_bounce} =
        BounceFlow.update(bounce, new_name, new_links, @relay)

      assert new_bounce.name == new_name
      assert new_bounce.links == new_links

      assert new_bounce == BounceQuery.fetch(bounce.bounce_id)
    end
  end
end
