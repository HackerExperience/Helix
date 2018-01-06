defmodule Helix.Software.Model.Virus.Active do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.Virus

  @type t ::
    %__MODULE__{
      virus_id: Virus.id,
      entity_id: Entity.id,
      storage_id: Storage.id
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @creation_fields [:virus_id, :entity_id, :storage_id]
  @required_fields [:virus_id, :entity_id, :storage_id]

  @primary_key false
  schema "viruses_active" do
    field :virus_id, File.ID,
      primary_key: true

    field :entity_id, Entity.ID
    field :storage_id, Storage.ID

    belongs_to :virus, Virus,
      references: :file_id,
      foreign_key: :virus_id,
      define_field: false
  end

  @spec create(Virus.t, Storage.id) ::
    changeset
  def create(virus = %Virus{}, storage_id = %Storage.ID{}) do
    params =
      %{
        virus_id: virus.file_id,
        entity_id: virus.entity_id,
        storage_id: storage_id
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  query do

    alias Helix.Software.Model.Virus

    @spec by_virus(Queryable.t, Virus.id) ::
      Queryable.t
    def by_virus(query \\ Virus.Active, virus_id),
      do: where(query, [va], va.virus_id == ^virus_id)
  end
end
