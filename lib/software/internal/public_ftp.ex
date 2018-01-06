defmodule Helix.Software.Internal.PublicFTP do

  alias Hector
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Repo

  @typep update_pftp_repo ::
    {:ok, PublicFTP.t}
    | {:error, PublicFTP.changeset}

  @spec fetch(Server.id) ::
    PublicFTP.t
    | nil
  def fetch(server_id) do
    server_id
    |> PublicFTP.Query.by_server()
    |> Repo.one()
  end

  @spec fetch_file(File.id) ::
    PublicFTP.File.t
    | nil
  def fetch_file(file_id) do
    file_id
    |> PublicFTP.File.Query.by_file()
    |> Repo.one()
  end

  @spec list_files(Server.id) ::
    [File.t]
  def list_files(server_id) do
    server_id
    |> PublicFTP.Query.list_files()
    |> Repo.all()
    |> Enum.map(&FileInternal.format/1)
  end

  @spec setup_server(Server.id) ::
    {:ok, PublicFTP.t}
    | {:error, PublicFTP.changeset}
  @doc """
  Creates a new PublicFTP server.
  """
  def setup_server(server_id) do
    server_id
    |> PublicFTP.create_server()
    |> Repo.insert()
  end

  @spec enable_server(PublicFTP.t) ::
    update_pftp_repo
  @doc """
  Marks an existing PublicFTP server as enabled.
  """
  def enable_server(pftp = %PublicFTP{}) do
    pftp
    |> PublicFTP.enable_server()
    |> update()
  end

  @spec disable_server(PublicFTP.t) ::
    update_pftp_repo
  @doc """
  Marks an existing PublicFTP server as disabled.
  """
  def disable_server(pftp = %PublicFTP{}) do
    pftp
    |> PublicFTP.disable_server()
    |> update()
  end

  @spec add_file(PublicFTP.t, File.id) ::
    {:ok, PublicFTP.File.t}
    | {:error, PublicFTP.File.changeset}
  @doc """
  Adds a file to a PublicFTP server.
  """
  def add_file(pftp = %PublicFTP{}, file_id) do
    pftp.server_id
    |> PublicFTP.File.add_file(file_id)
    |> Repo.insert()
  end

  @spec remove_file(PublicFTP.File.t) ::
    {:ok, PublicFTP.File.t}
    | {:error, PublicFTP.File.changeset}
  @doc """
  Removes a file from a PublicFTP server.
  """
  def remove_file(pftp_file = %PublicFTP.File{}),
    do: Repo.delete(pftp_file)

  @spec update(PublicFTP.changeset | PublicFTP.File.changeset) ::
    update_pftp_repo
  defp update(changeset),
    do: Repo.update(changeset)
end
