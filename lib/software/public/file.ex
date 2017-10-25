defmodule Helix.Software.Public.File do

  alias Helix.Network.Model.Net
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.File, as: FileFlow
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  @type download_errors ::
    {:error, {:file, :not_found}}
    | {:error, {:storage, :not_found}}
    | {:error, :internal}

  @spec download(Server.t, Server.t, Tunnel.t, Storage.t, File.t) ::
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
    file = %File{})
  do
    net = Net.new(tunnel)

    transfer =
      FileTransferFlow.transfer(:download, gateway, target, file, storage, net)

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
    Network.id,
    Network.ip,
    term)
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
    network_id = %Network.ID{},
    target_ip,
    bounce_id)
  do
    params = %{
      target_server_ip: target_ip
    }

    meta = %{
      bounce: bounce_id,
      network_id: network_id,
      cracker: cracker
    }

    FileFlow.execute_file(cracker, :bruteforce, gateway, target, params, meta)
  end
end
