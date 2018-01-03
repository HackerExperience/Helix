defmodule Helix.Software.Make.PFTP do

  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.PublicFTP, as: PublicFTPFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP

  @spec server(Server.t) ::
    {:ok, PublicFTP.t, %{}}
  def server(server = %Server{}) do
    {:ok, pftp} = PublicFTPFlow.enable_server(server)

    {:ok, pftp, %{}}
  end

  @spec add_file(File.t, PublicFTP.t) ::
    {:ok, PublicFTP.File.t, %{}}
  def add_file(file = %File{}, pftp = %PublicFTP{}) do
    {:ok, pftp_file} = PublicFTPFlow.add_file(pftp, file)

    {:ok, pftp_file, %{}}
  end
end
