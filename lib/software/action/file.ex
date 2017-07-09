defmodule Helix.Software.Action.File do

  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  @spec create(File.creation_params) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    FileInternal.create(params)
  end

  @spec copy(File.t, Storage.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def copy(file, storage, path) do
    FileInternal.copy(file, storage, path)
  end

  @spec move(File.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def move(file, path) do
    FileInternal.move(file, path)
  end

  @spec rename(File.t, name :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def rename(file, name) do
    FileInternal.rename(file, name)
  end

  @spec encrypt(File.t, version :: pos_integer) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def encrypt(file, version) do
    FileInternal.encrypt(file, version)
  end

  @spec decrypt(File.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def decrypt(file) do
    FileInternal.decrypt(file)
  end

  @spec delete(File.t) :: :ok
  def delete(file) do
    FileInternal.delete(file)
  end
end
