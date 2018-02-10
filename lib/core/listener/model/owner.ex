defmodule Helix.Core.Listener.Model.Owner do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Core.Listener.Model.Listener

  @type t :: term

  @type id :: String.t

  @typedoc """
  A `subscriber` is used as an optional, internal identifier, for the case when
  different services are interested on the same {object_id, event}. On this 
  scenario, the `subscriber` can be used as an identifier to make sure the
  owner is deleting/updating the subscription made by himself.
  It's optional but good practice to set the subscriber name.
  """
  @type subscriber :: String.t

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
    |> unique_constraint(:owner_id_object_id_event_subscriber)
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Core.Listener.Model.Listener
    alias Helix.Core.Listener.Model.Owner

    @spec find_listener(
      Queryable.t,
      Owner.id,
      Listener.object_id,
      Listener.hashed_event,
      Owner.subscriber
    ) ::
      Queryable.t
    def find_listener(query \\ Owner, owner_id, object_id, event, subscriber) do
      from owner in query,
        where: owner.owner_id == ^owner_id,
        where: owner.object_id == ^object_id,
        where: owner.event == ^event,
        where: owner.subscriber == ^subscriber,
        preload: [:listener]
    end
  end
end
