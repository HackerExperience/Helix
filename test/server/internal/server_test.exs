defmodule Helix.Server.Internal.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server

  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "fetch/1" do
    test "succeeds by id" do
      {server, _} = ServerSetup.server
      assert %Server{} = ServerInternal.fetch(server.server_id)
    end

    test "fails when server doesn't exists" do
      refute ServerInternal.fetch(Server.ID.generate())
    end
  end

  describe "fetch_by_motherboard/1" do
    test "succeeds with mobo id" do
      {server, _} = ServerSetup.server()

      result = ServerInternal.fetch_by_motherboard(server.motherboard_id)
      assert server.server_id == result.server_id
    end

    test "fails with non-existing id" do
      refute ServerInternal.fetch_by_motherboard(Component.ID.generate())
    end

    test "succeeds with mobo component" do
      {server, _} = ServerSetup.server()

      motherboard = MotherboardInternal.fetch(server.motherboard_id)
      result = ServerInternal.fetch_by_motherboard(motherboard)

      assert result.server_id == server.server_id
    end

    test "fails with non-existing component" do
      bogus_mobus = %Motherboard{motherboard_id: Component.ID.generate()}
      refute ServerInternal.fetch_by_motherboard(bogus_mobus)
    end
  end

  describe "creating" do
    test "succeeds with valid server_type" do
      params = %{server_type: :desktop}

      assert {:ok, _} = ServerInternal.create(params)
    end

    test "fails with invalid server_type" do
      {:error, cs} = ServerInternal.create(%{server_type: :foobar})
      assert :server_type in Keyword.keys(cs.errors)
    end
  end

  describe "set_hostname/2" do
    test "updates hostname" do
      {server, _} = ServerSetup.server()

      hostname = "transltr"
      refute server.hostname == hostname

      assert {:ok, updated} = ServerInternal.set_hostname(server, hostname)
      assert updated.hostname == hostname

      entry = ServerInternal.fetch(server.server_id)
      assert entry.hostname == hostname
    end
  end

  describe "delete/1" do
    test "removes entry" do
      {server, _} = ServerSetup.server()

      # Server exists
      assert ServerInternal.fetch(server.server_id)

      ServerInternal.delete(server)

      # No longer exists
      refute ServerInternal.fetch(server.server_id)

      CacheHelper.sync_test()
    end
  end
end
