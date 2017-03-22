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

  @spec find(File.t | File.id) ::
    {:ok, FileText.t}
    | {:error, :notfound}
  def find(file) do
    result =
      file
      |> FileText.Query.from_file()
      |> Repo.one()

    case result do
      nil ->
        {:error, :notfound}
      file_text ->
        {:ok, file_text}
    end
  end

  @spec update_contents(FileText.t, String.t) ::
    {:ok, FileText.t} | {:error, Ecto.Changeset.t}
  def update_contents(file_text, contents) do
    file_text
    |> FileText.update_changeset(%{contents: contents})
    |> Repo.update()
  end
end