defmodule Helix.Software.Action.Storage do

  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage

  @spec create() ::
    {:ok, Storage.t}
    | {:error, Ecto.Changeset.t}
  defdelegate create,
    to: StorageInternal

  @spec delete(Storage.t) ::
    :ok
  defdelegate delete(storage),
    to: StorageInternal
end
