defmodule Helix.Software.Process.File.Transfer do
  @moduledoc """
  SoftwareFileTransferProcess is the process responsible for transferring files
  from one storage to another. It currently implements the `download`, `upload`
  and `pftp_download` backends.

  Its process data consists basically of notifying what is the backend, and what
  storage the file is being transferred to. All other information, like which
  file is being transferred, is already present on the standard process data.
  """

  alias Helix.Software.Model.Storage

  @type t :: %{
    type: :download | :upload,
    destination_storage_id: Storage.id,
    connection_type: :ftp | :public_ftp
  }

  @enforce_keys [:type, :destination_storage_id, :connection_type]
  defstruct [:type, :destination_storage_id, :connection_type]

  def objective(:download, file),
    do: %{dlk: file.file_size}
  def objective(:upload, file),
    do: %{ulk: file.file_size}

  defimpl Helix.Process.Model.Process.ProcessType do
    @moduledoc """
    ProcessType handler for SoftwareFileTransferProcess

    All events emitted here are generic, i.e. they are not directly related to
    the backend using FileTransferProcess.

    For example, FileTransferProcessedEvent is emitted on conclusion, regardless
    if the backend is `download`, `upload` or `pftp_download`
    """

    import Helix.Process.Model.Macros

    alias Helix.Server.Model.Server

    alias Helix.Software.Event.File.Transfer.Aborted,
      as: FileTransferAbortedEvent
    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    def dynamic_resources(%{type: :download}),
      do: [:dlk]
    def dynamic_resources(%{type: :upload}),
      do: [:ulk]

    def minimum(_),
      do: %{}

    def kill(data, process, _) do
      process = unchange(process)

      context = get_servers_context(data, process)
      event = process_abortion(data, process, context)

      {delete(process), [event]}
    end

    def state_change(data, process, _, :complete) do
      process = unchange(process)

      context = get_servers_context(data, process)
      event = process_completion(data, process, context)

      {delete(process), [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    @spec get_servers_context(data :: term, process :: term) ::
      context :: {from_server :: Server.id, to_server :: Server.id}
    defp get_servers_context(%{type: :download}, process),
      do: {process.target_server_id, process.gateway_id}
    defp get_servers_context(%{type: :upload}, process),
      do: {process.gateway_id, process.target_server_id}

    defp process_completion(data, process, {from_server_id, to_server_id}) do
      %FileTransferProcessedEvent{
        entity_id: process.source_entity_id,
        to_server_id: to_server_id,
        from_server_id: from_server_id,
        file_id: process.file_id,
        network_id: process.network_id,
        to_storage_id: data.destination_storage_id,
        connection_type: data.connection_type,
        type: data.type
      }
    end

    defp process_abortion(data, process, {from_server_id, to_server_id}) do
      %FileTransferAbortedEvent{
        entity_id: process.source_entity_id,
        to_server_id: to_server_id,
        from_server_id: from_server_id,
        file_id: process.file_id,
        network_id: process.network_id,
        to_storage_id: data.destination_storage_id,
        connection_type: data.connection_type,
        type: data.type,
        reason: :killed
      }
    end

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end

  defimpl Helix.Process.Public.View.ProcessViewable do

    alias Helix.Process.Public.View.Process.Helper, as: ProcessViewHelper

    @type data ::
      data_download_full
      | data_download_partial
      | data_upload

    @typep data_download_full ::
      %{
        connection_type: String.t,
        storage_id: String.t
      }

    @typep data_download_partial ::
      %{
        connection_type: String.t
      }

    @typep data_upload :: %{}

    def get_scope(data, process, server, entity),
      do: ProcessViewHelper.get_default_scope(data, process, server, entity)

    def render(data, process, scope) do
      base = render_process(process, scope)
      complement = render_data(data, scope)

      {base, complement}
    end

    defp render_data(data = %{type: :download}, :full) do
      %{
        connection_type: to_string(data.connection_type),
        storage_id: to_string(data.destination_storage_id)
      }
    end
    defp render_data(data = %{type: :download}, :partial) do
      %{
        connection_type: to_string(data.connection_type)
      }
    end
    defp render_data(_, _),
      do: %{}

    defp render_process(process, scope),
      do: ProcessViewHelper.default_process_render(process, scope)
  end
end
