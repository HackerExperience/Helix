defmodule Helix.Account.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Account.Public.Index, as: AccountIndex

  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "index/1" do
    test "returns the expected data" do
      {server, %{entity: entity}} = ServerSetup.server()

      index = AccountIndex.index(entity)

      assert index.mainframe == server.server_id
    end
  end

  describe "render_index/1" do
    test "returns JSON-friendly index" do
      {_, %{entity: entity}} = ServerSetup.server()

      rendered =
        entity
        |> AccountIndex.index()
        |> AccountIndex.render_index()

      assert is_binary(rendered.mainframe)
    end
  end
end
