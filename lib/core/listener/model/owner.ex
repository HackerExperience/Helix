defmodule Helix.Core.Listener.Model.Owner do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Macros

  alias Ecto.Changeset
  alias Helix.Core.Listener.Model.Listener

  @type t :: term
  @type changeset :: %Changeset{data: %__MODULE__{}}
  @type creation_params :: term

  @creation_fields [:listener_id, :owner_id, :object_id, :event, :subscriber]
  @required_fields [:listener_id, :owner_id, :object_id, :event, :subscriber]

  @primary_key false
  schema "owners" do
    field :listener_id, Ecto.UUID,
      primary_key: true
    field :owner_id, :string
    field :object_id, :string
    field :event, Ecto.UUID
    field :subscriber, :string

    belongs_to :listener, Listener,
      foreign_key: :listener_id,
      references: :listener_id,
      define_field: false
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  defmodule Query do

    import Ecto.Query

    alias Helix.Core.Listener.Model.Owner

    def find_listener(query \\ Owner, owner_id, object_id, event, subscriber) do
      from owner in Owner,
        where: owner.owner_id == ^owner_id,
        where: owner.object_id == ^object_id,
        where: owner.event == ^event,
        where: owner.subscriber == ^subscriber,
        preload: [:listener]
    end

  end
end
