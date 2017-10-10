# defmodule Helix.Software.Internal.TextFile do

#   alias Helix.Software.Model.File
#   alias Helix.Software.Model.TextFile
#   alias Helix.Software.Model.Storage
#   alias Helix.Software.Repo

#   @spec create(Storage.t, String.t, String.t, String.t) ::
#     {:ok, TextFile.t}
#     | {:error, Ecto.Changeset.t}
#   @doc """
#   Creates a `text file` on `storage`
#   """
#   def create(storage, name, path, contents) do
#     storage
#     |> TextFile.create(name, path, contents)
#     |> Repo.insert()
#   end

#   @spec fetch!(File.t | File.id) ::
#     TextFile.t
#     | nil
#   @doc """
#   Fetches a `text file` by their id or their file
#   """
#   def fetch!(%File{file_id: id}),
#     do: fetch!(id)
#   def fetch!(id),
#     do: Repo.get!(TextFile, id)

#   @spec update_contents(TextFile.t, String.t) ::
#     {:ok, TextFile.t}
#     | {:error, Ecto.Changeset.t}
#   @doc """
#   Updates `text file` contents
#   """
#   def update_contents(text_file, contents) do
#     text_file
#     |> TextFile.update_contents(contents)
#     |> Repo.update()
#   end
# end
