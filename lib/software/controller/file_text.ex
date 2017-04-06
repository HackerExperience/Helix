defmodule Helix.Software.Controller.FileText do

  alias Helix.Software.Model.FileText
  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo

  @spec create(Storage.t, FileText.creation_params) ::
    {:ok, FileText.t}
    | {:error, Ecto.Changeset.t}
  def create(storage, params) do
    storage
    |> FileText.create(params)
    |> Repo.insert()
  end

  @spec fetch(File.t | File.id) ::
    FileText.t
    | nil
  def fetch(file) do
    file
    |> FileText.Query.from_file()
    |> Repo.one()
  end

  @spec update_contents(FileText.t, String.t) ::
    {:ok, FileText.t}
    | {:error, Ecto.Changeset.t}
  def update_contents(file_text, contents) do
    file_text
    |> FileText.update_contents(contents)
    |> Repo.update()
  end
end
