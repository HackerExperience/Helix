defmodule Helix.Software.Action.File do

  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  @spec create(File.creation_params, File.modules) ::
    {:ok, File.t}
    | {:error, :internal}
  def create(file_params, modules) do
    # TODO: Check storage size
    case FileInternal.create(file_params, modules) do
      {:ok, file} ->
        {:ok, file}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec copy(File.t, Storage.t, FileInternal.copy_params) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  defdelegate copy(file, storage, params),
    to: FileInternal

  @spec move(File.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  defdelegate move(file, path),
    to: FileInternal

  @spec rename(File.t, name :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  defdelegate rename(file, name),
    to: FileInternal

  @spec encrypt(File.t, version :: pos_integer) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  defdelegate encrypt(file, version),
    to: FileInternal

  @spec decrypt(File.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  defdelegate decrypt(file),
    to: FileInternal

  @spec delete(File.t) ::
    :ok
  defdelegate delete(file),
    to: FileInternal
end
