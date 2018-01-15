defmodule Helix.Software.Public.File do

  alias Helix.Event
  alias Helix.Network.Model.Net
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
    net = Net.new(tunnel)

    transfer =
      FileTransferFlow.download(gateway, target, file, storage, net, relay)

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
    term,
    relay)
  ::
    {:ok, Process.t}
    | FileFlow.bruteforce_execution_error
  @doc """
  Starts a bruteforce attack against `(network_id, target_ip)`, originating from
  `gateway_id` and having `bounces` as intermediaries.
  """
  def bruteforce(
    cracker = %File{software_type: :cracker},
    gateway = %Server{},
    target = %Server{},
    {network_id = %Network.ID{}, target_ip},
    bounce_id,
    relay)
  do
    params = %{
      target_server_ip: target_ip
    }

    meta = %{
      bounce: bounce_id,
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
    Network.id,
    Event.relay)
  ::
    {:ok, Process.t}
    | FileFlow.file_install_execution_error
  @doc """
  Installs a generic file using FileInstallProcess with the given `backend`.
  """
  def install(file = %File{}, gateway, target, backend, network_id, relay) do
    process_type = FileInstallProcess.get_process_type(backend)

    params = %{backend: backend}
    meta =
      %{
        file: file,
        type: process_type,
        network_id: network_id
      }

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
