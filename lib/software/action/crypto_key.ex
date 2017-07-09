defmodule Helix.Software.Action.CryptoKey do

  alias Helix.Event
  alias Helix.Software.Internal.CryptoKey, as: CryptoKeyInternal
  alias Helix.Software.Model.CryptoKey
  alias Helix.Software.Model.File

  @spec create(Storage.t, HELL.PK.t, File.t) ::
    {:ok, CryptoKey.t}
    | {:error, Ecto.Changeset.t}
  def create(storage, server_id, target_file) do
    CryptoKeyInternal.create(storage, server_id, target_file)
  end

  @spec invalidate_keys_for_file(File.t) :: [Event.t]
  def invalidate_keys_for_file(file = %File{}) do
    CryptoKeyInternal.invalidate_keys_for_file(file)
  end
end
