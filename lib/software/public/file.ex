defmodule Helix.Software.Public.File do

  alias Helix.Event
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.File, as: FileFlow
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  alias Helix.Software.Process.File.Install, as: FileInstallProcess

  @type download_errors ::
    {:error, {:file, :not_found}}
    | {:error, {:storage, :not_found}}
    | {:error, :internal}

  @typep relay :: Event.relay

  @spec download(Server.t, Server.t, Tunnel.t, Storage.t, File.t, relay) ::
    {:ok, Process.t}
    | FileTransferFlow.transfer_error
  @doc """
  Starts FileTransferProcess, responsible for downloading `file_id` into the
  given storage.
  """
  def download(
    gateway = %Server{},
    target = %Server{},
    tunnel = %Tunnel{},
    storage = %Storage{},
    file = %File{},
    relay)
  do
    transfer =
      FileTransferFlow.download(gateway, target, file, storage, tunnel, relay)

    case transfer do
      {:ok, process} ->
        {:ok, process}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec upload(Server.t, Server.t, Tunnel.t, Storage.t, File.t, relay) ::
    {:ok, Process.t}
    | FileTransferFlow.transfer_error
  @doc """
  Starts FileTransferProcess, responsible for uploading `file_id` into the given
  storage.
  """
  def upload(
    gateway = %Server{},
    target = %Server{},
    tunnel = %Tunnel{},
    storage = %Storage{},
    file = %File{},
    relay)
  do
    transfer =
      FileTransferFlow.upload(gateway, target, file, storage, tunnel, relay)

    case transfer do
      {:ok, process} ->
        {:ok, process}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec bruteforce(
    File.t_of_type(:cracker),
    gateway :: Server.t,
    target :: Server.t,
    target_nip :: {Network.id, Network.ip},
    Tunnel.bounce,
    relay)
  ::
    {:ok, Process.t}
    | FileFlow.bruteforce_execution_error
  @doc """
  Starts a bruteforce attack against `(network_id, target_ip)`, originating from
  `gateway_id` and having `bounce` as intermediaries.
  """
  def bruteforce(
    cracker = %File{software_type: :cracker},
    gateway = %Server{},
    target = %Server{},
    {network_id = %Network.ID{}, target_ip},
    bounce,
    relay)
  do
    params = %{
      target_server_ip: target_ip
    }

    meta = %{
      bounce: bounce,
      network_id: network_id,
      cracker: cracker
    }

    FileFlow.execute_file(
      {cracker, :bruteforce}, gateway, target, params, meta, relay
    )
  end

  @spec install(
    File.t,
    Server.t,
    Server.t,
    FileInstallProcess.backend,
    {Tunnel.t, Connection.ssh},
    Event.relay)
  ::
    {:ok, Process.t}
    | FileFlow.file_install_execution_error
  @doc """
  Installs a generic file using FileInstallProcess with the given `backend`.
  """
  def install(file = %File{}, gateway, target, backend, {tunnel, ssh}, relay) do
    params = %{backend: backend}
    meta =
      %{
        file: file,
        network_id: tunnel.network_id,
        bounce: tunnel.bounce_id,
        ssh: ssh
      }

    process_type = FileInstallProcess.get_process_type(params, meta)

    install_process =
      ProcessQuery.get_custom(
        process_type, gateway.server_id, %{tgt_file_id: file.file_id}
      )

    # Verifies whether the given file is already being installed, in which case
    # we immediately return the existing process
    case install_process do
      [process] ->
        {:ok, process}

      nil ->
        FileFlow.execute_file(
          :generic_install, gateway, target, params, meta, relay
        )
    end
  end
end
