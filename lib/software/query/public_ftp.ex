defmodule Helix.Software.Query.PublicFTP do

  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.PublicFTP, as: PublicFTPInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP

  @spec fetch_file(File.idt) ::
    PublicFTP.File.t
    | nil
  @doc """
  Returns the corresponding PublicFTP.File entry if:

  - The given file exists on the PublicFTP server AND
  - The PublicFTP server is active.
  """
  def fetch_file(file = %File{}),
    do: fetch_file(file.file_id)
  def fetch_file(file_id = %File.ID{}),
    do: PublicFTPInternal.fetch_file(file_id)

  @spec fetch_server(Server.idt) ::
    PublicFTP.t
    | nil
  @doc """
  Returns the PublicFTP entry of the server, if one exists.

  Disabled/inactive servers are returned as well.
  """
  def fetch_server(server = %Server{}),
    do: fetch_server(server.server_id)
  def fetch_server(server_id = %Server.ID{}),
    do: PublicFTPInternal.fetch(server_id)

  @spec list_files(Server.idt) ::
    [File.t]
  @doc """
  Returns a list of all files that exist on the given PublicFTP server.

  Returns an empty list if the server is disabled, even if there are files on it 
  """
  def list_files(server = %Server{}),
    do: list_files(server.server_id)
  def list_files(server_id = %Server.ID{}),
    do: PublicFTPInternal.list_files(server_id)
end
