defmodule Helix.Software.Action.CryptoKey do

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.CryptoKey, as: CryptoKeyInternal
  alias Helix.Software.Model.CryptoKey
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  @spec create(Storage.t, Server.id, File.t) ::
    {:ok, CryptoKey.t}
    | {:error, Ecto.Changeset.t}
  defdelegate create(storage, server_id, target_file),
    to: CryptoKeyInternal

  @spec invalidate_keys_for_file(File.t) ::
    [Event.t]
  defdelegate invalidate_keys_for_file(file),
    to: CryptoKeyInternal
end
