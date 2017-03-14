defmodule Helix.Software.Controller.Storage do

  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo

  import Ecto.Query, only: [where: 3]

  @spec create() :: {:ok, Storage.t} | {:error, Ecto.Changeset.t}
  def create do
    Storage.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(HELL.PK.t) :: Storage.t | nil
  def fetch(storage_id),
    do: Repo.get(Storage, storage_id)

  @spec delete(HELL.PK.t) :: no_return
  def delete(storage_id) do
    Storage
    |> where([s], s.storage_id == ^storage_id)
    |> Repo.delete_all()

    :ok
  end
end