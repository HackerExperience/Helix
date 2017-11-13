defmodule Helix.Software.Make.PFTP do

  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.PublicFTP, as: PublicFTPFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP

  def server(server = %Server{}, _data \\ %{}) do
    {:ok, pftp} = PublicFTPFlow.enable_server(server)
    pftp
  end

  def add_file(file = %File{}, pftp = %PublicFTP{}, _data \\ %{}) do
    {:ok, pftp_file} = PublicFTPFlow.add_file(pftp, file)
    pftp_file
  end
end
