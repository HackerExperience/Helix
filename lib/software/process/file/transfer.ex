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

    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    def dynamic_resources(%{type: :download}),
      do: [:dlk]
    def dynamic_resources(%{type: :upload}),
      do: [:ulk]

    def minimum(_),
      do: %{}

    def kill(_, process, _) do
      {delete(process), []}
    end

    def state_change(data = %{type: :download}, process, _, :complete) do
      process = unchange(process)

      from_server_id = process.target_server_id
      to_server_id = process.gateway_id

      process_completion(from_server_id, to_server_id, data, process)
    end

    def state_change(data = %{type: :upload}, process, _, :complete) do
      process = unchange(process)

      from_server_id = process.gateway_id
      to_server_id = process.target_server_id

      process_completion(from_server_id, to_server_id, data, process)
    end

    def state_change(_, process, _, _),
      do: {process, []}

    defp process_completion(from_server_id, to_server_id, data, process) do
      event = %FileTransferProcessedEvent{
        entity_id: process.source_entity_id,
        to_server_id: to_server_id,
        from_server_id: from_server_id,
        file_id: process.file_id,
        network_id: process.network_id,
        to_storage_id: data.destination_storage_id,
        connection_type: data.connection_type,
        type: data.type
      }

      {delete(process), [event]}
    end

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end

  defimpl Helix.Process.Public.View.ProcessViewable do
    
  end
end
