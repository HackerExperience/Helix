defmodule Helix.Software.Internal.PublicFTP do

  alias Hector
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Repo

  def fetch(server_id) do
    server_id
    |> PublicFTP.Query.by_server()
    |> Repo.one()
  end

  def list_files(server_id) do
    query = PublicFTP.Query.list_files(server_id)

    Hector.get(Repo, query, load: File)
  end

  def setup_server(server_id) do
    %{server_id: server_id}
    |> PublicFTP.create_changeset()
    |> Repo.insert()
  end

  def enable_server(pftp = %PublicFTP{}) do
    pftp
    |> PublicFTP.enable_server()
    |> update()
  end

  def disable_server(pftp = %PublicFTP{}) do
    pftp
    |> PublicFTP.disable_server()
    |> update()
  end

  def add_file(pftp = %PublicFTP{}, file_id) do
    pftp.server_id
    |> PublicFTP.Files.add_file(file_id)
    |> Repo.insert()
  end

  def remove_file(pftp = %PublicFTP{}, file_id) do
    # pftp.server_id
    # |> PublicFTP.Files.remove_file(file_id)
    # |> Repo.
  end

  defp update(changeset),
    do: Repo.update(changeset)
end
