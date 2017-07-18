defmodule Helix.Software.Query.File do

  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.File, as: FileQueryOrigin

  @spec fetch(File.id) ::
    File.t
    | nil
  defdelegate fetch(file_id),
    to: FileQueryOrigin

  @spec storage_contents(Storage.t) ::
    %{folder :: String.t => [File.t]}
  defdelegate storage_contents(storage),
    to: FileQueryOrigin

  @spec files_on_storage(Storage.t) ::
    [File.t]
  defdelegate files_on_storage(storage),
    to: FileQueryOrigin

  @spec get_modules(File.t) ::
    File.modules
  defdelegate get_modules(file),
    to: FileQueryOrigin

  defmodule Origin do

    alias Helix.Software.Internal.File, as: FileInternal

    def fetch(file_id) do
      FileInternal.fetch(file_id)
    end

    def storage_contents(storage) do
      storage
      |> FileInternal.get_files_on_target_storage()
      |> Enum.group_by(&(&1.path))
    end

    def files_on_storage(storage) do
      FileInternal.get_files_on_target_storage(storage)
    end

    def get_modules(file) do
      FileInternal.get_modules(file)
    end

  end
end
