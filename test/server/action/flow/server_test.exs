defmodule Helix.Server.Action.Flow.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Query.Component, as: ComponentQuery

  alias Helix.Test.Entity.Setup, as: EntitySetup

  @relay nil

  describe "setup/3" do
    test "creates desktop server from initial hardware/setup" do
      {entity, _} = EntitySetup.entity()

      assert {:ok, motherboard, mobo} =
        MotherboardFlow.initial_hardware(entity, @relay)

      assert {:ok, server} = ServerFlow.setup(:desktop, entity, mobo, @relay)

      assert server.motherboard_id == mobo.component_id
    end
  end
end
