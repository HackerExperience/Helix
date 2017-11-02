defmodule Helix.Process.Query.TOPTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Query.TOP, as: TOPQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id NetworkHelper.internet_id()

  describe "load_top_resources/1" do
    test "loads all resources on server" do
      {server, _} = ServerSetup.server()

      resources = TOPQuery.load_top_resources(server.server_id)

      # Note: these assertions will fail once we modify the initial hardware,
      # but that's on purpose. Once that happens, we'll probably have a proper
      # API to fetch the total server resources, and we can use it to:
      #   - Make the assertions below dynamic (not hard-coded)
      #   - Create new tests with edge-cases on resource utilization
      assert resources.cpu == 1333
      assert resources.ram == 1024
      assert resources.dlk[@internet_id] == 100
      assert resources.ulk[@internet_id] == 100
    end
  end
end
