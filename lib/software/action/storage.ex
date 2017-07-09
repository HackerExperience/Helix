defmodule Helix.Software.Action.Storage do

  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage

  @spec create() :: {:ok, Storage.t} | {:error, Ecto.Changeset.t}
  def create do
    StorageInternal.create()
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(storage_id) do
    StorageInternal.delete(storage_id)

    :ok
  end
end
