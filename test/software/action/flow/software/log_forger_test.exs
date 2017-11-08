# defmodule Helix.Software.Action.Flow.Software.LogForgerTest do

#   use Helix.Test.Case.Integration

#   alias Helix.Log.Action.Log, as: LogAction
#   alias Helix.Log.Model.Log
#   alias Helix.Software.Action.Flow.Software.LogForger, as: LogForgerFlow
#   alias Helix.Software.Model.SoftwareType.LogForge

#   alias Helix.Test.Process.TOPHelper
#   alias Helix.Test.Server.Setup, as: ServerSetup
#   alias Helix.Test.Software.Helper, as: SoftwareHelper
#   alias Helix.Test.Software.Setup, as: SoftwareSetup

#   describe "execute/3 for 'create' operation" do
#     test "fails if target log doesn't exist" do
#       {server, %{entity: entity}} = ServerSetup.server()

#       storage_id = SoftwareHelper.get_storage_id(server)
#      {file, _} = SoftwareSetup.file(type: :log_forger, storage_id: storage_id)

#       params = %{
#         target_log_id: Log.ID.generate(),
#         message: "I say hey hey",
#         operation: :edit,
#         entity_id: entity.entity_id
#       }

#       result = LogForgerFlow.execute(file, server.server_id, params)
#       assert {:error, {:log, :notfound}} == result
#     end

#     test "starts log_forger process on success" do
#       {server, %{entity: entity}} = ServerSetup.server()

#       storage_id = SoftwareHelper.get_storage_id(server)
#      {file, _} = SoftwareSetup.file(type: :log_forger, storage_id: storage_id)

#       {:ok, log, _} =
#         LogAction.create(server, entity.entity_id, "Root logged in")

#       params = %{
#         target_log_id: log.log_id,
#         message: "",
#         operation: :edit,
#         entity_id: entity.entity_id
#       }

#       result = LogForgerFlow.execute(file, server.server_id, params)
#       assert {:ok, process} = result
#       assert %LogForge{} = process.data
#       assert "log_forger" == process.type

#       TOPHelper.top_stop(server)
#     end
#   end

#   describe "log_forger 'create' operation" do
#     test "starts log_forger process on success" do
#       {server, %{entity: entity}} = ServerSetup.server()

#       storage_id = SoftwareHelper.get_storage_id(server)
#      {file, _} = SoftwareSetup.file(type: :log_forger, storage_id: storage_id)

#       params = %{
#         target_id: server,
#         message: "",
#         operation: :create,
#         entity_id: entity.entity_id
#       }

#       result = LogForgerFlow.execute(file, server.server_id, params)
#       assert {:ok, process} = result
#       assert %LogForge{} = process.data
#       assert "log_forger" == process.type

#       TOPHelper.top_stop(server)
#     end
#   end
# end
