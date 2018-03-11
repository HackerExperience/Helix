defmodule Helix.Test.Event.Setup.Software do

  import HELL.Macros

  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.File

  alias Helix.Software.Event.File.Deleted, as: FileDeletedEvent
  alias Helix.Software.Event.File.Downloaded, as: FileDownloadedEvent
  alias Helix.Software.Event.File.DownloadFailed, as: FileDownloadFailedEvent
  alias Helix.Software.Event.File.Install.Processed,
    as: FileInstallProcessedEvent
  alias Helix.Software.Event.File.Uploaded, as: FileUploadedEvent
  alias Helix.Software.Event.File.UploadFailed, as: FileUploadFailedEvent
  alias Helix.Software.Event.Cracker.Bruteforce.Processed,
    as: BruteforceProcessedEvent
  alias Helix.Software.Event.Cracker.Overflow.Processed,
    as: OverflowProcessedEvent

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @internet NetworkHelper.internet_id()

  @doc """
  Accepts:
    Process.t
    | Connection.t, Server.id
  """
  def overflow_conclusion(process = %Process{}) do
    %OverflowProcessedEvent{
      gateway_id: process.gateway_id,
      target_process_id: process.process_id,
      target_connection_id: nil
    }
  end
  def overflow_conclusion(connection = %Connection{}, gateway_id) do
    %OverflowProcessedEvent{
      gateway_id: gateway_id,
      target_process_id: nil,
      target_connection_id: connection.connection_id
    }
  end

  def bruteforce_conclusion(process = %Process{}),
    do: BruteforceProcessedEvent.new(process, process.data)
  def bruteforce_conclusion do
    %BruteforceProcessedEvent{
      source_entity_id: EntitySetup.id(),
      network_id: @internet,
      target_id: Server.ID.generate(),
      target_server_ip: Random.ipv4()
    }
  end

  @doc """
  Generates a FileDeletedEvent
  """
  def file_deleted(file_id = %File.ID{}, server_id = %Server.ID{}),
    do: FileDeletedEvent.new(file_id, server_id)

  @doc """
  Generates a FileDownloaded event with real data.
  """
  def file_downloaded(connection_type: type) do
    file_downloaded()
    |> Map.replace!(:connection_type, type)
  end

  def file_downloaded do
    {event, _} = setup_env(:download, :completed)
    event
  end

  @doc """
  Generates a FileDownloadFailed event with real data.
  """
  def file_download_failed(reason) do
    {event, _} = setup_env(:download, {:failed, reason})
    event
  end

  @doc """
  Generates a FileUploaded event with real data.
  """
  def file_uploaded do
    {event, _} = setup_env(:upload, :completed)
    event
  end

  @doc """
  Generates a FileUploadFailed event with real data.
  """
  def file_upload_failed(reason) do
    {event, _} = setup_env(:upload, {:failed, reason})
    event
  end

  @doc """
  Generates a FileInstallProcessed event with fake data.
  """
  def file_install_processed(:virus, fake: true) do
    virus = SoftwareSetup.virus!()
    entity_id = EntitySetup.id()

    %FileInstallProcessedEvent{
      file: virus,
      entity_id: entity_id,
      backend: :virus
    }
  end

  @doc """
  Generates a FileInstallProcessed event with real data.
  """
  def file_install_processed(:virus) do
    {process, related} = SoftwareSetup.Flow.install_virus(with_bounce: true)

    {_, [event]} = TOPHelper.soft_complete(process)

    TOPHelper.top_stop(process.gateway_id)

    {event, related}
  end

  @spec setup_env(:download | :upload, :completed | :failed) ::
    {event :: term, related :: term}
  docp """
  `setup_env` is a helper to generate real FileTransfer data and return the
  requested event (FileDownloaded/Uploaded/DownloadFailed/UploadFailed).
  """
  defp setup_env(type, :completed) do
    # We'll generate the event data based on a real process.
    # That's not necessary, we could generate everything directly here, but by
    # using the process implementation, we are centralizing the implementation
    # in a singe place so future changes must be made only on SoftwareSetup.Flow
    {process, _} = SoftwareSetup.Flow.file_transfer(type)

    {_, [event]} = TOPHelper.soft_complete(process)

    # Stop TOP, since we've only used it to infer the event data.
    TOPHelper.top_stop(process.gateway_id)

    new_file =
      copy_file(process.tgt_file_id, process.data.destination_storage_id)

    event = generate_event(event, type, {:completed, new_file})
    {event, %{}}
  end

  defp setup_env(type, {:failed, reason}) do
    {process, _} = SoftwareSetup.Flow.file_transfer(type)
    {_, event} = TOPHelper.soft_complete(process)
    TOPHelper.top_stop(process.gateway_id)

    event = generate_event(event, type, {:failed, reason})
    {event, %{}}
  end

  defp generate_event(transfer, :download, {:completed, file}),
    do: FileDownloadedEvent.new(transfer, file)
  defp generate_event(transfer, :download, {:failed, reason}),
    do: FileDownloadFailedEvent.new(transfer, reason)
  defp generate_event(transfer, :upload, {:completed, file}),
    do: FileUploadedEvent.new(transfer, file)
  defp generate_event(transfer, :upload, {:failed, reason}),
    do: FileUploadFailedEvent.new(transfer, reason)

  docp """
  Helper that naively copies a file to a new storage, using Internal methods.
  """
  defp copy_file(file_id, storage_id, path \\ nil) do
    file = FileInternal.fetch(file_id)

    storage = StorageInternal.fetch(storage_id)

    path =
      if path do
        path
      else
        file.path
      end

    params = %{
        path: path,
        name: file.name
      }

    {:ok, new_file} = FileInternal.copy(file, storage, params)
    new_file
  end
end
