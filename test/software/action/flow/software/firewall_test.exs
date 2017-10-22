# defmodule Helix.Software.Action.Flow.Software.FirewallTest do

#   use Helix.Test.Case.Integration

#   alias Helix.Software.Action.Flow.Software.Firewall, as: FirewallFlow
#  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: FirewallPassive

#   alias Helix.Test.Process.TOPHelper
#   alias Helix.Test.Server.Setup, as: ServerSetup
#   alias Helix.Test.Software.Helper, as: SoftwareHelper
#   alias Helix.Test.Software.Setup, as: SoftwareSetup

#   describe "firewall" do
#     test "starts firewall process on success" do
#       {server, _} = ServerSetup.server()

#       storage_id = SoftwareHelper.get_storage_id(server)
#       {file, _} = SoftwareSetup.file(type: :firewall, storage_id: storage_id)

#       result = FirewallFlow.execute(file, server.server_id, %{})
#       assert {:ok, process} = result
#       assert %FirewallPassive{} = process.process_data
#       assert "firewall_passive" == process.process_type

#       TOPHelper.top_stop(server)
#     end
#   end
# end
