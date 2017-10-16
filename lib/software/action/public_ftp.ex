defmodule Helix.Software.Action.PublicFTP do

  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.PublicFTP, as: PublicFTPInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Query.PublicFTP, as: PublicFTPQuery

  @spec enable_server(Server.t) ::
    {:ok, PublicFTP.t, [term]}
    | {:error, {:pftp, :already_enabled}}
  @doc """
  Enables a PublicFTP server. If no PFTP server exists for the given Server.t,
  we create a new one.
  """
  def enable_server(server = %Server{}) do
    result =
      case PublicFTPQuery.fetch_server(server) do
        pftp = %PublicFTP{is_active: false} ->
          PublicFTPInternal.enable_server(pftp)

        %PublicFTP{is_active: true} ->
          {:error, {:pftp, :already_enabled}}

        nil ->
          PublicFTPInternal.setup_server(server.server_id)
      end

    with {:ok, pftp} <- result do
      {:ok, pftp, []}
    end
  end

  @spec disable_server(PublicFTP.t) ::
    {:ok, PublicFTP.t, [term]}
    | {:error, :internal}
  @doc """
  Disables a PublicFTP server.
  """
  def disable_server(pftp = %PublicFTP{is_active: true}) do
    case PublicFTPInternal.disable_server(pftp) do
      {:ok, pftp} ->
        {:ok, pftp, []}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec add_file(PublicFTP.t, File.t) ::
    {:ok, PublicFTP.File.t, [term]}
    | {:error, :internal}
  @doc """
  Adds a file to a PublicFTP server.
  """
  def add_file(pftp = %PublicFTP{is_active: true}, file = %File{}) do
    case PublicFTPInternal.add_file(pftp, file.file_id) do
      {:ok, pftp_file} ->
        {:ok, pftp_file, []}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec remove_file(PublicFTP.t, PublicFTP.File.t) ::
    {:ok, PublicFTP.File.t, [term]}
    | {:error, :internal}
  @doc """
  Removes a file from a PublicFTP server.
  """
  def remove_file(%PublicFTP{is_active: true}, pftp_file = %PublicFTP.File{}) do
    case PublicFTPInternal.remove_file(pftp_file) do
      {:ok, pftp_file} ->
        {:ok, pftp_file, []}
      {:error, _} ->
        {:error, :internal}
    end
  end
end
