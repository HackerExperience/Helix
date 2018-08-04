import Helix.Process

process Helix.Software.Process.File.Transfer do
  @moduledoc """
  SoftwareFileTransferProcess is the process responsible for transferring files
  from one storage to another. It currently implements the `download`, `upload`
  and `pftp_download` backends.

  Its process data consists basically of which backend is being used, and what
  storage the file is being transferred to. All other information, e.g. which
  file is being transferred, is already present on the standard process data.
  """

  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  process_struct [:type, :destination_storage_id, :connection_type]

  @type t :: %__MODULE__{
    type: transfer_type,
    destination_storage_id: Storage.id,
    connection_type: connection_type
  }

  @type resources ::
    %{
      objective: objective,
      l_dynamic: [:dlk] | [:ulk],
      r_dynamic: [:ulk] | [:dlk],
      static: map
    }

  @type objective ::
    %{dlk: resource_usage}
    | %{ulk: resource_usage}

  @type process_type :: :file_download | :file_upload
  @type transfer_type :: :download | :upload
  @type connection_type :: :ftp | :public_ftp

  @type creation_params :: %{
    type: transfer_type,
    connection_type: connection_type,
    destination_storage_id: Storage.id
  }

  @type executable_meta :: %{
    file: File.t,
    type: process_type,
    network_id: Network.id,
    bounce: Bounce.idt | nil
  }

  @type resources_params :: %{
    type: transfer_type,
    file: File.t,
    network_id: Network.id
  }

  @spec new(creation_params, executable_meta) ::
    t
  def new(params = %{destination_storage_id: %Storage.ID{}}, _) do
    %__MODULE__{
      type: params.type,
      destination_storage_id: params.destination_storage_id,
      connection_type: params.connection_type
    }
  end

  @spec resources(resources_params) ::
    resources
  def resources(params = %{type: _, file: _, network_id: _}),
    do: get_resources params

  processable do
    @moduledoc """
    Processable handler for SoftwareFileTransferProcess

    All events emitted here are generic, i.e. they are not directly related to
    the backend using FileTransferProcess.

    For example, FileTransferProcessedEvent is emitted on conclusion, regardless
    if the backend is `download`, `upload` or `pftp_download`
    """

    alias Helix.Server.Model.Server
    alias Helix.Software.Model.Storage
    alias Helix.Software.Process.File.Transfer, as: FileTransferProcess

    alias Helix.Software.Event.File.Transfer.Aborted,
      as: FileTransferAbortedEvent
    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    @doc """
    Emits `FileTransferAbortedEvent.t` when/if process gets killed.
    """
    on_kill(process, data, _reason) do
      reason = :killed
      {from_id, to_id} = get_servers_context(data, process)

      event =
        FileTransferAbortedEvent.new(process, data, from_id, to_id, reason)

      {:delete, [event]}
    end

    @doc """
    Emits `FileTransferProcessedEvent.t` when process completes.
    """
    on_completion(process, data) do
      {from_id, to_id} = get_servers_context(data, process)
      event = FileTransferProcessedEvent.new(process, data, from_id, to_id)

      {:delete, [event]}
    end

    @spec get_servers_context(data :: term, process :: term) ::
      context :: {from_server :: Server.id, to_server :: Server.id}
    defp get_servers_context(%{type: :download}, process),
      do: {process.target_id, process.gateway_id}
    defp get_servers_context(%{type: :upload}, process),
        do: {process.gateway_id, process.target_id}

    def after_read_hook(data) do
      %FileTransferProcess{
        type: String.to_existing_atom(data.type),
        destination_storage_id: Storage.ID.cast!(data.destination_storage_id),
        connection_type: String.to_existing_atom(data.connection_type)
      }
    end
  end

  resourceable do
    @moduledoc """
    Sets the objectives to FileTransferProcess
    """

    alias Helix.Software.Process.File.Transfer, as: FileTransferProcess
    alias Helix.Software.Factor.File, as: FileFactor

    @type params :: FileTransferProcess.resources_params

    @type factors ::
      %{
        file: %{size: FileFactor.fact_size}
      }

    @doc """
    We only need to know the file size to figure out the process objectives.
    """
    get_factors(params) do
      factor Helix.Software.Factor.File, params, only: :size
    end

    @doc """
    Uses the downlink resource during download.
    """
    dlk(%{type: :download}) do
      f.file.size
    end

    @doc """
    Uses the uplink resource during upload.
    """
    ulk(%{type: :upload}) do
      f.file.size
    end

    network(%{network_id: network_id}) do
      network_id
    end

    # Safety fallbacks
    dlk(%{type: :upload})
    ulk(%{type: :download})

    dynamic(%{type: :download}) do
      [:dlk]
    end

    dynamic(%{type: :upload}) do
      [:ulk]
    end

    static do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end

    r_dynamic(%{type: :download}) do
      [:ulk]
    end

    r_dynamic(%{type: :upload}) do
      [:dlk]
    end
  end

  executable do
    @moduledoc """
    Defines how FileTransferProcess should be executed.
    """

    resources(_, _, params, meta) do
      %{
        type: params.type,
        file: meta.file,
        network_id: meta.network_id
      }
    end

    target_file(_gateway, _target, _params, %{file: file}) do
      file.file_id
    end

    source_connection(_gateway, _target, params, _) do
      {:create, params.connection_type}
    end
  end

  process_viewable do
    @moduledoc """
    Renders the FileTransferProcess to the client.
    """

    @type data ::
      data_download_full
      | data_download_partial
      | data_upload

    @typep download ::
      %{
        :type => :download,
        term => term
      }

    @typep upload ::
      %{
        :type => :upload,
        term => term
      }

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

    @spec render_data(download, :full) :: data_download_full
    @spec render_data(download, :partial) :: data_download_partial
    @spec render_data(upload, :full | :partial) :: data_upload

    render_data(data = %{type: :download}, :full) do
      %{
        connection_type: to_string(data.connection_type),
        storage_id: to_string(data.destination_storage_id)
      }
    end
    render_data(data = %{type: :download}, :partial) do
      %{
        connection_type: to_string(data.connection_type)
      }
    end
    render_data(_, _) do
      %{}
    end
  end
end
