# defmodule Helix.Software.Model.Software.Decryptor.ProcessType do

#   @enforce_keys [:storage_id, :target_file_id, :scope, :software_version]
#   defstruct [:storage_id, :target_file_id, :scope, :software_version]

#   defimpl Helix.Process.Model.Process.ProcessType do

#     alias Helix.Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent

#     @ram_base_factor 100

#     # The only value that is dynamic (ie: the more allocated, the faster the
#     # process goes) is cpu
#     def dynamic_resources(_),
#       do: [:cpu]

#     def minimum(%{software_version: v}),
#       do: %{
#         paused: %{
#           ram: v * @ram_base_factor
#         },
#         running: %{
#           ram: v * @ram_base_factor
#         }
#     }

#     def kill(_, process, _),
#       do: {%{Ecto.Changeset.change(process)| action: :delete}, []}

#     def state_change(data, process, _, :complete) do
#       process =
#         process
#         |> Ecto.Changeset.change()
#         |> Map.put(:action, :delete)

#       event = %ProcessConclusionEvent{
#         target_file_id: data.target_file_id,
#         target_server_id: Ecto.Changeset.get_field(process, :target_server_id),
#         storage_id: data.storage_id,
#         scope: data.scope
#       }

#       {process, [event]}
#     end

#     def state_change(_, process, _, _),
#       do: {process, []}

#     def conclusion(data, process),
#       do: state_change(data, process, :running, :complete)

#     def after_read_hook(data),
#         do: data
#   end

#   defimpl Helix.Process.Public.View.ProcessViewable do

#     alias Helix.Software.Model.File
#     alias Helix.Process.Model.Process
#     alias Helix.Process.Public.View.Process, as: ProcessView
#     alias Helix.Process.Public.View.Process.Helper, as: ProcessViewHelper

#     @type full_data ::
#       %{
#         target_file_id: File.id,
#         software_version: FileModule.version,
#         scope: term
#       }

#     @type partial_data ::
#       %{
#         target_file_id: File.id
#       }

#     def get_scope(data, process, server, entity),
#       do: ProcessViewHelper.get_default_scope(data, process, server, entity)

#     @spec render(map, Process.t, ProcessView.scopes) ::
#       {ProcessView.full_process, full_data}
#       | {ProcessView.partial_process, partial_data}
#     def render(data, process, scope) do
#       base = take_data_from_process(process, scope)
#       complement = %{
#         target_file_id: data.target_file_id
#       }

#       {base, complement}
#     end

#     defp take_data_from_process(process, scope),
#       do: ProcessViewHelper.default_process_render(process, scope)
#   end
# end
