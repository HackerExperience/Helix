defmodule Helix.Software.Public.PFTP do
  @moduledoc """
  Public layer of the PublicFTP feature -- shortened to PFTP to avoid confusion.
  """

  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.PublicFTP, as: PublicFTPFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP

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
end
