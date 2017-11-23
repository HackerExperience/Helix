defmodule Helix.Process.Query.TOPTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Component.Specable
  alias Helix.Process.Query.TOP, as: TOPQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id NetworkHelper.internet_id()

  describe "load_top_resources/1" do
    test "loads all resources on server" do
      {server, _} = ServerSetup.server()

      resources = TOPQuery.load_top_resources(server.server_id)

      # Note: dlk/ulk values are hard-coded because we don't have the ISP API.
      # Update when we do
      assert resources.cpu == get_initial_resource(:cpu, :clock)
      assert resources.ram == get_initial_resource(:ram, :size)
      assert resources.dlk[@internet_id] == 128
      assert resources.ulk[@internet_id] == 16
    end

    defp get_initial_resource(component_type, resource) do
      component_type
      |> Specable.get_initial()
      |> Specable.fetch()
      |> Map.fetch!(resource)
    end
  end
end
