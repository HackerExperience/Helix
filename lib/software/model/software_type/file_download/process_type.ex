defmodule Helix.Software.Model.Software.FileDownload.ProcessType do

  @enforce_keys [:target_file_id, :destination_storage_id]
  defstruct [:target_file_id, :destination_storage_id]

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent

    def dynamic_resources(_),
      do: [:dlk]

    def minimum(_),
      do: %{}

    def kill(_, process, _),
      do: {%{Ecto.Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %ProcessConclusionEvent{
        to_server_id: Ecto.Changeset.get_field(process, :gateway_id),
        from_server_id: Ecto.Changeset.get_field(process, :target_server_id),
        from_file_id: data.target_file_id,
        to_storage_id: data.destination_storage_id,
        network_id: Ecto.Changeset.get_field(process, :network_id)
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end

  defimpl Helix.Process.Public.View.ProcessViewable do

    alias Helix.Software.Model.File
    alias Helix.Process.Model.Process
    alias Helix.Process.Public.View.Process, as: ProcessView
    alias Helix.Process.Public.View.Process.Helper, as: ProcessViewHelper

    # Review: why use `target_file_id` when we have `file_id`?
    @type data ::
      %{
        target_file_id: File.id
      }

    def get_scope(data, process, server, entity),
      do: ProcessViewHelper.get_default_scope(data, process, server, entity)

    @spec render(map, Process.t, ProcessView.scopes) ::
      {ProcessView.full_process | ProcessView.partial_process, data}
    def render(data, process, scope) do
      base = take_data_from_process(process, scope)
      complement = take_complement_from_data(data)

      {base, complement}
    end

    defp take_complement_from_data(data) do
      %{
        target_file_id: data.target_file_id
      }
    end

    defp take_data_from_process(process, scope),
      do: ProcessViewHelper.default_process_render(process, scope)
  end
end
