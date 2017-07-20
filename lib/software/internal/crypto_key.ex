defmodule Helix.Software.Internal.CryptoKey do

  import Ecto.Query, only: [select: 3]

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.CryptoKey
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo

  @spec create(Storage.t, Server.id, File.t) ::
    {:ok, CryptoKey.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a key on `storage` to decrypt `target_file` that is on `server_id`
  """
  def create(storage, server_id, target_file) do
    storage
    |> CryptoKey.create(server_id, target_file)
    |> Repo.insert()
  end

  @spec fetch!(File.t | File.id) ::
    CryptoKey.t
    | nil
  @doc """
  Fetches a key by their id or their file
  """
  def fetch!(%File{file_id: id}),
    do: fetch!(id)
  def fetch!(id),
    do: Repo.get!(CryptoKey, id)

  @spec get_on_storage(Storage.t) ::
    [CryptoKey.t]
  @doc """
  Gets the keys on `storage`
  """
  def get_on_storage(storage) do
    storage
    |> CryptoKey.Query.from_storage()
    |> Repo.all()
  end

  @spec get_files_targeted_on_storage(Storage.t, Storage.t) ::
    [File.id]
  @doc """
  Returns the id of all files on `target_storage` for whom there is a key on
  `origin_storage`

  ## Example

      iex> get_files_targeted_on_storage(%Storage{}, %Storage{})
      ["aa::bb", "cc::dd"]
  """
  def get_files_targeted_on_storage(origin_storage, target_storage) do
    origin_storage
    |> CryptoKey.Query.from_storage()
    |> CryptoKey.Query.target_files_on_storage(target_storage)
    |> select([k], k.target_file_id)
    |> Repo.all()
  end

  @spec invalidate_keys_for_file(File.t) ::
    [Event.t]
  @doc """
  Invalidates all keys that affect `file`
  """
  def invalidate_keys_for_file(file = %File{}) do
    file
    |> CryptoKey.Query.target_file()
    |> Repo.update_all([set: [target_file_id: nil]], returning: [:file_id])
    |> elem(1) # First element on tuple is the amount of affected records
    |> Enum.map(&CryptoKey.InvalidatedEvent.event/1)
  end
end
