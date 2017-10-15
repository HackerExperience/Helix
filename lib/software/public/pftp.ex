defmodule Helix.Software.Public.PFTP do
  @moduledoc """
  Public layer of the PublicFTP feature -- shortened to PFTP to avoid confusion.
  """

  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow
  alias Helix.Software.Action.Flow.PublicFTP, as: PublicFTPFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Model.Storage

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

  def download(
    gateway_id = %Server.ID{},
    pftp_file = %PublicFTP.File{},
    storage = %Storage{},
    file = %File{})
  do
    # PFTP downloads are "public", so must always happen over the internet.
    network_id = @internet_id

    network_info =
      %{
        gateway_id: gateway_id,
        destination_id: pftp_file.server_id,
        network_id: network_id,
        bounces: []  # TODO 256
      }

    transfer =
      FileTransferFlow.transfer(:pftp_download, file, storage, network_info)

    case transfer do
      {:ok, process} ->
        {:ok, process}

      {:error, _} ->
        {:error, :internal}
    end
  end
end
