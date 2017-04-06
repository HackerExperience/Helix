defmodule Helix.Software.Controller.FileText do

  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileText
  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo

  @spec create(Storage.t, String.t, String.t, String.t) ::
    {:ok, FileText.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a `file text` on `storage`
  """
  def create(storage, name, path, contents \\ "") do
    storage
    |> FileText.create(name, path, contents)
    |> Repo.insert()
  end

  @spec fetch!(File.t | File.id) ::
    FileText.t
    | nil
  @doc """
  Fetches a `file text` by their id or their file
  """
  def fetch!(%File{file_id: id}),
    do: fetch!(id)
  def fetch!(id),
    do: Repo.get!(FileText, id)

  @spec update_contents(FileText.t, String.t) ::
    {:ok, FileText.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Updates `file text` contents
  """
  def update_contents(file_text, contents) do
    file_text
    |> FileText.update_contents(contents)
    |> Repo.update()
  end
end
