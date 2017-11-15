defmodule Helix.Software.Public.PFTP do
  @moduledoc """
  Public layer of the PublicFTP feature -- shortened to PFTP to avoid confusion.
  """

  alias Helix.Event
  alias Helix.Network.Model.Net
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow
  alias Helix.Software.Action.Flow.PublicFTP, as: PublicFTPFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.PublicFTP, as: PublicFTPQuery
  alias Helix.Software.Public.Index, as: SoftwareIndex

  @internet_id NetworkQuery.internet().network_id

  @spec enable_server(Server.t) ::
    {:ok, PublicFTP.t}
    | {:error, {:pftp, :already_enabled}}
  def enable_server(server = %Server{}),
    do: PublicFTPFlow.enable_server(server)

  @spec disable_server(PublicFTP.t) ::
    {:ok, PublicFTP.t}
    | {:error, :internal}
  def disable_server(pftp = %PublicFTP{}),
    do: PublicFTPFlow.disable_server(pftp)

  @spec add_file(PublicFTP.t, File.t) ::
    {:ok, PublicFTP.File.t}
    | {:error, :internal}
  def add_file(pftp = %PublicFTP{}, file = %File{}),
    do: PublicFTPFlow.add_file(pftp, file)

  @spec remove_file(PublicFTP.t, PublicFTP.File.t) ::
    {:ok, PublicFTP.File.t}
    | {:error, :internal}
  def remove_file(pftp = %PublicFTP{}, pftp_file = %PublicFTP.File{}),
    do: PublicFTPFlow.remove_file(pftp, pftp_file)

  @spec list_files(PublicFTP.t | Server.idt) ::
    [File.t]
  @doc """
  Returns a list of all files within the Public FTP server.
  """
  def list_files(pftp = %PublicFTP{}),
    do: list_files(pftp.server_id)
  def list_files(server = %Server{}),
    do: list_files(server.server_id)
  def list_files(server_id = %Server.ID{}),
    do: PublicFTPQuery.list_files(server_id)

  @spec render_list_files([File.t]) ::
    [SoftwareIndex.rendered_index_file]
  @doc """
  Renders the list of files in a Public FTP (retrieved from `list_files/1`) into
  a JSON-friendly format.
  """
  def render_list_files(files),
    do: Enum.map(files, &SoftwareIndex.render_file/1)

  @spec download(Server.t, Server.t, Storage.t, File.t, Event.relay) ::
    {:ok, Process.t}
    | FileTransferFlow.transfer_error
  @doc """
  Starts the download process of a file on a PublicFTP server.
  """
  def download(
    gateway = %Server{},
    destination = %Server{},
    storage = %Storage{},
    file = %File{},
    relay)
  do
    # PFTP downloads are "public", so must always happen over the internet.
    network_id = @internet_id

    net = Net.new(network_id, [])

    transfer =
      FileTransferFlow.pftp_download(
        gateway, destination, file, storage, net, relay
      )

    case transfer do
      {:ok, process} ->
        {:ok, process}

      {:error, _} ->
        {:error, :internal}
    end
  end
end
