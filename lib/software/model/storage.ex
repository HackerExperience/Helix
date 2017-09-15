defmodule Helix.Software.Model.Storage do

  use Ecto.Schema
  use HELL.ID, field: :storage_id, meta: [0x0020, 0x0001]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Software.Model.File
  alias Helix.Software.Model.StorageDrive

  @type t :: %__MODULE__{
    storage_id: id,
    drives: term,
    files: term
  }

  schema "storages" do
    field :storage_id, ID,
      primary_key: true

    has_many :drives, StorageDrive,
      foreign_key: :storage_id,
      references: :storage_id
    has_many :files, File,
      foreign_key: :storage_id,
      references: :storage_id
  end

  @spec create_changeset() ::
    Changeset.t
  def create_changeset,
    do: cast(%__MODULE__{}, %{}, [])

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Software.Model.Storage
    alias Helix.Software.Model.StorageDrive

    @spec by_id(Queryable.t, Storage.idtb) ::
      Queryable.t
    def by_id(query \\ Storage, id),
      do: where(query, [s], s.storage_id == ^id)

    @spec by_hdd(Queryable.t, Component.idtb) ::
      Queryable.t
    def by_hdd(query \\ Storage, hdd_id) do
      query
      |> join(:inner, [s], sd in StorageDrive, s.storage_id == sd.storage_id)
      |> where([s, sd], sd.drive_id == ^hdd_id)
    end
  end
end
