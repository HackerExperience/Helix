defmodule Helix.Software.Controller.FileText do

  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileText
  alias Helix.Software.Repo

  @spec create(FileText.creation_params) ::
    {:ok, FileText.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> FileText.create_changeset()
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
    {:ok, FileText.t} | {:error, Ecto.Changeset.t}
  def update_contents(file_text, contents) do
    file_text
    |> FileText.update_changeset(%{contents: contents})
    |> Repo.update()
  end
end
