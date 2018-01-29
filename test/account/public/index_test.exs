defmodule Helix.Account.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Account.Public.Index, as: AccountIndex

  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "index/1" do
    test "returns the expected data" do
      {server, %{entity: entity}} = ServerSetup.server()

      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      index = AccountIndex.index(entity)

      assert index.mainframe == server.server_id
      assert index.inventory
      assert index.bounces == [bounce]
    end
  end

  describe "render_index/1" do
    test "returns JSON-friendly index" do
      {server, %{entity: entity}} = ServerSetup.server()

      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      rendered =
        entity
        |> AccountIndex.index()
        |> AccountIndex.render_index()

      # Mainframe is valid
      assert rendered.mainframe == to_string(server.server_id)

      # Bounce is valid
      assert [rendered_bounce] = rendered.bounces
      assert rendered_bounce.bounce_id == to_string(bounce.bounce_id)
      assert rendered_bounce.name == bounce.name
      Enum.each(rendered_bounce.links, fn link ->
        assert is_binary(link.network_id)
        assert is_binary(link.ip)
      end)
    end
  end
end
