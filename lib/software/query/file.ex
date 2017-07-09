defmodule Helix.Software.Query.File do

  alias HELL.PK
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  @spec fetch(PK.t) ::
    File.t
    | nil
  def fetch(file_id) do
    FileInternal.fetch(file_id)
  end

  @spec storage_contents(Storage.t) ::
    %{folder :: String.t => [File.t]}
  def storage_contents(storage) do
    storage
    |> FileInternal.get_files_on_target_storage()
    |> Enum.group_by(&(&1.path))
  end

  @spec files_on_storage(Storage.t) ::
    [File.t]
  def files_on_storage(storage) do
    FileInternal.get_files_on_target_storage(storage)
  end

  @spec get_modules(File.t) :: File.modules
  def get_modules(file) do
    FileInternal.get_modules(file)
  end
end
