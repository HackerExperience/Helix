defmodule Helix.Software.Service.API.File do

  alias HELL.PK
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  @spec create(File.creation_params) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    FileController.create(params)
  end

  @spec fetch(PK.t) ::
    File.t
    | nil
  def fetch(file_id) do
    FileController.fetch(file_id)
  end

  @spec storage_contents(Storage.t) ::
    %{folder :: String.t => [File.t]}
  def storage_contents(storage) do
    storage
    |> FileController.get_files_on_target_storage()
    |> Enum.group_by(&(&1.path), &(&1))
  end

  @spec files_on_storage(Storage.t) ::
    [File.t]
  def files_on_storage(storage) do
    FileController.get_files_on_target_storage(storage)
  end

  @spec copy(File.t, Storage.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def copy(file, storage, path) do
    FileController.copy(file, storage, path)
  end

  @spec move(File.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def move(file, path) do
    FileController.move(file, path)
  end

  @spec rename(File.t, name :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def rename(file, name) do
    FileController.rename(file, name)
  end

  @spec encrypt(File.t, version :: pos_integer) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def encrypt(file, version) do
    FileController.encrypt(file, version)
  end

  @spec decrypt(File.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def decrypt(file) do
    FileController.decrypt(file)
  end

  @spec delete(File.t) :: :ok
  def delete(file) do
    FileController.delete(file)
  end
end
