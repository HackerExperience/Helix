# TODO: Superseded by Process.Executable. Rewrite. Use Bruteforce as example.
# defmodule Helix.Software.Action.Flow.Software.Firewall do

#   import HELF.Flow

#   alias Helix.Event
#   alias Helix.Process.Model.Process
#   alias Helix.Process.Action.Process, as: ProcessAction
#   alias Helix.Server.Model.Server
#   alias Helix.Software.Model.File
#  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: FirewallPassive

#   alias Helix.Software.Event.Firewall.Started, as: FirewallStartedEvent

#   @type params :: %{}
#   @type on_execute_error :: ProcessAction.on_create_error

#   @spec execute(File.t_of_type(:firewall), Server.id, params) ::
#     {:ok, Process.t}
#     | on_execute_error
#   def execute(file, server, _params) do
#     process_data = %FirewallPassive{version: file.modules.fwl_passive.version}

#     params = %{
#       gateway_id: server,
#       target_id: server,
#       file_id: file.file_id,
#       process_data: process_data,
#       process_type: "firewall_passive"
#     }

#     event = %FirewallStartedEvent{
#       gateway_id: server,
#       version: file.modules.fwl_passive.version
#     }

#     flowing do
#       with \
#         {:ok, process, p_events} <- ProcessAction.create(params),
#         on_success(fn -> Event.emit(p_events) end),
#         on_success(fn -> Event.emit(event) end)
#       do
#         {:ok, process}
#       end
#     end
#   end
# end
