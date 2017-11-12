defmodule Helix.Server.Public.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Public.Server, as: ServerPublic

  alias Helix.Test.Server.Setup, as: ServerSetup

  @relay nil

  describe "set_hostname/3" do
    test "hostname is updated" do
      {server, _} = ServerSetup.server()

      hostname = "madmax"

      assert {:ok, new_server} =
        ServerPublic.set_hostname(server, hostname, @relay)

      assert new_server.hostname == hostname
    end
  end
end
