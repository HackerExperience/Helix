defmodule Helix.Software.Model.Software.Encryptor.ProcessType do

  @enforce_keys [:storage_id, :target_file_id, :software_version]
  defstruct [:storage_id, :target_file_id, :software_version]

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Helix.Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent

    @ram_base_factor 100

    # The only value that is dynamic (ie: the more allocated, the faster the
    # process goes) is cpu
    def dynamic_resources(_),
      do: [:cpu]

    def minimum(%{software_version: v}),
      do: %{
        paused: %{
          ram: v * @ram_base_factor
        },
        running: %{
          ram: v * @ram_base_factor
        }
    }

    def kill(_, process, _),
      do: {%{Ecto.Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %ProcessConclusionEvent{
        target_file_id: data.target_file_id,
        target_server_id: Ecto.Changeset.get_field(process, :target_server_id),
        storage_id: data.storage_id,
        version: data.software_version
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end

  defimpl Helix.Process.Public.View.ProcessViewable do

    alias Helix.Entity.Model.Entity
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Process.Model.Process
    alias Helix.Process.Public.View.Process, as: ProcessView
    alias Helix.Process.Public.View.Process.Helper, as: ProcessViewHelper

    @type local_data ::
      %{
        target_file_id: File.id,
        software_version: File.module_version,
        scope: term  # Review: what's this?
      }

    @type remote_data ::
      %{
        target_file_id: File.id
      }

    @spec render(map, Process.t, Server.id, Entity.id) ::
      {ProcessView.local_process, local_data}
      | {ProcessView.remote_process, remote_data}
    def render(data, process = %{gateway_id: server}, server, _),
      do: do_render(data, process, :local)
    def render(data, process, _, _),
      do: do_render(data, process, :remote)

    defp do_render(data, process, scope) do
      base = take_data_from_process(process, scope)
      complement = take_complement_from_data(data, scope)

      {base, complement}
    end

    defp take_complement_from_data(data, :local) do
      %{
        target_file_id: data.target_file_id,
        software_version: data.software_version,
        scope: data.scope
      }
    end
    defp take_complement_from_data(data, :remote) do
      %{
        target_file_id: data.target_file_id
      }
    end

    defp take_data_from_process(process, scope),
      do: ProcessViewHelper.default_process_render(process, scope)
  end
end
