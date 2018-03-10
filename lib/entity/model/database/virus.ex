defmodule Helix.Entity.Model.Database.Virus do
  @moduledoc """
  `Database.Virus` keeps track of all viruses installed by the Entity, linking
  it to a `Database.Server`. It is basically a cache over `Software.Virus`,
  which holds all information about the virus, including its running time,
  whether it's active or not etc.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Entity.Model.Entity

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type t ::
    %__MODULE__{
      entity_id: Entity.id,
      server_id: Server.id,
      file_id: File.id
    }

  @type creation_params ::
    %{
      entity_id: Entity.id,
      server_id: Server.id,
      file_id: File.id
    }

  @creation_fields [:entity_id, :server_id, :file_id]
  @required_fields [:entity_id, :server_id, :file_id]

  @primary_key false
  schema "database_viruses" do
    field :entity_id, Entity.ID,
      primary_key: true
    field :server_id, Server.ID,
      primary_key: true
    field :file_id, File.ID,
      primary_key: true
  end

  @spec create_changeset(creation_params) ::
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  query do

    alias Helix.Entity.Model.Database
    alias Helix.Entity.Model.Entity

    @spec by_file(Queryable.t, File.id) ::
      Queryable.t
    def by_file(query \\ Database.Virus, file_id),
      do: where(query, [dv], dv.file_id == ^file_id)
  end
end
